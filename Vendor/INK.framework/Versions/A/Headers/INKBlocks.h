//
//  INKBlocks.h
//  INK
//
//  Created by Brett van Zuiden on 8/11/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#ifndef INK_INKBlocks_h
#define INK_INKBlocks_h

#import "INKBlob.h"
#import "INKAction.h"

// INKActionCallbackBlock is the method signature for recieving a callback from an INK action.
// When you set up an INK action with a callback, give an INKActionCallbackBlock
typedef void (^INKActionCallbackBlock)(INKBlob *result, INKAction*action, NSError *error);

// When you must provide a blob dynamically, use an INKDynamicBlobBlock
// An INKDynamicBlobBlock takes no arguments and returns an INKBlob that
// has been filled with all needed data and metadata.
typedef INKBlob* (^INKDynamicBlobBlock)(void);

#endif
