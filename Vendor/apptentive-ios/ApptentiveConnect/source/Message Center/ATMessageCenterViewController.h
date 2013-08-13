//
//  ATMessageCenterViewController.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 9/28/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATAutomatedMessageCell.h"
#import "ATFileMessageCell.h"
#import "ATMessageInputView.h"
#import "ATSimpleImageViewController.h"
#import "ATTextMessageUserCell.h"

@protocol ATMessageCenterThemeDelegate;
@protocol ATMessageCenterDismissalDelegate;

@interface ATMessageCenterViewController : UIViewController <ATMessageInputViewDelegate, ATSimpleImageViewControllerDelegate, NSFetchedResultsControllerDelegate, UIActionSheetDelegate, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (retain, nonatomic) IBOutlet UIView *inputContainerView;
@property (retain, nonatomic) IBOutlet UIView *attachmentView;
@property (retain, nonatomic) IBOutlet UIImageView *attachmentShadowView;
@property (retain, nonatomic) IBOutlet UIButton *iconButton;
@property (retain, nonatomic) IBOutlet UIButton *sendPhotoButton;
@property (retain, nonatomic) IBOutlet UIButton *cancelButton;
@property (retain, nonatomic) IBOutlet UIButton *poweredByButton;
@property (retain, nonatomic) IBOutlet ATAutomatedMessageCell *automatedCell;
@property (retain, nonatomic) IBOutlet ATTextMessageUserCell *userCell;
@property (retain, nonatomic) IBOutlet ATTextMessageUserCell *developerCell;
@property (retain, nonatomic) IBOutlet ATFileMessageCell *userFileMessageCell;
@property (readonly, nonatomic) NSObject<ATMessageCenterThemeDelegate> *themeDelegate;
@property (assign, nonatomic) NSObject<ATMessageCenterDismissalDelegate> *dismissalDelegate;

- (id)initWithThemeDelegate:(NSObject<ATMessageCenterThemeDelegate> *)themeDelegate;

- (IBAction)donePressed:(id)sender;
- (IBAction)settingsPressed:(id)sender;
- (IBAction)showInfoView:(id)sender;
- (IBAction)cameraPressed:(id)sender;
- (IBAction)cancelAttachmentPressed:(id)sender;
@end



@protocol ATMessageCenterThemeDelegate <NSObject>
@optional
- (UIView *)titleViewForMessageCenterViewController:(ATMessageCenterViewController *)vc;
- (void)configureSendButton:(UIButton *)sendButton forMessageCenterViewController:(ATMessageCenterViewController *)vc;
- (void)configureAttachmentsButton:(UIButton *)button forMessageCenterViewController:(ATMessageCenterViewController *)vc;
- (UIImage *)backgroundImageForMessageForMessageCenterViewController:(ATMessageCenterViewController *)vc;
@end

@protocol ATMessageCenterDismissalDelegate <NSObject>
- (void)messageCenterWillDismiss:(ATMessageCenterViewController *)messageCenter;
@optional
- (void)messageCenterDidDismiss:(ATMessageCenterViewController *)messageCenter;
@end
