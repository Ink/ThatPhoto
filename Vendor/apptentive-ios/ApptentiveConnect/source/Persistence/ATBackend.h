//
//  ATBackend.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif
#import <CoreData/CoreData.h>

#import "ATConversationUpdater.h"
#import "ATDeviceUpdater.h"
#import "ATPersonUpdater.h"
#if TARGET_OS_IPHONE
#import "ATMessageCenterViewController.h"
#import "ATMessagePanelViewController.h"
#endif

NSString *const ATBackendNewAPIKeyNotification;

#define USE_STAGING 0

@class ATAppConfigurationUpdater;
@class ATDataManager;
@class ATFeedback;
@class ATAPIRequest;

/*! Handles all of the backend activities, such as sending feedback. */
@interface ATBackend : NSObject <ATConversationUpdaterDelegate, ATDeviceUpdaterDelegate, ATPersonUpdaterDelegate
#if TARGET_OS_IPHONE
, NSFetchedResultsControllerDelegate, ATMessageCenterDismissalDelegate, ATMessagePanelDelegate, UIAlertViewDelegate
#endif
> {
@private
	NSString *apiKey;
	ATFeedback *currentFeedback;
	BOOL networkAvailable;
	BOOL apiKeySet;
	BOOL shouldStopWorking;
	BOOL working;
	
	ATConversationUpdater *conversationUpdater;
	ATDeviceUpdater *deviceUpdater;
	ATPersonUpdater *personUpdater;
	
	NSTimer *messageRetrievalTimer;
	ATDataManager *dataManager;
#if TARGET_OS_IPHONE
	NSFetchedResultsController *unreadCountController;
	NSInteger previousUnreadCount;
#endif
}
@property (nonatomic, copy) NSString *apiKey;
/*! The feedback currently being worked on by the user. */
@property (nonatomic, retain) ATFeedback *currentFeedback;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;

+ (ATBackend *)sharedBackend;
#if TARGET_OS_IPHONE
+ (UIImage *)imageNamed:(NSString *)name;
- (void)presentMessageCenterFromViewController:(UIViewController *)viewController;
- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (void)presentIntroDialogFromViewController:(UIViewController *)viewController;
- (void)presentIntroDialogFromViewController:(UIViewController *)viewController withTitle:(NSString *)title prompt:(NSString *)prompt placeholderText:(NSString *)placeholder;
#elif TARGET_OS_MAC
+ (NSImage *)imageNamed:(NSString *)name;
#endif

/*! Use this to add the feedback to a queue of feedback tasks which
    will be sent in the background. */
- (void)sendFeedback:(ATFeedback *)feedback;

/*! Use this to send an automated message. */
- (void)sendAutomatedMessageWithTitle:(NSString *)title body:(NSString *)body;

- (NSString *)supportDirectoryPath;

/*! Path to directory for storing attachments. */
- (NSString *)attachmentDirectoryPath;
- (NSString *)deviceUUID;

- (NSURL *)apptentiveHomepageURL;
- (NSURL *)apptentivePrivacyPolicyURL;

- (NSString *)distributionName;

- (NSUInteger)unreadMessageCount;

- (void)messageCenterEnteredForeground;
- (void)messageCenterLeftForeground;
@end
