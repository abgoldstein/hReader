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
    
    // Generate labels for the most recent 3 test results
    for (NSUInteger i = 0; i < results.count && i < 3; i++) {
        HRMEntry *result = results[i];
        
        // Format data to display in our columns
        NSString *dateText = [result.date hr_mediumStyleDate];
        NSString *description = result.desc;
        
        // Display units if we have them available
        NSString *resultUnits = [result.value objectForKey:@"units"];
        if (!resultUnits) {
            resultUnits = @"";
        }
        NSString *resultText = [NSString stringWithFormat:@"%@ %@",
                                [result.value objectForKey:@"scalar"],
                                resultUnits];
        
        // Truncate the test name if it's too long to fit
        if (description.length > 12) {
            NSString *truncatedDescription = [description substringToIndex:12];
            description = [NSString stringWithFormat:@"%@...", truncatedDescription];
        } else {
            description = result.desc;
        }
        
        int rowPosition = 49 + (i * 29);
        [self addResult:rowPosition testText:description dateText:dateText resultText:resultText];
    }

    // Display the most recent results if we have any
    if (!results || results.count == 0) {
        [self addResult:51 testText:@"None" dateText:@"None" resultText:@"None"];
    }
}

-(void)addResult:(int)rowPosition testText:(NSString *)testText dateText:(NSString *)dateText resultText:(NSString *)resultText {
    // Test
    UILabel *testLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, rowPosition, 150, 21)];
    testLabel.text = testText;
    [testLabel setFont:[UIFont boldSystemFontOfSize:12]];
    
    // Date
    UILabel *dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(102, rowPosition, 150, 21)];
    dateLabel.text = dateText;
    [dateLabel setFont:[UIFont boldSystemFontOfSize:12]];
    
    // Result
    UILabel *resultLabel = [[UILabel alloc]initWithFrame:CGRectMake(205, rowPosition, 150, 21)];
    resultLabel.text = resultText;
    [resultLabel setFont:[UIFont boldSystemFontOfSize:12]];
    
    [self addSubview:testLabel];
    [self addSubview:dateLabel];
    [self addSubview:resultLabel];
}

-(void)didReceiveTap:(UIViewController *)sender inRect:(CGRect)rect {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"HRResultsApplet" bundle:nil];
    HRResultsAppletTile *controller = [storyboard instantiateInitialViewController];
    
    [sender.navigationController pushViewController:controller animated:YES];
}

@end
