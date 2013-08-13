//
//  ATMessageCenterViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 9/28/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//
#import <CoreData/CoreData.h>
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>

#import "ATMessageCenterViewController.h"

#import "ATBackend.h"
#import "ATConnect.h"
#import "ATConnect_Private.h"
#import "ATData.h"
#import "ATAutomatedMessage.h"
#import "ATFileAttachment.h"
#import "ATFileMessage.h"
#import "ATLog.h"
#import "ATMessage.h"
#import "ATMessageCenterCell.h"
#import "ATDefaultMessageCenterTheme.h"
#import "ATMessageCenterMetrics.h"
#import "ATMessageSender.h"
#import "ATMessageTask.h"
#import "ATPersonDetailsViewController.h"
#import "ATPersonUpdater.h"
#import "ATTaskQueue.h"
#import "ATTextMessage.h"
#import "ATInfoViewController.h"

typedef enum {
	ATMessageCellTypeUnknown,
	ATMessageCellTypeAutomated,
	ATMessageCellTypeText,
	ATMessageCellTypeFile
} ATMessageCellType;

#define TextViewPadding 2

@interface ATMessageCenterViewController ()
- (void)relayoutSubviews;
- (CGRect)formRectToShow;
- (void)registerForKeyboardNotifications;
- (void)keyboardWillBeShown:(NSNotification *)aNotification;
- (void)keyboardWasShown:(NSNotification *)aNotification;
- (void)keyboardWillBeHidden:(NSNotification *)aNotification;
- (NSFetchedResultsController *)fetchedMessagesController;
- (void)scrollToBottomOfTableView;
- (void)markAllMessagesAsRead;
- (void)toggleAttachmentsView;
@end

@implementation ATMessageCenterViewController {
	BOOL firstLoad;
	BOOL attachmentsVisible;
	CGRect currentKeyboardFrameInView;
	CGFloat composerFieldHeight;
	NSFetchedResultsController *fetchedMessagesController;
	ATTextMessage *composingMessage;
	BOOL animatingTransition;
	NSDateFormatter *messageDateFormatter;
	UIImage *pickedImage;
	ATFeedbackImageSource pickedImageSource;
	ATDefaultMessageCenterTheme *defaultTheme;
	UIActionSheet *sendImageActionSheet;
	ATMessage *retryMessage;
	UIActionSheet *retryMessageActionSheet;
	
	UINib *inputViewNib;
	ATMessageInputView *inputView;
}
@synthesize tableView, containerView, inputContainerView, attachmentView, automatedCell;
@synthesize userCell, developerCell, userFileMessageCell;
@synthesize themeDelegate, dismissalDelegate;

- (id)initWithThemeDelegate:(NSObject<ATMessageCenterThemeDelegate> *)aThemeDelegate {
	self = [super initWithNibName:@"ATMessageCenterViewController" bundle:[ATConnect resourceBundle]];
	if (self != nil) {
		themeDelegate = aThemeDelegate;
		defaultTheme = [[ATDefaultMessageCenterTheme alloc] init];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[[ATBackend sharedBackend] messageCenterEnteredForeground];
	
	[self markAllMessagesAsRead];
	NSError *error = nil;
	if (![self.fetchedMessagesController performFetch:&error]) {
		ATLogError(@"Got an error loading messages: %@", error);
		//TODO: Handle this error.
	}
	[self.tableView reloadData];
	
	NSUInteger messageCount = [ATData countEntityNamed:@"ATMessage" withPredicate:nil];
	if (messageCount == 0) {
		NSString *title = NSLocalizedString(@"Welcome", @"Welcome");
		NSString *body = ATLocalizedString(@"Use this area to communicate with the developer of this app! If you have questions, suggestions, concerns, or just want to help us make the app better or get in touch, feel free to send us a message!", @"Placeholder welcome message.");
		[[ATBackend sharedBackend] sendAutomatedMessageWithTitle:title body:body];
	}
	
	messageDateFormatter = [[NSDateFormatter alloc] init];
	messageDateFormatter.dateStyle = NSDateFormatterMediumStyle;
	messageDateFormatter.timeStyle = NSDateFormatterShortStyle;
	[ATTextMessage clearComposingMessages];
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
	self.tableView.scrollsToTop = YES;
	firstLoad = YES;
	[self registerForKeyboardNotifications];
	
	if (themeDelegate && [themeDelegate respondsToSelector:@selector(titleViewForMessageCenterViewController:)]) {
		self.navigationItem.titleView = [themeDelegate titleViewForMessageCenterViewController:self];
	} else {
		self.navigationItem.titleView = [defaultTheme titleViewForMessageCenterViewController:self];
	}
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)] autorelease];
	if ([self.navigationItem.rightBarButtonItem respondsToSelector:@selector(initWithImage:landscapeImagePhone:style:target:action:)]) {
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[ATBackend imageNamed:@"at_user_button_image"] landscapeImagePhone:[ATBackend imageNamed:@"at_user_button_image_landscape"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPressed:)]autorelease];
	} else {
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[ATBackend imageNamed:@"at_user_button_image"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPressed:)]autorelease];
	}
	
//	self.composerBackgroundView.image = [[ATBackend imageNamed:@"at_inbox_composer_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 0, 29, 19)];
	[self.poweredByButton setTitle:ATLocalizedString(@"Powered By Apptentive", @"Short tagline for Apptentive") forState:UIControlStateNormal];
	[self.iconButton setImage:[ATBackend imageNamed:@"at_apptentive_icon_small"] forState:UIControlStateNormal];
	if (![[ATConnect sharedConnection] showTagline]) {
		self.poweredByButton.hidden = YES;
		self.iconButton.hidden = YES;
	}
	[self.tableView setBackgroundColor:[UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_chat_bg"]]];
	[self.containerView setBackgroundColor:[UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_chat_bg"]]];
	[self.attachmentView setBackgroundColor:[UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_mc_noise_bg"]]];
	
	UIImage *attachmentShadowBase = [ATBackend imageNamed:@"at_mc_attachment_shadow"];
	UIImage *attachmentShadow = nil;
	UIEdgeInsets attachmentInsets = UIEdgeInsetsMake(4, 0, 0, 128);
	if ([attachmentShadow respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
		attachmentShadow = [attachmentShadowBase resizableImageWithCapInsets:attachmentInsets];
	} else {
		attachmentShadow = [attachmentShadowBase stretchableImageWithLeftCapWidth:attachmentInsets.left topCapHeight:attachmentInsets.top];
	}
	self.attachmentShadowView.image = attachmentShadow;
	
	[self.view addSubview:self.containerView];
	inputViewNib = [UINib nibWithNibName:@"ATMessageInputView" bundle:[ATConnect resourceBundle]];
	NSArray *views = [inputViewNib instantiateWithOwner:self options:NULL];
	if ([views count] == 0) {
		ATLogError(@"Unable to load message input view.");
	} else {
		inputView = [views objectAtIndex:0];
		CGRect inputContainerFrame = self.inputContainerView.frame;
		[inputContainerView removeFromSuperview];
		self.inputContainerView = nil;
		[self.view addSubview:inputView];
		inputView.frame = inputContainerFrame;
		inputView.delegate = self;
		self.inputContainerView = inputView;
	}
	
	if (themeDelegate && [themeDelegate respondsToSelector:@selector(configureSendButton:forMessageCenterViewController:)]) {
		[themeDelegate configureSendButton:inputView.sendButton forMessageCenterViewController:self];
	} else {
		[defaultTheme configureSendButton:inputView.sendButton forMessageCenterViewController:self];
	}
	
	if (themeDelegate && [themeDelegate respondsToSelector:@selector(configureAttachmentsButton:forMessageCenterViewController:)]) {
		[themeDelegate configureAttachmentsButton:inputView.attachButton forMessageCenterViewController:self];
	} else {
		[defaultTheme configureAttachmentsButton:inputView.attachButton forMessageCenterViewController:self];
	}
	
	if (themeDelegate && [themeDelegate respondsToSelector:@selector(backgroundImageForMessageForMessageCenterViewController:)]) {
		inputView.backgroundImage = [themeDelegate backgroundImageForMessageForMessageCenterViewController:self];
	} else {
		inputView.backgroundImage = [defaultTheme backgroundImageForMessageForMessageCenterViewController:self];
	}
	
	inputView.placeholder = ATLocalizedString(@"What's on your mind?", @"Placeholder for message center text input.");
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
		[self relayoutSubviews];
	});
	
	self.sendPhotoButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
	self.sendPhotoButton.layer.cornerRadius = 4;
	self.sendPhotoButton.layer.shadowColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.2].CGColor;
	self.sendPhotoButton.layer.shadowRadius = 4;
	self.sendPhotoButton.layer.borderWidth = 1;
	self.sendPhotoButton.layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5].CGColor;
	self.sendPhotoButton.clipsToBounds = YES;
	UIImage *whiteImage = [ATBackend imageNamed:@"at_white_button_bg"];
	[self.sendPhotoButton setBackgroundImage:whiteImage forState:UIControlStateNormal];
	[self.sendPhotoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[self.sendPhotoButton setTitleShadowColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2] forState:UIControlStateNormal];
	[self.sendPhotoButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
	
	self.cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
	self.cancelButton.layer.cornerRadius = 4;
	self.cancelButton.layer.shadowColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.2].CGColor;
	self.cancelButton.layer.shadowRadius = 4;
	self.cancelButton.layer.borderWidth = 1;
	self.cancelButton.layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5].CGColor;
	self.cancelButton.clipsToBounds = YES;
	UIImage *redImage = [ATBackend imageNamed:@"at_red_button_bg"];
	[self.cancelButton setBackgroundImage:redImage forState:UIControlStateNormal];
	[self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[self.cancelButton setTitleShadowColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2] forState:UIControlStateNormal];
	[self.cancelButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
}

//TODO: Handle relayouting on iOS 4.
- (void)viewDidLayoutSubviews {
	[self relayoutSubviews];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)dealloc {
	[[ATBackend sharedBackend] messageCenterLeftForeground];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[pickedImage release], pickedImage = nil;
	[messageDateFormatter release];
	tableView.delegate = nil;
	[tableView release];
	[attachmentView release];
	[containerView release];
	[inputContainerView release];
	fetchedMessagesController.delegate = nil;
	[fetchedMessagesController release], fetchedMessagesController = nil;
	[_iconButton release];
	[_attachmentShadowView release];
	[defaultTheme release], defaultTheme = nil;
	themeDelegate = nil;
	[_sendPhotoButton release];
	[_cancelButton release];
	dismissalDelegate = nil;
	[_poweredByButton release];
	[super dealloc];
}

- (void)viewDidUnload {
	[self setTableView:nil];
	[self setAttachmentView:nil];
	[self setContainerView:nil];
	[self setInputContainerView:nil];
	[self setIconButton:nil];
	[self setAttachmentShadowView:nil];
	[self setSendPhotoButton:nil];
	[self setCancelButton:nil];
	[self setPoweredByButton:nil];
	[super viewDidUnload];
}

- (void)viewWillDisappear:(BOOL)animated {
	[self markAllMessagesAsRead];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterDidShowNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterDidHideNotification object:nil];
	if (self.dismissalDelegate && [self.dismissalDelegate respondsToSelector:@selector(messageCenterDidDismiss:)]) {
		[self.dismissalDelegate messageCenterDidDismiss:self];
	}
}

- (IBAction)donePressed:(id)sender {
	if (self.dismissalDelegate) {
		[self.dismissalDelegate messageCenterWillDismiss:self];
	}
	if ([[self navigationController] respondsToSelector:@selector(presentingViewController)]) {
		[self.navigationController.presentingViewController dismissModalViewControllerAnimated:YES];
	} else {
		[self.navigationController dismissModalViewControllerAnimated:YES];
	}
}

- (IBAction)settingsPressed:(id)sender {
	ATPersonDetailsViewController *vc = [[ATPersonDetailsViewController alloc] initWithNibName:@"ATPersonDetailsViewController" bundle:[ATConnect resourceBundle]];
	[self.navigationController pushViewController:vc animated:YES];
	[vc release], vc = nil;
}

- (IBAction)showInfoView:(id)sender {
	ATInfoViewController *vc = [[ATInfoViewController alloc] init];
	[self presentModalViewController:vc animated:YES];
	[vc release], vc = nil;
}

- (IBAction)cameraPressed:(id)sender {
	ATSimpleImageViewController *vc = [[ATSimpleImageViewController alloc] initWithDelegate:self];
	[self presentModalViewController:vc animated:YES];
	[vc release], vc = nil;
}

- (IBAction)cancelAttachmentPressed:(id)sender {
	[self toggleAttachmentsView];
}

#pragma mark Private
- (void)relayoutSubviews {
	CGFloat viewHeight = self.view.bounds.size.height;
	
	CGRect composerFrame = inputContainerView.frame;
	CGRect tableFrame = tableView.frame;
	CGRect containerFrame = containerView.frame;
	CGRect attachmentFrame = attachmentView.frame;
	
	if (attachmentsVisible) {
		composerFrame.origin.y = viewHeight - inputContainerView.frame.size.height - attachmentFrame.size.height;
	} else {
		composerFrame.origin.y = viewHeight - inputContainerView.frame.size.height;
	}
	
	if (!CGRectEqualToRect(CGRectZero, currentKeyboardFrameInView)) {
		CGFloat bottomOffset = viewHeight - composerFrame.size.height;
		CGFloat keyboardOffset = currentKeyboardFrameInView.origin.y - composerFrame.size.height;
		if (attachmentsVisible) {
			bottomOffset = bottomOffset - attachmentFrame.size.height;
			keyboardOffset = keyboardOffset - attachmentFrame.size.height;
		}
		composerFrame.origin.y = MIN(bottomOffset, keyboardOffset);
	}
	
	tableFrame.origin.y = 0;
	tableFrame.size.height = composerFrame.origin.y;
	containerFrame.size.height = tableFrame.size.height + composerFrame.size.height + attachmentFrame.size.height;
	attachmentFrame.origin.y = composerFrame.origin.y + composerFrame.size.height;
	
	//containerView.frame = containerFrame;
	//[containerView setNeedsLayout];
	tableView.frame = tableFrame;
	inputContainerView.frame = composerFrame;
	attachmentView.frame = attachmentFrame;
	/*
	 if (!CGRectEqualToRect(composerFrame, composerView.frame)) {
	 NSLog(@"composerFrame: %@ != %@", NSStringFromCGRect(composerFrame), NSStringFromCGRect(composerView.frame));
	 }
	 if (!CGRectEqualToRect(attachmentFrame, attachmentView.frame)) {
	 NSLog(@"attachmentFrame: %@ != %@", NSStringFromCGRect(attachmentFrame), NSStringFromCGRect(attachmentView.frame));
	 }
	 if (!CGRectEqualToRect(containerFrame, containerView.frame)) {
	 NSLog(@"containerFrame: %@ != %@", NSStringFromCGRect(containerFrame), NSStringFromCGRect(containerView.frame));
	 }
	 */
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self relayoutSubviews];
	
	CGRect containerFrame = containerView.frame;
	containerFrame.size.height = self.tableView.frame.size.height + self.inputContainerView.frame.size.height + self.attachmentView.frame.size.height;
	containerView.frame = containerFrame;
	[containerView setNeedsLayout];
	[self relayoutSubviews];
}

- (void)styleTextView {
}


- (NSFetchedResultsController *)fetchedMessagesController {
	@synchronized(self) {
		if (!fetchedMessagesController) {
			[NSFetchedResultsController deleteCacheWithName:@"at-messages-cache"];
			NSFetchRequest *request = [[NSFetchRequest alloc] init];
			[request setEntity:[NSEntityDescription entityForName:@"ATMessage" inManagedObjectContext:[[ATBackend sharedBackend] managedObjectContext]]];
			[request setFetchBatchSize:20];
			NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"clientCreationTime" ascending:YES];
			[request setSortDescriptors:@[sortDescriptor]];
			[sortDescriptor release], sortDescriptor = nil;
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"clientCreationTime != %d", 0];
			[request setPredicate:predicate];
			
			NSFetchedResultsController *newController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[[ATBackend sharedBackend] managedObjectContext] sectionNameKeyPath:nil cacheName:@"at-messages-cache"];
			newController.delegate = self;
			fetchedMessagesController = newController;
			
			[request release], request = nil;
		}
	}
	return fetchedMessagesController;
}

- (void)scrollToBottomOfTableView {
	if ([self.tableView numberOfSections] > 0) {
		NSInteger rowCount = [self.tableView numberOfRowsInSection:0];
		if (rowCount > 0) {
			NSUInteger row = rowCount - 1;
			NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
			[self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionBottom animated:YES];
		}
	}
}

#pragma mark ATMessageInputViewDelegate
- (void)messageInputViewDidChange:(ATMessageInputView *)anInputView {
	if (anInputView.text && ![anInputView.text isEqualToString:@""]) {
		if (!composingMessage) {
			composingMessage = (ATTextMessage *)[ATData newEntityNamed:@"ATTextMessage"];
			[composingMessage setup];
		}
	} else {
		if (composingMessage) {
			NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
			[context deleteObject:composingMessage];
			[composingMessage release], composingMessage = nil;
		}
	}
	[self relayoutSubviews];
	[self scrollToBottomOfTableView];
}

- (void)messageInputView:(ATMessageInputView *)anInputView didChangeHeight:(CGFloat)height {
	[self relayoutSubviews];
	[self scrollToBottomOfTableView];
}

- (void)messageInputViewSendPressed:(ATMessageInputView *)anInputView {
	@synchronized(self) {
		if (composingMessage == nil) {
			composingMessage = (ATTextMessage *)[ATData newEntityNamed:@"ATTextMessage"];
			[composingMessage setup];
		}
		composingMessage.body = [inputView text];
		composingMessage.pendingState = [NSNumber numberWithInt:ATPendingMessageStateSending];
		composingMessage.sentByUser = @YES;
		[composingMessage updateClientCreationTime];
		
		[[[ATBackend sharedBackend] managedObjectContext] save:nil];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterDidSendNotification object:@{ATMessageCenterMessageNonceKey:composingMessage.pendingMessageID}];
		
		// Give it a wee bit o' delay.
		NSString *pendingMessageID = [composingMessage pendingMessageID];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
			ATMessageTask *task = [[ATMessageTask alloc] init];
			task.pendingMessageID = pendingMessageID;
			[[ATTaskQueue sharedTaskQueue] addTask:task];
			[[ATTaskQueue sharedTaskQueue] start];
			[task release], task = nil;
		});
		[composingMessage release], composingMessage = nil;
		inputView.text = @"";
	}
	
}

- (void)messageInputViewAttachPressed:(ATMessageInputView *)anInputView {
	[self toggleAttachmentsView];
}

#pragma mark Keyboard Handling
- (CGRect)formRectToShow {
	CGRect result = self.inputContainerView.frame;
	return result;
}

- (void)registerForKeyboardNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeShown:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}


- (void)keyboardWillBeShown:(NSNotification *)aNotification {
	attachmentsVisible = NO;
	NSDictionary *info = [aNotification userInfo];
	CGRect kbFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect kbAdjustedFrame = [self.view.window convertRect:kbFrame toView:self.view];
	NSNumber *duration = [[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSNumber *curve = [[aNotification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	
	if (!animatingTransition) {
		[UIView animateWithDuration:[duration floatValue] animations:^(void){
			animatingTransition = YES;
			[UIView setAnimationCurve:[curve intValue]];
			currentKeyboardFrameInView = CGRectIntersection(self.view.frame, kbAdjustedFrame);
			[self relayoutSubviews];
		} completion:^(BOOL finished) {
			animatingTransition = NO;
			[self scrollToBottomOfTableView];
		}];
	} else {
		currentKeyboardFrameInView = CGRectIntersection(self.view.frame, kbAdjustedFrame);
	}
}

- (void)keyboardWasShown:(NSNotification *)aNotification {
	[self scrollToBottomOfTableView];
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
	NSNumber *duration = [[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSNumber *curve = [[aNotification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	
	if (!animatingTransition) {
		[UIView animateWithDuration:[duration floatValue] animations:^(void){
			animatingTransition = YES;
			[UIView setAnimationCurve:[curve intValue]];
			currentKeyboardFrameInView = CGRectZero;
			[self relayoutSubviews];
		} completion:^(BOOL finished) {
			animatingTransition = NO;
			[self scrollToBottomOfTableView];
		}];
	} else {
		currentKeyboardFrameInView = CGRectZero;
	}
}

#pragma mark ATSimpleImageViewControllerDelegate
- (void)imageViewController:(ATSimpleImageViewController *)vc pickedImage:(UIImage *)image fromSource:(ATFeedbackImageSource)source {
	if (pickedImage != image) {
		[pickedImage release], pickedImage = nil;
		pickedImage = [image retain];
		pickedImageSource = source;
	}
}

- (void)imageViewControllerWillDismiss:(ATSimpleImageViewController *)vc animated:(BOOL)animated {
	if (pickedImage) {
		if (sendImageActionSheet) {
			[sendImageActionSheet autorelease], sendImageActionSheet = nil;
		}
		sendImageActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:ATLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:ATLocalizedString(@"Send Image", @"Send image button title"), nil];
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
			[sendImageActionSheet showFromRect:inputView.sendButton.bounds inView:inputView.sendButton animated:YES];
		} else {
			[sendImageActionSheet showInView:self.view];
		}
	}
}

- (ATFeedbackAttachmentOptions)attachmentOptionsForImageViewController:(ATSimpleImageViewController *)vc {
	return ATFeedbackAllowPhotoAttachment | ATFeedbackAllowTakePhotoAttachment;
}

- (UIImage *)defaultImageForImageViewController:(ATSimpleImageViewController *)vc {
	return pickedImage;
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (actionSheet == sendImageActionSheet) {
		if (buttonIndex == 0) {
			if (pickedImage) {
				@synchronized(self) {
					ATFileMessage *fileMessage = (ATFileMessage *)[ATData newEntityNamed:@"ATFileMessage"];
					ATFileAttachment *fileAttachment = (ATFileAttachment *)[ATData newEntityNamed:@"ATFileAttachment"];
					fileMessage.pendingState = @(ATPendingMessageStateSending);
					fileMessage.sentByUser = @(YES);
					[fileMessage updateClientCreationTime];
					fileMessage.fileAttachment = fileAttachment;
					
					[fileAttachment setFileData:UIImageJPEGRepresentation(pickedImage, 1.0)];
					[fileAttachment setMimeType:@"image/jpeg"];
					
					switch (pickedImageSource) {
						case ATFeedbackImageSourceCamera:
						case ATFeedbackImageSourcePhotoLibrary:
							[fileAttachment setSource:@(ATFileAttachmentSourceCamera)];
							break;
							/* for now we're going to assume camera…
							[fileAttachment setSource:@(ATFileAttachmentSourcePhotoLibrary)];
							break;
							 */
						case ATFeedbackImageSourceScreenshot:
							[fileAttachment setSource:@(ATFileAttachmentSourceScreenshot)];
							break;
						default:
							[fileAttachment setSource:@(ATFileAttachmentSourceUnknown)];
							break;
					}
					
					
					[[[ATBackend sharedBackend] managedObjectContext] save:nil];
					
					// Give it a wee bit o' delay.
					NSString *pendingMessageID = [fileMessage pendingMessageID];
					dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
						ATMessageTask *task = [[ATMessageTask alloc] init];
						task.pendingMessageID = pendingMessageID;
						[[ATTaskQueue sharedTaskQueue] addTask:task];
						[[ATTaskQueue sharedTaskQueue] start];
						[task release], task = nil;
					});
					[fileMessage release], fileMessage = nil;
					[fileAttachment release], fileAttachment = nil;
				}

			}
		} else if (buttonIndex == 1) {
			[pickedImage release], pickedImage = nil;
		}
		[sendImageActionSheet autorelease], sendImageActionSheet = nil;
	} else if (actionSheet == retryMessageActionSheet) {
		if (buttonIndex == 0) {
			retryMessage.pendingState = [NSNumber numberWithInt:ATPendingMessageStateSending];
			[[[ATBackend sharedBackend] managedObjectContext] save:nil];
			
			// Give it a wee bit o' delay.
			NSString *pendingMessageID = [retryMessage pendingMessageID];
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
				ATMessageTask *task = [[ATMessageTask alloc] init];
				task.pendingMessageID = pendingMessageID;
				[[ATTaskQueue sharedTaskQueue] addTask:task];
				[[ATTaskQueue sharedTaskQueue] start];
				[task release], task = nil;
			});
			
			[retryMessage release], retryMessage = nil;
		} else if (buttonIndex == 1) {
			[ATData deleteManagedObject:retryMessage];
			[retryMessage release], retryMessage = nil;
		}
		[retryMessageActionSheet autorelease], retryMessageActionSheet = nil;
	}
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
	if (actionSheet == sendImageActionSheet) {
		if (pickedImage) {
			[pickedImage release], pickedImage = nil;
		}
		[sendImageActionSheet autorelease], sendImageActionSheet = nil;
	} else if (actionSheet == retryMessageActionSheet) {
		[retryMessageActionSheet autorelease], retryMessageActionSheet = nil;
	}
}

#pragma mark UIScrollViewDelegate
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
	return YES;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self tableView:aTableView cellForRowAtIndexPath:indexPath];
	if ([cell conformsToProtocol:@protocol(ATMessageCenterCell)]) {
		return [(NSObject<ATMessageCenterCell> *)cell cellHeightForWidth:aTableView.bounds.size.width];
	}
	return 44;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ATMessage *message = (ATMessage *)[self.fetchedMessagesController objectAtIndexPath:indexPath];
	if (message != nil && [message.sentByUser boolValue] && [message.pendingState intValue] == ATPendingMessageStateError) {
		if (retryMessageActionSheet) {
			[retryMessageActionSheet autorelease], retryMessageActionSheet = nil;
		}
		if (retryMessage) {
			[retryMessage release], retryMessage = nil;
		}
		retryMessage = [message retain];
		NSArray *errors = [message errorsFromErrorMessage];
		NSString *errorString = nil;
		if (errors != nil && [errors count] != 0) {
			errorString = [NSString stringWithFormat:ATLocalizedString(@"Error Sending Message: %@", @"Title of action sheet for messages with errors. Parameter is the error."), [errors componentsJoinedByString:@"\n"]];
		} else {
			errorString = ATLocalizedString(@"Error Sending Message", @"Title of action sheet for messages with errors, but no error details.");
		}
		retryMessageActionSheet = [[UIActionSheet alloc] initWithTitle:errorString delegate:self cancelButtonTitle:ATLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:ATLocalizedString(@"Retry Sending", @"Retry sending message title"), nil];
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
			[retryMessageActionSheet showFromRect:inputView.sendButton.bounds inView:inputView.sendButton animated:YES];
		} else {
			[retryMessageActionSheet showInView:self.view];
		}
	}
}

- (void)tableView:(UITableView *)aTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (firstLoad && indexPath.row == 0 && indexPath.section == 0) {
		firstLoad = NO;
		[self scrollToBottomOfTableView];
	}
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedMessagesController sections] objectAtIndex:0];
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *AutomatedCellIdentifier = @"ATAutomatedMessageCell";
	static NSString *UserCellIdentifier = @"ATTextMessageUserCell";
	static NSString *DevCellIdentifier = @"ATTextMessageDevCell";
	static NSString *FileCellIdentifier = @"ATFileMessageCell";
	
	ATMessageCellType cellType = ATMessageCellTypeUnknown;
	
	UITableViewCell *cell = nil;
	ATMessage *message = (ATMessage *)[self.fetchedMessagesController objectAtIndexPath:indexPath];
	
	if ([message isKindOfClass:[ATAutomatedMessage class]]) {
		cellType = ATMessageCellTypeAutomated;
	} else if ([message isKindOfClass:[ATTextMessage class]]) {
		cellType = ATMessageCellTypeText;
	} else if ([message isKindOfClass:[ATFileMessage class]]) {
		cellType = ATMessageCellTypeFile;
	} else {
		NSAssert(NO, @"Unknown cell type");
	}
	
	BOOL showDate = NO;
	NSString *dateString = nil;
	
	if (indexPath.row == 0) {
		showDate = YES;
	} else {
		ATMessage *previousMessage = (ATMessage *)[self.fetchedMessagesController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section]];
		if ([message.creationTime doubleValue] - [previousMessage.creationTime doubleValue] > 60 * 5) {
			showDate = YES;
		}
	}
	if ([message isKindOfClass:[ATAutomatedMessage class]]) {
		showDate = YES;
	}
	
	if (showDate) {
		NSTimeInterval t = (NSTimeInterval)[message.creationTime doubleValue];
		NSDate *date = [NSDate dateWithTimeIntervalSince1970:t];
		dateString = [messageDateFormatter stringFromDate:date];
	}
	
	if (cellType == ATMessageCellTypeText) {
		ATTextMessageUserCell *textCell = nil;
		ATTextMessageCellType cellSubType = [message.sentByUser boolValue] ? ATTextMessageCellTypeUser : ATTextMessageCellTypeDeveloper;
		if ([[message pendingState] intValue] == ATPendingMessageStateComposing || [[message pendingState] intValue] == ATPendingMessageStateSending) {
			cellSubType = ATTextMessageCellTypeUser;
		}
		
		if (cellSubType == ATTextMessageCellTypeUser) {
			textCell = (ATTextMessageUserCell *)[tableView dequeueReusableCellWithIdentifier:UserCellIdentifier];
		} else if (cellSubType == ATTextMessageCellTypeDeveloper) {
			textCell = (ATTextMessageUserCell *)[tableView dequeueReusableCellWithIdentifier:DevCellIdentifier];
		}
		
		
		if (!textCell) {
			UINib *nib = [UINib nibWithNibName:@"ATTextMessageUserCell" bundle:[ATConnect resourceBundle]];
			[nib instantiateWithOwner:self options:nil];
			if (cellSubType == ATTextMessageCellTypeUser) {
				textCell = userCell;
				
				UIEdgeInsets chatInsets = UIEdgeInsetsMake(15, 15, 27, 21);
				UIImage *chatBubbleBase = [ATBackend imageNamed:@"at_chat_bubble"];
				UIImage *chatBubbleImage = nil;
				if ([chatBubbleBase respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
					chatBubbleImage = [chatBubbleBase resizableImageWithCapInsets:chatInsets];
				} else {
					chatBubbleImage = [chatBubbleBase stretchableImageWithLeftCapWidth:chatInsets.left topCapHeight:chatInsets.top];
				}
				textCell.messageBubbleImage.image = chatBubbleImage;
				
				textCell.userIcon.image = [ATBackend imageNamed:@"at_mc_user_icon"];
				textCell.usernameLabel.text = ATLocalizedString(@"You", @"User name for text bubbles from users.");
			} else {
				textCell = developerCell;
				
				UIEdgeInsets chatInsets = UIEdgeInsetsMake(15, 21, 27, 15);
				UIImage *chatBubbleBase = [ATBackend imageNamed:@"at_dev_chat_bubble"];
				UIImage *chatBubbleImage = nil;
				if ([chatBubbleBase respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
					chatBubbleImage = [chatBubbleBase resizableImageWithCapInsets:chatInsets];
				} else {
					chatBubbleImage = [chatBubbleBase stretchableImageWithLeftCapWidth:chatInsets.left topCapHeight:chatInsets.top];
				}
				textCell.messageBubbleImage.image = chatBubbleImage;
				
				textCell.userIcon.image = [ATBackend imageNamed:@"at_mc_user_icon"];
			}
			[[textCell retain] autorelease];
			[userCell release], userCell = nil;
			[developerCell release], developerCell = nil;
			textCell.selectionStyle = UITableViewCellSelectionStyleNone;
			textCell.userIcon.layer.cornerRadius = 4.0;
			textCell.userIcon.layer.masksToBounds = YES;
			
			textCell.composingBubble.image = [ATBackend imageNamed:@"at_composing_bubble"];
			UIView *backgroundView = [[UIView alloc] init];
			backgroundView.backgroundColor = [UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_chat_bg"]];
			textCell.backgroundView = backgroundView;
			[backgroundView release];
			textCell.messageText.dataDetectorTypes = UIDataDetectorTypeAll;
		}
		textCell.composing = NO;
		if (cellSubType != ATTextMessageCellTypeUser) {
			textCell.usernameLabel.text = ATLocalizedString(@"Developer", @"User name for text bubbles from developers.");
			if (message.sender.name) {
				textCell.usernameLabel.text = message.sender.name;
			}
		}
		if ([message isKindOfClass:[ATTextMessage class]]) {
			ATMessageSender *sender = [(ATTextMessage *)message sender];
			if (sender.profilePhotoURL) {
				textCell.userIcon.imageURL = [NSURL URLWithString:sender.profilePhotoURL];
			}
			NSString *messageBody = [(ATTextMessage *)message body];
			if ([[message pendingState] intValue] == ATPendingMessageStateSending) {
				NSString *sendingText = NSLocalizedString(@"Sending:", @"Sending prefix on messages that are sending");
				NSString *fullText = [NSString stringWithFormat:@"%@ %@", sendingText, messageBody];
				[textCell.messageText setText:fullText afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
					NSRange boldRange = NSMakeRange(0, [sendingText length]);
					
					UIFont *boldFont = [UIFont boldSystemFontOfSize:15];
					CTFontRef font = CTFontCreateWithName((CFStringRef)[boldFont fontName], [boldFont pointSize], NULL);
					if (font) {
						[mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)font range:boldRange];
						CFRelease(font), font = NULL;
					}
					return mutableAttributedString;
				}];
			} else if ([[message pendingState] intValue] == ATPendingMessageStateComposing) {
				textCell.composing = YES;
				textCell.textLabel.text = @"";
			} else if ([[message pendingState] intValue] == ATPendingMessageStateError) {
				NSString *sendingText = NSLocalizedString(@"Error:", @"Sending prefix on messages that are sending");
				NSString *fullText = [NSString stringWithFormat:@"%@ %@", sendingText, messageBody];
				[textCell.messageText setText:fullText afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
					NSRange boldRange = NSMakeRange(0, [sendingText length]);
					
					UIFont *boldFont = [UIFont boldSystemFontOfSize:15];
					UIColor *redColor = [UIColor redColor];
					CTFontRef font = CTFontCreateWithName((CFStringRef)[boldFont fontName], [boldFont pointSize], NULL);
					if (font) {
						[mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)font range:boldRange];
						CFRelease(font), font = NULL;
					}
					[mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)redColor.CGColor range:boldRange];
					return mutableAttributedString;
				}];
			} else {
				textCell.messageText.text = messageBody;
			}
		} else {
			textCell.messageText.text = [message description];
		}
		
		if (showDate) {
			textCell.dateLabel.text = dateString;
			textCell.showDateLabel = YES;
		} else {
			textCell.showDateLabel = NO;
		}
		
		cell = textCell;
	} else if (cellType == ATMessageCellTypeAutomated) {
		ATAutomatedMessageCell *currentCell = (ATAutomatedMessageCell *)[tableView dequeueReusableCellWithIdentifier:AutomatedCellIdentifier];
		
		if (!currentCell) {
			UINib *nib = [UINib nibWithNibName:@"ATAutomatedMessageCell" bundle:[ATConnect resourceBundle]];
			[nib instantiateWithOwner:self options:nil];
			currentCell = automatedCell;
			[[currentCell retain] autorelease];
			[automatedCell release], automatedCell = nil;
			
			currentCell.selectionStyle = UITableViewCellSelectionStyleNone;
			currentCell.messageText.dataDetectorTypes = UIDataDetectorTypeAll;
		}
		if ([message isKindOfClass:[ATAutomatedMessage class]]) {
			ATAutomatedMessage *automatedMessage = (ATAutomatedMessage *)message;
			NSString *messageTitle = automatedMessage.title;
			NSString *messageBody = automatedMessage.body;
			
			currentCell.titleText.textAlignment = UITextAlignmentCenter;
			[currentCell.titleText setText:messageTitle afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
				NSRange boldRange = NSMakeRange(0, [mutableAttributedString length]);
				
				UIFont *boldFont = [UIFont fontWithName:@"AmericanTypewriter-Bold" size:15];
				CTFontRef font = CTFontCreateWithName((CFStringRef)[boldFont fontName], [boldFont pointSize], NULL);
				if (font) {
					[mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)font range:boldRange];
					CFRelease(font), font = NULL;
				}
				return mutableAttributedString;
			}];
			currentCell.messageText.text = messageBody;
		}
		currentCell.dateLabel.text = dateString;
		currentCell.showDateLabel = YES;
		
		cell = currentCell;
	} else if (cellType == ATMessageCellTypeFile) {
		ATFileMessageCell *currentCell = (ATFileMessageCell *)[tableView dequeueReusableCellWithIdentifier:FileCellIdentifier];
		
		if (!currentCell) {
			UINib *nib = [UINib nibWithNibName:@"ATFileMessageCell" bundle:[ATConnect resourceBundle]];
			[nib instantiateWithOwner:self options:nil];
			currentCell = userFileMessageCell;
			[[currentCell retain] autorelease];
			[userFileMessageCell release], userFileMessageCell = nil;
			
			currentCell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		if ([message isKindOfClass:[ATFileMessage class]]) {
			ATFileMessage *fileMessage = (ATFileMessage *)message;
			[currentCell configureWithFileMessage:fileMessage];
		}
		currentCell.userIcon.image = [ATBackend imageNamed:@"at_mc_user_icon"];
		
		
		
		UIEdgeInsets chatInsets = UIEdgeInsetsMake(15, 15, 27, 21);
		UIImage *chatBubbleBase = [ATBackend imageNamed:@"at_chat_bubble"];
		UIImage *chatBubbleImage = nil;
		if ([chatBubbleBase respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
			chatBubbleImage = [chatBubbleBase resizableImageWithCapInsets:chatInsets];
		} else {
			chatBubbleImage = [chatBubbleBase stretchableImageWithLeftCapWidth:chatInsets.left topCapHeight:chatInsets.top];
		}
		currentCell.messageBubbleImage.image = chatBubbleImage;
		
		ATMessageSender *sender = [(ATTextMessage *)message sender];
		if (sender.profilePhotoURL) {
			currentCell.userIcon.imageURL = [NSURL URLWithString:sender.profilePhotoURL];
		}
		if (showDate) {
			currentCell.dateLabel.text = dateString;
			currentCell.showDateLabel = YES;
		} else {
			currentCell.showDateLabel = NO;
		}
		cell = currentCell;
	}
	return cell;
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	@try {
		[self.tableView endUpdates];
	}
	@catch (NSException *exception) {
		ATLogError(@"caught exception: %@: %@", [exception name], [exception description]);
	}
	[self scrollToBottomOfTableView];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	switch (type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
			break;
		case NSFetchedResultsChangeMove:
			[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:newIndexPath.section] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeUpdate:
			[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		default:
			break;
	}
}

- (void)markAllMessagesAsRead {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:@"ATMessage" inManagedObjectContext:[[ATBackend sharedBackend] managedObjectContext]]];
	[request setFetchBatchSize:20];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"clientCreationTime" ascending:YES];
	[request setSortDescriptors:@[sortDescriptor]];
	[sortDescriptor release], sortDescriptor = nil;
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"seenByUser == %d", 0];
	[request setPredicate:predicate];
	
	NSManagedObjectContext *moc = [ATData moc];
	NSError *error = nil;
	NSArray *results = [moc executeFetchRequest:request error:&error];
	if (!results) {
		ATLogError(@"Error exceuting fetch request: %@", error);
	} else {
		for (ATMessage *message in results) {
			[message setSeenByUser:@(YES)];
			if (message.apptentiveID != nil && [message.sentByUser boolValue] != YES) {
				[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterDidReadNotification object:@{ATMessageCenterMessageIDKey:message.apptentiveID}];
			}
		}
		[ATData save];
	}
	[request release], request = nil;
}

- (void)toggleAttachmentsView {
	attachmentsVisible = !attachmentsVisible;
	if (!CGRectEqualToRect(CGRectZero, currentKeyboardFrameInView)) {
		[inputView resignFirstResponder];
	} else {
		if (!animatingTransition) {
			[UIView animateWithDuration:0.3 animations:^(void){
				animatingTransition = YES;
				[self relayoutSubviews];
			} completion:^(BOOL finished) {
				animatingTransition = NO;
				[self scrollToBottomOfTableView];
			}];
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterDidAttachNotification object:nil];
}
@end
