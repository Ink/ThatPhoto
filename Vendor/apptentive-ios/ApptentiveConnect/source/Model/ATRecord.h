//
//  ATRecord.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/13/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ATJSONModel.h"

@interface ATRecord : NSManagedObject <ATJSONModel>

@property (nonatomic, retain) NSString *apptentiveID;
@property (nonatomic, retain) NSNumber *creationTime;
@property (nonatomic, retain) NSNumber *clientCreationTime;
@property (nonatomic, retain) NSString *clientCreationTimezone;
@property (nonatomic, retain) NSNumber *clientCreationUTCOffset;

+ (NSTimeInterval)timeIntervalForServerTime:(NSNumber *)timestamp;
+ (NSNumber *)serverFormatForTimeInterval:(NSTimeInterval)timestamp;

- (void)setup;
- (void)updateClientCreationTime;
- (BOOL)isClientCreationTimeEmpty;
- (BOOL)isCreationTimeEmpty;
@end
