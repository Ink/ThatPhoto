//
//  ATPerson.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATPersonInfo.h"

#import "ATUtilities.h"
#import "NSDictionary+ATAdditions.h"

#define kATPersonCodingVersion 1

@implementation ATPersonInfo
@synthesize apptentiveID;
@synthesize name;
@synthesize facebookID;
@synthesize emailAddress;
@synthesize secret;
@synthesize needsUpdate;

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		self.apptentiveID = (NSString *)[coder decodeObjectForKey:@"apptentiveID"];
		self.name = (NSString *)[coder decodeObjectForKey:@"name"];
		self.facebookID = (NSString *)[coder decodeObjectForKey:@"facebookID"];
		self.emailAddress = (NSString *)[coder decodeObjectForKey:@"emailAddress"];
		self.secret = (NSString *)[coder decodeObjectForKey:@"secret"];
		self.needsUpdate = [coder decodeBoolForKey:@"needsUpdate"];
	}
	return self;
}

- (void)dealloc {
	[apptentiveID release], apptentiveID = nil;
	[name release], name = nil;
	[facebookID release], facebookID = nil;
	[emailAddress release], emailAddress = nil;
	[secret release], secret = nil;
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATPersonCodingVersion forKey:@"version"];
	
	[coder encodeObject:self.apptentiveID forKey:@"apptentiveID"];
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.facebookID forKey:@"facebookID"];
	[coder encodeObject:self.emailAddress forKey:@"emailAddress"];
	[coder encodeObject:self.secret forKey:@"secret"];
	[coder encodeBool:self.needsUpdate forKey:@"needsUpdate"];
}

+ (BOOL)personExists {
	ATPersonInfo *currentPerson = [ATPersonInfo currentPerson];
	if (currentPerson == nil) {
		return NO;
	} else {
		return YES;
	}
}

+ (ATPersonInfo *)currentPerson {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *personData = [defaults dataForKey:ATCurrentPersonPreferenceKey];
	if (!personData) {
		return nil;
	}
	ATPersonInfo *person = nil;
	
	@try {
		person = [NSKeyedUnarchiver unarchiveObjectWithData:personData];
	} @catch (NSException *exception) {
		ATLogError(@"Unable to unarchive person: %@", person);
	}
	
	return person;
}

+ (ATPersonInfo *)newPersonFromJSON:(NSDictionary *)json {
	ATPersonInfo *result = nil;
	BOOL success = NO;
	
	do { // once
		if (!json) break;
		NSDictionary *p = json;
		
		result = [[ATPersonInfo alloc] init];
		result.apptentiveID = [p at_safeObjectForKey:@"id"];
		result.name = [p at_safeObjectForKey:@"name"];
		result.facebookID = [p at_safeObjectForKey:@"facebook_id"];
		result.emailAddress = [p at_safeObjectForKey:@"email"];
		result.secret = [p at_safeObjectForKey:@"secret"];
		
		success = YES;
	} while (NO);
	
	if (result != nil && success == NO) {
		[result release], result = nil;
	}
	
	
	return result;
}

- (NSDictionary *)apiJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	if (self.name) {
		[result setObject:self.name forKey:@"name"];
	}
	if (self.facebookID) {
		[result setObject:self.facebookID forKey:@"facebook_id"];
	}
	if (self.emailAddress && [self.emailAddress length] > 0 && [ATUtilities emailAddressIsValid:self.emailAddress]) {
		[result setObject:self.emailAddress forKey:@"email"];
	}
	if (self.secret) {
		[result setObject:self.secret forKey:@"secret"];
	}
	
	return [NSDictionary dictionaryWithObject:result forKey:@"person"];
}

- (NSDictionary *)comparisonDictionary {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	if (self.apptentiveID) {
		[result setObject:self.apptentiveID forKey:@"apptentive_id"];
	}
	if (self.name) {
		[result setObject:self.name forKey:@"name"];
	}
	if (self.facebookID) {
		[result setObject:self.facebookID forKey:@"facebook_id"];
	}
	if (self.emailAddress) {
		[result setObject:self.emailAddress forKey:@"email"];
	}
	if (self.secret) {
		[result setObject:self.secret forKey:@"secret"];
	}
	
	return result;
}

- (NSUInteger)hash {
	NSString *hashString = [NSString stringWithFormat:@"%@,%@,%@,%@,%@", self.apptentiveID, self.name, self.facebookID, self.emailAddress, self.secret];
	return [hashString hash];
}

- (BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[ATPersonInfo class]]) {
		return NO;
	}
	ATPersonInfo *other = (ATPersonInfo *)object;
	BOOL equal = [ATUtilities dictionary:[self comparisonDictionary] isEqualToDictionary:[other comparisonDictionary]];
	return equal;
}

- (void)saveAsCurrentPerson {
	ATPersonInfo *currentPerson = [ATPersonInfo currentPerson];
	BOOL isDirty = ![self isEqual:currentPerson];
	if (isDirty || self.needsUpdate != currentPerson.needsUpdate) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSData *personData = [NSKeyedArchiver archivedDataWithRootObject:self];
		[defaults setObject:personData forKey:ATCurrentPersonPreferenceKey];
		[defaults synchronize];
	}
}
@end
