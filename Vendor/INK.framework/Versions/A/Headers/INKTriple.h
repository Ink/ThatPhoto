//
//  INKTriple.h
//  InkCore
//
//  Created by Liyan David Chang on 5/25/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//
// A Triple contains all of the information about a blob, its location, creator,
// future and past actions. A triple is a first class object, and can be saved
// or passed around an application before triggered.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "INKBlob.h"
#import "INKAction.h"
#import "INKUser.h"

@interface INKTriple : NSObject

@property(nonatomic, strong) INKBlob *blob;
@property(nonatomic, strong) INKAction *action;
@property(nonatomic, strong) INKUser *user;
@property BOOL useInstallFlowProtocol;


// Instantiates a new triple for the given [Action, Blob, User] set.
+ (id)tripleWithAction:(INKAction *)action blob:(INKBlob *)blob user:(INKUser *)user;

@end
