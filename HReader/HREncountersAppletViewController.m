//
//  HREncountersAppletViewController.m
//  HReader
//
//  Created by Adam Goldstein on 2/20/13.
//  Copyright (c) 2013 MITRE Corporation. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "HREncountersAppletViewController.h"
#import "HRAppletConfigurationViewController.h"
#import "HRPeoplePickerViewController.h"
#import "HRAppletTile.h"
#import "HRAppDelegate.h"
#import "HRMPatient.h"
#import "HRMEntry.h"
#import "HRPeoplePickerViewController_private.h"

#import "NSString+SentenceCapitalization.h"

@implementation HREncountersAppletViewController {
    
}

#pragma mark - object methods

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.title = @"Recent Encounters";
    }
    
    return self;
}


- (void)dealloc {
    
}


- (void)reloadWithPatient:(HRMPatient *)patient {
    NSLog(@"Reloading recent encounters with patient");
    
    [self initializeDataWithPatient:patient];
}

- (void)appletConfigurationDidChange {
    [self reloadData];
}

#pragma mark - view methods

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.encountersView.contentSize = CGSizeMake(640.0, 600.0);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)viewDidUnload {
    [self setPatientImageView:nil];
    [self setPatientNameLabel:nil];
    [self setEncountersView:nil];
    [super viewDidUnload];
}

- (void)initializeDataWithPatient:(HRMPatient *)currentPatient{
    NSLog(@"Initializing recent results data");
    
    // Generate labels for all of the test results
    NSArray *encounters = [currentPatient encounters];
    for (NSUInteger i = 0; i < encounters.count; i++) {
        HRMEntry *encounter = encounters[i];
        
        // Format data to display in our columns
        NSString *dateText = [encounter.startDate hr_mediumStyleDate];
        NSString *description = encounter.desc;
        NSString *dischargeDisposition = encounter.dischargeDisposition;
        
        // Construct the type using whatever codes we have available
        NSString *type;
        NSDictionary *codes = encounter.codes;
        NSDictionary *codeType = [[codes allKeys] lastObject];
        NSString *codeValues = [[codes objectForKey:codeType] componentsJoinedByString:@", "];
        if (codeType || codeValues) {
            type = [NSString stringWithFormat:@"%@ %@", codeType, codeValues];
        } else {
            type = @"";
        }
        
        int rowPosition = 51 + (i * 29);
        [self addResult:rowPosition descriptionText:description dateText:dateText typeText:type statusText:dischargeDisposition];
    }
    
    // Display the most recent results if we have any
    if (!encounters || encounters.count == 0) {
        [self addResult:51 descriptionText:@"None" dateText:@"None" typeText:@"None" statusText:@"None"];
    }
}

-(void)addResult:(int)rowPosition descriptionText:(NSString *)descriptionText dateText:(NSString *)dateText typeText:(NSString *)typeText statusText:(NSString *)statusText{
    // Test
    UILabel *descriptionLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, rowPosition, 350, 21)];
    descriptionLabel.text = descriptionText;
    [descriptionLabel setFont:[UIFont boldSystemFontOfSize:12]];
    
    // Date
    UILabel *dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(363, rowPosition, 200, 21)];
    dateLabel.text = dateText;
    [dateLabel setFont:[UIFont boldSystemFontOfSize:12]];
    
    // Result
    UILabel *typeLabel = [[UILabel alloc]initWithFrame:CGRectMake(463, rowPosition, 200, 21)];
    typeLabel.text = typeText;
    [typeLabel setFont:[UIFont boldSystemFontOfSize:12]];
    
    // Range
    UILabel *statusLabel = [[UILabel alloc]initWithFrame:CGRectMake(573, rowPosition, 200, 21)];
    statusLabel.text = statusText;
    [statusLabel setFont:[UIFont boldSystemFontOfSize:12]];
    
    [self.encountersView addSubview:descriptionLabel];
    [self.encountersView addSubview:dateLabel];
    [self.encountersView addSubview:typeLabel];
    [self.encountersView addSubview:statusLabel];
}

@end
