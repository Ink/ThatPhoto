//
//  ATTextMessage.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATTextMessage.h"

#import "ATBackend.h"
#import "ATData.h"
#import "NSDictionary+ATAdditions.h"

@implementation ATTextMessage

@dynamic body;
@dynamic title;

+ (NSObject *)newInstanceWithJSON:(NSDictionary *)json {
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	ATTextMessage *message = nil;
	NSString *apptentiveID = [json at_safeObjectForKey:@"id"];
	
	if (apptentiveID) {
		message = [(ATTextMessage *)[ATMessage findMessageWithID:apptentiveID] retain];
	}
	if (message == nil) {
		message = [[ATTextMessage alloc] initWithEntity:[NSEntityDescription entityForName:@"ATTextMessage" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	}
	[message updateWithJSON:json];
	if (![message isCreationTimeEmpty]) {
		message.clientCreationTime = message.creationTime;
	}
	return message;
}

- (void)updateWithJSON:(NSDictionary *)json {
	[super updateWithJSON:json];
	
	NSString *tmpBody = [json at_safeObjectForKey:@"body"];
	if (tmpBody) {
		self.body = tmpBody;
	}
}

- (NSDictionary *)apiJSON {
	NSDictionary *messageJSON = [super apiJSON];
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:messageJSON];
	
	if (self.body) {
		result[@"body"] = self.body;
	}
	result[@"type"] = @"TextMessage";
	
	return result;
}

+ (void)clearComposingMessages {
	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(pendingState == %d)", ATPendingMessageStateComposing];
		[ATData removeEntitiesNamed:@"ATTextMessage" withPredicate:fetchPredicate];
	}
}
@end
