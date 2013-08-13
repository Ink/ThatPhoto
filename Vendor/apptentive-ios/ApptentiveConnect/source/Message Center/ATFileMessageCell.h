//
//  ATFileMessageCell.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATMessageCenterCell.h"
#import "ATNetworkImageView.h"
#import "ATFileMessage.h"

@interface ATFileMessageCell : UITableViewCell <ATMessageCenterCell> {
	UILabel *dateLabel;
	ATNetworkImageView *userIcon;
	BOOL showDateLabel;
	ATFileMessage *fileMessage;
	UIImage *currentImage;
}
@property (retain, nonatomic) IBOutlet UILabel *dateLabel;
@property (retain, nonatomic) IBOutlet ATNetworkImageView *userIcon;
@property (retain, nonatomic) IBOutlet UIView *imageContainer;
@property (retain, nonatomic) IBOutlet UIView *chatBubbleContainer;
@property (retain, nonatomic) IBOutlet UIImageView *messageBubbleImage;
@property (nonatomic, assign, getter = shouldShowDateLabel) BOOL showDateLabel;

- (void)configureWithFileMessage:(ATFileMessage *)message;
@end
