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

///-------------------------
/// @name Workflow
///-------------------------
/**
 Determines if the current app was launched with Ink and therefore should return when the action is completed.
 
 When a user launches into your app to complete an action, the user expects that when the task is completed
 they will be given an opportunity to continue their workflow, optionally with the new content they just created
 in your app. Use the appShouldReturn method to determine if this app should call one of the Ink return methods
 when the current action is completed.
 
 @see return
 @see returnBlob:
 @see returnWithError:
 
 @return Returns if the current app should return.
*/

+ (BOOL)appShouldReturn;

/**
 Bring up the Ink workspace to allow the user to return to the calling application.
 
 This method should be called when the user completes an Ink workflow but the
 action is one where there is no data to return (i.e. INKActionType_View)
 
 The data shown in the workspace is the INKBlob that was used to launch this app.
 
 Before calling this, check the appShouldReturn method:
 
    if ([Ink appShouldReturn]) {
        [Ink return];
    }
 
 @see appShouldReturn
*/
+ (void)return;

/**
 Bring up the Ink workspace and allow the user to continue their workflow with new data.
 
 This method should be called whenever the user completes a workflow and they have new
 data to work with, for example for an edit action.
 
 Before calling this, check the appShouldReturn method.
 @param blob The new data that was a result of the user completing the desired action.
 @see appShouldReturn
 */
+ (void)returnBlob:(INKBlob*)blob;

/**
 Bring up the Ink workspace and allow the user to continue their workflow but show an error.
 
 This method should be called when an error occurred when the current app tried to complete the request.
 
 Before calling this, check the appShouldReturn method.
 @param error The error that occurred when trying to execute the desired action.
 @see appShouldReturn
 */
+ (void)returnWithError:(NSError*)error;


///-------------------------
/// @name Ink workspace
///-------------------------
/**
 Opens the Ink workspace and provides actions for the specified blob.
 
 The recommended way to use Ink is to bind the ink gesture to UIViews in your application
 using the INKEnableWithBlob: and related methods. However, there are situations where you
 need to open the workspace directly, for example as a result of a user tapping an Ink toolbar icon.
 
 This method will immediately show the Ink workspace with the content and uti specified by the given blob.
 warning: ensure that the blob has a uti before calling this method.
 
 @param blob The content to open Ink with.
 */
+ (void)showWorkspaceWithBlob:(INKBlob *)blob;

/**
 Opens the Ink workspace in a situation where the full content is not immediately available.
 
 For many situations, expecially those where the content is very large or stored server-size,
 fetching the blob data at launch time and binding it to a view would decrease performance.
 
 In these cases, the recommended paradigm is to specify a UTI so that the correct actions will show immediately,
 and then provide a block that will be run asynchronously on a background thread when the workflow screen
 is presented. Note that using this method will not block the UI, but will result in the user being shown a
 loading spinner, so the faster you can return the blob data the better.
 
 @param UTI The Uniform Type Identifier of the blob, used to filter the aciton list.
 @param block The block that will be called on a background thread to retrieve the blob.
 */
+ (void)showWorkspaceWithUTI:(NSString *)UTI dynamicBlob:(INKDynamicBlobBlock)block;

/**
 Opens the Ink workspace and binds a return handler for when the user completes their work and returns to this app.

 Specifying a return block allows you to easily preserve context for when the user returns to your application with
 their new content.
 
 Instead of or in addition to binding a global handler for return actions, you can pass in a callback block
 that will be called when the user returns from the app they were working in and comes back to this app.
 
  @param blob The content to open Ink with.
  @param returnBlock The block to be called with the user finishes their current workflow and returns back to this app.
*/
+ (void)showWorkspaceWithBlob:(INKBlob *)blob onReturn:(INKActionCallbackBlock)returnBlock;

/**
 Opens the Ink workspace with a late-binding blob and a return handler.
 
 This method is a combination of the capabilities of showWorkspaceWithBlob:onReturn: and showWorkspaceWithUTI:dynamicBlob:
 @see showWorkspaceWithBlob:onReturn:
 @see showWorkspaceWithUTI:dynamicBlob:
 
 @param UTI The Uniform Type Identifier of the blob, used to filter the aciton list.
 @param block The block that will be called on a background thread to retrieve the blob.
 @param returnBlock The block to be called with the user finishes their current workflow and returns back to this app.
 */
+ (void)showWorkspaceWithUTI:(NSString *)UTI dynamicBlob:(INKDynamicBlobBlock)block onReturn:(INKActionCallbackBlock)returnBlock;

@end
