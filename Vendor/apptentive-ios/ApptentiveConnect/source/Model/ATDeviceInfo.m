//
//  ATDeviceInfo.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//
#if TARGET_OS_IPHONE
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#endif

#import "ATDeviceInfo.h"

#import "ATBackend.h"
#import "ATConnect.h"
#import "ATConnect_Private.h"
#import "ATUtilities.h"

@implementation ATDeviceInfo
- (id)init {
	if ((self = [super init])) {
	}
	return self;
}

- (void)dealloc {
	[super dealloc];
}

+ (NSString *)carrier {
#if TARGET_OS_IPHONE
	NSString *result = nil;
	if ([CTTelephonyNetworkInfo class]) {
		CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
		CTCarrier *c = [netInfo subscriberCellularProvider];
		if (c.carrierName) {
			result = c.carrierName;
		}
		[netInfo release], netInfo = nil;
	}
	return result;
#elif TARGET_OS_MAC
	return @"";
#endif
}

- (NSDictionary *)apiJSON {
	NSMutableDictionary *device = [NSMutableDictionary dictionary];
	
	device[@"uuid"] = [[ATBackend sharedBackend] deviceUUID];
	device[@"os_name"] = [ATUtilities currentSystemName];
	device[@"os_version"] = [ATUtilities currentSystemVersion];
	device[@"model"] = [ATUtilities currentMachineName];
	
	NSString *carrier = [ATDeviceInfo carrier];
	if (carrier != nil) {
		device[@"carrier"] = carrier;
	}
	
	NSLocale *locale = [NSLocale currentLocale];
	NSString *localeIdentifier = [locale localeIdentifier];
	NSDictionary *localeComponents = [NSLocale componentsFromLocaleIdentifier:localeIdentifier];
	NSString *countryCode = [localeComponents objectForKey:NSLocaleCountryCode];
	NSString *languageCode = [localeComponents objectForKey:NSLocaleLanguageCode];
	if (localeIdentifier) {
		device[@"locale_raw"] = localeIdentifier;
	}
	if (countryCode) {
		device[@"locale_country_code"] = countryCode;
	}
	if (languageCode) {
		device[@"locale_language_code"] = languageCode;
	}
	
	NSDictionary *extraInfo = [[ATConnect sharedConnection] customData];
	if (extraInfo && [extraInfo count]) {
		device[@"custom_data"] = extraInfo;
	}
	
	return @{@"device":device};
}
@end
