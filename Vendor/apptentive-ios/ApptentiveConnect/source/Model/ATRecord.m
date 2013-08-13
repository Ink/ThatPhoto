//
//  ATRecord.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/13/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATRecord.h"

#import "NSDictionary+ATAdditions.h"

@implementation ATRecord

@dynamic apptentiveID;
@dynamic creationTime;
@dynamic clientCreationTime;
@dynamic clientCreationTimezone;
@dynamic clientCreationUTCOffset;

+ (NSTimeInterval)timeIntervalForServerTime:(NSNumber *)timestamp {
	long long serverTimestamp = [timestamp longLongValue];
	NSTimeInterval clientTimestamp = ((double)serverTimestamp);
	return clientTimestamp;
}

+ (NSNumber *)serverFormatForTimeInterval:(NSTimeInterval)timestamp {
	return @((long long)(timestamp));
}

+ (NSObject *)newInstanceWithJSON:(NSDictionary *)json {
	NSAssert(NO, @"Abstract method called.");
	return nil;
}

- (void)updateWithJSON:(NSDictionary *)json {
	NSString *tmpID = [json at_safeObjectForKey:@"id"];
	if (tmpID != nil) {
		self.apptentiveID = tmpID;
	}
	
	NSObject *createdAt = [json at_safeObjectForKey:@"created_at"];
	if ([createdAt isKindOfClass:[NSNumber class]]) {
		NSTimeInterval creationTimestamp = [ATRecord timeIntervalForServerTime:(NSNumber *)createdAt];
		self.creationTime = @(creationTimestamp);
	} else if ([createdAt isKindOfClass:[NSDate class]]) {
		NSDate *creationDate = (NSDate *)createdAt;
		NSTimeInterval t = [creationDate timeIntervalSince1970];
		NSNumber *creationTimestamp = [NSNumber numberWithFloat:t];
		self.creationTime = creationTimestamp;
	}
	if ([self isClientCreationTimeEmpty] && self.creationTime != nil) {
		self.clientCreationTime = self.creationTime;
	}
}

- (NSDictionary *)apiJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	if (self.clientCreationTime != nil) {
		result[@"client_created_at"] = [ATRecord serverFormatForTimeInterval:(NSTimeInterval)[self.clientCreationTime doubleValue]];
	}
	if (self.clientCreationTimezone != nil) {
		result[@"client_created_at_timezone"] = self.clientCreationTimezone;
	}
	if (self.clientCreationUTCOffset != nil) {
		result[@"client_created_at_utc_offset"] = self.clientCreationUTCOffset;
	}
	return result;
}

- (void)setup {
	if ([self isClientCreationTimeEmpty]) {
		[self updateClientCreationTime];
	}
	if ([self isCreationTimeEmpty]) {
		self.creationTime = self.clientCreationTime;
	}
}

- (void)updateClientCreationTime {
	NSDate *d = [NSDate date];
	self.clientCreationTime = [NSNumber numberWithDouble:(double)[d timeIntervalSince1970]];
	self.creationTime = self.clientCreationTime;
	self.clientCreationUTCOffset = [NSNumber numberWithInteger:[[NSTimeZone systemTimeZone] secondsFromGMTForDate:d]];
}

- (BOOL)isClientCreationTimeEmpty {
	if (self.clientCreationTime == nil || [self.clientCreationTime doubleValue] == 0) {
		return YES;
	}
	return NO;
}

- (BOOL)isCreationTimeEmpty {
	if (self.creationTime == nil || [self.creationTime doubleValue] == 0) {
		return YES;
	}
	return NO;
}
@end
