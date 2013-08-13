//
//  INKAction.h
//  InkCore
//
//  Created by Liyan David Chang on 5/25/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//
//  A specific app-action pair to perform
//

#import <Foundation/Foundation.h>
#import "INKBlob.h"
#import "INKApp.h"

@interface INKAction : NSObject <NSCopying>

//Provided by the server, don't touch
@property(nonatomic) NSString *uuid;

//Name of the action
@property(nonatomic) NSString *name;
// Name of Action Type. Action types are categories of actions that can be performed by a number of different applications. They are specific to UTI. Ex: Sign, Annotate, Edit, Convert, Crop
@property(nonatomic, strong) NSString *type;

// List of supported UTI's for a given action, as UTType objects
@property(nonatomic, strong) NSArray *supportedUTIs;

//Parent app
@property(nonatomic, strong) INKApp *app;

+ (id)action:(NSString *)name type:(NSString *)type;
+ (id)action:(NSString *)name type:(NSString *)type app:(INKApp *)app;

- (BOOL) isReturnAction;
- (BOOL) isErrorAction;

@end
