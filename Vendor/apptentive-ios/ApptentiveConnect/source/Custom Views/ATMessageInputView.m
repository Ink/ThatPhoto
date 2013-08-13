//
//  ATMessageInputView.m
//  ResizingTextView
//
//  Created by Andrew Wooster on 3/29/13.
//  Copyright (c) 2013 Andrew Wooster. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "ATMessageInputView.h"

UIEdgeInsets insetsForView(UIView *v) {
	CGRect frame = v.frame;
	CGRect superBounds = v.superview.bounds;
	return UIEdgeInsetsMake(frame.origin.y, frame.origin.x, superBounds.size.height - frame.size.height - frame.origin.y, superBounds.size.width - frame.size.width - frame.origin.x);
}

@interface ATMessageInputView ()
- (void)resizeTextViewWithString:(NSString *)string animated:(BOOL)animated;
- (void)validateTextField;
@end

@implementation ATMessageInputView {
	CGFloat minHeight;
	CGFloat minTextFieldHeight;
	CGFloat maxTextFieldHeight;
	NSUInteger maxNumberOfLines;
	UIEdgeInsets textViewInsets;
	
	UIEdgeInsets textViewContentInset;
}
@synthesize sendButton, attachButton, delegate, text, allowsEmptyText;

- (void)awakeFromNib {
	[super awakeFromNib];
	maxNumberOfLines = 5;
	
	textViewInsets = insetsForView(textView);
	
	textView.delegate = self;
	minHeight = self.bounds.size.height;
	minTextFieldHeight = textView.font.lineHeight;
	maxTextFieldHeight = textView.font.lineHeight * maxNumberOfLines;
	
	textView.backgroundColor = [UIColor clearColor];
	
	textView.autoresizingMask = UIViewAutoresizingNone;
	//TODO: Get rid of magic numbers here.
	textViewContentInset = UIEdgeInsetsMake(-4, -2, -4, 0);
	textView.contentInset = textViewContentInset;
	textView.showsHorizontalScrollIndicator = NO;
	
	[self validateTextField];
	[self resizeTextViewWithString:textView.text animated:NO];
}

- (void)dealloc {
	delegate = nil;
	textView.delegate = nil;
	[textView release], textView = nil;
	[sendButton release], sendButton = nil;
	[attachButton release], attachButton = nil;
	[backgroundImageView release], backgroundImageView = nil;
	[text release], text = nil;
	[super dealloc];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect textFrame = textView.frame;
	textFrame.origin.x = textViewInsets.left;
	textFrame.size.width = self.bounds.size.width - textViewInsets.left - textViewInsets.right;
	textView.frame = textFrame;
	textView.contentInset = textViewContentInset;
	[self resizeTextViewWithString:textView.text animated:NO];
}

- (BOOL)resignFirstResponder {
	return textView.resignFirstResponder;
}

- (void)resizeTextViewWithString:(NSString *)string animated:(BOOL)animated {
	if (!string || [string length] == 0) {
		string = @"YWM";
	}
	
	CGFloat textViewWidth = textView.bounds.size.width;
	CGFloat previousHeight = self.frame.size.height;
	CGSize optimisticSize = [string sizeWithFont:textView.font];
	CGSize pessimisticSize = [string sizeWithFont:textView.font constrainedToSize:CGSizeMake(textViewWidth, maxTextFieldHeight) lineBreakMode:NSLineBreakByWordWrapping];
	CGSize contentSize = textView.contentSize;
	
	if ([string hasSuffix:@"\n"]) {
		pessimisticSize.height += textView.font.lineHeight;
	} else if (contentSize.height - textView.font.lineHeight > pessimisticSize.height) {
		pessimisticSize.height = contentSize.height - textView.font.lineHeight + 2;
	}
	NSTimeInterval time = animated ? 0.1 : 0;
	[UIView animateWithDuration:time delay:0 options:0 animations:^{
		CGFloat newTextHeight = MIN(maxTextFieldHeight, MAX(minTextFieldHeight, MAX(optimisticSize.height, pessimisticSize.height)));
		newTextHeight += -(textView.contentInset.top + textView.contentInset.bottom);
		CGFloat currentTextHeight = textView.bounds.size.height;
		CGFloat textHeightDelta = newTextHeight - currentTextHeight;
		
		textView.overflowing = (BOOL)(newTextHeight > maxTextFieldHeight);
		textView.scrollEnabled = textView.overflowing;
		
		CGRect newFrame = self.frame;
		CGFloat newHeight = MAX(minHeight, MIN(newTextHeight + textViewInsets.top + textViewInsets.bottom , newFrame.size.height + textHeightDelta));
		
		CGFloat heightDelta = newHeight - newFrame.size.height;
		newFrame.origin.y = newFrame.origin.y - heightDelta;
		newFrame.size.height = newFrame.size.height + heightDelta;
		
		self.frame = newFrame;
		
		CGRect newTextFrame = textView.frame;
		newTextFrame.origin.y = textViewInsets.top;
		newTextFrame.size.height = newTextHeight;
		textView.frame = newTextFrame;
		
		if (previousHeight != newFrame.size.height) {
			[self.delegate messageInputView:self didChangeHeight:newFrame.size.height];
		}
	} completion:^(BOOL finished) {
	}];
}

- (void)validateTextField {
	if (self.allowsEmptyText) {
		self.sendButton.enabled = YES;
	} else {
		NSString *trimmedText = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		BOOL textIsEmpty = (trimmedText == nil || [trimmedText length] == 0);
		self.sendButton.enabled = !textIsEmpty;
	}
}

- (IBAction)sendPressed:(id)sender {
	[self.delegate messageInputViewSendPressed:self];
}

- (IBAction)attachPressed:(id)sender {
	[self.delegate messageInputViewAttachPressed:self];
}

#pragma mark Properties
- (void)setText:(NSString *)string {
	textView.text = string;
	// The text view delegate method is not called on a direct change to the text property.
	[self textViewDidChange:textView];
}

- (NSString *)text {
	return textView.text;
}

- (NSString *)placeholder {
	return [textView placeholder];
}

- (void)setPlaceholder:(NSString *)placeholder {
	[textView setPlaceholder:placeholder];
}

- (void)setAllowsEmptyText:(BOOL)allow {
	if (allow != allowsEmptyText) {
		allowsEmptyText = allow;
		[self validateTextField];
	}
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
	backgroundImageView.image = backgroundImage;
}

- (UIImage *)backgroundImage {
	return backgroundImageView.image;
}

#pragma mark UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)aTextView {
	[self resizeTextViewWithString:textView.text animated:YES];
	[self.delegate messageInputViewDidChange:self];
}

- (void)textViewDidEndEditing:(UITextView *)aTextView {
	[self resizeTextViewWithString:textView.text animated:YES];
	[self.delegate messageInputViewDidChange:self];
}

- (void)textViewDidChange:(UITextView *)aTextView {
	[self validateTextField];
	[self resizeTextViewWithString:textView.text animated:YES];
	[self.delegate messageInputViewDidChange:self];
}

- (BOOL)textView:(UITextView *)aTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)string {
	// We want to size for the new string, not the old.
	NSString *newString = [textView.text stringByReplacingCharactersInRange:range withString:string];
	[self resizeTextViewWithString:newString animated:YES];
	return YES;
}

- (void)textViewDidChangeSelection:(UITextView *)aTextView {
	NSRange selectedRange = [textView selectedRange];
	if (selectedRange.location != NSNotFound) {
		[textView scrollRangeToVisible:selectedRange];
	}
}
@end

@implementation ATMessageTextView
@synthesize overflowing;

- (void)setContentOffset:(CGPoint)offset animated:(BOOL)animated {
	if (overflowing == NO) {
		// Don't scroll if we're not overflowing.
		[super setContentOffset:CGPointZero animated:animated];
	} else if (offset.y < (self.contentSize.height - self.bounds.size.height + self.contentInset.bottom + self.contentInset.top)) {
		// If the text selection changes to contain text above the current text viewport,
		// we want to show the cursor.
		offset.y += self.contentInset.top;
		[super setContentOffset:offset animated:animated];
	} else {
		// Otherwise, scroll the bottom portion of the text view into the viewport.
		CGPoint scrollpoint = CGPointMake(offset.x, self.contentSize.height - self.bounds.size.height + self.contentInset.bottom);
		[super setContentOffset:scrollpoint animated:animated];
	}
}
@end
