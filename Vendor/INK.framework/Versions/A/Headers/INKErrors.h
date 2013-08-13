//
//  INKErrors.h
//  INK
//
//  Created by Brett van Zuiden on 8/11/13.
//  Copyright (c) 2013 Computer Club. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString* const kINKCoreErrorDomain;
FOUNDATION_EXPORT uint32_t const  kINKActionNotSupported;
FOUNDATION_EXPORT uint32_t const  kINKInvalidURLFormat;

@interface INKErrors : NSObject

@end
