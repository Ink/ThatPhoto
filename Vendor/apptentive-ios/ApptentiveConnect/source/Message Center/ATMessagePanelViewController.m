//
//  ATMessagePanelViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/5/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "ATMessagePanelViewController.h"

#import "ATConnect_Private.h"
#import "ATContactStorage.h"
#import "ATCustomButton.h"
#import "ATCustomView.h"
#import "ATToolbar.h"
#import "ATDefaultTextView.h"
#import "ATBackend.h"
#import "ATConnect.h"
#import "ATHUDView.h"
#import "ATLabel.h"
#import "ATMessageCenterMetrics.h"
#import "ATUtilities.h"
#import "ATShadowView.h"

#define DEG_TO_RAD(angle) ((M_PI * angle) / 180.0)
#define RAD_TO_DEG(radians) (radians * (180.0/M_PI))

enum {
	kMessagePanelContainerViewTag = 1009,
	kATEmailAlertTextFieldTag = 1010,
	kMessagePanelGradientLayerTag = 1011,
};

@interface ATMessagePanelViewController ()
- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion withAction:(ATMessagePanelDismissAction)action;
@end

@interface ATMessagePanelViewController (Private)
- (void)setupScrollView;
- (void)teardown;
- (BOOL)shouldReturn:(UIView *)view;
- (UIWindow *)findMainWindowPreferringMainScreen:(BOOL)preferMainScreen;
- (UIWindow *)windowForViewController:(UIViewController *)viewController;
+ (CGFloat)rotationOfViewHierarchyInRadians:(UIView *)leafView;
+ (CGAffineTransform)viewTransformInWindow:(UIWindow *)window;
- (void)statusBarChanged:(NSNotification *)notification;
- (void)applicationDidBecomeActive:(NSNotification *)notification;
- (void)feedbackChanged:(NSNotification *)notification;
- (void)hide:(BOOL)animated;
- (void)finishHide;
- (void)finishUnhide;
- (void)sendMessageAndDismiss;
- (void)updateSendButtonState;
@end

@interface ATMessagePanelViewController (Positioning)
- (BOOL)isIPhoneAppInIPad;
- (CGRect)onscreenRectOfView;
- (CGPoint)offscreenPositionOfView;
- (void)positionInWindow;
@end

@implementation ATMessagePanelViewController
@synthesize window;
@synthesize cancelButton;
@synthesize sendButton;
@synthesize toolbar;
@synthesize scrollView;
@synthesize emailField;
@synthesize feedbackView;
@synthesize promptTitle;
@synthesize promptText;
@synthesize customPlaceholderText;
@synthesize showEmailAddressField;
@synthesize delegate;

- (id)initWithDelegate:(NSObject<ATMessagePanelDelegate> *)aDelegate {
	self = [super initWithNibName:@"ATMessagePanelViewController" bundle:[ATConnect resourceBundle]];
	if (self != nil) {
		showEmailAddressField = YES;
		startingStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
		delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	[_toolbarShadowImage release], _toolbarShadowImage = nil;
	[noEmailAddressAlert release], noEmailAddressAlert = nil;
	[invalidEmailAddressAlert release], invalidEmailAddressAlert = nil;
	delegate = nil;
	[super dealloc];
}

- (void)presentFromViewController:(UIViewController *)newPresentingViewController animated:(BOOL)animated {
	[self retain];
	
	if (presentingViewController != newPresentingViewController) {
		[presentingViewController release], presentingViewController = nil;
		presentingViewController = [newPresentingViewController retain];
		[presentingViewController.view setUserInteractionEnabled:NO];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChanged:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
	
	CALayer *l = self.view.layer;
	
	UIWindow *parentWindow = [self windowForViewController:presentingViewController];
	if (!parentWindow) {
		ATLogError(@"Unable to find parentWindow!");
	}
	if (originalPresentingWindow != parentWindow) {
		[originalPresentingWindow release], originalPresentingWindow = nil;
		originalPresentingWindow = [parentWindow retain];
	}
	
	[self setupScrollView];
	
	CGRect animationBounds = CGRectZero;
	CGPoint animationCenter = CGPointZero;
	
	CGAffineTransform t = [ATMessagePanelViewController viewTransformInWindow:parentWindow];
	self.window.transform = t;
	self.window.hidden = NO;
	[parentWindow resignKeyWindow];
	[self.window makeKeyAndVisible];
	animationBounds = parentWindow.bounds;
	animationCenter = parentWindow.center;
	
	
	// Animate in from above.
	self.window.bounds = animationBounds;
	self.window.windowLevel = UIWindowLevelNormal;
	CGPoint center = animationCenter;
	center.y = ceilf(center.y);
	
	CGRect endingFrame = [[UIScreen mainScreen] applicationFrame];
	
	[self positionInWindow];
	
	if ([self.emailField.text isEqualToString:@""] && self.showEmailAddressField) {
		[self.emailField becomeFirstResponder];
	} else {
		[self.feedbackView becomeFirstResponder];
	}
	
	self.window.center = CGPointMake(CGRectGetMidX(endingFrame), CGRectGetMidY(endingFrame));
	self.view.center = [self offscreenPositionOfView];
	
	CGRect newFrame = [self onscreenRectOfView];
	CGPoint newViewCenter = CGPointMake(CGRectGetMidX(newFrame), CGRectGetMidY(newFrame));
	
	ATShadowView *shadowView = [[ATShadowView alloc] initWithFrame:self.window.bounds];
	shadowView.tag = kMessagePanelGradientLayerTag;
	[self.window addSubview:shadowView];
	[self.window sendSubviewToBack:shadowView];
	shadowView.alpha = 1.0;
	
	l.cornerRadius = 10.0;
	l.backgroundColor = [UIColor whiteColor].CGColor;
	l.shadowColor = [UIColor blackColor].CGColor;
	l.shadowOpacity = 0.72;
	l.shadowRadius = 8;
	
	l.masksToBounds = YES;
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
	} else {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	}
	
	[UIView animateWithDuration:0.3 animations:^(void){
		self.view.center = newViewCenter;
		shadowView.alpha = 1.0;
	} completion:^(BOOL finished) {
		self.window.hidden = NO;
		if ([self.emailField.text isEqualToString:@""] && self.showEmailAddressField) {
			[self.emailField becomeFirstResponder];
		} else {
			[self.feedbackView becomeFirstResponder];
		}
	}];
	[shadowView release], shadowView = nil;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroDidShowNotification object:self userInfo:nil];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedbackChanged:) name:UITextViewTextDidChangeNotification object:self.feedbackView];
	self.cancelButton = [[[ATCustomButton alloc] initWithButtonStyle:ATCustomButtonStyleCancel] autorelease];
	[self.cancelButton setAction:@selector(cancelPressed:) forTarget:self];
	
	self.sendButton = [[[ATCustomButton alloc] initWithButtonStyle:ATCustomButtonStyleSend] autorelease];
	[self.sendButton setAction:@selector(sendPressed:) forTarget:self];
	
	UIImage *toolbarShadowBase = [ATBackend imageNamed:@"at_message_toolbar_shadow"];
	UIImage *toolbarShadow = nil;
	if ([toolbarShadowBase respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
		toolbarShadow = [toolbarShadowBase resizableImageWithCapInsets:UIEdgeInsetsMake(8, 0, 0, 128)];
	} else {
		toolbarShadow = [toolbarShadowBase stretchableImageWithLeftCapWidth:0 topCapHeight:8];
	}
	self.toolbarShadowImage.image = toolbarShadow;
	self.toolbarShadowImage.alpha = 0;
	
	NSMutableArray *toolbarItems = [[self.toolbar items] mutableCopy];
	[toolbarItems insertObject:self.cancelButton atIndex:0];
	[toolbarItems addObject:self.sendButton];
	
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	if (self.promptTitle) {
		titleLabel.text = self.promptTitle;
	} else {
		titleLabel.text = ATLocalizedString(@"Give Feedback", @"Title of feedback screen.");
	}
	titleLabel.textAlignment = UITextAlignmentCenter;
	titleLabel.textColor = [UIColor colorWithRed:105/256. green:105/256. blue:105/256. alpha:1.0];
	titleLabel.shadowColor = [UIColor whiteColor];
	titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.opaque = NO;
	[titleLabel sizeToFit];
	CGRect titleFrame = titleLabel.frame;
	titleLabel.frame = titleFrame;
	
	UIBarButtonItem *titleButton = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
	[toolbarItems insertObject:titleButton atIndex:2];
	[titleButton release], titleButton = nil;
	[titleLabel release], titleLabel = nil;
		
	self.toolbar.items = toolbarItems;
	[toolbarItems release], toolbarItems = nil;
	
	self.toolbar.at_drawRectBlock = ^(NSObject *toolbar, CGRect rect) {
		UIColor *color = [UIColor colorWithRed:215/255. green:215/255. blue:215/255. alpha:1];
		UIBezierPath *rectanglePath = [UIBezierPath bezierPathWithRect:CGRectMake(0, rect.size.height - 1, rect.size.width, 1)];
		[color setFill];
		[rectanglePath fill];
	};
	
	[self updateSendButtonState];
	[super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	//	return YES;
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
}

- (IBAction)sendPressed:(id)sender {
	[self.emailField resignFirstResponder];
	[self.feedbackView resignFirstResponder];
	if (self.showEmailAddressField && [self.emailField.text length] > 0 && ![ATUtilities emailAddressIsValid:self.emailField.text]) {
		if (invalidEmailAddressAlert) {
			[invalidEmailAddressAlert release], invalidEmailAddressAlert = nil;
		}
		self.window.windowLevel = UIWindowLevelNormal;
		self.window.userInteractionEnabled = NO;
		self.window.layer.shouldRasterize = YES;
		NSString *title = NSLocalizedString(@"Invalid Email Address", @"Invalid email dialog title.");
		NSString *message = NSLocalizedString(@"That doesn't look like an email address. An email address will help us respond.", @"Invalid email dialog message.");
		invalidEmailAddressAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Okay", @"Okay button title"), nil];
		[invalidEmailAddressAlert show];
	} else if (self.showEmailAddressField && (!self.emailField.text || [self.emailField.text length] == 0)) {
		if (noEmailAddressAlert) {
			[noEmailAddressAlert release], noEmailAddressAlert = nil;
		}
		self.window.windowLevel = UIWindowLevelNormal;
		self.window.userInteractionEnabled = NO;
		self.window.layer.shouldRasterize = YES;
		NSString *title = NSLocalizedString(@"No email address?", @"Lack of email dialog title.");
		NSString *message = NSLocalizedString(@"An email address will help us respond.", @"Lack of email dialog message.");
		noEmailAddressAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Send Feedback", @"Send button title"), nil];
		BOOL useNativeTextField = [noEmailAddressAlert respondsToSelector:@selector(alertViewStyle)];
		UITextField *field = nil;
		
		if (useNativeTextField) {
			// iOS 5 and above.
			[noEmailAddressAlert setAlertViewStyle:2]; // UIAlertViewStylePlainTextInput
			field = [noEmailAddressAlert textFieldAtIndex:0];
			[field retain];
		} else {
			NSString *messagePadded = [NSString stringWithFormat:@"%@\n\n\n", message];
			[noEmailAddressAlert setMessage:messagePadded];
			field = [[UITextField alloc] initWithFrame:CGRectMake(16, 83, 252, 25)];
			field.font = [UIFont systemFontOfSize:18];
			field.textColor = [UIColor lightGrayColor];
			field.backgroundColor = [UIColor clearColor];
			field.keyboardAppearance = UIKeyboardAppearanceAlert;
			field.borderStyle = UITextBorderStyleRoundedRect;
		}
		field.keyboardType = UIKeyboardTypeEmailAddress;
		field.delegate = self;
		field.autocapitalizationType = UITextAutocapitalizationTypeNone;
		field.placeholder = NSLocalizedString(@"Email Address", @"Email address popup placeholder text.");
		field.tag = kATEmailAlertTextFieldTag;
		
		if (!useNativeTextField) {
			[field becomeFirstResponder];
			[noEmailAddressAlert addSubview:field];
		} else {
			[field becomeFirstResponder];
		}
		[field release], field = nil;
		[noEmailAddressAlert sizeToFit];
		[noEmailAddressAlert show];
	} else {
		[self sendMessageAndDismiss];
	}
}

- (IBAction)cancelPressed:(id)sender {
	[self.delegate messagePanelDidCancel:self];
	[self dismissAnimated:YES completion:NULL withAction:ATMessagePanelDidCancel];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroDidCancelNotification object:self userInfo:nil];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion withAction:(ATMessagePanelDismissAction)action {
	[self.emailField resignFirstResponder];
	[self.feedbackView resignFirstResponder];
	
	CGPoint endingPoint = [self offscreenPositionOfView];
	
	UIView *gradientView = [self.window viewWithTag:kMessagePanelGradientLayerTag];
	
	CGFloat duration = 0;
	if (animated) {
		duration = 0.3;
	}
	[UIView animateWithDuration:duration animations:^(void){
		self.view.center = endingPoint;
		gradientView.alpha = 0.0;
	} completion:^(BOOL finished) {
		[self.emailField resignFirstResponder];
		[self.feedbackView resignFirstResponder];
		UIView *gradientView = [self.window viewWithTag:kMessagePanelGradientLayerTag];
		[gradientView removeFromSuperview];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
		[presentingViewController.view setUserInteractionEnabled:YES];
		[self.window resignKeyWindow];
		[self.window removeFromSuperview];
		self.window.hidden = YES;
		[[UIApplication sharedApplication] setStatusBarStyle:startingStatusBarStyle];
		[self teardown];
		[self release];
		
		if (completion) {
			completion();
		}
		[self.delegate messagePanel:self didDismissWithAction:action];
	}];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion {
	[self dismissAnimated:animated completion:completion withAction:ATMessagePanelWasDismissed];
}

- (void)dismiss:(BOOL)animated {
	[self dismissAnimated:animated completion:nil withAction:ATMessagePanelWasDismissed];
}

- (void)unhide:(BOOL)animated {
	self.window.windowLevel = UIWindowLevelNormal;
	self.window.hidden = NO;
	if (animated) {
		[UIView animateWithDuration:0.2 animations:^(void){
			self.window.alpha = 1.0;
		} completion:^(BOOL complete){
			[self finishUnhide];
		}];
	} else {
		[self finishUnhide];
	}
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	return [self shouldReturn:textField];
}

#pragma mark UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
	if (textView == self.feedbackView) {
		CGFloat minTextViewHeight = self.scrollView.frame.size.height - textView.frame.origin.y;
		CGSize oldContentSize = self.scrollView.contentSize;
		CGRect oldTextViewRect = textView.frame;
		
		CGSize sizedText = [textView sizeThatFits:CGSizeMake(textView.bounds.size.width, CGFLOAT_MAX)];
		sizedText.height = MAX(minTextViewHeight, sizedText.height);
		CGFloat heightDiff = oldTextViewRect.size.height - sizedText.height;
		
		CGSize newContentSize = oldContentSize;
		newContentSize.height -= heightDiff;
		CGRect newTextViewFrame = oldTextViewRect;
		newTextViewFrame.size.height -= heightDiff;
		textView.frame = newTextViewFrame;
		// Fix for iOS 4.
		textView.contentInset = UIEdgeInsetsMake(0, -8, 0, 0);
		if (!CGSizeEqualToSize(self.scrollView.contentSize, newContentSize)) {
			self.scrollView.contentSize = newContentSize;
		}
	}
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
	if (self.scrollView.contentOffset.y != 0) {
		[UIView animateWithDuration:0.2 animations:^{
			self.toolbarShadowImage.alpha = 1;
		}];
	} else {
		[UIView animateWithDuration:0.0 animations:^{
			self.toolbarShadowImage.alpha = 0;
		}];
	}
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	self.window.layer.shouldRasterize = NO;
	if (noEmailAddressAlert && [alertView isEqual:noEmailAddressAlert]) {
		[noEmailAddressAlert release], noEmailAddressAlert = nil;
		UITextField *textField = (UITextField *)[alertView viewWithTag:kATEmailAlertTextFieldTag];
		if (textField) {
			self.emailField.text = textField.text;
			[self sendMessageAndDismiss];
		}
	} else if (invalidEmailAddressAlert && [alertView isEqual:invalidEmailAddressAlert]) {
		self.window.userInteractionEnabled = YES;
		[invalidEmailAddressAlert release], invalidEmailAddressAlert = nil;
		[self.emailField becomeFirstResponder];
	}
}

- (void)alertViewCancel:(UIAlertView *)alertView {
	self.window.layer.shouldRasterize = NO;
	self.window.userInteractionEnabled = YES;
	if (noEmailAddressAlert && [alertView isEqual:noEmailAddressAlert]) {
		[noEmailAddressAlert release], noEmailAddressAlert = nil;
	} else if (invalidEmailAddressAlert && [alertView isEqual:invalidEmailAddressAlert]) {
		[invalidEmailAddressAlert release], invalidEmailAddressAlert = nil;
	}
}

#pragma mark -

- (void)viewDidUnload {
	[self setToolbarShadowImage:nil];
	[super viewDidUnload];
}
@end

@implementation ATMessagePanelViewController (Private)
- (void)setupScrollView {
	CGFloat offsetY = 0;
	CGFloat horizontalPadding = 7;
	self.scrollView.backgroundColor = [UIColor colorWithRed:240/255. green:240/255. blue:240/255. alpha:1];
	self.scrollView.delegate = self;
	if (self.promptText) {
		CGRect containerFrame = self.scrollView.bounds;
		CGFloat labelPadding = 4;
		
		ATLabel *promptLabel = [[ATLabel alloc] initWithFrame:containerFrame];
		promptLabel.text = self.promptText;
		promptLabel.textColor = [UIColor colorWithRed:128/255. green:128/255. blue:128/255. alpha:1];
		promptLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:18];
		promptLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		promptLabel.lineBreakMode = UILineBreakModeWordWrap;
		promptLabel.numberOfLines = 0;
		CGSize fitSize = [promptLabel sizeThatFits:CGSizeMake(containerFrame.size.width - labelPadding*2, CGFLOAT_MAX)];
		containerFrame.size.height = fitSize.height + labelPadding*2;
		
		UIView *promptContainer = [[UIView alloc] initWithFrame:containerFrame];
		promptContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		promptContainer.backgroundColor = [UIColor whiteColor];
		CGRect labelFrame = CGRectInset(containerFrame, labelPadding, labelPadding);
		promptLabel.frame = labelFrame;
		[promptContainer addSubview:promptLabel];
		
		[self.scrollView addSubview:promptContainer];
		offsetY += promptContainer.bounds.size.height;
		[promptContainer release], promptContainer = nil;
		[promptLabel release], promptLabel = nil;
	}
	
	CGRect lineFrame = self.scrollView.bounds;
	lineFrame.size.height = 4;
	lineFrame.origin.y = offsetY;
	lineFrame.size.width += 1;
	UIView *blueLineView = [[UIView alloc] initWithFrame:lineFrame];
	blueLineView.backgroundColor = [UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_message_blue_line"]];
	blueLineView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.scrollView addSubview:blueLineView];
	offsetY += blueLineView.bounds.size.height;
	[blueLineView release], blueLineView = nil;
	
	if (self.showEmailAddressField) {
		offsetY += 5;
		CGRect emailFrame = self.scrollView.bounds;
		emailFrame.origin.x = horizontalPadding;
		emailFrame.origin.y = offsetY;
		UIFont *emailFont = [UIFont systemFontOfSize:17];
		CGSize sizedEmail = [@"XXYyI|" sizeWithFont:emailFont];
		emailFrame.size.height = sizedEmail.height;
		emailFrame.size.width = emailFrame.size.width - horizontalPadding*2;
		self.emailField = [[[UITextField alloc] initWithFrame:emailFrame] autorelease];
		self.emailField.placeholder = ATLocalizedString(@"Your Email", @"Email Address Field Placeholder");
		self.emailField.font = emailFont;
		self.emailField.adjustsFontSizeToFitWidth = YES;
		self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
		self.emailField.returnKeyType = UIReturnKeyNext;
		self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
		self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		self.emailField.backgroundColor = [UIColor clearColor];
		self.emailField.clearButtonMode = UITextFieldViewModeWhileEditing;
		self.emailField.text = [self.delegate initialEmailAddressForMessagePanel:self];

		[self.scrollView addSubview:self.emailField];
		offsetY += self.emailField.bounds.size.height + 5;
		
		ATCustomView *thinBlueLineView = [[ATCustomView alloc] initWithFrame:CGRectZero];
		thinBlueLineView.at_drawRectBlock = ^(NSObject *caller, CGRect rect) {
			UIColor *color = [UIColor colorWithRed:133/255. green:149/255. blue:160/255. alpha:1];
			UIBezierPath *rectanglePath = [UIBezierPath bezierPathWithRect:rect];
			[color setFill];
			[rectanglePath fill];
		};
		thinBlueLineView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		CGRect lineFrame = self.scrollView.bounds;
		CGFloat linePadding = 2;
		lineFrame.origin.x = linePadding;
		lineFrame.origin.y = offsetY;
		lineFrame.size.width = lineFrame.size.width - linePadding*2;
		lineFrame.size.height = 1;
		thinBlueLineView.frame = lineFrame;
		[self.scrollView addSubview:thinBlueLineView];
		offsetY += lineFrame.size.height;
		[thinBlueLineView release], thinBlueLineView = nil;
	}
	
	CGRect feedbackFrame = self.scrollView.bounds;
	feedbackFrame.origin.x = horizontalPadding;
	feedbackFrame.origin.y = offsetY;
	feedbackFrame.size.height = 20;
	feedbackFrame.size.width = feedbackFrame.size.width - horizontalPadding*2;
	self.feedbackView = [[[ATDefaultTextView alloc] initWithFrame:feedbackFrame] autorelease];
	UIEdgeInsets insets = UIEdgeInsetsMake(0, -8, 0, 0);
	self.feedbackView.contentInset = insets;
	self.feedbackView.clipsToBounds = YES;
	self.feedbackView.font = [UIFont systemFontOfSize:17];
	self.feedbackView.backgroundColor = [UIColor clearColor];
	self.feedbackView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.feedbackView.scrollEnabled = NO;
	self.feedbackView.delegate = self;
	[self.scrollView addSubview:self.feedbackView];
	offsetY += self.feedbackView.bounds.size.height;
	
	if (self.customPlaceholderText) {
		self.feedbackView.placeholder = self.customPlaceholderText;
	} else {
		self.feedbackView.placeholder = ATLocalizedString(@"Feedback (required)", @"Feedback placeholder");
	}
	
	self.feedbackView.at_drawRectBlock = ^(NSObject *caller, CGRect rect) {
		ATDefaultTextView *textView = (ATDefaultTextView *)caller;
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextSetLineWidth(context, 0.5);
		CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:183/255. green:183/255. blue:183/255. alpha:1].CGColor);
		CGContextBeginPath(context);
		
		CGFloat startX = rect.origin.x;
		CGFloat endX = startX + rect.size.width;
		CGFloat lineHeight = textView.font.lineHeight;
		CGFloat offsetY = 4 - textView.font.descender;
		CGFloat scale = [UIScreen mainScreen].scale;
		
		NSUInteger firstLine = MAX(1, (textView.contentOffset.y/lineHeight));
		NSUInteger lastLine = (textView.contentOffset.y + textView.bounds.size.height)/lineHeight + 1;
		for (NSUInteger line = firstLine; line < lastLine; line++) {
			CGFloat lineY = round((offsetY + (lineHeight * line))*scale)/scale + 0.5;
			CGContextMoveToPoint(context, startX, lineY);
			CGContextAddLineToPoint(context, endX, lineY);
		}
		
		CGContextClosePath(context);
		CGContextStrokePath(context);
	};
	
	CGSize contentSize = CGSizeMake(self.scrollView.bounds.size.width, offsetY);
	
	self.scrollView.contentSize = contentSize;
	[self textViewDidChange:self.feedbackView];
}

- (void)teardown {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.window removeFromSuperview];
	self.window = nil;
		
	self.cancelButton = nil;
	self.sendButton = nil;
	self.toolbar = nil;
	self.scrollView = nil;
	self.emailField = nil;
	self.feedbackView = nil;
	self.customPlaceholderText = nil;
	[originalPresentingWindow makeKeyWindow];
	[presentingViewController release], presentingViewController = nil;
	[originalPresentingWindow release], originalPresentingWindow = nil;
}

- (BOOL)shouldReturn:(UIView *)view {
	if (view == self.emailField) {
		[self.feedbackView becomeFirstResponder];
		return NO;
	} else if (view == self.feedbackView) {
		[self.feedbackView resignFirstResponder];
		return YES;
	}
	return NO;
}

- (UIWindow *)findMainWindowPreferringMainScreen:(BOOL)preferMainScreen {
	UIApplication *application = [UIApplication sharedApplication];
	for (UIWindow *tmpWindow in [[application windows] reverseObjectEnumerator]) {
		if (tmpWindow.rootViewController || tmpWindow.isKeyWindow) {
			if (preferMainScreen && [tmpWindow respondsToSelector:@selector(screen)]) {
				if (tmpWindow.screen && [tmpWindow.screen isEqual:[UIScreen mainScreen]]) {
					return tmpWindow;
				}
			} else {
				return tmpWindow;
			}
		}
	}
	return nil;
}

- (UIWindow *)windowForViewController:(UIViewController *)viewController {
	UIWindow *result = nil;
	UIView *rootView = [viewController view];
	if (rootView.window) {
		result = rootView.window;
	}
	if (!result) {
		result = [self findMainWindowPreferringMainScreen:YES];
		if (!result) {
			result = [self findMainWindowPreferringMainScreen:NO];
		}
	}
	return result;
}

+ (CGFloat)rotationOfViewHierarchyInRadians:(UIView *)leafView {
	CGAffineTransform t = leafView.transform;
	UIView *s = leafView.superview;
	while (s && s != leafView.window) {
		t = CGAffineTransformConcat(t, s.transform);
		s = s.superview;
	}
	return atan2(t.b, t.a);
}

+ (CGAffineTransform)viewTransformInWindow:(UIWindow *)window {
	CGAffineTransform result = CGAffineTransformIdentity;
	do { // once
		if (!window) break;
		
		if ([[window rootViewController] view]) {
			CGFloat rotation = [ATMessagePanelViewController rotationOfViewHierarchyInRadians:[[window rootViewController] view]];
			result = CGAffineTransformMakeRotation(rotation);
			break;
		}
		
		if ([[window subviews] count]) {
			for (UIView *v in [window subviews]) {
				if (!CGAffineTransformIsIdentity(v.transform)) {
					result = v.transform;
					break;
				}
			}
		}
	} while (NO);
	return result;
}

- (void)statusBarChanged:(NSNotification *)notification {
	[self positionInWindow];
}


- (void)applicationDidBecomeActive:(NSNotification *)notification {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (self.window.hidden == NO) {
		[self retain];
		[self unhide:NO];
	}
	[pool release], pool = nil;
}

- (void)feedbackChanged:(NSNotification *)notification {
	if (notification.object == self.feedbackView) {
		[self updateSendButtonState];
	}
}

- (void)hide:(BOOL)animated {
	[self retain];
	
	self.window.windowLevel = UIWindowLevelNormal;
	[self.emailField resignFirstResponder];
	[self.feedbackView resignFirstResponder];
	
	if (animated) {
		[UIView animateWithDuration:0.2 animations:^(void){
			self.window.alpha = 0.0;
		} completion:^(BOOL finished) {
			[self finishHide];
		}];
	} else {
		[self finishHide];
	}
}

- (void)finishHide {
	self.window.alpha = 0.0;
	self.window.hidden = YES;
	[self.emailField resignFirstResponder];
	[self.feedbackView resignFirstResponder];
	[self.window removeFromSuperview];
}

- (void)finishUnhide {
	self.window.alpha = 1.0;
	[self.window makeKeyAndVisible];
	[self positionInWindow];
	if (self.showEmailAddressField) {
		[self.emailField becomeFirstResponder];
	} else {
		[self.feedbackView becomeFirstResponder];
	}
	[self release];
}

- (void)sendMessageAndDismiss {
	[self.delegate messagePanel:self didSendMessage:self.feedbackView.text withEmailAddress:self.emailField.text];
	[self dismissAnimated:YES completion:NULL withAction:ATMessagePanelDidSendMessage];
}

- (void)updateSendButtonState {
	NSString *trimmedText = [self.feedbackView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	BOOL empty = [trimmedText length] == 0;
	self.sendButton.enabled = !empty;
	self.sendButton.style = empty == YES ? UIBarButtonItemStyleBordered : UIBarButtonItemStyleDone;
}
@end


@implementation ATMessagePanelViewController (Positioning)
- (BOOL)isIPhoneAppInIPad {
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		NSString *model = [[UIDevice currentDevice] model];
		if ([model isEqualToString:@"iPad"]) {
			return YES;
		}
	}
	return NO;
}

- (CGRect)onscreenRectOfView {
	BOOL constrainViewWidth = [self isIPhoneAppInIPad];
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	CGFloat w = statusBarSize.width;
	CGFloat h = statusBarSize.height;
	if (CGSizeEqualToSize(CGSizeZero, statusBarSize)) {
		w = screenBounds.size.width;
		h = screenBounds.size.height;
	}
	
	BOOL isLandscape = NO;
	
	CGFloat windowWidth = 0.0;
	
	switch (orientation) {
		case UIInterfaceOrientationLandscapeLeft:
		case UIInterfaceOrientationLandscapeRight:
			isLandscape = YES;
			windowWidth = h;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
		case UIInterfaceOrientationPortrait:
		default:
			windowWidth = w;
			break;
	}
	
	CGFloat viewHeight = 0.0;
	CGFloat viewWidth = 0.0;
	CGFloat originY = 0.0;
	CGFloat originX = 0.0;
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		viewHeight = isLandscape ? 368.0 : 368.0;
		originY = isLandscape ? 20.0 : 200;
		viewWidth = windowWidth - 12*2 - 100.0;
		originX = floorf((windowWidth - viewWidth)/2.0);
	} else {
		CGFloat landscapeKeyboardHeight = 162;
		CGFloat portraitKeyboardHeight = 216;
		viewHeight = self.view.window.bounds.size.height - (isLandscape ? landscapeKeyboardHeight + 8 - 6 : portraitKeyboardHeight + 8);
		viewWidth = windowWidth - 12;
		originX = 6.0;
		if (constrainViewWidth) {
			viewWidth = MIN(320, windowWidth - 12);
		}
	}
	
	CGRect f = self.view.frame;
	f.origin.y = originY;
	f.origin.x = originX;
	f.size.width = viewWidth;
	f.size.height = viewHeight;
	
	return f;
}

- (CGPoint)offscreenPositionOfView {
	CGRect f = [self onscreenRectOfView];
	CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
	CGFloat statusBarHeight = MIN(statusBarSize.height, statusBarSize.width);
	CGFloat viewHeight = f.size.height;
	
	CGRect offscreenViewRect = f;
	offscreenViewRect.origin.y = -(viewHeight + statusBarHeight);
	CGPoint offscreenPoint = CGPointMake(CGRectGetMidX(offscreenViewRect), CGRectGetMidY(offscreenViewRect));
	
	return offscreenPoint;
}

- (void)positionInWindow {
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	
	CGFloat angle = 0.0;
	CGRect newFrame = originalPresentingWindow.bounds;
	CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
	
	switch (orientation) {
		case UIInterfaceOrientationPortraitUpsideDown:
			angle = M_PI;
			newFrame.size.height -= statusBarSize.height;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			angle = - M_PI / 2.0f;
			newFrame.origin.x += statusBarSize.width;
			newFrame.size.width -= statusBarSize.width;
			break;
		case UIInterfaceOrientationLandscapeRight:
			angle = M_PI / 2.0f;
			newFrame.size.width -= statusBarSize.width;
			break;
		case UIInterfaceOrientationPortrait:
		default:
			angle = 0.0;
			newFrame.origin.y += statusBarSize.height;
			newFrame.size.height -= statusBarSize.height;
			break;
	}
	[self.toolbar sizeToFit];
	
	CGRect toolbarBounds = self.toolbar.bounds;
	UIView *containerView = [self.view viewWithTag:kMessagePanelContainerViewTag];
	if (containerView != nil) {
		CGRect containerFrame = containerView.frame;
		containerFrame.origin.y = toolbarBounds.size.height;
		containerFrame.size.height = self.view.bounds.size.height - toolbarBounds.size.height;
		containerView.frame = containerFrame;
	}
	CGRect toolbarShadowImageFrame = self.toolbarShadowImage.frame;
	toolbarShadowImageFrame.origin.y = toolbarBounds.size.height;
	self.toolbarShadowImage.frame = toolbarShadowImageFrame;
	
	self.window.transform = CGAffineTransformMakeRotation(angle);
	self.window.frame = newFrame;
	CGRect onscreenRect = [self onscreenRectOfView];
	self.view.frame = onscreenRect;
	
	[self textViewDidChange:self.feedbackView];
}
@end
