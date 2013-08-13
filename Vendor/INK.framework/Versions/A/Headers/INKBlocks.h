//
//  INKBlocks.h
//  INK
//
//  Created by Brett van Zuiden on 8/11/13.
//  Copyright (c) 2013 Computer Club. All rights reserved.
//

#ifndef INK_INKBlocks_h
#define INK_INKBlocks_h

#import "INKBlob.h"
#import "INKAction.h"

typedef void (^INKActionCallbackBlock)(INKBlob *result, INKAction*action, NSError *error);
typedef INKBlob* (^INKDynamicBlobBlock)(void);

#endif
