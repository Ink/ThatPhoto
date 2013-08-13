//
//  ATEvent.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/13/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ATRecord.h"

#import "ATJSONModel.h"
#import "ATRecordRequestTask.h"

@interface ATEvent : ATRecord <ATJSONModel, ATRequestTaskProvider>

@property (nonatomic, retain) NSString *pendingEventID;
@property (nonatomic, retain) NSData *dictionaryData;
@property (nonatomic, retain) NSString *label;

- (void)setValue:(id)value forKey:(NSString *)key;
- (void)addEntriesFromDictionary:(NSDictionary *)dictionary;
@end
