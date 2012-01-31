//
//  HRRootViewController.m
//  HReader
//
//  Created by Marshall Huss on 11/30/11.
//  Copyright (c) 2011 MITRE Corporation. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "HRRootViewController.h"
#import "HRPatientSummaryViewController.h"
#import "HRTimelineViewController.h"
#import "HRMessagesViewController.h"
#import "HRDoctorsViewController.h"
#import "HRPatient.h"
#import "HRC32ViewController.h"
#import "HRPasscodeWarningViewController.h"
#import "HRPasscodeManager.h"

@interface HRRootViewController ()
- (void)setupPatientLabelWithText:(NSString *)text;
- (void)setLogo;
- (void)setupSegmentedControl;
- (void)showRawC32:(id)sender;
- (void)privacyCheck:(id)sender;

@property (nonatomic, assign) NSInteger selectedIndex;
@end

@implementation HRRootViewController

@synthesize segmentedControl    = __segmentedControl;
@synthesize selectedIndex = __selectedIndex;

- (void)dealloc {
    [__segmentedControl release];
    
    [self.childViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj removeObserver:self forKeyPath:@"title"];
    }];
    
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        HRPatientSummaryViewController *patientSummaryViewController = [[[HRPatientSummaryViewController alloc] initWithNibName:nil bundle:nil] autorelease];
        patientSummaryViewController.title = @"Summary";
        patientSummaryViewController.view.backgroundColor = [UIColor whiteColor];
        [self addChildViewController:patientSummaryViewController];
        
        HRTimelineViewController *timelineViewController = [[HRTimelineViewController alloc] initWithNibName:nil bundle:nil];
        [self addChildViewController:timelineViewController];
        [timelineViewController release];
        
        HRMessagesViewController *messagesViewController = [[HRMessagesViewController alloc] initWithNibName:nil bundle:nil];
        [self addChildViewController:messagesViewController];
        [messagesViewController release];

        HRDoctorsViewController *doctorsViewController = [[HRDoctorsViewController alloc] initWithNibName:nil bundle:nil];
        [self addChildViewController:doctorsViewController];
        [doctorsViewController release];
        
        [self.childViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj addObserver:self forKeyPath:@"title" options:0 context:0];
        }];
        
        HRPatient *patient = [[HRConfig patients] objectAtIndex:0];
        [HRConfig setSelectedPatient:patient];
    }
    
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupPatientLabelWithText:@"Last Updated: 05 May by Joseph Yang, M.D. (Columbia Pediatric Associates)"];
    [self setLogo];

    [self setSelectedIndex:0];
    
    [self setupSegmentedControl];
}


- (void)viewDidUnload {
    [super viewDidUnload];

    self.segmentedControl = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}


#pragma mark - Private methods

- (void)setupPatientLabelWithText:(NSString *)text {
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                                                          target:nil 
                                                                          action:nil];
    UILabel *lastUpdatedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 11.0f, self.view.frame.size.width, 21.0f)];
    lastUpdatedLabel.text = text;
    lastUpdatedLabel.textAlignment = UITextAlignmentCenter;
    lastUpdatedLabel.shadowColor = [UIColor whiteColor];
    lastUpdatedLabel.shadowOffset = CGSizeMake(0.0, 1.0);
    lastUpdatedLabel.font = [UIFont boldSystemFontOfSize:14.0];
    lastUpdatedLabel.textColor = [UIColor grayColor];
    lastUpdatedLabel.backgroundColor = [UIColor clearColor];
    UIBarButtonItem *lastUpdated = [[UIBarButtonItem alloc] initWithCustomView:lastUpdatedLabel];
    
    UIBarButtonItem *rawC32Button = [[UIBarButtonItem alloc] initWithTitle:@"C32 HTML" style:UIBarButtonItemStyleBordered target:self action:@selector(showRawC32:)];
    
    self.toolbarItems = [NSArray arrayWithObjects:flex, lastUpdated, flex, rawC32Button, nil];
    [lastUpdatedLabel release];
    [lastUpdated release];
    [rawC32Button release];
    [flex release];
}

- (void)setLogo {
    UIImage *logo = [UIImage imageNamed:@"hReader_Logo_34x150"];
    UIImageView *logoView = [[UIImageView alloc] initWithImage:logo];
    logoView.frame = CGRectMake(5, 5, 150, 34);
    [self.navigationController.navigationBar addSubview:logoView];
    [logoView release];
}

- (void)setupSegmentedControl {
    
    NSArray *segmentedItems = [self.childViewControllers valueForKey:@"title"];

    self.segmentedControl = [[[UISegmentedControl alloc] initWithItems:segmentedItems] autorelease];
    self.segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    
    NSInteger count = [segmentedItems count];
    for (int i = 0; i < count; i++) {
        [self.segmentedControl setWidth:600/count forSegmentAtIndex:i];
    }
    
    self.segmentedControl.selectedSegmentIndex = 0;
    self.navigationItem.titleView = self.segmentedControl;
    
    [self.segmentedControl addTarget:self action:@selector(segmentSelected) forControlEvents:UIControlEventValueChanged];    
}

- (void)segmentSelected {
    self.selectedIndex = self.segmentedControl.selectedSegmentIndex;
}

- (void)showRawC32:(id)sender {
    [TestFlight passCheckpoint:@"View C32 HTML"];
    HRC32ViewController *c32ViewController = [[HRC32ViewController alloc] initWithNibName:nil bundle:nil];
    c32ViewController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentModalViewController:c32ViewController animated:YES];
    [c32ViewController release];
}

#pragma mark - segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [TestFlight passCheckpoint:segue.identifier];
}

#pragma mark - kvo

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"title"]) {
        // update segments
        UIViewController *viewController = (UIViewController *)object;
        [self.segmentedControl setTitle:viewController.title 
                      forSegmentAtIndex:[self.childViewControllers indexOfObject:viewController]];
    }
}

- (void)privacyCheck:(id)sender {
//    HRPasscodeWarningViewController *warningViewController = [[HRPasscodeWarningViewController alloc] initWithNibName:nil bundle:nil];
//    [self presentModalViewController:warningViewController animated:YES];
//    [warningViewController release];
}

- (void)setSelectedIndex:(NSInteger)index {

    // save old value
    NSInteger oldValue = __selectedIndex;
    
    // save new value 
    __selectedIndex = index;
    
    // get vc at old index
    UIViewController *oldViewController = [self.childViewControllers objectAtIndex:oldValue];
    // call lifecycle methods
    [oldViewController viewWillDisappear:NO];
    
    NSString *title = [[self.childViewControllers objectAtIndex:index] title];
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"Navigation - %@", title]];

    [self.view.subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        [view removeFromSuperview];
     }];
    [oldViewController viewDidDisappear:NO];
    
    UIViewController *viewController = [self.childViewControllers objectAtIndex:index];
    UIView *view = viewController.view;
    view.frame = self.view.bounds;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [viewController viewWillAppear:YES];
    [self.view addSubview:view];
    [viewController viewDidAppear:YES];
}

@end
