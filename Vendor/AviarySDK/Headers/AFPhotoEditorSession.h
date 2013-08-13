//
//  AFPhotoEditorSession.h
//  AviarySDK
//
//  Created by Cameron Spickert on 3/6/12.
//  Copyright (c) 2012 Aviary, Inc. All rights reserved.
//

@class AFPhotoEditorContext;

extern NSString *const AFPhotoEditorSessionCancelledNotification;

/**
 Photo Editor Sessions are obtained from instances of AFPhotoEditorController through the `session` property. A session tracks and stores all user 
 actions taken in the AFPhotoEditorController it was obtained from.
 */
@interface AFPhotoEditorSession : NSObject

/** Specifies whether the session is still open.
 
 Value will be TRUE if the generating AFPhotoEditorController has not been dismissed.
 */
@property (nonatomic, assign, readonly, getter=isOpen) BOOL open;
/** Specifies if the session has been cancelled.
 
 Value will be TRUE if the user has invalided all actions by pressing "Cancel" in the generating AFPhotoEditorController.
 */
@property (nonatomic, assign, readonly, getter=isCancelled) BOOL cancelled;
/** Specifies whether the session contains any actions.
 
 Value will be TRUE if the user has modified the image in the generating AFPhotoEditorController.
 */
@property (nonatomic, assign, readonly, getter=isModified) BOOL modified;

/**
 Generates a new AFPhotoEditorContext. 
 
 Contexts may be used to replay the session's actions on images. See AFPhotoEditorContext for more information.
 
 @param image The image to generate the context with.
 @return A new photo editor context.
 
 @warning Calling this method from any thread other in the main thread may result in undefined behavior.
 */
- (AFPhotoEditorContext *)createContextWithImage:(UIImage *)image;

/**
 Generates a new AFPhotoEditorContext with a maximum size.
 
 @param image The image to generate the context with.
 @param size The maximum size the context should render the image at.
 @return A new photo editor context that can be used to replay the session's actions. See AFPhotoEditorContext.
 
 @warning Calling this method from any thread other in the main thread may result in undefined behavior.
 */
- (AFPhotoEditorContext *)createContextWithImage:(UIImage *)image maxSize:(CGSize)size;

/**
 Deprecated. 
 
 Please use `-createContextWithImage: instead.
 */
- (AFPhotoEditorContext *)createContext DEPRECATED_ATTRIBUTE;

/**
  Deprecated. 
 
  Please use `-createContextWithImage:maxSize:` instead.
 
  @param size The size of the context.
 */
- (AFPhotoEditorContext *)createContextWithSize:(CGSize)size DEPRECATED_ATTRIBUTE;

@end
