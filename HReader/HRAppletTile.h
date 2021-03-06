//
//  HRAppletTile.h
//  HReader
//
//  Created by Caleb Davenport on 4/10/12.
//  Copyright (c) 2012 MITRE Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *HRAppletTilePatientIdentityTokenKey;

/*
 
 
 
 */
@interface HRAppletTile : UIView

/*
 
 
 
 */
+ (id)tileWithUserInfo:(NSDictionary *)userInfo;

/*
 
 Called when the tile has been fully loaded. At this point all properties have
 been set and you take any additional steps to configure the tile.
 
 */
- (void)tileDidLoad;

/*
 
 
 
 */
@property (nonatomic, readonly) NSString *patientIdentityToken;

/*
 
 Access the configuration options that you provided for this applet tile in
 HReaderApplets.plist
 
 */
@property (nonatomic, readonly) NSDictionary *userInfo;

/*
 
 
 
 */
- (void)didReceiveTap:(UIViewController *)sender inRect:(CGRect)rect;

/*
 
 Since the application performs a few cleanup tasks when the app goes into
 the background, we require all applets to perform any cleanup such as hiding
 popovers or action sheets here.
 
 */
- (void)applicationDidEnterBackground;

@end
