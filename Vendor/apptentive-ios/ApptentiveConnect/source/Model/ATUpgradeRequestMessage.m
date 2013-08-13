//
//  ATUpgradeRequestMessage.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATUpgradeRequestMessage.h"

#import "ATBackend.h"
#import "ATData.h"
#import "NSDictionary+ATAdditions.h"

@implementation ATUpgradeRequestMessage
@dynamic forced;

+ (NSObject *)newInstanceWithJSON:(NSDictionary *)json {
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	ATUpgradeRequestMessage *message = nil;
	NSString *apptentiveID = [json at_safeObjectForKey:@"id"];
	
	if (apptentiveID) {
		message = [(ATUpgradeRequestMessage *)[ATMessage findMessageWithID:apptentiveID] retain];
	}
	if (message == nil) {
		message = [[ATUpgradeRequestMessage alloc] initWithEntity:[NSEntityDescription entityForName:@"ATUpgradeRequestMessage" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	}
	[message updateWithJSON:json];
	return message;
}

- (void)updateWithJSON:(NSDictionary *)json {
	[super updateWithJSON:json];
	
	NSNumber *tmpForced = [json at_safeObjectForKey:@"forced"];
	if (tmpForced) {
		self.forced = tmpForced;
	}
}

@end
