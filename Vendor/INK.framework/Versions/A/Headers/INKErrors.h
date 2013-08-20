//
//  INKErrors.h
//  INK
//
//  Created by Brett van Zuiden on 8/11/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <Foundation/Foundation.h>

// kINKCoreErrorDomain indicates that thrower of an INK Error
FOUNDATION_EXPORT NSString* const kINKCoreErrorDomain;

// kINKActionNotSupported indicates that an app has received an action that it has no handler for.
FOUNDATION_EXPORT uint32_t const  kINKActionNotSupported;

// kINKInvalidURLFormat indicates that an app has received an action with an unrecognized format.
// You should never see this error.
FOUNDATION_EXPORT uint32_t const  kINKInvalidURLFormat;

@interface INKErrors : NSObject

@end
