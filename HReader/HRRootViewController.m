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

static int HRRootViewControllerTitleContext;

@interface HRRootViewController ()
@property (nonatomic, retain) UISegmentedControl *segmentedControl;
@property (nonatomic, retain) UIViewController *visibleViewController;
@property (nonatomic, retain) UILabel *lastUpdatedLabel;
- (void)showRawC32;
- (void)privacyCheck;
@end

@implementation HRRootViewController

@synthesize visibleViewController = __visibleViewController;
@synthesize segmentedControl = __segmentedControl;
@synthesize lastUpdatedLabel = __lastUpdatedLabel;

#pragma mark - object methods
- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        
        // vars
        id controller;
        
        // create child view controllers
        controller = [[[HRPatientSummaryViewController alloc] initWithNibName:nil bundle:nil] autorelease];
        [self addChildViewController:controller];
        controller = [[[HRTimelineViewController alloc] initWithNibName:nil bundle:nil] autorelease];
        [self addChildViewController:controller];
        controller = [[[HRMessagesViewController alloc] initWithNibName:nil bundle:nil] autorelease];
        [self addChildViewController:controller];
        controller = [[[HRDoctorsViewController alloc] initWithNibName:nil bundle:nil] autorelease];
        [self addChildViewController:controller];
        
        // register observers
        [self.childViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSAssert([obj title], @"Child view controllers must have a title");
            [obj
             addObserver:self
             forKeyPath:@"title"
             options:NSKeyValueObservingOptionNew
             context:&HRRootViewControllerTitleContext];
        }];
        
    }
    return self;
}
- (void)dealloc {
    self.segmentedControl = nil;
    self.lastUpdatedLabel = nil;
    self.visibleViewController = nil;
    [self.childViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj removeObserver:self forKeyPath:@"title"];
    }];
    [super dealloc];
}
- (BOOL)automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers {
    return NO;
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [TestFlight passCheckpoint:segue.identifier];
}
- (void)privacyCheck {
//    HRPasscodeWarningViewController *warningViewController = [[HRPasscodeWarningViewController alloc] initWithNibName:nil bundle:nil];
//    [self presentModalViewController:warningViewController animated:YES];
//    [warningViewController release];
}
- (void)setVisibleViewController:(UIViewController *)controller {
    
    // tear down old view controller
    [__visibleViewController viewWillDisappear:NO];
    [__visibleViewController.view removeFromSuperview];
    [__visibleViewController viewDidDisappear:NO];
    __visibleViewController.view = nil; // not sure if this works yet
    [__visibleViewController viewDidUnload]; // probably shouldn't call this method at all, ever
    [__visibleViewController release];
    
    // capture new controller
    __visibleViewController = [controller retain];
    UIView *view = __visibleViewController.view;
    view.frame = self.view.bounds;
    view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [__visibleViewController viewWillAppear:NO];
    [self.view addSubview:view];
    [__visibleViewController viewDidDisappear:NO];
    
    // TestFlight
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"Navigation - %@", __visibleViewController.title]];
    
}

#pragma mark - kvo
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &HRRootViewControllerTitleContext) {
        UIViewController *controller = (id)object;
        NSUInteger index = [self.childViewControllers indexOfObject:controller];
        [self.segmentedControl setTitle:controller.title forSegmentAtIndex:index];
    }
}

#pragma mark - view methods
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // configure toolbar
    {
        UIBarButtonItem *flexible = [[[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil
                                      action:nil]
                                     autorelease];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 0.0, 500.0, 30.0)];
        label.textAlignment = UITextAlignmentCenter;
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0.0, 1.0);
        label.font = [UIFont boldSystemFontOfSize:14.0];
        label.textColor = [UIColor grayColor];
        label.backgroundColor = [UIColor clearColor];
        UIBarButtonItem *labelItem = [[[UIBarButtonItem alloc] initWithCustomView:label] autorelease];
        UIBarButtonItem *C32Item = [[[UIBarButtonItem alloc]
                                     initWithTitle:@"C32 HTML"
                                     style:UIBarButtonItemStyleBordered
                                     target:self
                                     action:@selector(showRawC32)]
                                    autorelease];
        self.toolbarItems = [NSArray arrayWithObjects:flexible, labelItem, flexible, C32Item, nil];
        self.lastUpdatedLabel = label;
    }
    
    // configure logo
    {
        UIImage *logo = [UIImage imageNamed:@"hReader_Logo_34x150"];
        UIImageView *logoView = [[[UIImageView alloc] initWithImage:logo] autorelease];
        logoView.frame = CGRectMake(5, 5, 150, 34);
        UIBarButtonItem *logoItem = [[[UIBarButtonItem alloc] initWithCustomView:logoView] autorelease];
        self.navigationItem.leftBarButtonItem = logoItem;
    }
    
    // configure segmented control
    {
        NSArray *titles = [self.childViewControllers valueForKey:@"title"];
        UISegmentedControl *control = [[[UISegmentedControl alloc] initWithItems:titles] autorelease];
        control.segmentedControlStyle = UISegmentedControlStyleBar;
        control.selectedSegmentIndex = 0;
        NSUInteger count = [titles count];
        for (NSUInteger i = 0; i < count; i++) {
            [control setWidth:(600.0 / count) forSegmentAtIndex:i];
        }
        [control addTarget:self action:@selector(segmentSelected) forControlEvents:UIControlEventValueChanged];    
        self.navigationItem.titleView = control;
        self.segmentedControl = control;
    }
    
    // configure first view
    self.visibleViewController = [self.childViewControllers objectAtIndex:0];
    
    // set last updated text
    self.lastUpdatedLabel.text = @"Last Updated: 05 May by Joseph Yang, M.D. (Columbia Pediatric Associates)";
    
}
- (void)viewDidUnload {
    [super viewDidUnload];
    self.lastUpdatedLabel = nil;
    self.segmentedControl = nil;
    self.visibleViewController = nil;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.visibleViewController viewWillAppear:animated];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.visibleViewController viewDidAppear:animated];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.visibleViewController viewWillDisappear:animated];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.visibleViewController viewDidDisappear:animated];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
//    return [self.visibleViewController shouldAutorotateToInterfaceOrientation:orientation];
    return UIInterfaceOrientationIsLandscape(orientation);
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
    [self.visibleViewController willRotateToInterfaceOrientation:orientation duration:duration];
}
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
    [self.visibleViewController willAnimateRotationToInterfaceOrientation:orientation duration:duration];
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orientation {
    [self.visibleViewController didRotateFromInterfaceOrientation:orientation];
}

#pragma mark - button actions
- (void)showRawC32 {
    [TestFlight passCheckpoint:@"View C32 HTML"];
    UIViewController *controller = [[[HRC32ViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    controller.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentModalViewController:controller animated:YES];
}
- (void)segmentSelected {
    NSInteger index = self.segmentedControl.selectedSegmentIndex;
    self.visibleViewController = [self.childViewControllers objectAtIndex:index];
}

@end
