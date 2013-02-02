//
//  HRAppDelegate.m
//  HReader
//
//  Created by Marshall Huss on 11/14/11.
//  Copyright (c) 2011 MITRE Corporation. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <objc/message.h>
#import <sys/stat.h>

#import "CMDEncryptedSQLiteStore.h"

#import "HRAppDelegate.h"
#import "HRAPIClient.h"
#import "HRRHExLoginViewController.h"
#import "HRPeopleSetupViewController.h"
#import "HRCryptoManager.h"
#import "HRSplashScreenViewController.h"
#import "HRHIPPAMessageViewController.h"
#import "HRAppletConfigurationViewController.h"
#import "HRCryptoManager.h"
#import "HRMPatient.h"

#import "IMSPasswordViewController.h"
#import <SecureFoundation/SecureFoundation.h>

@implementation HRAppDelegate {
    NSUInteger passcodeAttempts;
    UINavigationController *securityNavigationController;
    NSPersistentStore *persistentStore;
}

#pragma mark - class methods

/**
 * Retrieve the PersistentStoreCoordinator. This is mostly used to attach the coordinator to MOCs.
 */
+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    static NSPersistentStoreCoordinator *coordinator = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"hReader" withExtension:@"momd"];
        NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    });
    
    return coordinator;
}

/**
 * Returns the MOC that we use essentially for FIFO synchronous background tasks.
 */
+ (NSManagedObjectContext *)rootManagedObjectContext {
    static NSManagedObjectContext *context = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [context setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
    });
    return context;
}

/**
 * Returns the MOC that we use essentially for FIFO synchronous tasks for the main application.
 * For example, UI events may be queued here. Note that main tasks are enqueued onto the rootMOC, meaing we will have to wait our turn.
 */
+ (NSManagedObjectContext *)managedObjectContext {
    static NSManagedObjectContext *context = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [context setParentContext:[self rootManagedObjectContext]];
    });
    return context;
}

#pragma mark - object methods

/**
 * Called while launching to define the PersistentStoreCoordinator. Opens our secured DB.
 */
- (void)addPersistentStoreIfNeeded {
    if (persistentStore != nil) { return; }
    
    NSError *error = nil;
    NSPersistentStoreCoordinator *coordinator = [HRAppDelegate persistentStoreCoordinator];
    
    // Define behavior of our persistent store. 
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    [fileManager createDirectoryAtURL:applicationSupportURL withIntermediateDirectories:NO attributes:nil error:nil];
    NSURL *databaseURL = [applicationSupportURL URLByAppendingPathComponent:@"database.sqlite3.2"];
    NSDictionary *options = @{
        NSPersistentStoreFileProtectionKey : NSFileProtectionComplete,
        NSMigratePersistentStoresAutomaticallyOption : @YES,
        NSInferMappingModelAutomaticallyOption : @YES
    };
    
    // add store
    persistentStore = HRCryptoManagerAddEncryptedStoreToCoordinator(coordinator,
                                                                    nil,
                                                                    databaseURL,
                                                                    options,
                                                                    &error);
    NSAssert(persistentStore, @"Unable to add persistent store\n%@", error);
}


/**
 * Exit the application if we find we are compromised. Checks for some basic forms of vulnerability.
 */
- (void)abortIfCompromised {
#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
#define PEACE_OUT() raise(SIGKILL); abort(); exit(EXIT_FAILURE);
    
    // fork test
    pid_t child = fork();
    if (child == 0) { exit(0); } // child process should exit
    if (child > 0) { // fork succeeded, compromised!
        PEACE_OUT();
    }
    
    // mobile substrate test
    char path1[] = {
        220, 191, 154, 145, 129, 146, 129, 138, 220, 190, 156, 145, 154, 159,
        150, 160, 134, 145, 128, 135, 129, 146, 135, 150, 220, 190, 156, 145,
        154, 159, 150, 160, 134, 145, 128, 135, 129, 146, 135, 150, 221, 151,
        138, 159, 154, 145, '\0'
    };
    IMSXOR(243, path1, strlen(path1));
    HRDebugLog(@"Checking for %s", path1);
    struct stat s1;
    if (stat(path1, &s1) == 0) { // file exists
        PEACE_OUT();
    };
    
    // sshd test
    char path2[] = {
        230, 188, 186, 187, 230, 171, 160, 167, 230, 186, 186, 161, 173, '\0'
    };
    IMSXOR(201, path2, strlen(path2));
    HRDebugLog(@"Checking for %s", path2);
    struct stat s2;
    if (stat(path2, &s2) == 0) { // file exists
        PEACE_OUT();
    };
    
#endif
}

/**
 * Have the user perform any necessary authentication tasks as the applciation launches.
 * For the first run, they will be required to sign the HIPPA notice, create a passcode, etc.
 * For all subsequent runs, the user will just be prompted for their passcode.
 */
- (void)performLaunchSteps {
    [self abortIfCompromised];
    
    if (![HRHIPPAMessageViewController hasAcceptedHIPPAMessage]) {
        // If the user hasn't accepted the HIPPA message yet, present it to them
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"InitialSetup_iPad" bundle:nil];
        HRHIPPAMessageViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"HIPPAViewController"];
        controller.navigationItem.hidesBackButton = YES;
        controller.target = self;
        controller.action = _cmd;
        
        UINavigationController *navigation = (id)self.window.rootViewController;
        [navigation popToRootViewControllerAnimated:NO];
        [navigation pushViewController:controller animated:YES];
    } else if (!HRCryptoManagerHasPasscode() || !HRCryptoManagerHasSecurityQuestions()) {
        // If the user hasn't configured their passcode or security questions yet, prompt them to do so
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"InitialSetup_iPad" bundle:nil];
        IMSPasswordViewController *password = [storyboard instantiateViewControllerWithIdentifier:@"CreatePasscodeViewController"];
        password.title = @"Set Password";
        password.target = self;
        password.action = @selector(createInitialPasscode::);
        password.navigationItem.hidesBackButton = YES;
        
        [(id)self.window.rootViewController pushViewController:password animated:YES];
        [[[UIAlertView alloc]
          initWithTitle:@"Welcome"
          message:@"Before you start using hReader, you must set a passcode and create security questions."
          delegate:nil
          cancelButtonTitle:@"OK"
          otherButtonTitles:nil]
         show];
    } else if (HRCryptoManagerIsUnlocked()) {
        // Crypto has been configured, so try to log in
        NSArray *hosts = [HRAPIClient hosts];
        UIViewController *controller = [(id)self.window.rootViewController topViewController];
        
        [self addPersistentStoreIfNeeded];
        
        // Connect to our sources of data and sync
        if ([hosts count] == 0) {
            // If we haven't authenticated with any servers, attempt to do so.
            HRAPIClient *client = [HRAPIClient clientWithHost:@"default"];
            [client requestAuthorization];
        } else {
            // We've already authenticated, so just update local data from servers
            NSString *host = [hosts lastObject];
            [[HRAPIClient clientWithHost:host] patientFeed:nil];
            [HRMPatient performSync];
            
            // Present the People Setup view if it's not already being shown
            if ([controller isKindOfClass:[HRSplashScreenViewController class]] ||
                [controller isKindOfClass:[HRHIPPAMessageViewController class]]) {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"InitialSetup_iPad" bundle:nil];
                id controller = [storyboard instantiateViewControllerWithIdentifier:@"PeopleSetupViewController"];
                [[controller navigationItem] setHidesBackButton:YES];
                [(id)self.window.rootViewController pushViewController:controller animated:YES];
            }
        }
    } else {
        // Otherwise, we have not successfully authenticated yet, so let the user login
        [self presentPasscodeVerificationController:YES];
    }
}

#pragma mark - notifications

/**
 * Called anytime a MOC is saved.
 */
- (void)managedObjectContextDidSave:(NSNotification *)notification {
    // Get contexts
    NSManagedObjectContext *rootContext = [HRAppDelegate rootManagedObjectContext];
    NSManagedObjectContext *mainContext = [HRAppDelegate managedObjectContext];
    NSManagedObjectContext *savingContext = [notification object];
    
    // main -> root
    if (savingContext == mainContext) {
        [rootContext performBlock:^{
            NSError *error = nil;
            if (![rootContext save:&error]) { HRDebugLog(@"Unable to save root context: %@", error); }
        }];
    }
    
    // child -> main
    else if ([savingContext parentContext] == mainContext) {
        [mainContext performBlock:^{
            NSError *error = nil;
            if (![mainContext save:&error]) { HRDebugLog(@"Unable to save main context: %@", error); }
        }];
    }
    
}

#pragma mark - application lifecycle

/**
 * Called once the app has launched.
 */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Register a notification to call our MOC save handler whenever a MOC completes a save
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(managedObjectContextDidSave:)
     name:NSManagedObjectContextDidSaveNotification
     object:nil];
   
    // ABG TODO why do we wait here? Can't we just call dispatch_async?
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC);
    dispatch_after(time, dispatch_get_main_queue(), ^(void){
        [self performLaunchSteps];
    });
    
    return YES;
}

/**
 * This is the entry point when another application invokes us with a URL. We hit this method from Safari notifying us
 * that a user has successfully authorized with an identity server.
 */
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSString *host = [url host];
    
    // If we're being sent an authentication code for OpenID, continue the authenetication process and retrieve an OAuth token.
    if ([host isEqualToString:@"openid"]) {
        // Fetch the host for which we just received a code
        NSDictionary *parameters = [HRAPIClient parametersFromQueryString:[url query]];
        HRAPIClient *client = [HRAPIClient clientWithHost:[parameters objectForKey:@"host"]];
        
        // Continue the authorization process
        NSDictionary *refreshParameters = @{@"code" : [parameters objectForKey:@"code"]};
        [client requestAccessTokenWithParameters:refreshParameters];
        
        [self performLaunchSteps];
        
        /*
        // Form token request
        NSDictionary *parameters = [HRAPIClient tokenRequestParameters:code];
        NSString *tokenQuery = [HRAPIClient queryStringWithParameters:parameters];
        NSString *URLString = [NSString stringWithFormat:@"%@token?%@", HRAuthenticationServer, tokenQuery];
        NSURL *URL = [NSURL URLWithString:URLString];
        
        // Send token request TODO What if this is a failure?
        NSError *error = nil;
        NSURLResponse *response = nil;
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
        NSDictionary *resultsJSON = [NSJSONSerialization
                                     JSONObjectWithData:data
                                     options:NSJSONReadingAllowFragments
                                     error:&error];
        
        // Parse out token from response
        NSString *token = [resultsJSON objectForKey:@"access_token"];
        
        // Add client with token to hosts list and sync
        // HRAPIClient *client = [HRAPIClient clientWithHost:HRAuthenticationServer];
        
        // Grab the patient data
        URL = [NSURL URLWithString:@"http://MM170163-PC.mitre.org:8080/rhex-simple-endpoint/patients"];
        NSString *bearer = [NSString stringWithFormat:@"Bearer %@", token];
        NSMutableURLRequest *patientRequest = [[NSMutableURLRequest alloc] initWithURL:URL];
        [patientRequest setValue:bearer forHTTPHeaderField:@"Authorization"];
        [patientRequest setHTTPMethod:@"GET"];
        
        data = [NSURLConnection sendSynchronousRequest:patientRequest returningResponse:&response error:&error];
        NSString *patient = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
         */
        
        return YES;
    }
    
    return NO;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // For now, destroy stored encryption keys.
    HRCryptoManagerPurge();
    
    // Reset crypto interface. User will need to reauthenticate when the application regains focus.
    if (!HRCryptoManagerHasPasscode() || !HRCryptoManagerHasSecurityQuestions()) {
        [(id)self.window.rootViewController popToRootViewControllerAnimated:NO];
    }
    [securityNavigationController dismissViewControllerAnimated:NO completion:nil];
    securityNavigationController = nil;
    [self presentPasscodeVerificationController:NO];
}

#pragma mark - security scenario one

/*
 
 Methods used when setting the security information on first launch.
 
 */

- (void)createInitialPasscode :(IMSPasswordViewController *)controller :(NSString *)passcode {
    HRCryptoManagerStoreTemporaryPasscode(passcode);
    HRSecurityQuestionsViewController *questions = [controller.storyboard instantiateViewControllerWithIdentifier:@"SecurityQuestionsController"];
    questions.navigationItem.hidesBackButton = YES;
    questions.mode = HRSecurityQuestionsViewControllerModeCreate;
    questions.delegate = self;
    questions.title = @"Security Questions";
    questions.action = @selector(createInitialSecurityQuestions:::);
    [controller.navigationController pushViewController:questions animated:YES];
}

- (void)createInitialSecurityQuestions :(HRSecurityQuestionsViewController *)controller :(NSArray *)questions :(NSArray *)answers {
    HRCryptoManagerStoreTemporarySecurityQuestionsAndAnswers(questions, answers);
    HRCryptoManagerFinalize();
    [self performLaunchSteps];
}

#pragma mark - security scenario two

/*
 
 Methods used when verifying the user's passcode on launch.
 
 */

- (void)presentPasscodeVerificationController:(BOOL)animated {
    NSAssert(!securityNavigationController, @"You cannot present two passcode verification controllers");
    passcodeAttempts = 0;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"InitialSetup_iPad" bundle:nil];
    IMSPasswordViewController *password = [storyboard instantiateViewControllerWithIdentifier:@"VerifyPasscodeViewController"];
    password.target = self;
    password.action = @selector(verifyPasscodeOnLaunch::);
    password.title = @"Enter Password";
    securityNavigationController = [[UINavigationController alloc] initWithRootViewController:password];
    UIViewController *controller = self.window.rootViewController;
    while (YES) {
        UIViewController *presented = controller.presentedViewController;
        if (presented) { controller = presented; }
        else { break; }
    }
    [controller presentViewController:securityNavigationController animated:animated completion:nil];
}

- (BOOL)verifyPasscodeOnLaunch :(IMSPasswordViewController *)controller :(NSString *)passcode {
    if (HRCryptoManagerUnlockWithPasscode(passcode)) {
        [self addPersistentStoreIfNeeded];
        [controller dismissViewControllerAnimated:YES completion:^{
            securityNavigationController = nil;
            [self performLaunchSteps];
        }];
        return YES;
    }
    else {
        if (++passcodeAttempts > 2) {
            controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] 
                                                           initWithTitle:@"Reset Passcode" 
                                                           style:UIBarButtonItemStyleDone 
                                                           target:self 
                                                           action:@selector(resetPasscodeWithSecurityQuestions)];
        }
        return NO;
    }
}

- (void)resetPasscodeWithSecurityQuestions {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"InitialSetup_iPad" bundle:nil];
    HRSecurityQuestionsViewController *questions = [storyboard instantiateViewControllerWithIdentifier:@"SecurityQuestionsController"];
    questions.navigationItem.hidesBackButton = YES;
    questions.mode = HRSecurityQuestionsViewControllerModeVerify;
    questions.delegate = self;
    questions.title = @"Security Questions";
    questions.action = @selector(resetPasscodeWithSecurityQuestions:::);
    [securityNavigationController pushViewController:questions animated:YES];
}

- (void)resetPasscodeWithSecurityQuestions :(HRSecurityQuestionsViewController *)controller :(NSArray *)questions :(NSArray *)answers {
    if (HRCryptoManagerUnlockWithAnswersForSecurityQuestions(answers)) {
        IMSPasswordViewController *password = [controller.storyboard instantiateViewControllerWithIdentifier:@"CreatePasscodeViewController"];
        password.target = self;
        password.action = @selector(resetPasscode::);
        password.title = @"Enter Password";
        password.navigationItem.hidesBackButton = YES;
        [controller.navigationController pushViewController:password animated:YES];
    }
    else {
        [[[UIAlertView alloc]
          initWithTitle:@"The answers you provided are not correct."
          message:nil
          delegate:nil
          cancelButtonTitle:@"OK"
          otherButtonTitles:nil]
         show];
    }
}

- (void)resetPasscode :(IMSPasswordViewController *)controller :(NSString *)passcode {
    HRCryptoManagerUpdatePasscode(passcode);
    [controller dismissViewControllerAnimated:YES completion:^{
        [self performLaunchSteps];
    }];
}

#pragma mark - security scenario three

/*
 
 Methods used when changing the passcode at the request of the user.
 
 */

- (BOOL)verifyPasscodeOnPasscodeChange :(IMSPasswordViewController *)controller :(NSString *)passcode {
    if (HRCryptoManagerUnlockWithPasscode(passcode)) {
        IMSPasswordViewController *password = [controller.storyboard instantiateViewControllerWithIdentifier:@"CreatePasscodeViewController"];
        password.target = self;
        password.action = @selector(resetPasscode::);
        password.title = @"Enter New Password";
        password.navigationItem.hidesBackButton = YES;
        password.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:password
                                                      action:@selector(doneButtonAction:)];
        [controller.navigationController pushViewController:password animated:YES];
        return YES;
    }
    return NO;
}

#pragma mark - security scenario four

/*
 
 Methods used when changing the security questions at the request of the user.
 
 */

- (BOOL)verifyPasscodeOnQuestionsChange :(IMSPasswordViewController *)controller :(NSString *)passcode {
    if (HRCryptoManagerUnlockWithPasscode(passcode)) {
        HRSecurityQuestionsViewController *questions = [controller.storyboard instantiateViewControllerWithIdentifier:@"SecurityQuestionsController"];
        questions.navigationItem.hidesBackButton = YES;
        questions.mode = HRSecurityQuestionsViewControllerModeCreate;
        questions.delegate = self;
        questions.title = @"Security Questions";
        questions.action = @selector(updateSecurityQuestions:::);
        [controller.navigationController pushViewController:questions animated:YES];
        return YES;
    }
    return NO;
}

- (void)updateSecurityQuestions :(HRSecurityQuestionsViewController *)controller :(NSArray *)questions :(NSArray *)answers {
    HRCryptoManagerUpdateSecurityQuestionsAndAnswers(questions, answers);
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - security scenario five

/*
 
 Methods used when the user has successfully autheticated
 
 */

- (void)initialLoginDidSucceed :(HRRHExLoginViewController *)login {
    HRPeopleSetupViewController *setup = [login.storyboard instantiateViewControllerWithIdentifier:@"PeopleSetupViewController"];
    setup.navigationItem.hidesBackButton = YES;
    [login.navigationController pushViewController:setup animated:YES];
}

#pragma mark - security questions delegate

- (NSUInteger)numberOfSecurityQuestions {
    return 2;
}

- (NSArray *)securityQuestions {
    return HRCryptoManagerSecurityQuestions();
}

@end