//
//  ATRecordRequestTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/10/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATRecordRequestTask.h"

#import "ATBackend.h"
#import "ATData.h"
#import "ATWebClient.h"

#define kATRecordRequestTaskCodingVersion 1

@interface ATRecordRequestTask (Private)
- (void)setup;
- (void)teardown;
@end

@implementation ATRecordRequestTask
@synthesize taskProvider;

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATRecordRequestTaskCodingVersion) {
			NSURL *providerURI = [coder decodeObjectForKey:@"managedObjectURIRepresentation"];
			NSManagedObject *obj = [ATData findEntityWithURI:providerURI];
			if (obj == nil) {
				ATLogError(@"Unarchived task can't be found in CoreData");
				self.finished = YES;
			} else if ([obj conformsToProtocol:@protocol(ATRequestTaskProvider)]) {
				taskProvider = (NSObject<ATRequestTaskProvider> *)[obj retain];
			} else {
				ATLogError(@"Unarchived task doesn't conform to ATRequestTaskProvider protocol.");
				goto fail;
			}
		} else {
			goto fail;
		}
	}
	return self;
fail:
	[self release];
	return nil;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATRecordRequestTaskCodingVersion forKey:@"version"];
	NSURL *URL = [taskProvider managedObjectURIRepresentationForTask:self];
	[coder encodeObject:URL forKey:@"managedObjectURIRepresentation"];
}

- (void)dealloc {
	[self teardown];
	[taskProvider release], taskProvider = nil;
	[super dealloc];
}

- (BOOL)canStart {
	if ([[ATBackend sharedBackend] apiKey] == nil) {
		return NO;
	}
	if (![ATConversationUpdater conversationExists]) {
		return NO;
	}
	return YES;
}

- (void)start {
	if (!request) {
		request = [[self.taskProvider requestForTask:self] retain];
		if (request != nil) {
			request.delegate = self;
			[request start];
			self.inProgress = YES;
		} else {
			self.finished = YES;
		}
	}
}

- (void)stop {
	if (request) {
		request.delegate = nil;
		[request cancel];
		[request release], request = nil;
		self.inProgress = NO;
	}
}

- (float)percentComplete {
	if (request) {
		return [request percentageComplete];
	} else {
		return 0.0f;
	}
}

- (NSString *)taskName {
	return @"request";
}

- (void)cleanup {
	[taskProvider cleanupAfterTask:self];
}

#pragma mark ATAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(id)result {
	@synchronized(self) {
		[self retain];
		
		ATRecordRequestTaskResult taskResult = [self.taskProvider taskResultForTask:self withRequest:sender withResult:result];
		switch (taskResult) {
			case ATRecordRequestTaskFailedResult:
				self.failed = YES;
				break;
			case ATRecordRequestTaskFinishedResult:
				self.finished = YES;
				break;
			default:
				break;
		}
		[self stop];
		[self release];
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		[self retain];
		self.failed = YES;
		self.lastErrorTitle = sender.errorTitle;
		self.lastErrorMessage = sender.errorMessage;
		ATLogInfo(@"ATAPIRequest failed: %@, %@", sender.errorTitle, sender.errorMessage);
		[self stop];
		[self release];
	}
}
@end

@implementation ATRecordRequestTask (Private)
- (void)setup {
	
}

- (void)teardown {
	[self stop];
}
@end
