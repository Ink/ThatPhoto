//
//  ATDeviceUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATDeviceUpdater.h"

#import "ATConversationUpdater.h"
#import "ATUtilities.h"
#import "ATWebClient+MessageCenter.h"


NSString *const ATDeviceLastUpdatePreferenceKey = @"ATDeviceLastUpdatePreferenceKey";
NSString *const ATDeviceLastUpdateValuePreferenceKey = @"ATDeviceLastUpdateValuePreferenceKey";

@implementation ATDeviceUpdater
@synthesize delegate;

+ (void)registerDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaultPreferences =
	[NSDictionary dictionaryWithObjectsAndKeys:
	 [NSDate distantPast], ATDeviceLastUpdatePreferenceKey,
	 [NSDictionary dictionary], ATDeviceLastUpdateValuePreferenceKey,
	 nil];
	[defaults registerDefaults:defaultPreferences];
}

+ (BOOL)shouldUpdate {
	[ATDeviceUpdater registerDefaults];
	
	if (![ATConversationUpdater conversationExists]) {
		return NO;
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSObject *lastValue = [defaults objectForKey:ATDeviceLastUpdateValuePreferenceKey];
	BOOL shouldUpdate = NO;
	if (lastValue == nil || ![lastValue isKindOfClass:[NSDictionary class]]) {
		shouldUpdate = YES;
	} else {
		NSDictionary *lastValueDictionary = (NSDictionary *)lastValue;
		ATDeviceInfo *deviceInfo = [[ATDeviceInfo alloc] init];
		NSDictionary *currentValueDictionary = [deviceInfo apiJSON];
		[deviceInfo release], deviceInfo = nil;
		if (![ATUtilities dictionary:currentValueDictionary isEqualToDictionary:lastValueDictionary]) {
			shouldUpdate = YES;
		}
	}
	
	return shouldUpdate;
}

- (id)initWithDelegate:(NSObject<ATDeviceUpdaterDelegate> *)aDelegate {
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

- (void)update {
	[self cancel];
	ATDeviceInfo *deviceInfo = [[ATDeviceInfo alloc] init];
	request = [[[ATWebClient sharedClient] requestForUpdatingDevice:deviceInfo] retain];
	request.delegate = self;
	[request start];
	[deviceInfo release], deviceInfo = nil;
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

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized (self) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		ATDeviceInfo *deviceInfo = [[ATDeviceInfo alloc] init];
		NSDictionary *currentValueDictionary = [deviceInfo apiJSON];
		[deviceInfo release], deviceInfo = nil;
		
		[defaults setObject:[NSDate date] forKey:ATDeviceLastUpdatePreferenceKey];
		[defaults setObject:currentValueDictionary forKey:ATDeviceLastUpdateValuePreferenceKey];
		if (![defaults synchronize]) {
			ATLogError(@"Unable to synchronize defaults for device update.");
			[delegate deviceUpdater:self didFinish:NO];
		} else {
			[delegate deviceUpdater:self didFinish:YES];
		}
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		ATLogInfo(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
		
		[delegate deviceUpdater:self didFinish:NO];
	}
}

@end
