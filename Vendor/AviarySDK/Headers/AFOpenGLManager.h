//
//  Header.h
//  AviarySDK
//
//  Created by Jack Sisson on 2/12/13.
//  Copyright (c) 2013 Aviary, Inc. All rights reserved.
//


/**
 Aviary products process images using OpenGL when possible. Before this happens, some OpenGL must be loaded, which takes some time. This class
 provides a few class methods to help control that loading and unloading behavior. 
 
 Developers may call beginOpenGLLoad to begin OpenGL loading before launching any Aviary products. This will reduce the already very fast load time
 down to basically nothing. 
 
 Once OpenGL data is loaded, Aviary's default behavior is to retain that data for the lifetime of the app. This allows
 Aviary products to provide the best user experience possible. The data is fairly small in size, and it resides in GPU memory, so you likely won't 
 see it in your profiler.
 
 Should you have a need to release the OpenGL data, the requestOpenGLDataPurge method sets an internal flag that causes OpenGL data to be unloaded
 when it is no longer needed. If for whatever reason you change your mind about the unload, cancelOpenGLDataPurgeRequest will cancel the request if 
 data has not already been unloaded. 
 
 Calls to requestOpenGLDataPurge only apply to the currently loaded OpenGL data, so if you wish to always purge, you would need to call 
 requestOpenGLDataPurge every time you use an Aviary product. In this case a better solution would be to set the editor.purgesGPUMemory customization 
 option to YES, which causes Open GL data to be purged whenever possible. This option defaults to NO in order to optimize Aviary performance.
 */
@interface AFOpenGLManager : NSObject

/**
 If necessary OpenGL data has not been loaded, this call begins the OpenGL load process.
 */
+ (void)beginOpenGLLoad;

/**
 Sets a flag that tells the current OpenGL data to be unloaded when possible.
 
 Calls to requestOpenGLDataPurge only apply to the currently loaded OpenGL data, so if you wish to always purge, you would need to call
 requestOpenGLDataPurge every time you use an Aviary product. In this case a better solution would be to set the editor.purgesGPUMemory customization
 option to YES, which causes Open GL data to be purged whenever possible. This option defaults to NO in order to optimize Aviary performance.
 */
+ (void)requestOpenGLDataPurge;

/**
 If a call has been made to requestOpenGLDataPurge and OpenGL data has not yet been unloaded, this method causes the request to be cancelled.
 */
+ (void)cancelOpenGLDataPurgeRequest;

@end