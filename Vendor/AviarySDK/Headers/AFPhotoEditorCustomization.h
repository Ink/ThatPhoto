//
//  AFOption.h
//  AFOptions
//
//  Created by Michael Vitrano on 9/5/12.
//  Copyright (c) 2012 Aviary. All rights reserved.
//

/** @defgroup AFPhotoEditorControllerOptions AFPhotoEditorController Option Dictionary Keys */

/** @addtogroup AFPhotoEditorControllerOptions
 @{
 */

/**
 This key allows developers to customize the visibility of, and order in which
 tools appear in the SDK interface. A valid value for this key is a NSArray
 containing NSString instances whose values match the constants below.
 */
extern NSString *const kAFPhotoEditorControllerToolsKey;

extern NSString *const kAFEnhance;     /* Enhance */
extern NSString *const kAFEffects;     /* Effects */
extern NSString *const kAFStickers;    /* Stickers */
extern NSString *const kAFOrientation; /* Orientation */
extern NSString *const kAFCrop;        /* Crop */
extern NSString *const kAFAdjustments;  /* Adjustments */
extern NSString *const kAFSharpness;   /* Sharpness */
extern NSString *const kAFDraw;        /* Draw */
extern NSString *const kAFText;        /* Text */
extern NSString *const kAFRedeye;      /* Redeye */
extern NSString *const kAFWhiten;      /* Whiten */
extern NSString *const kAFBlemish;     /* Blemish */
extern NSString *const kAFMeme;        /* Meme */
extern NSString *const kAFFrames;      /* Frames */
extern NSString *const kAFFocus;       /* TiltShift */
extern NSString *const kAFSplash;      /* ColorSplash */


/**
 Use this key to define the interface orientations you want to allow in
 `-shouldAutorotateToInterfaceOrientation`. The value for this key should be
 a NSArray of NSNumber objects wrapping UIInterfaceOrientation values. For
 example, if you only want to support the portrait orientation, set the
 following value for this key: `[NSArray arrayWithObject:[NSNumber
 numberWithUnsignedInt:UIInterfaceOrientationPortrait]]`.
 */
extern NSString *const kAFPhotoEditorControllerSupportedOrientationsKey;

/**
 Use this key to define the background color for the photo editor (behind the
 image being edited). The value for this key should be a UIColor object. Any
 color space supported by UIKit should work, including patterns created with
 `+colorWithPatternImage:`. Use `[UIColor clearColor]` to make the background
 transparent.
 */
extern NSString *const kAFPhotoEditorControllerBackgroundColorKey;

extern NSString *const kAFLeftNavigationTitlePresetCancel; /* Cancel */
extern NSString *const kAFLeftNavigationTitlePresetBack;   /* Back */
extern NSString *const kAFLeftNavigationTitlePresetExit;   /* Exit */

extern NSString *const kAFRightNavigationTitlePresetDone;  /* Done */
extern NSString *const kAFRightNavigationTitlePresetSave;  /* Save */
extern NSString *const kAFRightNavigationTitlePresetNext;  /* Next */
extern NSString *const kAFRightNavigationTitlePresetSend;  /* Send */

extern NSString *const kAFCropPresetName;   /* Name */
extern NSString *const kAFCropPresetWidth;  /* Width */
extern NSString *const kAFCropPresetHeight; /* Height */

extern NSString *const kAFTextBorderColors; /* Text Tool Text Border Colors */
extern NSString *const kAFTextFillColors;   /* Text Tool Text Fill Colors */

/** @} */


/**
 This class provides a powerful interface for configuring an AFPhotoEditorController's appearance and behavior. While changing values after presenting an AFPhotoEditorController instance is possible, it is strongly recommended that you make all necessary calls to AFPhotoEditorCustomization *before* editor presentation. Example of usage can be found in the Aviary iOS SDK Customization Guide.
 */
@interface AFPhotoEditorCustomization : NSObject

/** 
 Enables or disables in-app purchases in the editor.
 
 By default, in-app purchases are disabled. See the Aviary In-App Purchase guide for more information on setting up in app purchases.
 
 @param enableIAP YES enables IAPs, NO disables them. 
 */
+ (void)enableInAppPurchases:(BOOL)enableIAP;

/** 
 Configures the editor to point at the Premium Content Network's staging environment.
 
 By default, the editor points at the production environment. Call this method with YES before editor to launch to view the content in the Premium Content Network staging environment.
 
 @param usePCNStagingEnvironment YES points the editor to staging, no points it to production. 
 */
+ (void)usePCNStagingEnvironment:(BOOL)usePCNStagingEnvironment;

/** 
 Configures the editor to free GPU memory when possible.
 
 By default, Aviary keeps a small number of OpenGL objects loaded to optimize launches of Aviary products. Set this key to YES purge GPU memory when possible.
 
 @param purgeGPUMemory YES purges GPU memory when possible, NO retains it. 
 */
+ (void)purgeGPUMemoryWhenPossible:(BOOL)purgeGPUMemory;

/** 
 Sets the text of the editor's left navigation bar button. 
 
 Attempting to set any string besides one of the kAFLeftNavigationTitlePresets will have no effect.
 
 @param leftNavigationBarButtonTitle An NSString value represented by one of the three kAFLeftNavigationTitlePreset keys.*/
+ (void)setLeftNavigationBarButtonTitle:(NSString *)leftNavigationBarButtonTitle;

/**
 Sets the text of the editor's right navigation bar button.
 
 Attempting to set any string besides one of the kAFRightNavigationTitlePresets will have no effect.
 
 @param rightNavigationBarButtonTitle An NSString value represented by one of the three kAFRightNavigationTitlePreset keys.*/
+ (void)setRightNavigationBarButtonTitle:(NSString *)rightNavigationBarButtonTitle;

/** 
 Sets the type and order of tools to be presented by the editor.
 
 The valid tool keys are:
 
    kAFEnhance
    kAFEffects
    kAFStickers
    kAFOrientation
    kAFCrop
    kAFAdjustments
    kAFSharpness
    kAFDraw
    kAFText
    kAFRedeye
    kAFWhiten
    kAFBlemish
    kAFMeme
    kAFFrames;
    kAFFocus

 @param toolOrder An NSArray containing NSString values represented by one of the tool keys*/
+ (void)setToolOrder:(NSArray *)toolOrder;

/**
 Configures the editor to use localization or not.
 
 By default, Aviary enables localization.
 
 @param disableLocalization YES disables localization, NO leaves it enabled.*/
+ (void)disableLocalization:(BOOL)disableLocalization;

/**
 Configures the orientations the editor can have on the iPad form factor.
 
 On the iPhone form factor, orientation is always portrait.
 
 @param supportedOrientations An NSArray containing NSNumbers each representing a valid UIInterfaceOrientation.*/
+ (void)setSupportedIpadOrientations:(NSArray *)supportedOrientations;

/**
 Enables or disables the custom crop size.

 The Custom crop preset does not constrain the crop area to any specific aspect ratio. By default, custom crop size is enabled.
 
 @param cropToolEnableCustom YES enables the custom crop size, NO disables it.*/
+ (void)setCropToolCustomEnabled:(BOOL)cropToolEnableCustom;

/**
 Enables or disables the custom crop size.
 
 The Original crop preset constrains the crop area to photo's original aspect ratio. By default, original crop size is enabled.
 
 @param cropToolEnableOriginal YES enables the original crop size, NO disables it.*/
+ (void)setCropToolOriginalEnabled:(BOOL)cropToolEnableOriginal;

/**
 Enables or disables the invertability of crop sizes.
 
 By default, inversion is enabled. Presets with names, i.e. Square, are not invertible, regardless of whether inversion is enabled.
 
 @param cropToolEnableInvert YES enables the crop size inversion, NO disables it.*/
+ (void)setCropToolInvertEnabled:(BOOL)cropToolEnableInvert;

/** Sets the availability and order of crop preset options.

 The dictionaries should be of the form @{kAFCropPresetName: <NSString representing the display name>, kAFCropPresetWidth: <NSNumber representing width>, kAFCropPresetHeight: <NSNumber representing height>}. When the corresponding option is selected, the crop box will be constrained to a kAFCropPresetWidth:kAFCropPresetHeight aspect ratio. 
 
 If Original and/or Custom options are enabled, then they will precede the presets defined here. If no crop tool presets are set, the default options are Square, 3x2, 5x3, 4x3, 6x4, and 7x5. 
 
 @param cropToolPresets An array of dictionaries. The dictionaries should 
 */
+ (void)setCropToolPresets:(NSArray *)cropToolPresets;

/** 
 This property sets the width of the crop preset selection cells.
 
 @param cropToolCellWidth The width of the crop option cell in points.
 */
+ (void)setCropToolCellWidth:(float)cropToolCellWidth;


@end
