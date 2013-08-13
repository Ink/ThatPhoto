//
//  ATTextMessageUserCell.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/9/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "ATTextMessageUserCell.h"


@implementation ATTextMessageUserCell
@synthesize dateLabel, chatBubbleContainer, userIcon, messageBubbleImage, usernameLabel, messageText, composingBubble, composing, showDateLabel;
@synthesize cellType;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		// Initialization code
	}
	return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];

	// Configure the view for the selected state
}

- (void)setIsComposing:(BOOL)comp {
	if (composing != comp) {
		composing = comp;
		if (composing) {
			self.showDateLabel = NO;
		}
		[self setNeedsLayout];
	}
}

- (void)setShowDateLabel:(BOOL)show {
	if (showDateLabel != show) {
		showDateLabel = show;
		[self setNeedsLayout];
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
	if (showDateLabel == NO || composing == YES) {
		self.dateLabel.hidden = YES;
		CGRect chatBubbleRect = self.chatBubbleContainer.frame;
		chatBubbleRect.size.height = self.bounds.size.height;
		chatBubbleRect.origin.y = 0;
		self.chatBubbleContainer.frame = chatBubbleRect;
	} else {
		self.dateLabel.hidden = NO;
		CGRect dateLabelRect = self.dateLabel.frame;
		CGRect chatBubbleRect = self.chatBubbleContainer.frame;
		chatBubbleRect.size.height = self.bounds.size.height - dateLabelRect.size.height;
		chatBubbleRect.origin.y = dateLabelRect.size.height;
		self.chatBubbleContainer.frame = chatBubbleRect;
	}
	self.chatBubbleContainer.hidden = composing;
	self.composingBubble.hidden = !composing;
}

- (void)dealloc {
	[userIcon release], userIcon = nil;
	[messageBubbleImage release], messageBubbleImage = nil;
	[messageText release], messageText = nil;
	[composingBubble release], composingBubble = nil;
	[dateLabel release], dateLabel = nil;
	[chatBubbleContainer release], chatBubbleContainer = nil;
	[usernameLabel release], usernameLabel = nil;
	[super dealloc];
}

- (CGFloat)cellHeightForWidth:(CGFloat)width {
	CGFloat cellHeight = 0;
	
	do { // once
		if (self.isComposing) {
			cellHeight += 60;
			break;
		}
		if (showDateLabel) {
			cellHeight += self.dateLabel.bounds.size.height;
		}
		cellHeight += self.usernameLabel.bounds.size.height;
		CGFloat textWidth = width - 101;
		CGFloat heightPadding = 19 + 6;
		CGSize textSize = [self.messageText sizeThatFits:CGSizeMake(textWidth, 2000)];
		cellHeight += MAX(60, textSize.height + heightPadding);

	} while (NO);
	return cellHeight;
}
@end
