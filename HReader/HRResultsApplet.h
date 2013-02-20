//
//  HRResultsApplet.h
//  HReader
//
//  Created by Adam on 2/19/13.
//  Copyright (c) 2013 MITRE Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HRContentViewController.h"

@interface HRResultsApplet : HRContentViewController

@property (weak, nonatomic) IBOutlet UIScrollView *resultsView;

@property (weak, nonatomic) IBOutlet UILabel *patientName;
@property (weak, nonatomic) IBOutlet UIImageView *patientImage;

@end
