//
//  HRAPIClient.h
//  HReader
//
//  Created by Caleb Davenport on 5/30/12.
//  Copyright (c) 2012 MITRE Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HRAPIClient : NSObject

@property NSString *authorizationCode;

+ (NSString *)queryStringWithParameters:(NSDictionary *)parameters;

/*
 
 Decode the given query string into a set of parameters.
 
 */
+ (NSDictionary *)parametersFromQueryString:(NSString *)string;

/*
 
 Set the host name (or IP address) of the RHEx server.
 
 */
+ (HRAPIClient *)clientWithHost:(NSString *)host;

/*
 
 Get a list of all hosts that have authenticated accounts stored locally.
 
 */
+ (NSArray *)hosts;

/*
 
 Request the patient feed from the receiver. This method returns imediatly and
 notifies the caller upon completion using the completion block.
 
 The completion accepts an array of dictionaries each having two keys: id and
 name. Should an error occur, `patients` will be nil. It will be executed on
 the main queue.
 
 */
- (void)patientFeed:(void (^) (NSArray *patients))completion;

/*
 
 Fetch a given patient payload from the receiver. This method returns
 imediately and notifes the caller of progress using the `startBlock` and
 `finishBlock` parameters.
 
 `startBlock` simply notifies the caller that the operation is about to begin.
 
 `finishBlock` accepts a dictionary that represents the patient payload. This
 will be `nil` should an error occur.
 
 Both blocks will be executed on the main queue.
 
 */
- (void)JSONForPatientWithIdentifier:(NSString *)identifier
                          startBlock:(void (^) (void))startBlock
                         finishBlock:(void (^) (NSDictionary *payload))finishBlock;

/*
 
 Fetch a given patient payload from the receiver. This method waits for the
 response to come back so do not call this on the main thread.
 
 */
- (NSDictionary *)JSONForPatientWithIdentifier:(NSString *)identifier;

/*
 
 Get the access token payload given the appropriate parameters. This method
 will not execute anything if another request is in
 
 The parameters dictionary MUST contain the "grant_type" which should be either
 "authorization_code" or "refresh_token", and the appropriate associated value.
 
 It is up to the caller to validate the returned payload and store any values.
 
 */
- (BOOL)requestAccessTokenWithParameters:(NSDictionary *)parameters;

- (void)requestAuthorization;

- (NSURLRequest *)authenticationRequestWithParameters:(NSDictionary *)parameters;

- (NSURLRequest *)authorizationRequest;

- (NSString *)hostDataByKey:(NSString *)key;

- (NSString *)accessToken;

@end

