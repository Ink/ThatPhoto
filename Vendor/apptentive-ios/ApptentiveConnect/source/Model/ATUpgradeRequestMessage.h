//
//  ATUpgradeRequestMessage.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ATTextMessage.h"


@interface ATUpgradeRequestMessage : ATTextMessage
@property (nonatomic, retain) NSNumber *forced;
@end
