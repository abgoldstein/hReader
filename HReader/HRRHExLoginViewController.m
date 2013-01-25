//
//  HRRHExLoginViewController.m
//  HReader
//
//  Created by Caleb Davenport on 5/30/12.
//  Copyright (c) 2012 MITRE Corporation. All rights reserved.
//

#import "HRRHExLoginViewController.h"
#import "HRAPIClient_private.h"
#import "HRPeopleSetupViewController.h"
#import "HRAPIClient_private.h"

#import "CMDActivityHUD.h"

static NSString *HROAuthURLScheme = @"x-org-mitre-hreader";
static NSString *HROAuthURLHost = @"oauth";

@interface HRRHExLoginViewController ()
@property (nonatomic, strong) IBOutlet UIToolbar *navigationToolbar;
@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, strong) HRAPIClient *client;
@end

@implementation HRRHExLoginViewController

#pragma mark - class methods

+ (HRRHExLoginViewController *)loginViewControllerForClient:(HRAPIClient *)client {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"InitialSetup_iPad" bundle:nil];
    HRRHExLoginViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"RHExLoginViewController"];
    controller.client = client;
    return controller;
}

#pragma mark - object methods

- (IBAction)navigateBack:(id)sender {
    [self.webView goBack];
}

- (IBAction)navigateForward:(id)sender {
    [self.webView goForward];
}

- (IBAction)navigateReload:(id)sender {
    [self.webView reload];
}

#pragma mark - view methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // toolbar
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:self.navigationToolbar];
    self.navigationItem.leftBarButtonItem = item;
    
    [CMDActivityHUD show];
    
    // Form the HTTP request to get an OpenID code. This will be loaded via Safari so we can take advantage of cert handling there.
    NSURLRequest *request = [self.client authorizationRequest];
    NSURL *URL = [request URL];
    [[UIApplication sharedApplication] openURL:URL];
}

#pragma mark - web view delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
    
    if ([self requestIsInvalid:request]) { return YES; }

    // Collect our parameters for authentication
    NSURL *URL = [request URL];
    NSDictionary *parameters = [HRAPIClient parametersFromQueryString:[URL query]];
    
    // Show the HUD to block while we fetch our access tokens
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([self.client refreshAccessTokenWithParameters:parameters]) {
            dispatch_async(dispatch_get_main_queue(), ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self.target performSelector:self.action withObject:self];
#pragma clang diagnostic pop
            });
        } else {
            NSLog(@"Error %@ %d", NSStringFromClass([self class]), __LINE__);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc]
                  initWithTitle:@"Unable to get access tokens from server"
                  message:nil
                  delegate:nil
                  cancelButtonTitle:@"OK"
                  otherButtonTitles:nil]
                  show];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [CMDActivityHUD dismiss];
        });
    });
    
    return YES;
}

- (BOOL)requestIsInvalid: (NSURLRequest *)request {
    // Request headers to mark us as hReader.
    // static NSString *targetHeaderFieldValue = @"ipad";
    // static NSString *headerFieldKey = @"x-org-mitre-hreader";
    
    // If our headers aren't marked as hReader, don't handle this request but register a new one with the correct headers.
    // TODO: This is obselete once RHEx is updated to properly use OpenID because we'll use clientIDs. This hack gets around Devise.
    /*NSString *currentFieldValue = [request valueForHTTPHeaderField:headerFieldKey];
    if (![currentFieldValue isEqualToString:targetHeaderFieldValue]) {
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        [mutableRequest setValue:targetHeaderFieldValue forHTTPHeaderField:headerFieldKey];
        [self.webView loadRequest:mutableRequest];
        return YES;
    }*/
    
    // Only attempt to authenticate with a server that we know
    /*NSURL *URL = [request URL];
    if (![[URL scheme] isEqualToString:HROAuthURLScheme] || ![[URL host] isEqualToString:HROAuthURLHost]) {
        return YES;
    }*/
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [CMDActivityHUD dismiss];
    
    NSArray *buttons = self.navigationToolbar.items;
    [(UIBarButtonItem *)buttons[0] setEnabled:[webView canGoBack]];
    [(UIBarButtonItem *)buttons[1] setEnabled:[webView canGoForward]];
    [(UIBarButtonItem *)buttons[2] setEnabled:YES];
}

@end