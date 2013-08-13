//
//  INKWelcomeViewController.m
//  ThatPhoto
//
//  Created by Brett van Zuiden on 8/8/13.
//  Copyright (c) 2013 Aviary. All rights reserved.
//

#import "INKWelcomeViewController.h"

@interface INKWelcomeViewController ()

@end

CGFloat const scrollViewHeight = 578.f;
CGFloat const scrollViewMargin = 0.f;

NSString *pasteboardDataName = @"com.inkmobility.hasRunWelcomeFlow";

@implementation INKWelcomeViewController
@synthesize pageScrollView, nextViewController;

+ (BOOL) shouldRunWelcomeFlow {
    UIPasteboard *pasteboardData = [UIPasteboard pasteboardWithName:pasteboardDataName create:YES];
    return ![[pasteboardData string] isEqual: @"NO"];
}

+ (void) setShouldRunWelcomeFlow:(BOOL)should {
    NSString *data = should ? @"YES" : @"NO";
    UIPasteboard *pasteboardData = [UIPasteboard pasteboardWithName:pasteboardDataName create:YES];
    [pasteboardData setString:data];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat scrollViewWidth = self.view.bounds.size.width;
    CGRect pageFrame = CGRectMake((self.view.bounds.size.width - scrollViewWidth), (self.view.bounds.size.height - scrollViewHeight), scrollViewWidth, scrollViewHeight);
    
    pageScrollView = [pageScrollView initWithFrame:pageFrame];
    
    NSString* appID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    
    NSMutableArray *views = [NSMutableArray arrayWithCapacity:4];
    NSMutableArray *images = [NSMutableArray arrayWithObjects:@"OnboardStep2", @"OnboardStep3", nil];
    
    if ([appID isEqualToString:@"com.inkmobility.ThatPhoto"]) {
        [images insertObject:@"WelcomeThatPhoto" atIndex:0];
    } else if ([appID isEqualToString:@"com.inkmobility.thatinbox"]) {
        [images insertObject:@"WelcomeThatInbox" atIndex:0];
    } else if ([appID isEqualToString:@"com.inkmobility.ThatPDF"]) {
        [images insertObject:@"WelcomeThatPDF" atIndex:0];
    } else if ([appID isEqualToString:@"com.inkmobility.thatcloud"]) {
        [images insertObject:@"WelcomeThatCloud" atIndex:0];
    }
    for (NSString *imageName in images) {
        UIView *welcomeScreen = [[UIView alloc] init];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
        imageView.frame = CGRectMake(CGRectGetMidX(welcomeScreen.bounds) - CGRectGetMidX(imageView.bounds), 0, imageView.bounds.size.width, imageView.bounds.size.height);
        imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        [welcomeScreen addSubview:imageView];
        welcomeScreen.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
        [views addObject:welcomeScreen];
    }
    
    [pageScrollView setScrollViewContents:views];
}

- (void) viewWillLayoutSubviews {
    CGFloat scrollViewWidth = self.view.bounds.size.width;
    CGRect pageFrame = CGRectMake((self.view.bounds.size.width - scrollViewWidth), (self.view.bounds.size.height - scrollViewHeight), scrollViewWidth, scrollViewHeight);
    [self.pageScrollView setFrame:pageFrame];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)skipWelcomeFlow:(id)sender {
    [INKWelcomeViewController setShouldRunWelcomeFlow:NO];
    [[[UIApplication sharedApplication] keyWindow] setRootViewController:self.nextViewController];
}



@end
