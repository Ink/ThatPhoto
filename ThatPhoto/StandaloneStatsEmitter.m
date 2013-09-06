//
//  StatsEmitter.m
//  INK
//
//  Created by Russell Cohen on 9/4/13.
//  Copyright (c) 2013 Computer Club. All rights reserved.
//

#import "StandaloneStatsEmitter.h"
//#import "InternalConstants.h"
//#import "InternalWorkflowConstants.h"

#define ink_STATSURL @"https://www.example.com/"
#define WARNING(...) NSLog(__VA_ARGS__); assert(false);
#define REQUIRED_KEYS @[@"Stat_Action_Type", @"Originating_App", @"Device_ID", @"Device_Type"]

@implementation StandaloneStatsEmitter {
    NSString *_appKey;
    NSMutableData *_responseData;
}

+ (StandaloneStatsEmitter *)sharedEmitter {

    static StandaloneStatsEmitter *_sharedEmitter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedEmitter = [[StandaloneStatsEmitter alloc] init];
        
    });
    
    return _sharedEmitter;
}

- (void) setAppKey: (NSString *)appKey {
    _appKey = appKey;
}

- (id)init:(NSURL *)url {
    self = [super init];
    if (!self) {
        return nil;
    }

    return self;
}
- (NSDictionary *) addCoreDictionaryTo: (NSDictionary *)stat withActionType: (NSString *)actionType {
    NSMutableDictionary *statParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"Device_ID",
                                [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"], @"Originating_App",
                                [UIDevice currentDevice].model, @"Device_Type",
                                [UIDevice currentDevice].systemVersion, @"OS_Version",
                                actionType, @"Stat_Action_Type",
                                nil];
    [statParams addEntriesFromDictionary:stat];
    return [NSDictionary dictionaryWithDictionary:statParams];
}

- (void) sendDictionary: (NSDictionary *)stat {
#ifndef DEBUG
    NSURL *url = [NSURL URLWithString:ink_STATSURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSError *error = [[NSError alloc] init];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:stat options:0 error:&error];
    if (jsonData) {
        [request setHTTPBody:jsonData];
    } else {
        NSLog(@"Unable to serialize the data %@: %@", stat, error);
    }
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *resp, NSData *data, NSError *err) {
        NSHTTPURLResponse *resphttp = (NSHTTPURLResponse *)resp;
        NSLog(@"woo: %d", [resphttp statusCode]);
    }];
#else
    NSLog(@"Mock stat: %@", stat);
#endif
}

- (void) sendStat: (NSString *)actionType withAdditionalStatistics:(NSDictionary *)additonalStatistics {
    if (_appKey == nil) {
        WARNING(@"App key is nil in stats emitter");
    }
    NSDictionary *finalDict = [self addCoreDictionaryTo:additonalStatistics withActionType:actionType];
    for(id key in REQUIRED_KEYS) {
        if ([finalDict objectForKey:key] == nil) {
            WARNING(@"Required parameter: %@ not found in stats dict: %@", key, finalDict);
        }
    }
    [self sendDictionary:finalDict];
}

@end
