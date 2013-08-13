//
//  ATJSONSerialization.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/22/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, ATJSONWritingOptions) {
    ATJSONWritingPrettyPrinted = (1UL << 0)
};

@interface ATJSONSerialization : NSObject
+ (NSData *)dataWithJSONObject:(id)obj options:(ATJSONWritingOptions)opt error:(NSError **)error;
+ (NSString *)stringWithJSONObject:(id)obj options:(ATJSONWritingOptions)opt error:(NSError **)error;
+ (id)JSONObjectWithData:(NSData *)data error:(NSError **)error;
+ (id)JSONObjectWithString:(NSString *)string error:(NSError **)error;
@end
