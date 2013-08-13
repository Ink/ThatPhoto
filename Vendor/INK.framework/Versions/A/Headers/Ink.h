//
//  Ink.h
//  INK
//
//  Created by Brett van Zuiden on 8/11/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "INKTriple.h"
//Being explicit
#import "INKAction.h"
#import "INKBlob.h"
#import "INKUser.h"

//Includes to expose other functionalities of Ink
#import "INKConstants.h"
#import "UIView+Ink.h"

@interface Ink : NSObject

//Configuration and application setup
+ (void)setupWithAppKey:(NSString*)appkey;
+ (BOOL)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

//Registering actions to be used with Ink
+ (void)registerAction:(INKAction *)action withTarget:(NSObject *)target selector:(SEL)selector;
+ (void)registerAction:(INKAction *)action withBlock:(INKActionCallbackBlock)actionCallback;

//Workflow
+ (void)return;
+ (void)returnBlob:(INKBlob*)blob;
+ (void)returnWithError:(NSError*)error;

//Lower level functions
+ (BOOL)executeTriple:(INKTriple *)triple;
+ (BOOL)executeTriple:(INKTriple *)triple onReturn:(INKActionCallbackBlock)returnBlock;

//Checking state
//Whether the app should return
+ (BOOL)appShouldReturn;

//Showing the workspace
+ (void)showWorkspaceWithBlob:(INKBlob *)blob;
+ (void)showWorkspaceWithUTI:(NSString *)UTI dynamicBlob:(INKDynamicBlobBlock)block;
+ (void)showWorkspaceWithBlob:(INKBlob *)blob onReturn:(INKActionCallbackBlock)returnBlock;
+ (void)showWorkspaceWithUTI:(NSString *)UTI dynamicBlob:(INKDynamicBlobBlock)block onReturn:(INKActionCallbackBlock)returnBlock;

@end
