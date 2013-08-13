//
//  ATDefaultTextView.h
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATTypes.h"

@interface ATDefaultTextView : UITextView  {
@private
	UILabel *placeholderLabel;
	ATDrawRectBlock at_drawRectBlock;
}
@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, readwrite, copy) ATDrawRectBlock at_drawRectBlock;
- (BOOL)isDefault;
@end
