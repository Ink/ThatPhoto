//
//  ATFileAttachment.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATFileAttachment.h"
#import "ATBackend.h"
#import "ATFileMessage.h"
#import "ATUtilities.h"

@interface ATFileAttachment ()
- (NSString *)fullLocalPathForFilename:(NSString *)filename;
- (NSString *)filenameForThumbnailOfSize:(CGSize)size;
- (void)deleteSidecarIfNecessary;
@end

@implementation ATFileAttachment
@dynamic localPath;
@dynamic mimeType;
@dynamic name;
@dynamic source;
@dynamic transient;
@dynamic userVisible;
@dynamic fileMessage;

- (void)prepareForDeletion {
	[self setFileData:nil];
}

- (void)setFileData:(NSData *)data {
	[self deleteSidecarIfNecessary];
	self.localPath = nil;
	if (data) {
		self.localPath = [ATUtilities randomStringOfLength:20];
		if (![data writeToFile:[self fullLocalPath] atomically:YES]) {
			ATLogError(@"Unable to save file data to path: %@", [self fullLocalPath]);
			self.localPath = nil;
		}
		self.mimeType = @"application/octet-stream";
		self.name = [NSString stringWithString:self.localPath];
	}
}

- (void)setFileFromSourcePath:(NSString *)sourceFilename {
	[self deleteSidecarIfNecessary];
	self.localPath = nil;
	if (sourceFilename) {
		BOOL isDir = NO;
		NSFileManager *fm = [NSFileManager defaultManager];
		if (![fm fileExistsAtPath:sourceFilename isDirectory:&isDir] || isDir) {
			ATLogError(@"Either source attachment file doesn't exist or is directory: %@, %d", sourceFilename, isDir);
			return;
		}
		self.localPath = [ATUtilities randomStringOfLength:20];
		NSError *error = nil;
		if (![fm copyItemAtPath:sourceFilename toPath:[self fullLocalPath] error:&error]) {
			self.localPath = nil;
			ATLogError(@"Unable to write attachment to path: %@, %@", [self fullLocalPath], error);
			return;
		}
		self.mimeType = @"application/octet-stream";
		self.name = [sourceFilename lastPathComponent];
	}
}

- (NSString *)fullLocalPath {
	return [self fullLocalPathForFilename:self.localPath];
}

- (NSString *)fullLocalPathForFilename:(NSString *)filename {
	if (!filename) {
		return nil;
	}
	return [[[ATBackend sharedBackend] attachmentDirectoryPath] stringByAppendingPathComponent:filename];
}

- (NSString *)filenameForThumbnailOfSize:(CGSize)size {
	if (self.localPath == nil) {
		return nil;
	}
	return [NSString stringWithFormat:@"%@_%dx%d.thumbnail", self.localPath, (int)floor(size.width), (int)floor(size.height)];
}

- (void)deleteSidecarIfNecessary {
	if (self.localPath) {
		NSFileManager *fm = [NSFileManager defaultManager];
		NSString *fullPath = [self fullLocalPath];
		NSError *error = nil;
		BOOL isDir = NO;
		if (![fm fileExistsAtPath:fullPath isDirectory:&isDir] || isDir) {
			ATLogError(@"File attachment sidecar doesn't exist at path or is directory: %@, %d", fullPath, isDir);
			return;
		}
		if (![fm removeItemAtPath:fullPath error:&error]) {
			ATLogError(@"Error removing attachment at path: %@. %@", fullPath, error);
			return;
		}
		// Delete any thumbnails.
		NSArray *filenames = [fm contentsOfDirectoryAtPath:[[ATBackend sharedBackend] attachmentDirectoryPath] error:&error];
		if (!filenames) {
			ATLogError(@"Error listing attachments directory: %@", error);
		} else {
			for (NSString *filename in filenames) {
				if ([filename rangeOfString:self.localPath].location == 0) {
					NSString *thumbnailPath = [self fullLocalPathForFilename:filename];
					
					if (![fm removeItemAtPath:thumbnailPath error:&error]) {
						ATLogError(@"Error removing attachment thumbnail at path: %@. %@", thumbnailPath, error);
						continue;
					}
				}
			}
		}
		self.localPath = nil;
	}
}

- (UIImage *)thumbnailOfSize:(CGSize)size {
	NSString *filename = [self filenameForThumbnailOfSize:size];
	if (!filename) {
		return nil;
	}
	NSString *path = [self fullLocalPathForFilename:filename];
	UIImage *image = [UIImage imageWithContentsOfFile:path];
	if (image == nil) {
		image = [self createThumbnailOfSize:size];
	}
	return image;
}

- (UIImage *)createThumbnailOfSize:(CGSize)size {
	CGFloat scale = [[UIScreen mainScreen] scale];
	NSString *fullLocalPath = [self fullLocalPath];
	NSString *filename = [self filenameForThumbnailOfSize:size];
	NSString *fullThumbnailPath = [self fullLocalPathForFilename:filename];
    BOOL isFromITouchCamera = ([self.source intValue] == ATFileAttachmentSourceCamera);
	
	UIImage *image = [UIImage imageWithContentsOfFile:fullLocalPath];
	UIImage *thumb = [ATUtilities imageByScalingImage:image toSize:size scale:scale fromITouchCamera:isFromITouchCamera];
	[UIImagePNGRepresentation(thumb) writeToFile:fullThumbnailPath atomically:YES];
	return thumb;
}

//TODO: Should this be removed?
- (void)createThumbnailOfSize:(CGSize)size completion:(void (^)(void))completion {
	CGFloat scale = [[UIScreen mainScreen] scale];
	NSString *fullLocalPath = [self fullLocalPath];
	NSString *filename = [self filenameForThumbnailOfSize:size];
	NSString *fullThumbnailPath = [self fullLocalPathForFilename:filename];
    BOOL isFromITouchCamera = ([self.source intValue] == ATFileAttachmentSourceCamera);
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		UIImage *image = [UIImage imageWithContentsOfFile:fullLocalPath];
		UIImage *thumb = [ATUtilities imageByScalingImage:image toSize:size scale:scale fromITouchCamera:isFromITouchCamera];
		[UIImagePNGRepresentation(thumb) writeToFile:fullThumbnailPath atomically:YES];
		dispatch_sync(dispatch_get_main_queue(), ^{
			completion();
		});
	});
}
@end
