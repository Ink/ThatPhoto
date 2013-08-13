//
//  ATFileMessageCell.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "ATFileMessageCell.h"

#import "ATBackend.h"
#import "ATUtilities.h"

@implementation ATFileMessageCell {
	CGSize cachedThumbnailSize;
}
@synthesize dateLabel, userIcon, imageContainer, showDateLabel;

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

- (void)setShowDateLabel:(BOOL)show {
	if (showDateLabel != show) {
		showDateLabel = show;
		[self setNeedsLayout];
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if (showDateLabel == NO) {
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
	self.imageContainer.layer.borderColor = [UIColor grayColor].CGColor;
	self.imageContainer.layer.borderWidth = 1;
	self.imageContainer.layer.cornerRadius = 2;
	self.imageContainer.backgroundColor = [UIColor grayColor];
	self.imageContainer.clipsToBounds = YES;
	self.imageContainer.layer.contentsGravity = kCAGravityResizeAspect;
}

- (void)setCurrentImage:(UIImage *)image {
	if (currentImage != image) {
		[currentImage release], currentImage = nil;
		currentImage = [image retain];
		if (currentImage != nil) {
			self.imageContainer.layer.contents = (id)currentImage.CGImage;
			self.imageContainer.layer.contentsGravity = kCAGravityResizeAspect;
		}
	}
	if (currentImage == nil) {
		currentImage = [[ATBackend imageNamed:@"at_mc_file_default"] retain];
		self.imageContainer.layer.contentsGravity = kCAGravityResizeAspect;
		self.imageContainer.layer.contents = (id)currentImage.CGImage;
	}
}

- (void)configureWithFileMessage:(ATFileMessage *)message {
	if (message != fileMessage) {
		[fileMessage release], fileMessage = nil;
		[currentImage release], currentImage = nil;
		fileMessage = [message retain];
		
		UIImage *imageFile = [UIImage imageWithContentsOfFile:[message.fileAttachment fullLocalPath]];
		CGSize thumbnailSize = ATThumbnailSizeOfMaxSize(imageFile.size, CGSizeMake(320, 320));
		cachedThumbnailSize = thumbnailSize;
		CGFloat scale = [[UIScreen mainScreen] scale];
		thumbnailSize.width *= scale;
		thumbnailSize.height *= scale;
		
		UIImage *thumbnail = [message.fileAttachment thumbnailOfSize:thumbnailSize];
		if (thumbnail) {
			[currentImage release], currentImage = nil;
			currentImage = [thumbnail retain];
			self.imageContainer.layer.contents = (id)currentImage.CGImage;
		} else {
			[self setCurrentImage:nil];
			[message.fileAttachment createThumbnailOfSize:thumbnailSize completion:^{
				UIImage *image = [UIImage imageWithContentsOfFile:[message.fileAttachment fullLocalPath]];
				[self setCurrentImage:image];
			}];
		}
		
		[self setNeedsLayout];
	}
}

- (void)dealloc {
	[dateLabel release], dateLabel = nil;
	[userIcon release], userIcon = nil;
	[imageContainer release];
	[fileMessage release], fileMessage = nil;
	[currentImage release], currentImage = nil;
	[_chatBubbleContainer release];
	[_messageBubbleImage release];
	[super dealloc];
}

- (CGFloat)cellHeightForWidth:(CGFloat)width {
	CGFloat cellHeight = 0;
	if (showDateLabel) {
		cellHeight += self.dateLabel.bounds.size.height;
	}
	
	CGSize thumbSize = cachedThumbnailSize;
	if (CGSizeEqualToSize(CGSizeZero, thumbSize)) {
		thumbSize = CGSizeMake(320, 320);
	}
	thumbSize.width = MAX(thumbSize.width, 1);
	CGFloat thumbRatio = thumbSize.height/thumbSize.width;
	
	UIEdgeInsets chatBubbleInsets = [ATUtilities edgeInsetsOfView:self.chatBubbleContainer];
	UIEdgeInsets imageInsets = [ATUtilities edgeInsetsOfView:self.imageContainer];
	
	CGFloat imageContainerWidth = width - (chatBubbleInsets.left + chatBubbleInsets.right + imageInsets.left + imageInsets.right);
	CGFloat scaledHeight = ceil(imageContainerWidth * thumbRatio);
	cellHeight += MAX(150, scaledHeight);
	cellHeight += imageInsets.top + imageInsets.bottom;
	return cellHeight;
}
@end
