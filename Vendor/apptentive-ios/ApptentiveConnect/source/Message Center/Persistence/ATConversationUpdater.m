//
//  ATActivityFeedUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATConversationUpdater.h"

#import "ATBackend.h"
#import "ATUtilities.h"
#import "ATWebClient+MessageCenter.h"

NSString *const ATCurrentConversationPreferenceKey = @"ATCurrentConversationPreferenceKey";

NSString *const ATConversationLastUpdatePreferenceKey = @"ATConversationLastUpdatePreferenceKey";
NSString *const ATConversationLastUpdateValuePreferenceKey = @"ATConversationLastUpdateValuePreferenceKey";

@interface ATConversationUpdater (Private)
- (void)processResult:(NSDictionary *)jsonActivityFeed;
@end

@implementation ATConversationUpdater
@synthesize delegate;

+ (void)registerDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaultPreferences =
	[NSDictionary dictionaryWithObjectsAndKeys:
	 [NSDate distantPast], ATConversationLastUpdatePreferenceKey,
	 [NSDictionary dictionary], ATConversationLastUpdateValuePreferenceKey,
	 nil];
	[defaults registerDefaults:defaultPreferences];
}

- (id)initWithDelegate:(NSObject<ATConversationUpdaterDelegate> *)aDelegate {
	if ((self = [super init])) {
		delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	delegate = nil;
	[self cancel];
	[super dealloc];
}

- (void)createOrUpdateConversation {
	[self cancel];
    
    ATConversation *currentConversation = [ATConversationUpdater currentConversation];
    if (currentConversation == nil) {
		ATLogInfo(@"Creating conversation");
        creatingConversation = YES;
        ATConversation *conversation = [[ATConversation alloc] init];
        conversation.deviceID = [[ATBackend sharedBackend] deviceUUID];
        request = [[[ATWebClient sharedClient] requestForCreatingConversation:conversation] retain];
        request.delegate = self;
        [request start];
        [conversation release], conversation = nil;
    } else {
        creatingConversation = NO;
        request = [[[ATWebClient sharedClient] requestForUpdatingConversation:currentConversation] retain];
        request.delegate = self;
        [request start];
    }
}

- (void)cancel {
	if (request) {
		request.delegate = nil;
		[request cancel];
		[request release], request = nil;
	}
}

- (float)percentageComplete {
	if (request) {
		return [request percentageComplete];
	} else {
		return 0.0f;
	}
}

+ (BOOL)conversationExists {
	ATConversation *currentFeed = [ATConversationUpdater currentConversation];
	if (currentFeed == nil) {
		return NO;
	} else {
		return YES;
	}
}

+ (ATConversation *)currentConversation {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *conversationData = [defaults dataForKey:ATCurrentConversationPreferenceKey];
	if (!conversationData) {
		return nil;
	}
	ATConversation *conversation = nil;
	@try {
		conversation = [NSKeyedUnarchiver unarchiveObjectWithData:conversationData];
	} @catch (NSException *exception) {
		ATLogError(@"Unable to unarchive conversation: %@", exception);
	}
	return conversation;
}

+ (BOOL)shouldUpdate {
	[ATConversationUpdater registerDefaults];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSObject *lastValue = [defaults objectForKey:ATConversationLastUpdateValuePreferenceKey];
	BOOL shouldUpdate = YES;
	
	do { // once
		if (lastValue == nil || ![lastValue isKindOfClass:[NSDictionary class]]) {
			break;
		}
		NSDictionary *lastValueDictionary = (NSDictionary *)lastValue;
		ATConversation *conversation = [self currentConversation];
		if (!conversation) {
			break;
		}
		NSDictionary *currentValueDictionary = [conversation apiUpdateJSON];
		if (![ATUtilities dictionary:currentValueDictionary isEqualToDictionary:lastValueDictionary]) {
			break;
		}
		shouldUpdate = NO;
	} while (NO);
	
	return shouldUpdate;
}

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized (self) {
		if ([result isKindOfClass:[NSDictionary class]]) {
			[self processResult:(NSDictionary *)result];
		} else {
			ATLogError(@"Activity feed result is not NSDictionary!");
            if (creatingConversation) {
                [delegate conversationUpdater:self createdConversationSuccessfully:NO];
            } else {
                [delegate conversationUpdater:self updatedConversationSuccessfully:NO];
            }
		}
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		ATLogInfo(@"Conversation request failed: %@, %@", sender.errorTitle, sender.errorMessage);
        if (creatingConversation) {
            [delegate conversationUpdater:self createdConversationSuccessfully:NO];
        } else {
            [delegate conversationUpdater:self updatedConversationSuccessfully:NO];
        }
	}
}

@end


@implementation ATConversationUpdater (Private)
- (void)processResult:(NSDictionary *)jsonActivityFeed {
    if (creatingConversation) {
        ATConversation *conversation = (ATConversation *)[ATConversation newInstanceWithJSON:jsonActivityFeed];
        if (conversation) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSData *conversationData = [NSKeyedArchiver archivedDataWithRootObject:conversation];
            [defaults setObject:conversationData forKey:ATCurrentConversationPreferenceKey];
            [defaults setObject:[conversation apiUpdateJSON] forKey:ATConversationLastUpdateValuePreferenceKey];
            [defaults setObject:[NSDate date] forKey:ATConversationLastUpdatePreferenceKey];
			if (![defaults synchronize]) {
				ATLogError(@"Unable to synchronize defaults for conversation creation.");
				[delegate conversationUpdater:self createdConversationSuccessfully:NO];
			} else {
				ATLogInfo(@"Conversation created successfully.");
				[delegate conversationUpdater:self createdConversationSuccessfully:YES];
			}
        } else {
			ATLogError(@"Unable to create conversation");
            [delegate conversationUpdater:self createdConversationSuccessfully:NO];
        }
        [conversation release], conversation = nil;
    } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		ATConversation *conversation = [ATConversationUpdater currentConversation];
        [defaults setObject:[conversation apiUpdateJSON] forKey:ATConversationLastUpdateValuePreferenceKey];
        [defaults setObject:[NSDate date] forKey:ATConversationLastUpdatePreferenceKey];
		if (![defaults synchronize]) {
			ATLogError(@"Unable to synchronize defaults for conversation update.");
			[delegate conversationUpdater:self updatedConversationSuccessfully:NO];
		} else {
			[delegate conversationUpdater:self updatedConversationSuccessfully:YES];
		}
    }
}
@end
