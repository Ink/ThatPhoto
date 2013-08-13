//
//  ATFileMessage.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ATMessage.h"
#import "ATFileAttachment.h"

@interface ATFileMessage : ATMessage
@property (nonatomic, retain) ATFileAttachment *fileAttachment;
@end
