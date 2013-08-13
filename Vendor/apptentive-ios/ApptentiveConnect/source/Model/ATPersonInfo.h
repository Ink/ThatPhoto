//
//  ATPerson.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *const ATCurrentPersonPreferenceKey;

@interface ATPersonInfo : NSObject <NSCoding> {
@private
	NSString *apptentiveID;
	NSString *name;
	NSString *facebookID;
	NSString *secret;
	BOOL needsUpdate;
}
@property (nonatomic, copy) NSString *apptentiveID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *facebookID;
@property (nonatomic, copy) NSString *emailAddress;
@property (nonatomic, copy) NSString *secret;
@property (nonatomic, assign) BOOL needsUpdate;

+ (BOOL)personExists;
+ (ATPersonInfo *)currentPerson;

/*! If json is nil will not create a new person and will return nil. */
+ (ATPersonInfo *)newPersonFromJSON:(NSDictionary *)json;

- (NSDictionary *)apiJSON;
- (void)saveAsCurrentPerson;
@end
