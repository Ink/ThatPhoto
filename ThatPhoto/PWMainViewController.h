//
//  AFSDKDemoViewController.h
//  AviaryDemo-iOS
//
//  Created by Michael Vitrano on 1/23/13.
//  Copyright (c) 2013 Aviary. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <INK/InkCore.h>
#import <QuickLook/QuickLook.h>
#import "iCarousel.h"

@interface PWMainViewController : UIViewController


@property (strong, nonatomic) IBOutlet UIButton *editButton;
@property (strong, nonatomic) IBOutlet UIButton *inkButton;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (strong, nonatomic) IBOutlet UIImageView *logoImageView;
@property (nonatomic, retain) IBOutlet iCarousel *carousel;
@property (strong, nonatomic) IBOutlet UILabel *albumName;
@property (strong, nonatomic) UISlider *albumSlider;

@property (atomic, strong) NSArray *albums;

- (void) launchEditorWithBlob:(INKBlob *)blob;

@end
