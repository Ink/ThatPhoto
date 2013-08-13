//
//  ATLabel.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/5/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATLabel.h"

@implementation ATLabel
@synthesize at_drawRectBlock;

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	if (at_drawRectBlock) {
		at_drawRectBlock(self, rect);
	}
}

- (void)dealloc {
	[at_drawRectBlock release], at_drawRectBlock = nil;
	[super dealloc];
}
@end
