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

static NSString * const HROAuthURLScheme = @"x-org-mitre-hreader";
static NSString * const HROAuthURLHost = @"oauth";

@interface HRRHExLoginViewController () {
@private
    NSString *_host;
}

@end

@implementation HRRHExLoginViewController

@synthesize webView = _webView;

+ (HRRHExLoginViewController *)loginViewControllerWithHost:(NSString *)host {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"InitialSetup_iPad" bundle:nil];
    HRRHExLoginViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"RHExLoginViewController"];
    controller->_host = [host copy];
    return controller;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    self.webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    self.webView.delegate = self;
    HRAPIClient *client = [HRAPIClient clientWithHost:_host];
    [self.webView loadRequest:[client authorizationRequest]];
    [self.view addSubview:self.webView];
}

- (void)viewDidUnload {
    self.webView = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return UIInterfaceOrientationIsLandscape(orientation);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *URL = [request URL];
    if ([[URL scheme] isEqualToString:HROAuthURLScheme] && [[URL host] isEqualToString:HROAuthURLHost]) {
        HRAPIClient *client = [HRAPIClient clientWithHost:_host];
        dispatch_async(client->_requestQueue, ^{
            NSDictionary *parameters = [HRAPIClient parametersFromQueryString:[URL query]];
            parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                          [parameters objectForKey:@"code"], @"code",
                          @"authorization_code", @"grant_type",
                          nil];
            if ([client refreshAccessTokenWithParameters:parameters]) {
                HRPeopleSetupViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"PeopleSetupViewController"];
                controller.navigationItem.hidesBackButton = YES;
                [self.navigationController pushViewController:controller animated:YES];
            }
            else {
                NSLog(@"Error %@ %d", NSStringFromClass([self class]), __LINE__);
            }
        });
    }
    return YES;
}

@end