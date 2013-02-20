//
//  HRResultsApplet.m
//  HReader
//
//  Created by Adam on 2/19/13.
//  Copyright (c) 2013 MITRE Corporation. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "HRResultsApplet.h"
#import "HRAppletConfigurationViewController.h"
#import "HRPeoplePickerViewController.h"
#import "HRAppletTile.h"
#import "HRAppDelegate.h"
#import "HRMPatient.h"
#import "HRMEntry.h"
#import "HRPeoplePickerViewController_private.h"

#import "NSString+SentenceCapitalization.h"

@implementation HRResultsApplet {

}

#pragma mark - object methods

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.title = @"Recent Results";
    }
    
    return self;
}


- (void)dealloc {

}


- (void)reloadWithPatient:(HRMPatient *)patient {
    NSLog(@"Reloading recent results with patient");
    
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
    self.resultsView.contentSize = CGSizeMake(640.0, 1100.0);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)viewDidUnload {
    [self setPatientImageView:nil];
    [self setPatientNameLabel:nil];
    [self setResultsView:nil];
    [super viewDidUnload];
}

- (void)initializeDataWithPatient:(HRMPatient *)currentPatient{
    NSLog(@"Initializing recent results data");
    
    // Generate labels for all of the test results
    NSArray *results = [currentPatient results];
    for (NSUInteger i = 0; i < results.count; i++) {
        HRMEntry *result = results[i];
        
        // Format data to display in our columns
        NSString *dateText = [result.date hr_mediumStyleDate];
        NSString *description = result.desc;
        NSString *range = result.referenceRange;
        
        // Display units if we have them available
        NSString *resultUnits = [result.value objectForKey:@"units"];
        if (!resultUnits) {
            resultUnits = @"";
        }
        NSString *resultText = [NSString stringWithFormat:@"%@ %@",
                                [result.value objectForKey:@"scalar"],
                                resultUnits];
        
        int rowPosition = 51 + (i * 29);
        [self addResult:rowPosition testText:description dateText:dateText resultText:resultText rangeText:range];
    }
    
    // Display the most recent results if we have any
    if (!results || results.count == 0) {
        [self addResult:51 testText:@"None" dateText:@"None" resultText:@"None" rangeText:@"None"];
    }
}

-(void)addResult:(int)rowPosition testText:(NSString *)testText dateText:(NSString *)dateText resultText:(NSString *)resultText rangeText:(NSString *)rangeText{
    // Test
    UILabel *testLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, rowPosition, 350, 21)];
    testLabel.text = testText;
    [testLabel setFont:[UIFont boldSystemFontOfSize:12]];
    
    // Date
    UILabel *dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(363, rowPosition, 200, 21)];
    dateLabel.text = dateText;
    [dateLabel setFont:[UIFont boldSystemFontOfSize:12]];
    
    // Result
    UILabel *resultLabel = [[UILabel alloc]initWithFrame:CGRectMake(463, rowPosition, 200, 21)];
    resultLabel.text = resultText;
    [resultLabel setFont:[UIFont boldSystemFontOfSize:12]];
    
    // Range
    UILabel *rangeLabel = [[UILabel alloc]initWithFrame:CGRectMake(573, rowPosition, 200, 21)];
    rangeLabel.text = rangeText;
    [rangeLabel setFont:[UIFont boldSystemFontOfSize:12]];
    
    [self.resultsView addSubview:testLabel];
    [self.resultsView addSubview:dateLabel];
    [self.resultsView addSubview:resultLabel];
    [self.resultsView addSubview:rangeLabel];
}

@end
