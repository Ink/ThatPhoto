//
//  ATConversationUpdater.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ATAPIRequest.h"
#import "ATConversation.h"

NSString *const ATCurrentConversationPreferenceKey;

@protocol ATConversationUpdaterDelegate;

@interface ATConversationUpdater : NSObject <ATAPIRequestDelegate> {
@private
	NSObject<ATConversationUpdaterDelegate> *delegate;
	ATAPIRequest *request;
	BOOL creatingConversation;
}
@property (nonatomic, assign) NSObject<ATConversationUpdaterDelegate> *delegate;
+ (BOOL)conversationExists;
+ (ATConversation *)currentConversation;
+ (BOOL)shouldUpdate;

- (id)initWithDelegate:(NSObject<ATConversationUpdaterDelegate> *)delegate;
- (void)createOrUpdateConversation;
- (void)cancel;
- (float)percentageComplete;
@end

@protocol ATConversationUpdaterDelegate <NSObject>
- (void)conversationUpdater:(ATConversationUpdater *)updater createdConversationSuccessfully:(BOOL)success;
- (void)conversationUpdater:(ATConversationUpdater *)updater updatedConversationSuccessfully:(BOOL)success;
@end
