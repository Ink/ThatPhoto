//
//  ATPersonUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATPersonUpdater.h"
#import "ATWebClient+MessageCenter.h"

NSString *const ATCurrentPersonPreferenceKey = @"ATCurrentPersonPreferenceKey";


@interface ATPersonUpdater (Private)
- (void)processResult:(NSDictionary *)jsonPerson;
@end

@implementation ATPersonUpdater
@synthesize delegate;

- (id)initWithDelegate:(NSObject<ATPersonUpdaterDelegate> *)aDelegate {
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

+ (BOOL)shouldUpdate {
	ATPersonInfo *person = [ATPersonInfo currentPerson];
	if (!person) {
		// Avoid creating a person "just because".
		return NO;
	}
	return person.needsUpdate;
}

- (void)update {
	[self cancel];
	ATPersonInfo *person = [ATPersonInfo currentPerson];
	if (person) {
		person.needsUpdate = YES;
		[person saveAsCurrentPerson];
	}
	request = [[[ATWebClient sharedClient] requestForUpdatingPerson:person] retain];
	request.delegate = self;
	[request start];
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
		if ([result isKindOfClass:[NSDictionary class]]) {
			[self processResult:(NSDictionary *)result];
		} else {
			ATLogError(@"Person result is not NSDictionary!");
			[delegate personUpdater:self didFinish:NO];
		}
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		ATLogInfo(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
		
		[delegate personUpdater:self didFinish:NO];
	}
}
@end

@implementation ATPersonUpdater (Private)
- (void)processResult:(NSDictionary *)jsonPerson {
	ATPersonInfo *person = [ATPersonInfo newPersonFromJSON:jsonPerson];
	
	if (person) {
		person.needsUpdate = NO;
		[person saveAsCurrentPerson];
		[delegate personUpdater:self didFinish:YES];
	} else {
		[delegate personUpdater:self didFinish:NO];
	}
	[person release], person = nil;
}
@end
