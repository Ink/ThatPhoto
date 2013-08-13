//
//  ApptentiveMigrationTests.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMigrationTests.h"
#import "ATDataManager.h"

@implementation ApptentiveMigrationTests
- (void)performTestWithStoreName:(NSString *)name {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSURL *storeURL = [bundle URLForResource:name withExtension:@"sqlite"];

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *path = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	
	ATDataManager *dataManager = [[ATDataManager alloc] initWithModelName:@"ATDataModel" inBundle:bundle storagePath:path];

	NSError *error = nil;
	[fileManager removeItemAtURL:[dataManager persistentStoreURL] error:nil];
	if (![fileManager copyItemAtURL:storeURL toURL:[dataManager persistentStoreURL] error:&error]) {
		STFail(@"Unable to copy item: %@", error);
		return;
	}

	STAssertNotNil([dataManager persistentStoreCoordinator], @"Shouldn't be nil");
}

- (void)testV1Upgrade {
	// For example, we will do the following with a copy of an old data model.
	//[self performTestWithStoreName:@"ExampleModel v1"];
}
@end
