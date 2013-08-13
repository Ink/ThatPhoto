//
//  ATRecordTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATTask.h"
#import "ATAPIRequest.h"

@class ATLegacyRecord;

@interface ATRecordTask : ATTask<ATAPIRequestDelegate> {
@private
	ATAPIRequest *request;
	ATLegacyRecord *record;
}
@property (nonatomic, retain) ATLegacyRecord *record;

@end
