//
//  ATAutomatedMessage.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/19/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATAutomatedMessage.h"

#import "ATBackend.h"
#import "ATData.h"
#import "NSDictionary+ATAdditions.h"

@implementation ATAutomatedMessage

@dynamic title;

+ (NSObject *)newInstanceWithJSON:(NSDictionary *)json {
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	ATAutomatedMessage *message = nil;
	NSString *apptentiveID = [json at_safeObjectForKey:@"id"];
	
	if (apptentiveID) {
		message = [(ATAutomatedMessage *)[ATMessage findMessageWithID:apptentiveID] retain];
	}
	if (message == nil) {
		message = [[ATAutomatedMessage alloc] initWithEntity:[NSEntityDescription entityForName:@"ATAutomatedMessage" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	}
	[message updateWithJSON:json];
	if (![message isCreationTimeEmpty]) {
		message.clientCreationTime = message.creationTime;
	}
	return message;
}

- (NSDictionary *)apiJSON {
	NSDictionary *messageJSON = [super apiJSON];
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:messageJSON];
	
	if (self.title) {
		result[@"title"] = self.title;
	}
	result[@"type"] = @"AutomatedMessage";
	
	return result;
}

- (void)updateWithJSON:(NSDictionary *)json {
	[super updateWithJSON:json];
	
	NSString *tmpTitle = [json at_safeObjectForKey:@"title"];
	if (tmpTitle) {
		self.title = tmpTitle;
	}
}
@end
