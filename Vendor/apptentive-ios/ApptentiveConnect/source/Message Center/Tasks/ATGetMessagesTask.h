//
//  ATGetMessagesTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/12/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATTask.h"
#import "ATAPIRequest.h"
#import "ATMessage.h"

static NSString *const ATMessagesLastRetrievedMessageIDPreferenceKey;

@interface ATGetMessagesTask : ATTask <ATAPIRequestDelegate> {
@private
	ATAPIRequest *request;
	ATMessage *lastMessage;
}

@end
