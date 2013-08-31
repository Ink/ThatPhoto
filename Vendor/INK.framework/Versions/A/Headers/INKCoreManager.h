//
//  INKActionManager.h
//  INK
//
//  Created by Brett van Zuiden on 7/28/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "INKAction.h"
#import "INKApp.h"
#import "INKTriple.h"
#import "INKBlocks.h"
#import "INKErrors.h"

@interface INKCoreManager : NSObject

@property (strong, atomic) NSString *callbackURLScheme;
@property (readonly,atomic) INKApp *callingApp;
@property (readonly,atomic) NSString *currentRequestId;
@property (readonly, nonatomic) INKBlob *currentBlob;
@property (readonly, atomic) NSInteger blobChecksum;

// RCOH THIS IS REQUIRED FOR BACKWARDS COMPATIBILITY. REMOVO PRONTO.
@property (copy,atomic) INKActionCallbackBlock ios6ReturnBlock;
@property (strong,atomic) INKAction *ios6Action;

//singleton
+ (id) sharedManager;

// Receive actions by registering the app to listen to specific actions. The selector
// will be called upon receiving the action. The selector should support receiving
// an INKBlob object as a parameter.
- (void)registerAction:(INKAction *)action withTarget:(NSObject *)target selector:(SEL)selector;

- (void)registerAction:(INKAction *)action withBlock:(INKActionCallbackBlock)actionCallback;


//New trigger DX
- (BOOL)executeTriple:(INKTriple *)triple;
- (BOOL)executeTriple:(INKTriple *)triple onReturn:(INKActionCallbackBlock)block;

// Use for receiving apps to return data back to the originating app
- (void)return;
- (void)returnBlob:(INKBlob *)blob;
- (void)returnWithError:(NSError *)error;

// Returns whether app was launched via ink and this should return in the corresponding way
- (BOOL)appShouldReturn;
- (BOOL)canPerformAction:(INKAction*)action;

//Low-level inter-app communication stuff
- (BOOL)handleOpenURL:(NSURL *)url;
- (NSURL*)constructIACURL:(INKAction*)action;
- (NSURL*)constructReturnIACURL:(INKAction*)action requestId:(NSString*)requestId;
- (NSURL *)constructIOS6ReturnURL:(INKAction*)action withRequestId:(NSString *)requestId;
- (NSURL *)constructIOS6OpenURL: (INKAction *) action withRequestId:(NSString *)requestId;

- (void)registerForRequest:(NSString*)requestId returnHandler:(INKActionCallbackBlock)handler;
- (NSString*)createRequestId;

- (void) clearCallingApp;

//A fallback method for upgrade paths
- (void) registerAdditionalURLScheme:(NSString*) oldScheme;

@end
