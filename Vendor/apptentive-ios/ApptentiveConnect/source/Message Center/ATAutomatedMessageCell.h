//
//  ATAutomatedMessageCell.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/19/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATMessageCenterCell.h"
#import "TTTAttributedLabel.h"

@interface ATAutomatedMessageCell : UITableViewCell <ATMessageCenterCell>
@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (retain, nonatomic) IBOutlet UILabel *dateLabel;
@property (retain, nonatomic) IBOutlet ATTTTAttributedLabel *titleText;
@property (retain, nonatomic) IBOutlet UIView *grayLineView;
@property (retain, nonatomic) IBOutlet ATTTTAttributedLabel *messageText;
@property (nonatomic, assign, getter = shouldShowDateLabel) BOOL showDateLabel;

@end
