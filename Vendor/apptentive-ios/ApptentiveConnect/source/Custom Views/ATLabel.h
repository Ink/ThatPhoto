//
//  ATLabel.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/5/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATTypes.h"

@interface ATLabel : UILabel {
	ATDrawRectBlock at_drawRectBlock;
}
@property (nonatomic, readwrite, copy) ATDrawRectBlock at_drawRectBlock;

@end
