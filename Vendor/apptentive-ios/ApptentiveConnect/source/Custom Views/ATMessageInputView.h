//
//  ATMessageInputView.h
//  ResizingTextView
//
//  Created by Andrew Wooster on 3/29/13.
//  Copyright (c) 2013 Andrew Wooster. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATDefaultTextView.h"

@protocol ATMessageInputViewDelegate;
@class ATMessageTextView;

@interface ATMessageInputView : UIView <UITextViewDelegate> {
@private
	IBOutlet ATMessageTextView *textView;
	IBOutlet UIImageView *backgroundImageView;
}
@property (nonatomic, retain) IBOutlet UIButton *sendButton;
@property (nonatomic, retain) IBOutlet UIButton *attachButton;
@property (nonatomic, assign) NSObject<ATMessageInputViewDelegate> *delegate;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, assign) BOOL allowsEmptyText;
@property (nonatomic, retain) UIImage *backgroundImage;

- (IBAction)sendPressed:(id)sender;
- (IBAction)attachPressed:(id)sender;
@end

@protocol ATMessageInputViewDelegate <NSObject>
- (void)messageInputView:(ATMessageInputView *)inputView didChangeHeight:(CGFloat)height;
- (void)messageInputViewDidChange:(ATMessageInputView *)inputView;
- (void)messageInputViewSendPressed:(ATMessageInputView *)inputView;
- (void)messageInputViewAttachPressed:(ATMessageInputView *)inputView;
@end


@interface ATMessageTextView : ATDefaultTextView
@property (nonatomic, assign) BOOL overflowing;
@end
