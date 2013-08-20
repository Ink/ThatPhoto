//
//  UIImageView+Ink.h
//  INK Workflow Framework
//
//  Created by Liyan David Chang on 5/17/13.
//  Copyright (c) 2013 Ink. All rights reserved.
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

/**
 Enable a view to transmit a static INKBlob. 
 For example:
 
     INKBlob blob;
     blob.data = someNSData;
     blob.filename = @"somefile.png";
     blob.uti = @"public.png";
     [view INKEnableWithBlob:blob]; 
 
 @param blob The INKBlob containing the required data.
 */
- (void) INKEnableWithBlob:(INKBlob *)blob;

/**
 Enable a view to transmit a dynamically loaded INKBlob.
 For example:
 
 [self.view INKEnableWithUTI:myFile.uti dynamicBlob:^INKBlob *{
    INKBlob *blob = [INKBlob blobFromData:[myFile getData]];
    blob.uti = myFile.uti;
    blob.filename = myFile.fileName;
    return blob;
 }]; 
 
 @param UTI The NSString representation of the UTI of the INKBlob. Since the actions shown depend on the UTI, the UTI cannot be dynamically loaded.
 @param blobBlock The INKDynamicBlobBlock returning the INKBlob.
 */
- (void) INKEnableWithUTI:(NSString*)UTI dynamicBlob:(INKDynamicBlobBlock)blobBlock;

/**
 Enable a view to transmit a static INKBlob and provide a return handler
 For example:
 
 INKBlob blob;
 blob.data = someNSData;
 blob.filename = @"somefile.png";
 blob.uti = @"public.png";
 [view INKEnableWithBlob:b returnBlock:^(INKBlob *blob, INKAction *action, NSError *error) {
    if ([action.type isEqualToString: INKActionType_Return]) {
        [self saveBlob: blob withFilename:myFile.fileName];
    } else {
        NSLog(@"Return cancel.");
    }
 }];
 
 @param blob The INKBlob containing the required data.
 @param returnBlock The INKActionCallback block to be called on a return action. This handler should examine the return action type and respond appropriately.
 */
- (void) INKEnableWithBlob:(INKBlob *)blob returnBlock:(INKActionCallbackBlock)returnBlock;

/**
 Enable a view to transmit a dynamically loaded INKBlob and provide a return handler
 For example:
 
 [self.view INKEnableWithUTI:myFile.uti dynamicBlob:^INKBlob *{
 INKBlob *blob = [INKBlob blobFromData:[myFile getData]];
     blob.uti = myFile.uti;
     blob.filename = myFile.fileName;
     return blob;
 } returnBlock:^(INKBlob *blob, INKAction *action, NSError *error) {
     if ([action.type isEqualToString: INKActionType_Return]) {
        [self saveBlob: blob withFilename:myFile.fileName];
     } else {
        NSLog(@"Return cancel.");
     }
 }];
 
 @param UTI The NSString representation of the UTI of the INKBlob. Since the actions shown depend on the UTI, the UTI cannot be dynamically loaded.
 @param blobBlock The INKDynamicBlobBlock returning the INKBlob.
 @param returnBlock The INKActionCallback block to be called on a return action. This handler should determine the return action type and respond appropriately.
 */
- (void) INKEnableWithUTI:(NSString *)UTI dynamicBlob:(INKDynamicBlobBlock)blobBlock returnBlock:(INKActionCallbackBlock)returnBlock;

/** 
  INKAddLaunchButton will add a button to your INK enabled view, automatically positioned in the top right corner. If 
  you wish to position it in an alternate location, the button is returned and you can place it as you like.
  
  @return (UIButton *) The placed, movable, button INK button.
 */
- (UIButton*) INKAddLaunchButton;

@end





