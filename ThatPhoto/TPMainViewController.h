//
//  TPMainViewController.h
//  ThatPhoto
//
//  Created by Brett van Zuiden
//  Copyright (c) 2013 Ink (Cloudtop Inc). All rights reserved.
//

#import <UIKit/UIKit.h>
#import <INK/Ink.h>
#import "iCarousel.h"

@interface TPMainViewController : UIViewController


@property (strong, nonatomic) IBOutlet UIButton *editButton;
@property (strong, nonatomic) IBOutlet UIButton *inkButton;
@property (nonatomic, retain) IBOutlet iCarousel *carousel;
@property (strong, nonatomic) IBOutlet UILabel *albumName;
@property (strong, nonatomic) UISlider *albumSlider;

@property (atomic, strong) NSArray *albums;

- (void) launchEditorWithBlob:(INKBlob *)blob action:(INKAction*)action error:(NSError*)error;

@end
