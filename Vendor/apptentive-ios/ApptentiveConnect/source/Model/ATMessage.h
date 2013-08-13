//
//  ATMessage.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ATJSONModel.h"
#import "ATRecord.h"

typedef enum {
	ATPendingMessageStateComposing,
	ATPendingMessageStateSending,
	ATPendingMessageStateConfirmed,
	ATPendingMessageStateError
} ATPendingMessageState;

@class ATMessageDisplayType, ATMessageSender;

@interface ATMessage : ATRecord <ATJSONModel>

@property (nonatomic, retain) NSString *pendingMessageID;
@property (nonatomic, retain) NSNumber *pendingState;
@property (nonatomic, retain) NSNumber *priority;
@property (nonatomic, retain) NSNumber *seenByUser;
@property (nonatomic, retain) NSNumber *sentByUser;
@property (nonatomic, retain) NSNumber *errorOccurred;
@property (nonatomic, retain) NSString *errorMessageJSON;
@property (nonatomic, retain) ATMessageSender *sender;
@property (nonatomic, retain) NSSet *displayTypes;

+ (ATMessage *)findMessageWithID:(NSString *)apptentiveID;
+ (ATMessage *)findMessageWithPendingID:(NSString *)pendingID;
- (NSArray *)errorsFromErrorMessage;
@end

@interface ATMessage (CoreDataGeneratedAccessors)

- (void)addDisplayTypesObject:(ATMessageDisplayType *)value;
- (void)removeDisplayTypesObject:(ATMessageDisplayType *)value;
- (void)addDisplayTypes:(NSSet *)values;
- (void)removeDisplayTypes:(NSSet *)values;

@end
