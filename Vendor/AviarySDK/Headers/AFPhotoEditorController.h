//
//  AFPhotoEditorController.h
//  AviarySDK
//
//  Copyright (c) 2012 Aviary, Inc. All rights reserved.
//

#import "AFPhotoEditorControllerOptions.h"
#import "AFPhotoEditorSession.h"
#import "AFPhotoEditorContext.h"
#import "AFOpenGLManager.h"

@class AFPhotoEditorController;

/**
 Implement this protocol to be notified when the user is done using the editor.
 You are responsible for dismissing the editor when you (and/or your user) are
 finished with it.
 */
@protocol AFPhotoEditorControllerDelegate <NSObject>
@optional

/**
 Implement this method to be notified when the user presses the "Done" button.
 
 The edited image is passed via the `image` parameter. The size of this image may 
 not be equivalent to the size of the input image, if the input image is larger 
 than the maximum image size supported by the SDK. Currently (as of 9/19/12), the 
 maximum size is {1024.0, 1024.0} pixels on all devices.

 @param editor The photo editor controller.
 @param image The edited image.


 */
- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image;

/**
 Implement this method to be notified when the user presses the "Cancel" button.

 @param editor The photo editor controller.
 */
- (void)photoEditorCanceled:(AFPhotoEditorController *)editor;

@end

/**
 This class encapsulates the Aviary SDK's photo editor. Present this view controller to provide the user with a fast
 and powerful image editor. Be sure that you don't forget to set the delegate property 
 to an object that conforms to the AFPhotoEditorControllerDelegate protocol.
 */
@interface AFPhotoEditorController : UIViewController

/**
 The photo editor's delegate. 
 */
@property (nonatomic, weak) id<AFPhotoEditorControllerDelegate> delegate;

/**
 An AFPhotoEditorSession instance that tracks user actions within the photo editor. This can be used for high-resolution
 processing.
 */
@property (nonatomic, strong, readonly) AFPhotoEditorSession *session;

/**
 Deprecated
 
 This method was previously used initialize the photo editor controller with an image along
 with configuration options. Now, please initialize with initWithImage: and use 
 AFPhotoEditorCustomization to configure the options.

 @param image The image to edit.
 @param options (optional) Additional configuration options. See
 AFPhotoEditorControllerOptions for more information.

 */
- (id)initWithImage:(UIImage *)image options:(NSDictionary *)options DEPRECATED_ATTRIBUTE;

/**
 Initialize the photo editor controller with an image.

 @param image The image to edit.
 */
- (id)initWithImage:(UIImage *)image;

/**
 @return The SDK version number.
 */
+ (NSString *)versionString;

@end
