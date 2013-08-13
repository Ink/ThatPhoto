//
//  Ink.h
//  Ink Mobile Framework v0.4.0 - Release candidate #1
//
//  Created by Brett van Zuiden on 8/11/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <Foundation/Foundation.h>
//Explicitly importing all the exposed headers

/**
 Ink Model headers
*/
//An INKAction represents a single behavior that an app can perform.
#import "INKAction.h"
//An INKApp represents an iOS application that works with Ink.
#import "INKApp.h"
//An INKBlob is the data representation that is passed between apps. Encapsulates both data and metadata.
#import "INKBlob.h"
//An INKUser represents a user working with the Ink framework. Currently a placeholder.
#import "INKUser.h"
//An INKTriple encapsulates all the information needed to fire an action in Ink: (action, blob, user)
#import "INKTriple.h"

/**
 Typedef headers
*/
//Defining the type of blocks used in the Ink mobile framework
#import "INKBlocks.h"
//Defines the contants used in the Ink mobile framework
#import "INKConstants.h"
//Defines the error codes and domains used by Ink.
#import "INKErrors.h"

/**
 Categories
*/
//The UIView+Ink category allows views to be configured to automatically launch Ink when
//the user does a two-finger double-tap on the view.
#import "UIView+Ink.h"

/**
 Low-level capabilities
*/
//The INKCoreManager should not be used unless you need specific access to the low-level
//functionality of executing triples. If you work with the INKCoreManager directly,
//you need to be responsible for registering your own action/return handlers
//and verifying that actions were executed successfully.
#import "INKCoreManager.h"


/**
 Ink allows users easily move content between apps and create workflows.
 
 The Ink mobile framework is the library for allowing iOS apps to hook into the
 Ink ecosystem. Each app is both a launching-off point for actions and a recipient of actions.
 
 v0.4.0 - Initial release candidate.
 
 Change log:
 v0.4.0: First public release. 8/13/2013
*/
@interface Ink : NSObject

///-------------------------
/// @name Configuration and application setup
///-------------------------

/**
 Initializes Ink with your app key. 
 
 Must be called in your app delegate's didFinishLaunchingWithOptions method before
 any other Ink method can be used.
 
 You can get an app key at https://inkmobility.com/account
 
 @param appkey The app key for this app. Should be 20 characters long.
 
*/
+ (void)setupWithAppKey:(NSString*)appkey;

/**
 Handles the launching of this app as part of an Ink workflow and dispatches
 the event to the appropriate handle.
 
 All parameters are the same as those passed to your application delegate and should
 be passed unmodified
 
 @param url The url this app was opened with.
 @param sourceApplication The calling application.
 @param annotation User data for this request.
 @return YES if Ink has handled this url
*/
+ (BOOL)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

///-------------------------
/// @name Registering actions
///-------------------------

/**
 Register a handler for the given action via the target-selector paradigm.
 
 Note: the selector should take the same arguments as the INKActionCallbackBlock, namely (INKBlob*,INKAction*,NSError*)

 For example:
 
    INKAction *store = [INKAction action:@"Store in ThatCloud" type:INKActionType_Store];
    [Ink registerAction:store withTarget:self selector:@selector(storeBlob:action:error:)];
    ...
    - (void) storeBlob:(INKBlob*)blob action:(INKAction*)action error:(NSError*)error {
        ...
    }
 
 @param action The action to listen for.
 @param target The target to pass the message to when the event occurs.
 @param selector The selector to call when the event occurs.
 */
+ (void)registerAction:(INKAction *)action withTarget:(NSObject *)target selector:(SEL)selector;

/**
 Register a handler for the given action via the block callback paradigm.
 
 @param action The action to listen for.
 @param actionCallback The block to call when the action is fired. 
    The block takes three parameters:(INKBlob*,INKAction*,NSError*)
*/
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
