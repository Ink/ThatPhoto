//
//  ATWebClient+Metrics.m
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive. All rights reserved.
//

#import "ATWebClient+Metrics.h"
#import "ATWebClient_Private.h"
#import "ATAPIRequest.h"
#import "ATBackend.h"
#import "ATConnect.h"
#import "ATEvent.h"
#import "ATMetric.h"
#import "ATJSONSerialization.h"
#import "ATURLConnection.h"

@implementation ATWebClient (Metrics)
- (ATAPIRequest *)requestForSendingMetric:(ATMetric *)metric {
	NSDictionary *postData = [metric apiDictionary];
	NSString *url = [self apiURLStringWithPath:@"records"];
	ATURLConnection *conn = nil;
	
	conn = [self connectionToPost:[NSURL URLWithString:url] parameters:postData];
	conn.timeoutInterval = 240.0;
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:ATWebClientDefaultChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return [request autorelease];
}

- (ATAPIRequest *)requestForSendingEvent:(ATEvent *)event {
	NSDictionary *postJSON = [event apiJSON];
	NSError *error = nil;
	NSString *postString = [ATJSONSerialization stringWithJSONObject:postJSON options:ATJSONWritingPrettyPrinted error:&error];
	if (!postString && error != nil) {
		ATLogError(@"Error while encoding JSON: %@", error);
		return nil;
	}
	ATConversation *conversation = [ATConversationUpdater currentConversation];
	if (!conversation) {
		ATLogError(@"No current conversation.");
		return nil;
	}
	NSString *url = [self apiURLStringWithPath:@"events"];
	ATURLConnection *conn = nil;
	
	conn = [self connectionToPost:[NSURL URLWithString:url] JSON:postString];
	conn.timeoutInterval = 240.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:ATWebClientDefaultChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return [request autorelease];
}
@end

void ATWebClient_Metrics_Bootstrap() {
	NSLog(@"Loading ATWebClient_Metrics_Bootstrap");
}
