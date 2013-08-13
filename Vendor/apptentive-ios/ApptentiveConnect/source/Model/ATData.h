//
//  ATData.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/29/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ATData : NSObject
+ (NSManagedObject *)newEntityNamed:(NSString *)entityName;
+ (NSArray *)findEntityNamed:(NSString *)entityName withPredicate:(NSPredicate *)predicate;
+ (NSManagedObject *)findEntityWithURI:(NSURL *)URL;
+ (NSUInteger)countEntityNamed:(NSString *)entityName withPredicate:(NSPredicate *)predicate;
+ (void)removeEntitiesNamed:(NSString *)entityName withPredicate:(NSPredicate *)predicate;
+ (void)deleteManagedObject:(NSManagedObject *)object;
+ (void)save;
+ (NSManagedObjectContext *)moc;
@end
