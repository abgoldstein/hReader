//
//  HRAPIClient.m
//  HReader
//
//  Created by Caleb Davenport on 5/30/12.
//  Copyright (c) 2012 MITRE Corporation. All rights reserved.
//

#import <SecureFoundation/SecureFoundation.h>

#import "HRAPIClient_private.h"
#import "HRCryptoManager.h"
#import "HRRHExLoginViewController.h"

#import "DDXML.h"

#define hr_dispatch_main(block) dispatch_async(dispatch_get_main_queue(), block)

// Managing hosts for authentication and patient data
static NSString * const HROAuthKeychainService = @"org.hreader.oauth.2";
static NSMutableDictionary *allClients = nil;
static NSMutableDictionary *knownHostData = nil;

@interface NSString (HRAPIClientAdditions)
- (NSString *)hr_percentEncodedString;
@end

@interface HRAPIClient () {
    NSString *_host;
    NSString *_accessToken;
    NSDate *_accessTokenExpirationDate;
    NSArray *_patientFeed;
    NSConditionLock *_authorizationLock;
    dispatch_queue_t _requestQueue;
}

@end

@implementation HRAPIClient

#pragma mark - class methods

+ (NSLock *)authorizationLock {
    static NSLock *lock = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        lock = [[NSLock alloc] init];
    });
    return lock;
}

+ (HRAPIClient *)clientWithHost:(NSString *)host {
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        allClients = [[NSMutableDictionary alloc] initWithCapacity:1];
    });
    HRAPIClient *client = [allClients objectForKey:host];
    if (client == nil) {
        client = [[HRAPIClient alloc] initWithHost:host];
        [allClients setObject:client forKey:host];
    }
    return client;
}

+ (NSArray *)hosts {
    NSArray *accounts = [IMSKeychain accountsForService:HROAuthKeychainService];
    NSArray *hosts = [accounts valueForKey:(__bridge NSString *)kSecAttrAccount];
    
    return [[IMSKeychain accountsForService:HROAuthKeychainService] valueForKey:(__bridge NSString *)kSecAttrAccount];
}

+ (NSString *)queryStringWithParameters:(NSDictionary *)parameters {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[parameters count]];
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [array addObject:[NSString stringWithFormat:@"%@=%@", [key hr_percentEncodedString], [obj hr_percentEncodedString]]];
    }];
    return [array componentsJoinedByString:@"&"];
}

+ (NSDictionary *)parametersFromQueryString:(NSString *)string {
    NSArray *array = [string componentsSeparatedByString:@"&"];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:[array count]];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSUInteger location = [obj rangeOfString:@"="].location;
        if (location != NSNotFound) {
            NSString *key = [obj substringToIndex:location];
            NSString *value = [obj substringFromIndex:(location + 1)];
            [dictionary setObject:value forKey:key];
        }
    }];
    return dictionary;
}

+ (NSMutableDictionary *)knownHosts {
    if (!knownHostData) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"known-hosts" ofType:@"plist"];
        knownHostData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    }
    
    return knownHostData;
}

#pragma mark - retrieve data from the api

- (void)patientFeed:(void (^)(NSArray *patients))completion ignoreCache:(BOOL)ignore {
    dispatch_async(_requestQueue, ^{
        hr_dispatch_main(^{
            [[UIApplication sharedApplication] hr_pushNetworkOperation];
        });
        NSArray *feed = _patientFeed;
        
        // check time stamp
        NSTimeInterval interval = ABS([_patientFeedLastFetchDate timeIntervalSinceNow]);
        if (interval > 50 * 5 || _patientFeedLastFetchDate == nil || ignore) {
            
            // get the request
            NSMutableURLRequest *request = [self GETRequestWithPath:@"/"];
            
            // run request
            NSError *error = nil;
            NSHTTPURLResponse *response = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
            // get ids
            DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
            [[document rootElement] addNamespace:[DDXMLNode namespaceWithName:@"atom" stringValue:@"http://www.w3.org/2005/Atom"]];
            NSArray *IDs = [[document nodesForXPath:@"/atom:feed/atom:entry/atom:id" error:nil] valueForKey:@"stringValue"];
            NSArray *names = [[document nodesForXPath:@"/atom:feed/atom:entry/atom:title" error:nil] valueForKey:@"stringValue"];
            
            // build array
            if ([response statusCode] == 200 && IDs && [IDs count] == [names count]) {
                NSMutableArray *patients = [[NSMutableArray alloc] initWithCapacity:[IDs count]];
                [IDs enumerateObjectsUsingBlock:^(NSString *patientID, NSUInteger idx, BOOL *stop) {
                    NSDictionary *dict = @{
                        @"id" : patientID,
                        @"name" : [names objectAtIndex:idx]
                    };
                    [patients addObject:dict];
                }];
                _patientFeed = feed = [patients copy];
                _patientFeedLastFetchDate = [NSDate date];
            }
            else { feed = nil; }
            
        }
        
        // call completion handler
        hr_dispatch_main(^{
            [[UIApplication sharedApplication] hr_popNetworkOperation];
            if (completion) { completion(feed); }
        });
        
    });
}

- (void)patientFeed:(void (^) (NSArray *patients))completion {
    [self patientFeed:completion ignoreCache:NO];
}

- (NSDictionary *)JSONForPatientWithIdentifier:(NSString *)identifier {
    __block NSDictionary *dictionary = nil;
    dispatch_sync(_requestQueue, ^{
        
        // start block
        hr_dispatch_main(^{
            [[UIApplication sharedApplication] hr_pushNetworkOperation];
        });
        
        // create request
        NSString *path = [NSString stringWithFormat:@"/records/%@/c32/%@.json", identifier, identifier];
        NSMutableURLRequest *request = [self GETRequestWithPath:path];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        // run request
        NSError *connectionError = nil;
        NSHTTPURLResponse *response = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
        
        // create patient
        NSError *JSONError = nil;
        if (data && [response statusCode] == 200) {
            dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONError];
        }
        
        // finish block
        hr_dispatch_main(^{
            [[UIApplication sharedApplication] hr_popNetworkOperation];
        });
        
    });
    return dictionary;
}

- (void)JSONForPatientWithIdentifier:(NSString *)identifier startBlock:(void (^) (void))startBlock finishBlock:(void (^) (NSDictionary *payload))finishBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // start block
        hr_dispatch_main(^{
            if (startBlock) { startBlock(); }
        });
        
        // run request
        NSDictionary *dictionary = [self JSONForPatientWithIdentifier:identifier];
        
        // finish block
        hr_dispatch_main(^{
            if (finishBlock) { finishBlock(dictionary); }
        });
        
    });
}

#pragma mark - send data

- (BOOL) sendDataWithParameters:(NSDictionary *)params forPatientWithIdentifier:(NSString *)identifier{
    BOOL success = NO;
    // start block
    hr_dispatch_main(^{
        [[UIApplication sharedApplication] hr_pushNetworkOperation];
    });
    
    // create request
    NSString *path = [NSString stringWithFormat:@"/records/%@/c32/%@", identifier, identifier];
    NSMutableURLRequest *request = [self POSTRequestWithPath:path andParameters:params];
    
    // run request
    NSError *connectionError = nil;
    NSHTTPURLResponse *response = nil;
    //TODO: LMD discard data?
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
    
    success = ([response statusCode] == 200);
    
    // finish block
    if(success){
        hr_dispatch_main(^{
            [[UIApplication sharedApplication] hr_popNetworkOperation];
        });
    }
    
    
    return success;
}

#pragma mark - build requests

- (void)refreshAccessToken {
    HRDebugLog(@"Building request");
    
    // Make sure we have a refresh token
    NSString *refresh = HRCryptoManagerKeychainItemString(HROAuthKeychainService, _host);
    if (refresh == nil) {
        HRDebugLog(@"No refresh token is present");
        return;
    }
    
    // Used to refresh the access token
    NSTimeInterval interval = [_accessTokenExpirationDate timeIntervalSinceNow];
    if (_accessTokenExpirationDate) { HRDebugLog(@"Access token expires in %f minutes", interval / 60.0); }
    NSDictionary *refreshParameters = @{
        @"refresh_token" : refresh,
        @"grant_type" : @"refresh_token"
    };
    
    // Make sure we have both required elements
    if (_accessToken == nil || _accessTokenExpirationDate == nil || interval < 60.0) {
        HRDebugLog(@"Access token is invalid -- refreshing...");
        if (![self requestAccessTokenWithParameters:refreshParameters]) { return; }
    } else if (interval < 60.0 * 3.0) {
        // Check if our access token will expire soon
        HRDebugLog(@"Access token will expire soon -- refreshing later");
        dispatch_async(_requestQueue, ^{
            [self requestAccessTokenWithParameters:refreshParameters];
        });
    }
}

- (void)requestAuthorization {
    NSURLRequest *request = [self authorizationRequest];
    NSURL *URL = [request URL];
    [[UIApplication sharedApplication] openURL:URL];
}

- (BOOL)requestAccessTokenWithParameters:(NSDictionary *)parameters {
    // Build the request to get an access token
    NSError *error = nil;
    NSURLResponse *response = nil;
    NSDictionary *payload = nil;
    NSURLRequest *request = [self authenticationRequestWithParameters:parameters];
    
    // Send the token request
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (data) {
        // If we got data back, parse the response and check for errors.
        payload = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        if (error) { HRDebugLog(@"%@", error); }
    } else {
        HRDebugLog(@"%@", error);
    }

    // Handle the response we got based on success or failure
    if ([payload objectForKey:@"expires_in"] && [payload objectForKey:@"access_token"]) {
        // We were granted a token. Store the data appropriately
        if ([payload objectForKey:@"access_token"]) {
            HRCryptoManagerSetKeychainItemString(HROAuthKeychainService, _host, [payload objectForKey:@"access_token"]);
        }
        NSTimeInterval interval = [[payload objectForKey:@"expires_in"] doubleValue];
        _accessTokenExpirationDate = [NSDate dateWithTimeIntervalSinceNow:interval];
        _accessToken = [payload objectForKey:@"access_token"];
        return YES;
    } else if ([[payload objectForKey:@"error"] isEqualToString:@"invalid_grant"]) {
        HRDebugLog(@"Request for access token denied. Retrying.");
        [self requestAuthorization];
        return YES;
    } else {
        HRDebugLog(@"%@", payload);
    }

    return NO;
}

- (NSMutableURLRequest *)GETRequestWithPath:(NSString *)path {
    [self refreshAccessToken];
    
    // Build request parameters
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:_accessToken forKey:@"access_token"];
    NSString *query = [HRAPIClient queryStringWithParameters:parameters];
    NSString *URLString = [NSString stringWithFormat:@"https://%@%@?%@", _host, path, query];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    // Build request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    [request setHTTPShouldHandleCookies:NO];
    [request setHTTPMethod:@"GET"];
    
    return request;
}

- (NSMutableURLRequest *)POSTRequestWithPath:(NSString *)path andParameters:(NSDictionary *)params {
    [self refreshAccessToken];
    
    // Build request parameters
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:params];
    [parameters setObject:_accessToken forKey:@"access_token"];
    
    NSString *query = [HRAPIClient queryStringWithParameters:parameters];
    NSData *post = [query dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:YES];//LMD TODO: Change to ascii?
    NSString *URLString = [NSString stringWithFormat:@"https://%@%@", _host, path];//TODO: LMD other post URL changes?
    NSURL *URL = [NSURL URLWithString:URLString];
    
    // Build request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    [request setHTTPShouldHandleCookies:NO];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"%d", [post length]] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:post];
    
    return request;
}

- (NSString *)hostDataByKey:(NSString *)key {
    NSMutableDictionary *hostData = [[HRAPIClient knownHosts] objectForKey:_host];
    return [hostData objectForKey:key];
}

- (NSURLRequest *)authorizationRequest {
    // Build the parameters to retrieve an OpenID authorization code
    NSDictionary *parameters = @{
        @"client_id" : [self hostDataByKey:@"clientID"],
        @"client_secret" : [self hostDataByKey:@"clientSecret"],
        @"response_type" : @"code",
        @"scope" : @"openid profile address email phone",
        @"redirect_uri" : [NSString stringWithFormat:@"hreader://openid?host=%@", _host]
    };
    
    // Build the HTTP request URL using the parameters we just defined
    NSString *query = [HRAPIClient queryStringWithParameters:parameters];
    NSString *URLString = [NSString stringWithFormat:@"%@%@?%@",
                           [self hostDataByKey:@"identityServer"],
                           [self hostDataByKey:@"identityPath"],
                           query];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [[NSURLRequest alloc] initWithURL:URL];
}

- (NSURLRequest *)authenticationRequestWithParameters:(NSDictionary *)parameters {
    // Build the parameters to retrieve an OAuth2 token
    NSMutableDictionary *params = [parameters mutableCopy];
    
    [params addEntriesFromDictionary:@{
        @"client_id" : [self hostDataByKey:@"clientID"],
        @"client_secret" : [self hostDataByKey:@"clientSecret"],
        @"redirect_uri" : [NSString stringWithFormat:@"hreader://openid?host=%@", _host],
        @"approval_prompt" : @"force"
    }];
    
    // Build the HTTP request URL using the parameters we just defined
    NSString *query = [HRAPIClient queryStringWithParameters:params];
    NSString *URLString = [NSString stringWithFormat:@"%@%@?%@",
                           [self hostDataByKey:@"authenticationServer"],
                           [self hostDataByKey:@"authenticationPath"],
                           query];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [[NSURLRequest alloc] initWithURL:URL];
}

#pragma mark - object methods

- (id)initWithHost:(NSString *)host {
    self = [super init];
    if (self) {
        _host = [host copy];
        NSString *name = [NSString stringWithFormat:@"org.mitre.hreader.rhex-queue.%@", _host];
        _requestQueue = dispatch_queue_create([name UTF8String], DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)destroy {
    [IMSKeychain deletePasswordForService:HROAuthKeychainService account:_host];
    [allClients removeObjectForKey:_host];
}

- (NSString *)accessToken {
    return _accessToken;
}

@end

@implementation NSString (HRAPIClientAdditions)

- (NSString *)hr_percentEncodedString {
    CFStringRef string = CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                 (__bridge CFStringRef)self,
                                                                 NULL,
                                                                 CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                 kCFStringEncodingUTF8);
    return (__bridge_transfer NSString *)string;
}

@end
