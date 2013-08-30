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
#import <libswyp/libswyp.h>

@interface TPMainViewController : UIViewController <swypBackedPhotoDataSourceDelegate>


@property (strong, nonatomic) IBOutlet UIButton *editButton;
@property (strong, nonatomic) IBOutlet UIButton *inkButton;
@property (weak, nonatomic) IBOutlet UIButton *swypButton;
@property (nonatomic, retain) IBOutlet iCarousel *carousel;
@property (strong, nonatomic) IBOutlet UILabel *albumName;
@property (strong, nonatomic) UISlider *albumSlider;
@property (strong, nonatomic) swypWorkspaceViewController * swypWorkspace;

@property (atomic, strong) NSArray *albums;

- (void) launchEditorWithBlob:(INKBlob *)blob action:(INKAction*)action error:(NSError*)error;


- (IBAction)launchSwypForCurrentPhoto:(id)sender;
- (IBAction)launchInkForCurrentPhoto:(id)sender;
- (IBAction)launchEditorForCurrentPhoto:(id)sender;

@end
