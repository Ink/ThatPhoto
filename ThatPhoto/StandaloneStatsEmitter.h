//
//  StatsEmitter.h
//  INK
//
//  Created by Russell Cohen on 9/4/13.
//  Copyright (c) 2013 Computer Club. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface StandaloneStatsEmitter : NSObject<NSURLConnectionDelegate>

+ (StandaloneStatsEmitter *)sharedEmitter;
- (void) sendStat: (NSString *)actionType withAdditionalStatistics:(NSDictionary *)additonalStatistics;
- (void) setAppKey: (NSString *)_appKey;

@end
