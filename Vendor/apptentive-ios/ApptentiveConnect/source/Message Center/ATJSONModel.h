//
//  ATJSONModel.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ATJSONModel <NSObject>
+ (NSObject *)newInstanceWithJSON:(NSDictionary *)json;
- (void)updateWithJSON:(NSDictionary *)json;
- (NSDictionary *)apiJSON;
@end
