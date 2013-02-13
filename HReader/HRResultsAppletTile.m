//
//  HRResultsAppletTile.m
//  HReader
//
//  Created by Adam Goldstein on 2/13/13.
//  Copyright (c) 2013 MITRE Corporation. All rights reserved.
//

#import "HRResultsAppletTile.h"
#import "HRMEntry.h"
#import "HRMPatient.h"

#import "NSString+SentenceCapitalization.h"

@implementation HRResultsAppletTile

- (void)tileDidLoad {
    [super tileDidLoad];
    
    HRMPatient *patient = [self.userInfo objectForKey:@"__private_patient__"];
    NSArray *results = patient.results;
    
    // Display the most recent results if we have any
    if (results) {
        HRMEntry *result1 = results[0];

        NSString *description = result1.desc;
        if (description.length > 12) {
            NSString *truncatedDescription = [description substringToIndex:12];
            description = [NSString stringWithFormat:@"%@...", truncatedDescription];
        } else {
            description = result1.desc;
        }
        
        self.testLabel1.text = description;
        self.dateLabel1.text = [result1.date hr_mediumStyleDate];
        self.resultLabel1.text = [result1.value objectForKey:@"scalar"];
        
        self.testLabel2.text = nil;
        self.dateLabel2.text = nil;
        self.resultLabel2.text = nil;
        
        self.testLabel3.text = nil;
        self.dateLabel3.text = nil;
        self.resultLabel3.text = nil;
    } else {
        // Otherwise, just clear out all of our labels
        self.testLabel1.text = @"None";
        self.dateLabel1.text = nil;
        self.resultLabel1.text = nil;
    }
}

@end
