//
//  ATBackend.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATBackend.h"
#import "ATAppConfigurationUpdateTask.h"
#import "ATAutomatedMessage.h"
#import "ATConnect.h"
#import "ATConnect_Private.h"
#import "ATContactStorage.h"
#import "ATData.h"
#import "ATDataManager.h"
#import "ATDeviceUpdater.h"
#import "ATAutomatedMessage.h"
#import "ATFeedback.h"
#import "ATFeedbackTask.h"
#import "ATNavigationController.h"
#import "ApptentiveMetrics.h"
#import "ATReachability.h"
#import "ATSurveys.h"
#import "ATStaticLibraryBootstrap.h"
#import "ATSurveys_Private.h"
#import "ATTaskQueue.h"
#import "ATUtilities.h"
#import "ATWebClient.h"
#import "ATMessageDisplayType.h"
#import "ATGetMessagesTask.h"
#import "ATMessageCenterMetrics.h"
#import "ATMessageTask.h"
#import "ATMessagePanelViewController.h"
#import "ATTextMessage.h"
#import "ATLog.h"
#import "ATPersonUpdater.h"

NSString *const ATBackendNewAPIKeyNotification = @"ATBackendNewAPIKeyNotification";
NSString *const ATUUIDPreferenceKey = @"ATUUIDPreferenceKey";
NSString *const ATInfoDistributionKey = @"ATInfoDistributionKey";

@interface ATBackend ()
- (void)updateConfigurationIfNeeded;
@end

@interface ATBackend (Private)
- (void)setupDataManager;
- (void)setup;
- (void)startup;
- (void)updateWorking;
- (void)networkStatusChanged:(NSNotification *)notification;
- (void)stopWorking:(NSNotification *)notification;
- (void)startWorking:(NSNotification *)notification;
- (void)checkForSurveys;
- (void)checkForMessages;
- (void)startMonitoringUnreadMessages;
@end

@interface ATBackend ()
#if TARGET_OS_IPHONE
@property (nonatomic, retain) UIViewController *presentingViewController;
#endif
@property (nonatomic, assign) BOOL working;
- (void)updateConversationIfNeeded;
- (void)updateDeviceIfNeeded;
- (void)updatePersonIfNeeded;
@end

@implementation ATBackend
#if TARGET_OS_IPHONE
{
	UIViewController *presentedMessageCenterViewController;
	ATMessagePanelViewController *currentMessagePanelController;
	
	UIViewController *presentingViewController;
	UIAlertView *messagePanelSentMessageAlert;
}
@synthesize presentingViewController;
#endif
@synthesize apiKey, working, currentFeedback, persistentStoreCoordinator;

+ (ATBackend *)sharedBackend {
	static ATBackend *sharedBackend = nil;
	@synchronized(self) {
		if (sharedBackend == nil) {
			sharedBackend = [[self alloc] init];
			[sharedBackend startup];
		}
	}
	return sharedBackend;
}

#if TARGET_OS_IPHONE
+ (UIImage *)imageNamed:(NSString *)name {
	NSString *imagePath = nil;
	UIImage *result = nil;
	CGFloat scale = [[UIScreen mainScreen] scale];
	if (scale > 1.0) {
		imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@@2x", name] ofType:@"png"];
	} else {
		imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@", name] ofType:@"png"];
	}
	
	if (!imagePath) {
		if (scale > 1.0) {
			imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@@2x", name] ofType:@"png" inDirectory:@"generated"];
		} else {
			imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@", name] ofType:@"png" inDirectory:@"generated"];
		}
	}
	
	if (imagePath) {
		result = [UIImage imageWithContentsOfFile:imagePath];
	} else {
		result = [UIImage imageNamed:name];
	}
	if (!result) {
		ATLogError(@"Unable to find image named: %@", name);
		ATLogError(@"sought at: %@", imagePath);
		ATLogError(@"bundle is: %@", [ATConnect resourceBundle]);
	}
	return result;
}
#elif TARGET_OS_MAC
+ (NSImage *)imageNamed:(NSString *)name {
	NSString *imagePath = nil;
	NSImage *result = nil;
	CGFloat scale = 1.0;
	
	if ([[NSScreen mainScreen] respondsToSelector:@selector(backingScaleFactor)]) {
		scale = (CGFloat)[[NSScreen mainScreen] backingScaleFactor];
	}
	if (scale > 1.0) {
		imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@@2x", name] ofType:@"png"];
	} else {
		imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@", name] ofType:@"png"];
	}
	
	if (!imagePath) {
		if (scale > 1.0) {
			imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@@2x", name] ofType:@"png" inDirectory:@"generated"];
		} else {
			imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@", name] ofType:@"png" inDirectory:@"generated"];
		}
	}
	
	if (imagePath) {
		result = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
	} else {
		result = [NSImage imageNamed:name];
	}
	if (!result) {
		ATLogError(@"Unable to find image named: %@", name);
		ATLogError(@"sought at: %@", imagePath);
		ATLogError(@"bundle is: %@", [ATConnect resourceBundle]);
	}
	return result;
}
#endif

- (id)init {
	if ((self = [super init])) {
		[self setup];
	}
	return self;
}

- (void)dealloc {
	[messageRetrievalTimer invalidate];
	[messageRetrievalTimer release], messageRetrievalTimer = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[apiKey release], apiKey = nil;
	[currentFeedback release], currentFeedback = nil;
	[dataManager release], dataManager = nil;
#if TARGET_OS_IPHONE
	if (presentedMessageCenterViewController) {
		[presentedMessageCenterViewController release], presentedMessageCenterViewController = nil;
	}
	if (currentMessagePanelController) {
		[currentMessagePanelController release], currentMessagePanelController = nil;
	}
	if (presentingViewController) {
		[presentingViewController release], presentingViewController = nil;
	}
#endif
	[super dealloc];
}

- (void)setApiKey:(NSString *)anAPIKey {
	if (apiKey != anAPIKey) {
		[apiKey release];
		apiKey = nil;
		apiKey = [anAPIKey retain];
		if (apiKey == nil) {
			apiKeySet = NO;
		} else {
			apiKeySet = YES;
		}
		[self updateWorking];
		[[NSNotificationCenter defaultCenter] postNotificationName:ATBackendNewAPIKeyNotification object:nil];
	}
}

- (void)sendFeedback:(ATFeedback *)feedback {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if ([[NSThread currentThread] isMainThread]) {
		[feedback retain];
		[self performSelectorInBackground:@selector(sendFeedback:) withObject:feedback];
		[pool release], pool = nil;
		return;
	}
	if (feedback == self.currentFeedback) {
		self.currentFeedback = nil;
	}
	ATContactStorage *contact = [ATContactStorage sharedContactStorage];
	contact.name = feedback.name;
	contact.email = feedback.email;
	contact.phone = feedback.phone;
	[ATContactStorage releaseSharedContactStorage];
	contact = nil;
	
	ATFeedbackTask *task = [[ATFeedbackTask alloc] init];
	task.feedback = feedback;
	[[ATTaskQueue sharedTaskQueue] addTask:task];
	[task release];
	task = nil;
	
	[feedback release];
	[pool release];
}

- (void)sendAutomatedMessageWithTitle:(NSString *)title body:(NSString *)body {
	ATAutomatedMessage *message = (ATAutomatedMessage *)[ATData newEntityNamed:@"ATAutomatedMessage"];
	[message setup];
	message.title = title;
	message.body = body;
	message.pendingState = [NSNumber numberWithInt:ATPendingMessageStateSending];
	message.sentByUser = @YES;
	[message updateClientCreationTime];
	NSError *error = nil;
	if (![[self managedObjectContext] save:&error]) {
		ATLogError(@"Unable to send automated message with title: %@, body: %@, error: %@", title, body, error);
		[message release], message = nil;
		return;
	}
	
	// Give it a wee bit o' delay.
	NSString *pendingMessageID = [message pendingMessageID];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
		ATMessageTask *task = [[ATMessageTask alloc] init];
		task.pendingMessageID = pendingMessageID;
		[[ATTaskQueue sharedTaskQueue] addTask:task];
		[[ATTaskQueue sharedTaskQueue] start];
		[task release], task = nil;
	});
	[message release], message = nil;
}

- (BOOL)sendTextMessageWithBody:(NSString *)body completion:(void (^)(NSString *pendingMessageID))completion {
	ATTextMessage *message = (ATTextMessage *)[ATData newEntityNamed:@"ATTextMessage"];
	[message setup];
	message.body = body;
	message.pendingState = [NSNumber numberWithInt:ATPendingMessageStateSending];
	message.sentByUser = @YES;
	[message updateClientCreationTime];
	NSError *error = nil;
	if (![[self managedObjectContext] save:&error]) {
		ATLogError(@"Unable to send text message with body: %@, error: %@", body, error);
		[message release], message = nil;
		return NO;
	}
	if (completion) {
		completion(message.pendingMessageID);
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterDidSendNotification object:@{ATMessageCenterMessageNonceKey:message.pendingMessageID}];
	
	// Give it a wee bit o' delay.
	NSString *pendingMessageID = [message pendingMessageID];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
		ATMessageTask *task = [[ATMessageTask alloc] init];
		task.pendingMessageID = pendingMessageID;
		[[ATTaskQueue sharedTaskQueue] addTask:task];
		[[ATTaskQueue sharedTaskQueue] start];
		[task release], task = nil;
	});
	[message release], message = nil;
	return YES;
}

- (NSString *)supportDirectoryPath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *path = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	
	NSString *newPath = [path stringByAppendingPathComponent:@"com.apptentive.feedback"];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	BOOL result = [fm createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:&error];
	if (!result) {
		ATLogError(@"Failed to create support directory: %@", newPath);
		ATLogError(@"Error was: %@", error);
		return nil;
	}
	return newPath;
}

- (NSString *)attachmentDirectoryPath {
	NSString *supportPath = [self supportDirectoryPath];
	if (!supportPath) {
		return nil;
	}
	NSString *newPath = [supportPath stringByAppendingPathComponent:@"attachments"];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	BOOL result = [fm createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:&error];
	if (!result) {
		ATLogError(@"Failed to create attachments directory: %@", newPath);
		ATLogError(@"Error was: %@", error);
		return nil;
	}
	return newPath;
}

- (NSString *)deviceUUID {
#if TARGET_OS_IPHONE
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *uuid = [defaults objectForKey:ATUUIDPreferenceKey];
	if (!uuid) {
		CFUUIDRef uuidRef = CFUUIDCreate(NULL);
		CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
		
		uuid = [NSString stringWithFormat:@"ios:%@", (NSString *)uuidStringRef];
		
		CFRelease(uuidRef), uuidRef = NULL;
		CFRelease(uuidStringRef), uuidStringRef = NULL;
		
		[defaults setObject:uuid forKey:ATUUIDPreferenceKey];
		[defaults synchronize];
	}
	return uuid;
#elif TARGET_OS_MAC
	static CFStringRef keyRef = CFSTR("apptentiveUUID");
	static CFStringRef appIDRef = CFSTR("com.apptentive.feedback");
	NSString *uuid = nil;
	uuid = (NSString *)CFPreferencesCopyAppValue(keyRef, appIDRef);
	if (!uuid) {
		CFUUIDRef uuidRef = CFUUIDCreate(NULL);
		CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
		
		uuid = [[NSString alloc] initWithFormat:@"osx:%@", (NSString *)uuidStringRef];
		
		CFRelease(uuidRef), uuidRef = NULL;
		CFRelease(uuidStringRef), uuidStringRef = NULL;
		
		CFPreferencesSetValue(keyRef, (CFStringRef)uuid, appIDRef, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		CFPreferencesSynchronize(appIDRef, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
	}
	return [uuid autorelease];
#endif
}

#pragma mark Message Center
- (void)presentMessageCenterFromViewController:(UIViewController *)viewController {
	NSUInteger messageCount = [ATData countEntityNamed:@"ATMessage" withPredicate:nil];
	if (messageCount == 0) {
		NSString *title = ATLocalizedString(@"Give Feedback", @"First feedback screen title.");
		NSString *body = ATLocalizedString(@"Let us know how to make our app better for you!", @"First feedback screen body.");
		NSString *placeholder = ATLocalizedString(@"How can we help? (required)", @"First feedback placeholder text.");
		[self presentIntroDialogFromViewController:viewController withTitle:title prompt:body placeholderText:placeholder];
		return;
	}
	
	if (presentedMessageCenterViewController != nil) {
		ATLogInfo(@"Apptentive message center controller already shown.");
		return;
	}
	ATMessageCenterViewController *vc = [[ATMessageCenterViewController alloc] initWithThemeDelegate:nil];
	vc.dismissalDelegate = self;
	ATNavigationController *nc = [[ATNavigationController alloc] initWithRootViewController:vc];
	nc.disablesAutomaticKeyboardDismissal = NO;
	nc.modalPresentationStyle = UIModalPresentationFormSheet;
	if ([viewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
		[viewController presentViewController:nc animated:YES completion:^{}];
	} else {
		[viewController presentModalViewController:nc animated:YES];
	}
	presentedMessageCenterViewController = nc;
	[vc release], vc = nil;
}

- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion {
	if (currentMessagePanelController != nil) {
		[currentMessagePanelController dismissAnimated:animated completion:completion];
		return;
	}
	
	if (presentedMessageCenterViewController != nil) {
		BOOL didDismiss = NO;
		if ([presentedMessageCenterViewController respondsToSelector:@selector(presentingViewController)]) {
			UIViewController *vc = [presentedMessageCenterViewController presentingViewController];
			if ([vc respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
				didDismiss = YES;
				[vc dismissViewControllerAnimated:animated completion:completion];
			}
		}
		if (!didDismiss) {
			// Gnarly hack for iOS 4.
			[presentedMessageCenterViewController dismissModalViewControllerAnimated:YES];
			[presentedMessageCenterViewController release], presentedMessageCenterViewController = nil;
			
			double delayInSeconds = 1.0;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
			dispatch_after(popTime, dispatch_get_main_queue(), completion);
		}
	}
}

- (void)presentIntroDialogFromViewController:(UIViewController *)viewController withTitle:(NSString *)title prompt:(NSString *)prompt placeholderText:(NSString *)placeholder {
	@synchronized(self) {
		if (currentMessagePanelController) {
			ATLogInfo(@"Apptentive message panel controller already shown.");
			return;
		}
		
		ATMessagePanelViewController *vc = [[ATMessagePanelViewController alloc] initWithDelegate:self];
		if (title) {
			vc.promptTitle = title;
		}
		if (prompt) {
			vc.promptText = prompt;
		}
		if (placeholder) {
			vc.customPlaceholderText = placeholder;
		}
		[vc setShowEmailAddressField:[[ATConnect sharedConnection] showEmailField]];
		[vc presentFromViewController:viewController animated:YES];
		currentMessagePanelController = vc;
		self.presentingViewController = viewController;
	}
}

- (void)presentIntroDialogFromViewController:(UIViewController *)viewController {
	[self presentIntroDialogFromViewController:viewController withTitle:nil prompt:nil placeholderText:nil];
}

#if TARGET_OS_IPHONE
#pragma mark ATMessagePanelDelegate
- (void)messagePanelDidCancel:(ATMessagePanelViewController *)messagePanel {
	if (currentMessagePanelController == messagePanel) {
		return;
	}
}

- (void)messagePanel:(ATMessagePanelViewController *)messagePanel didSendMessage:(NSString *)message withEmailAddress:(NSString *)emailAddress {
	if (currentMessagePanelController == messagePanel) {
		ATPersonInfo *person = nil;
		if ([ATPersonInfo personExists]) {
			person = [ATPersonInfo currentPerson];
		} else {
			person = [[[ATPersonInfo alloc] init] autorelease];
		}
		if (emailAddress && ![emailAddress isEqualToString:person.emailAddress]) {
			person.emailAddress = emailAddress;
			person.needsUpdate = YES;
		}
		[person saveAsCurrentPerson];
		
		[self sendTextMessageWithBody:message completion:^(NSString *pendingMessageID) {
			[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroDidSendNotification object:nil userInfo:@{ATMessageCenterMessageNonceKey: pendingMessageID}];
		}];
	}
}

- (void)messagePanel:(ATMessagePanelViewController *)messagePanel didDismissWithAction:(ATMessagePanelDismissAction)action {
	if (currentMessagePanelController) {
		[currentMessagePanelController release], currentMessagePanelController = nil;
		if (action == ATMessagePanelDidSendMessage) {
			if (!messagePanelSentMessageAlert) {
				messagePanelSentMessageAlert = [[UIAlertView alloc] initWithTitle:ATLocalizedString(@"Thanks!", nil) message:ATLocalizedString(@"Your response has been saved in this app's Message Center, where you may get a reply from us.", @"Message panel sent message confirmation dialog text") delegate:self cancelButtonTitle:ATLocalizedString(@"Close", @"Close alert view title") otherButtonTitles:ATLocalizedString(@"View Messages", @"View messages button title"), nil];
				[messagePanelSentMessageAlert show];
				
				[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroThankYouDidShowNotification object:self userInfo:nil];
			}
		}
	}
}

- (NSString *)initialEmailAddressForMessagePanel:(ATMessagePanelViewController *)messagePanel {
	ATPersonInfo *person = [ATPersonInfo currentPerson];
	return person.emailAddress;
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView == messagePanelSentMessageAlert) {
		if (buttonIndex == 1) {
			[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroThankYouHitMessagesNotification object:self userInfo:nil];
			UIViewController *vc = [[self presentingViewController] retain];
			self.presentingViewController = nil;
			[self presentMessageCenterFromViewController:vc];
			[vc release], vc = nil;
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroThankYouDidCloseNotification object:self userInfo:nil];
		}
		[messagePanelSentMessageAlert release], messagePanelSentMessageAlert = nil;
	}
}
#endif

#pragma mark Accessors

- (void)setWorking:(BOOL)newWorking {
	if (working != newWorking) {
		working = newWorking;
		if (working) {
			[[ATTaskQueue sharedTaskQueue] start];
			
			[self updateConversationIfNeeded];
			[self updateConfigurationIfNeeded];
		} else {
			[[ATTaskQueue sharedTaskQueue] stop];
			[ATTaskQueue releaseSharedTaskQueue];
		}
	}
}


- (NSURL *)apptentiveHomepageURL {
	return [NSURL URLWithString:@"http://www.apptentive.com/"];
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
	return [dataManager managedObjectContext];
}

- (NSManagedObjectModel *)managedObjectModel {
	return [dataManager managedObjectModel];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	return [dataManager persistentStoreCoordinator];
}

#pragma mark -

- (void)updateConversationIfNeeded {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(updateConversationIfNeeded) withObject:nil waitUntilDone:NO];
		return;
	}
	if (!conversationUpdater && [ATConversationUpdater shouldUpdate]) {
		conversationUpdater = [[ATConversationUpdater alloc] initWithDelegate:self];
		[conversationUpdater createOrUpdateConversation];
	}
}

- (void)updateDeviceIfNeeded {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(updateDeviceIfNeeded) withObject:nil waitUntilDone:NO];
		return;
	}
	if (![ATConversationUpdater conversationExists]) {
		return;
	}
	if (!deviceUpdater) {
		if ([ATDeviceUpdater shouldUpdate]) {
			deviceUpdater = [[ATDeviceUpdater alloc] initWithDelegate:self];
			[deviceUpdater update];
		}
	}
}

- (void)updatePersonIfNeeded {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(updatePersonIfNeeded) withObject:nil waitUntilDone:NO];
		return;
	}
	if (![ATConversationUpdater conversationExists]) {
		return;
	}
	if (!personUpdater) {
		if ([ATPersonUpdater shouldUpdate]) {
			personUpdater = [[ATPersonUpdater alloc] initWithDelegate:self];
			[personUpdater update];
		}
	}
}

- (void)updateConfigurationIfNeeded {
	if (![ATConversationUpdater conversationExists]) {
		return;
	}
	
	ATTaskQueue *queue = [ATTaskQueue sharedTaskQueue];
	if (![queue hasTaskOfClass:[ATAppConfigurationUpdateTask class]]) {
		ATAppConfigurationUpdateTask *task = [[ATAppConfigurationUpdateTask alloc] init];
		[queue addTask:task];
		[task release], task = nil;
	}
}

#if TARGET_OS_IPHONE
#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	if (controller == unreadCountController) {
		id<NSFetchedResultsSectionInfo> sectionInfo = [[unreadCountController sections] objectAtIndex:0];
		NSUInteger unreadCount = [sectionInfo numberOfObjects];
		if (unreadCount != previousUnreadCount) {
			previousUnreadCount = unreadCount;
			[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterUnreadCountChangedNotification object:nil userInfo:@{@"count":@(previousUnreadCount)}];
		}
	}
}
#endif

#pragma mark ATActivityFeedUpdaterDelegate
- (void)conversationUpdater:(ATConversationUpdater *)updater createdConversationSuccessfully:(BOOL)success {
	if (conversationUpdater == updater) {
		[conversationUpdater release], conversationUpdater = nil;
		if (!success) {
			// Retry after delay.
			[self performSelector:@selector(updateConversationIfNeeded) withObject:nil afterDelay:20];
		} else {
			// Queued tasks can probably start now.
			ATTaskQueue *queue = [ATTaskQueue sharedTaskQueue];
			[queue start];
			[self updateDeviceIfNeeded];
			[self updatePersonIfNeeded];
		}
	}
}

- (void)conversationUpdater:(ATConversationUpdater *)updater updatedConversationSuccessfully:(BOOL)success {
	if (conversationUpdater == updater) {
		[conversationUpdater release], conversationUpdater = nil;
	}
}

#pragma mark ATDeviceUpdaterDelegate
- (void)deviceUpdater:(ATDeviceUpdater *)aDeviceUpdater didFinish:(BOOL)success {
	if (deviceUpdater == aDeviceUpdater) {
		[deviceUpdater release], deviceUpdater = nil;
	}
}

#pragma mark ATPersonUpdaterDelegate
- (void)personUpdater:(ATPersonUpdater *)aPersonUpdater didFinish:(BOOL)success {
	if (personUpdater == aPersonUpdater) {
		[personUpdater release], personUpdater = nil;
	}
}

#if TARGET_OS_IPHONE
- (void)messageCenterWillDismiss:(ATMessageCenterViewController *)messageCenter {
	if (presentedMessageCenterViewController) {
		[presentedMessageCenterViewController release], presentedMessageCenterViewController = nil;
	}
}
#endif

#pragma mark -

- (NSURL *)apptentivePrivacyPolicyURL {
	return [NSURL URLWithString:@"http://www.apptentive.com/privacy"];
}

- (NSString *)distributionName {
	static NSString *cachedDistributionName = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
		cachedDistributionName = [(NSString *)[[ATConnect resourceBundle] objectForInfoDictionaryKey:ATInfoDistributionKey] retain];
	});
	return cachedDistributionName;
}

- (NSUInteger)unreadMessageCount {
	return previousUnreadCount;
}

- (void)messageCenterEnteredForeground {
	@synchronized(self) {
		[self checkForMessages];
		if (!messageRetrievalTimer) {
			NSNumber *refreshIntervalNumber = [[NSUserDefaults standardUserDefaults] objectForKey:ATAppConfigurationMessageCenterForegroundRefreshIntervalKey];
			int refreshInterval = 8;
			if (refreshIntervalNumber) {
				refreshInterval = [refreshIntervalNumber intValue];
				refreshInterval = MAX(4, refreshInterval);
			}
			messageRetrievalTimer = [[NSTimer timerWithTimeInterval:refreshInterval target:self selector:@selector(checkForMessages) userInfo:nil repeats:YES] retain];
			NSRunLoop *mainRunLoop = [NSRunLoop mainRunLoop];
			[mainRunLoop addTimer:messageRetrievalTimer forMode:NSDefaultRunLoopMode];
		}
	}
}

- (void)messageCenterLeftForeground {
	@synchronized(self) {
		if (messageRetrievalTimer) {
			[messageRetrievalTimer invalidate];
			[messageRetrievalTimer release], messageRetrievalTimer = nil;
		}
	}
}
@end

@implementation ATBackend (Private)
/* Methods which are safe to run when sharedBackend is still nil. */
- (void)setup {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(setup) withObject:nil waitUntilDone:YES];
		return;
	}
	[ATStaticLibraryBootstrap forceStaticLibrarySymbolUsage];
#if TARGET_OS_IPHONE
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWorking:) name:UIApplicationWillTerminateNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startWorking:) name:UIApplicationDidBecomeActiveNotification object:nil];
	
	
	if (&UIApplicationDidEnterBackgroundNotification != nil) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWorking:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startWorking:) name:UIApplicationWillEnterForegroundNotification object:nil];
	}
#elif TARGET_OS_MAC
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWorking:) name:NSApplicationWillTerminateNotification object:nil];
#endif
}

/* Methods which are not safe to run until sharedBackend is assigned. */
- (void)startup {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(startup) withObject:nil waitUntilDone:NO];
		return;
	}
	[self setupDataManager];
	[ApptentiveMetrics sharedMetrics];
	
	[ATMessageDisplayType setupSingletons];
	
	// One-shot actions at startup.
	[self performSelector:@selector(checkForSurveys) withObject:nil afterDelay:4];
	[self performSelector:@selector(updateDeviceIfNeeded) withObject:nil afterDelay:7];
	[self performSelector:@selector(checkForMessages) withObject:nil afterDelay:8];
	[self performSelector:@selector(updatePersonIfNeeded) withObject:nil afterDelay:9];
	
	[ATReachability sharedReachability];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:ATReachabilityStatusChanged object:nil];
	[self performSelector:@selector(startMonitoringUnreadMessages) withObject:nil afterDelay:0.2];
}

- (void)updateWorking {
	if (shouldStopWorking) {
		// Probably going into the background or being terminated.
		self.working = NO;
	} else if (apiKeySet && networkAvailable && dataManager != nil && [dataManager persistentStoreCoordinator] != nil) {
		// API Key is set and the network and Core Data stack is up. Start working.
		self.working = YES;
	} else {
		// No API Key, no network, or no Core Data. Stop working.
		self.working = NO;
	}
}

#pragma mark Notification Handling
- (void)networkStatusChanged:(NSNotification *)notification {
	ATNetworkStatus status = [[ATReachability sharedReachability] currentNetworkStatus];
	if (status == ATNetworkNotReachable) {
		networkAvailable = NO;
	} else {
		networkAvailable = YES;
	}
	[self updateWorking];
}

- (void)stopWorking:(NSNotification *)notification {
	shouldStopWorking = YES;
	[self updateWorking];
}

- (void)startWorking:(NSNotification *)notification {
	shouldStopWorking = NO;
	[self updateWorking];
}

- (void)checkForSurveys {
	@autoreleasepool {
		[ATSurveys checkForAvailableSurveys];
	}
}

- (void)checkForMessages {
	@autoreleasepool {
		@synchronized(self) {
			ATTaskQueue *queue = [ATTaskQueue sharedTaskQueue];
			if (![queue hasTaskOfClass:[ATGetMessagesTask class]]) {
				ATGetMessagesTask *task = [[ATGetMessagesTask alloc] init];
				[queue addTask:task];
				[task release], task = nil;
			}
		}
	}
}

- (void)clearDemoData {
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	
	@synchronized(self) {
		NSFetchRequest *fetchTypes = [[NSFetchRequest alloc] initWithEntityName:@"ATMessage"];
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(sender.apptentiveID == 'demouserid' || sender.apptentiveID = 'demodevid')"];
		fetchTypes.predicate = fetchPredicate;
		NSError *fetchError = nil;
		NSArray *fetchArray = [context executeFetchRequest:fetchTypes error:&fetchError];
		
		if (fetchArray) {
			for (NSManagedObject *fetchedObject in fetchArray) {
				[context deleteObject:fetchedObject];
			}
			[context save:nil];
		}
		
		[fetchTypes release], fetchTypes = nil;
	}
}

- (void)setupDataManager {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(setupDataManager) withObject:nil waitUntilDone:YES];
		return;
	}
	ATLogInfo(@"Setting up data manager");
	dataManager = [[ATDataManager alloc] initWithModelName:@"ATDataModel" inBundle:[ATConnect resourceBundle] storagePath:[self supportDirectoryPath]];
	if (![dataManager persistentStoreCoordinator]) {
		ATLogError(@"There was a problem setting up the persistent store coordinator!");
	}
}

- (void)startMonitoringUnreadMessages {
	@autoreleasepool {
#if TARGET_OS_IPHONE
		if (unreadCountController != nil) {
			ATLogError(@"startMonitoringUnreadMessages called more than once!");
			return;
		}
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		[request setEntity:[NSEntityDescription entityForName:@"ATMessage" inManagedObjectContext:[self managedObjectContext]]];
		[request setFetchBatchSize:20];
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"clientCreationTime" ascending:YES];
		[request setSortDescriptors:@[sortDescriptor]];
		[sortDescriptor release], sortDescriptor = nil;
		
		NSPredicate *unreadPredicate = [NSPredicate predicateWithFormat:@"seenByUser == %@ AND sentByUser == %@", @(NO), @(NO)];
		request.predicate = unreadPredicate;
		
		NSFetchedResultsController *newController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[[ATBackend sharedBackend] managedObjectContext] sectionNameKeyPath:nil cacheName:@"at-unread-messages-cache"];
		newController.delegate = self;
		unreadCountController = newController;
		
		NSError *error = nil;
		if (![unreadCountController performFetch:&error]) {
			ATLogError(@"got an error loading unread messages: %@", error);
			//!! handle me
		} else {
			[self controllerDidChangeContent:unreadCountController];
		}
		
		[request release], request = nil;
#endif
	}
}
@end
