//
//  INKBlob.h
//  InkCore
//
//  Created by Liyan David Chang on 5/25/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//
//  Blobs can be created from local binary data, and device file:// urls.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface INKBlob : NSObject <NSCoding>

//The name of the file
@property(nonatomic, strong) NSString *filename;

// Mimetype of a file
@property(nonatomic, strong) NSString *uti;

// Size of the blob in bytes
@property(nonatomic) NSUInteger size;

// When file blob created, ISO 8601 format
@property(nonatomic, strong) NSString *createdAt;

// When file was last updated, ISO 8601 format
@property(nonatomic, strong) NSString *lastUpdated;

// ...
@property(nonatomic, strong) NSData *data;

// Creates a blob from binary data
+ (INKBlob*)blobFromData:(NSData *)data;

// Creates a blob from a file:// url pointing to a file on the device.
+ (INKBlob*)blobFromLocalFile:(NSURL *)source;

- (NSInteger) crcChecksum;

@end
