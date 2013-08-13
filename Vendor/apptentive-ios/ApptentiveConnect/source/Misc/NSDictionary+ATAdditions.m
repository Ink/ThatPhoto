//
//  NSDictionary+ATAdditions.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/8/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "NSDictionary+ATAdditions.h"

@implementation NSDictionary (ATAdditions)

- (id)at_safeObjectForKey:(id)aKey {
	id result = [self objectForKey:aKey];
	if (!result || [result isKindOfClass:[NSNull class]]) {
		return nil;
	}
	return result;
}
@end
