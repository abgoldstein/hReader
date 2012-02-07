//
//  HRAppDelegate.h
//  HReader
//
//  Created by Marshall Huss on 11/14/11.
//  Copyright (c) 2011 MITRE Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

//@class HRPrivacyViewController;

@interface HRAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
//@property (strong, nonatomic) HRPrivacyViewController *privacyViewController;

//- (void)showPrivacyWarning;
//- (void)setupPrivacyView;

// access the singleton persistent store coordinator
+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

@end
