//
//  HRResultsAppletTile.h
//  HReader
//
//  Created by Adam Goldstein on 2/13/13.
//  Copyright (c) 2013 MITRE Corporation. All rights reserved.
//

#import "HRAppletTile.h"

@interface HRResultsAppletTile : HRAppletTile

@property (strong, nonatomic) IBOutlet UILabel *testLabel1;
@property (strong, nonatomic) IBOutlet UILabel *testLabel2;
@property (strong, nonatomic) IBOutlet UILabel *testLabel3;

@property (strong, nonatomic) IBOutlet UILabel *dateLabel1;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel2;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel3;

@property (strong, nonatomic) IBOutlet UILabel *resultLabel1;
@property (strong, nonatomic) IBOutlet UILabel *resultLabel2;
@property (strong, nonatomic) IBOutlet UILabel *resultLabel3;
 
@end
