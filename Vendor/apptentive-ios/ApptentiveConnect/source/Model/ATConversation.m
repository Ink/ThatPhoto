//
//  ATConversation.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATConversation.h"

#import "ATConnect.h"
#import "ATUtilities.h"
#import "NSDictionary+ATAdditions.h"

#define kATConversationCodingVersion 1

@implementation ATConversation
@synthesize token;
@synthesize personID;
@synthesize deviceID;

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		self.token = (NSString *)[coder decodeObjectForKey:@"token"];
		self.personID = (NSString *)[coder decodeObjectForKey:@"personID"];
		self.deviceID = (NSString *)[coder decodeObjectForKey:@"deviceID"];
	}
	return self;
}

- (void)dealloc {
	[token release], token = nil;
	[personID release], personID = nil;
	[deviceID release], deviceID = nil;
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATConversationCodingVersion forKey:@"version"];
	
	[coder encodeObject:self.token forKey:@"token"];
	[coder encodeObject:self.personID forKey:@"personID"];
	[coder encodeObject:self.deviceID forKey:@"deviceID"];
}

+ (NSObject *)newInstanceWithJSON:(NSDictionary *)json {
	ATConversation *result = nil;
	
	if (json != nil) {
		result = [[ATConversation alloc] init];
		[result updateWithJSON:json];
	} else {
		ATLogError(@"Conversation JSON was nil");
	}
	
	return result;
}

- (void)updateWithJSON:(NSDictionary *)json {
	NSString *tokenObject = [json at_safeObjectForKey:@"token"];
	if (tokenObject != nil) {
		self.token = tokenObject;
	}
	NSString *deviceIDObject = [json at_safeObjectForKey:@"device_id"];
	if (deviceIDObject != nil) {
		self.deviceID = deviceIDObject;
	}
	NSString *personIDObject = [json at_safeObjectForKey:@"person_id"];
	if (personIDObject != nil) {
		self.personID = personIDObject;
	}
}

//TODO: Add support for sending person.
- (NSDictionary *)apiJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	if (self.deviceID) {
		NSDictionary *deviceInfo = @{@"uuid":self.deviceID};
		result[@"device"] = deviceInfo;
	}
	result[@"app_release"] = [self appReleaseJSON];
	result[@"sdk"] = [self sdkJSON];
	
	return result;
}

- (NSDictionary *)appReleaseJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	NSString *appVersion = [ATUtilities appVersionString];
	if (appVersion) {
		result[@"version"] = appVersion;
	}
	NSString *buildNumber = [ATUtilities buildNumberString];
	if (buildNumber) {
		result[@"build_number"] = buildNumber;
	}
	return result;
}

- (NSDictionary *)sdkJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	result[@"version"] = kATConnectVersionString;
	result[@"programming_language"] = @"Objective-C";
	result[@"author_name"] = @"Apptentive, Inc.";
	result[@"platform"] = kATConnectPlatformString;
	return result;
}

- (NSDictionary *)apiUpdateJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	result[@"app_release"] = [self appReleaseJSON];
	result[@"sdk"] = [self sdkJSON];
	return result;
}
@end
