//
//  ATWebClient+Metrics.h
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ATWebClient.h"

@class ATAPIRequest, ATMetric, ATEvent;

@interface ATWebClient (Metrics)
- (ATAPIRequest *)requestForSendingMetric:(ATMetric *)metric;
- (ATAPIRequest *)requestForSendingEvent:(ATEvent *)event;
@end


void ATWebClient_Metrics_Bootstrap();
