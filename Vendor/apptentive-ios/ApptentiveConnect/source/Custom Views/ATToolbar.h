//
//  ATToolbar.h
//  CustomWindow
//
//  Created by Andrew Wooster on 9/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATTypes.h"

@interface ATToolbar : UIToolbar {
	ATDrawRectBlock at_drawRectBlock;
}
@property (nonatomic, readwrite, copy) ATDrawRectBlock at_drawRectBlock;
@end

void ATToolbar_Bootstrap();
