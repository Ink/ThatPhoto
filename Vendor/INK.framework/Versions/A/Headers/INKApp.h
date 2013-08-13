//
//  INKApp.h
//  INK
//
//  Created by Brett van Zuiden on 8/11/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface INKApp : NSObject <NSCopying>

@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *bundleId;
@property(nonatomic, strong) NSString *scheme;
@property(nonatomic, strong) NSString *appstoreURL;
@property(nonatomic, strong) NSString *iconURL;

+ (INKApp *) currentApp;

+ (INKApp *) appWithScheme:(NSString*)scheme;
+ (INKApp *) appWithScheme:(NSString*)scheme name:(NSString*)name;

@end
