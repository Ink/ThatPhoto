//
//  ATJSONSerialization.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/22/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATJSONSerialization.h"
#import "PJSONKit.h"

@implementation ATJSONSerialization
+ (NSData *)dataWithJSONObject:(id)obj options:(ATJSONWritingOptions)opt error:(NSError **)error {
	if ([NSJSONSerialization class]) {
		return [NSJSONSerialization dataWithJSONObject:obj options:opterr error:error];
	} else {
		ATJKSerializeOptionFlags flags = 0;
		if (opt & ATJSONWritingPrettyPrinted) {
			flags = flags | ATJSONWritingPrettyPrinted;
		}
		if ([obj isKindOfClass:[NSString class]]) {
			NSString *s = (NSString *)obj;
			return [s ATJSONDataWithOptions:flags includeQuotes:YES error:error];
		} else if ([obj isKindOfClass:[NSArray class]]) {
			NSArray *a = (NSArray *)obj;
			return [a ATJSONDataWithOptions:flags error:error];
		} else if ([obj isKindOfClass:[NSDictionary class]]) {
			NSDictionary *d = (NSDictionary *)obj;
			return [d ATJSONDataWithOptions:flags error:error];
		} else {
			if (error != NULL) {
				*error = [[[NSError alloc] initWithDomain:@"ATErrorDomain" code:-1L userInfo:@{NSLocalizedDescriptionKey:@"Cannot serialize object of unknown type."}] autorelease];
			}
			return nil;
		}
	}
}

+ (NSString *)stringWithJSONObject:(id)obj options:(ATJSONWritingOptions)opt error:(NSError **)error {
	NSData *d = [ATJSONSerialization dataWithJSONObject:obj options:opt error:error];
	if (!d) {
		return nil;
	}
	NSString *s = [[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] autorelease];
	return s;
}

+ (id)JSONObjectWithData:(NSData *)data error:(NSError **)error {
	if ([NSJSONSerialization class]) {
		return [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
	} else {
		ATJSONDecoder *decoder = [ATJSONDecoder decoder];
		id decodedObject = [decoder objectWithData:data error:error];
		return decodedObject;
	}
}

+ (id)JSONObjectWithString:(NSString *)string error:(NSError **)error {
	NSData *d = [string dataUsingEncoding:NSUTF8StringEncoding];
	NSObject *result = [ATJSONSerialization JSONObjectWithData:d error:error];
	return result;
}
@end
