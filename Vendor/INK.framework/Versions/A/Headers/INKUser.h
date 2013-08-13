//
//  INKUser.h
//  InkCore
//
//  Created by Liyan David Chang on 6/4/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface INKUser : NSObject

//The unique id assigned to this user by Ink, immutable
@property (nonatomic) NSString *InkId;

@property (nonatomic) NSString *email;
@property (nonatomic) NSNumber *user_id;

//A list of apps currently available on the device
@property (nonatomic) NSArray *apps;

+ (id)user;
+ (id)user:(NSString *)email;
+ (id)fetch:(NSString *)id;
+ (id)current;


@end
