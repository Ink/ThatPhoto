//
//  ATDefaultMessageCenterTheme.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/24/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATDefaultMessageCenterTheme.h"

#import "ATBackend.h"
#import "ATDefaultMessageCenterTitleView.h"

@implementation ATDefaultMessageCenterTheme
- (UIView *)titleViewForMessageCenterViewController:(ATMessageCenterViewController *)vc {
	return [[[ATDefaultMessageCenterTitleView alloc] initWithFrame:vc.navigationController.navigationBar.bounds] autorelease];
}

- (void)configureSendButton:(UIButton *)sendButton forMessageCenterViewController:(ATMessageCenterViewController *)vc {
	UIImage *sendImageBase = [ATBackend imageNamed:@"at_send_button_flat"];
	UIImage *sendImage = nil;
	if ([sendImageBase respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
		sendImage = [sendImageBase resizableImageWithCapInsets:UIEdgeInsetsMake(12, 49, 13, 13)];
	} else {
		sendImage = [sendImageBase stretchableImageWithLeftCapWidth:49 topCapHeight:12];
	}
	[sendButton setBackgroundImage:sendImage forState:UIControlStateNormal];
	[sendButton.titleLabel setShadowOffset:CGSizeMake(0, 1)];
	[sendButton setTitleColor:[UIColor colorWithWhite:0.0 alpha:0.7] forState:UIControlStateNormal];
	[sendButton setTitleShadowColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateNormal];
	[sendButton setTitleShadowColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateDisabled];
	[sendButton setTitleColor:[UIColor colorWithWhite:0.0 alpha:0.3] forState:UIControlStateDisabled];
	//[sendButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateDisabled];
}

- (void)configureAttachmentsButton:(UIButton *)button forMessageCenterViewController:(ATMessageCenterViewController *)vc {
	[button setTitle:@"" forState:UIControlStateNormal];
	[button setImage:[ATBackend imageNamed:@"at_plus_button_flat"] forState:UIControlStateNormal];
}

- (UIImage *)backgroundImageForMessageForMessageCenterViewController:(ATMessageCenterViewController *)vc {
	UIImage *flatInputBackgroundImage = [ATBackend imageNamed:@"at_flat_input_bg"];
	UIEdgeInsets capInsets = UIEdgeInsetsMake(16, 44, flatInputBackgroundImage.size.height - 16 - 1, flatInputBackgroundImage.size.width - 44 - 1);
	
	UIImage *resizableImage = nil;
	if ([flatInputBackgroundImage respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
		resizableImage = [flatInputBackgroundImage resizableImageWithCapInsets:capInsets];
	} else {
		resizableImage = [flatInputBackgroundImage stretchableImageWithLeftCapWidth:capInsets.left topCapHeight:capInsets.top];
	}
	return resizableImage;
}
@end
