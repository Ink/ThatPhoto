//
//  ATStaticLibraryBootstrap.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 12/7/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATStaticLibraryBootstrap.h"

#import "ATToolbar.h"
#import "ATWebClient+Metrics.h"
#import "ATWebClient+SurveyAdditions.h"
#import "ATURLConnection_Private.h"
#import "ATWebClient+MessageCenter.h"
#import "ATWebClient_Private.h"

@implementation ATStaticLibraryBootstrap
+ (void)forceStaticLibrarySymbolUsage {
	ATWebClient_Metrics_Bootstrap();
	ATWebClient_SurveyAdditions_Bootstrap();
	ATURLConnection_Private_Bootstrap();
	ATWebClient_Private_Bootstrap();
	ATWebClient_MessageCenter_Bootstrap();
	ATToolbar_Bootstrap();
}
@end
