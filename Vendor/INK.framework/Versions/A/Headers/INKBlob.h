//
//  INKBlob.h
//  InkCore
//
//  Created by Jonathan Uy on 5/25/13.
//  Copyright (c) 2013 Computer Club. All rights reserved.
//
//  Blobs can be created from local binary data, publically available urls,
//  device file:// urls, and credential­location pairs for cloud storage services.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SocketIO.h"

@interface INKBlob : NSObject <NSCoding>

//The name of the file
@property(nonatomic, strong) NSString *filename;

// Mimetype of a file
@property(nonatomic, strong) NSString *uti;

// Size of the blob in bytes
@property NSUInteger size;

// When file blob created, ISO 8601 format
@property(nonatomic, strong) NSString *createdAt;

// When file was last updated, ISO 8601 format
@property(nonatomic, strong) NSString *lastUpdated;

// ...
@property(nonatomic, strong) NSData *data;

// Creates a blob from binary data
+ (INKBlob*)blobFromData:(NSData *)data;

// Creates a blob from a publically available URL (will use the User­Agent “Ink iOS v1”)
+ (INKBlob*)blobFromUrl:(NSURL *)source;

// Creates a blob from a file:// url pointing to a file on the device.
+ (INKBlob*)blobFromLocalFile:(NSURL *)source;

@end
