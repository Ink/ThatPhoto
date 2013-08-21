//
//  INKWelcomeViewController.h
//  ThatPDF
//
//  Created by Brett van Zuiden on 8/8/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PagedScrollView.h"

@interface INKWelcomeViewController : UIViewController
@property IBOutlet PagedScrollView *pageScrollView;

+ (BOOL) shouldRunWelcomeFlow;
+ (void) setShouldRunWelcomeFlow:(BOOL)should;

@end
