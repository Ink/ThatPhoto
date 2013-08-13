//
//  UIImageView+Ink.h
//  INK Workflow Framework
//
//  Created by Jonathan Uy on 5/17/13.
//  Copyright (c) 2013 Computer Club. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "INKBlocks.h"
#import "INKBlob.h"

@interface UIView (Ink) <UIGestureRecognizerDelegate>

/*
@property (nonatomic, retain) INKDynamicBlobBlock associatedBlobBlock;
@property (nonatomic, retain) NSString* associatedUTI;
@property (nonatomic, retain) INKActionCallbackBlock associatedReturnBlock;
*/

- (void) INKEnableWithBlob:(INKBlob *)blob;

- (void) INKEnableWithUTI:(NSString*)UTI dynamicBlob:(INKDynamicBlobBlock)blobBlock;

- (void) INKEnableWithBlob:(INKBlob *)blob returnBlock:(INKActionCallbackBlock)returnBlock;

- (void) INKEnableWithUTI:(NSString *)UTI dynamicBlob:(INKDynamicBlobBlock)blobBlock returnBlock:(INKActionCallbackBlock)returnBlock;

- (UIButton*) INKAddLaunchButton;

@end





