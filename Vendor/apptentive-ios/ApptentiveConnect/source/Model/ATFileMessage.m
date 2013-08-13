//
//  ATFileMessage.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATFileMessage.h"


@implementation ATFileMessage

@dynamic fileAttachment;


- (NSDictionary *)apiJSON {
	NSDictionary *messageJSON = [super apiJSON];
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:messageJSON];
	
	result[@"type"] = @"FileMessage";
	if (self.fileAttachment && self.fileAttachment.mimeType) {
		result[@"mime_type"] = self.fileAttachment.mimeType;
	}
	
	return result;
}
@end
