//
//  INKWelcomeViewController.h
//  ThatPhoto
//
//  Created by Brett van Zuiden on 8/8/13.
//  Copyright (c) 2013 Aviary. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PagedScrollView.h"

@interface INKWelcomeViewController : UIViewController
@property IBOutlet PagedScrollView *pageScrollView;
@property UIViewController *nextViewController;

+ (BOOL) shouldRunWelcomeFlow;
+ (void) setShouldRunWelcomeFlow:(BOOL)should;

@end
