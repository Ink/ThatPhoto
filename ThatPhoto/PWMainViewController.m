//
//  AFSDKDemoViewController.m
//  AviaryDemo-iOS
//
//  Created by Michael Vitrano on 1/23/13.
//  Copyright (c) 2013 Aviary. All rights reserved.
//

#import "PWMainViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import "AFPhotoEditorController.h"
#import "AFPhotoEditorCustomization.h"
#import "AFOpenGLManager.h"
#import "ATConnect.h"

#import <INK/Ink.h>

#define kAFSDKDemoImageViewInset 10.0f
#define kAFSDKDemoBorderAspectRatioPortrait 3.0f/4.0f
#define kAFSDKDemoBorderAspectRatioLandscape 4.0f/3.0f

@interface PWMainViewController () <UINavigationControllerDelegate, AFPhotoEditorControllerDelegate, UIPopoverControllerDelegate, iCarouselDataSource, iCarouselDelegate>

@property (strong, nonatomic) UIImageView * imagePreviewView;
@property (nonatomic, strong) UIView * borderView;
@property (nonatomic, strong) UIPopoverController * popover;
@property (nonatomic, assign) BOOL shouldReleasePopover;

@property (nonatomic, strong) ALAssetsLibrary * assetLibrary;
@property (nonatomic, strong) NSMutableArray * sessions;

@end

@implementation PWMainViewController {
    UIImage *currentImage;
    NSMutableDictionary *photos;
    NSMutableArray *photoIndexOrder;
    UIView *raisedView;
}

@synthesize carousel, albums, albumName, albumSlider;

#pragma mark - View Controller Methods

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        albums = [NSArray array];
        //Dictionary of NSIndexPath > ALAsset
        photos = [NSMutableDictionary dictionary];
        //Ordering of indexpaths
        photoIndexOrder = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Allocate Asset Library
    ALAssetsLibrary * assetLibrary = [[ALAssetsLibrary alloc] init];
    [self setAssetLibrary:assetLibrary];
    
    // Allocate Sessions Array
    NSMutableArray * sessions = [NSMutableArray new];
    [self setSessions:sessions];
    
    // Start the Aviary Editor OpenGL Load
    [AFOpenGLManager beginOpenGLLoad];
    
    [self setupView];
    
    //Register for the app switch focus event. Reload the data so things show up immeadiately.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadPhotoData) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self loadPhotoData];
}

- (void)loadPhotoData {
    NSMutableArray *albumCollector = [[NSMutableArray alloc] initWithCapacity:1];
    //Holding a place for camera roll
    [albumCollector setObject:[[NSObject alloc] init] atIndexedSubscript:0];
    ALAssetsLibrary *al = self.assetLibrary;
    
    [al enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:
     ^(ALAssetsGroup *group, BOOL *stop) {
         if (group == nil) {
             return;
         }
         
         NSString *sGroupPropertyName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
         NSUInteger nType = [[group valueForProperty:ALAssetsGroupPropertyType] intValue];
         
         [group setAssetsFilter:[ALAssetsFilter allPhotos]];
         
         int groupIndex = 0;
         if ([[sGroupPropertyName lowercaseString] isEqualToString:@"camera roll"] && nType == ALAssetsGroupSavedPhotos) {
             [albumCollector setObject:group atIndexedSubscript:0]; //already held
         }
         else {
             [albumCollector addObject:group];
             groupIndex = [albumCollector count] - 1;
         }
         NSLog(@"Album name: %@", [group valueForProperty:ALAssetsGroupPropertyName]);
         
         [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
             if (result == nil) {
                 return;
             }
             NSUInteger indexArr[] = {groupIndex, index};
             
             NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:indexArr length:2];
             [photos setObject:result forKey:indexPath];
             if (groupIndex == 0) {
                 [photoIndexOrder insertObject:indexPath atIndex:0]; //camera roll at the beginning, reverse order
             } else {
                 [photoIndexOrder addObject:indexPath];
             }
         }];
         
         [self setAlbums:albumCollector];
         [self reloadCarousel];
     } failureBlock:^(NSError *error) {
         NSLog(@"There was an error with the ALAssetLibrary: %@", error);
     }
     ];
}

- (void) reloadCarousel {
    //refresh count
    [carousel reloadData];
}

#pragma mark - Photo Editor Launch Methods

- (void) launchEditorWithBlob:(INKBlob *)blob action:(INKAction*)action error:(NSError*)error
{
    [AFPhotoEditorCustomization setLeftNavigationBarButtonTitle:kAFLeftNavigationTitlePresetExit];
    [AFPhotoEditorCustomization setRightNavigationBarButtonTitle:kAFRightNavigationTitlePresetDone];

    UIImage *photo = [UIImage imageWithData:blob.data];
    [self launchPhotoEditorWithImage:photo highResolutionImage:nil];
}

- (void) launchEditorWithAsset:(ALAsset *)asset
{
    [AFPhotoEditorCustomization setLeftNavigationBarButtonTitle:kAFLeftNavigationTitlePresetCancel];
    [AFPhotoEditorCustomization setRightNavigationBarButtonTitle:kAFRightNavigationTitlePresetSave];
    UIImage * editingResImage = [self editingResImageForAsset:asset];
    UIImage * highResImage = [self highResImageForAsset:asset];
    
    [self launchPhotoEditorWithImage:editingResImage highResolutionImage:highResImage];
}

- (void) saveBlob:(INKBlob *)blob action:(INKAction*)action error:(NSError*)error
{
    UIImage *image = [UIImage imageWithData:blob.data];
    [self saveNewUIImage:image];
}

- (void) saveNewUIImage:(UIImage*) image{
    [self.carousel scrollToItemAtIndex:0 animated:NO];
    ALAssetsGroup *album = [albums objectAtIndex:0]; //photo roll
    
    [self.assetLibrary writeImageToSavedPhotosAlbum:[image CGImage] metadata:[NSDictionary dictionary] completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error.code == 0) {
            NSLog(@"saved image completed:\nurl: %@", assetURL);
            
            // try to get the asset
            [self.assetLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                NSUInteger indexArr[] = {0, [album numberOfAssets]};
                NSIndexPath *newIndex = [NSIndexPath indexPathWithIndexes:indexArr length:2];
                [photoIndexOrder insertObject:newIndex atIndex:0];
                [photos setObject:asset forKey:newIndex];
                [self.carousel insertItemAtIndex:0 animated:YES];
                [album addAsset:asset];
            } failureBlock:^(NSError *error) {
            }];
        }
    }];
}

#pragma mark - Photo Editor Creation and Presentation
- (void) launchPhotoEditorWithImage:(UIImage *)editingResImage highResolutionImage:(UIImage *)highResImage
{
    currentImage = highResImage != nil ? highResImage : editingResImage;
    
    // Initialize the photo editor and set its delegate
    AFPhotoEditorController * photoEditor = [[AFPhotoEditorController alloc] initWithImage:editingResImage];
    [photoEditor setDelegate:self];
    
    // Customize the editor's apperance. The customization options really only need to be set once in this case since they are never changing, so we used dispatch once here.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setPhotoEditorCustomizationOptions];
    });
    
    // If a high res image is passed, create the high res context with the image and the photo editor.
    if (highResImage) {
        [self setupHighResContextForPhotoEditor:photoEditor withImage:highResImage];
    }
    
    // Present the photo editor.
    [self presentViewController:photoEditor animated:NO completion:nil];
}

- (IBAction)feedbackButtonPressed:(id)sender {
    ATConnect *connection = [ATConnect sharedConnection];
    [connection presentMessageCenterFromViewController:self];
}

- (void) setupHighResContextForPhotoEditor:(AFPhotoEditorController *)photoEditor withImage:(UIImage *)highResImage
{
    // Capture a reference to the editor's session, which internally tracks user actions on a photo.
    __block AFPhotoEditorSession *session = [photoEditor session];
    
    // Add the session to our sessions array. We need to retain the session until all contexts we create from it are finished rendering.
    [[self sessions] addObject:session];
    
    // Create a context from the session with the high res image.
    AFPhotoEditorContext *context = [session createContextWithImage:highResImage];
    
    __block PWMainViewController * blockSelf = self;
    
    // Call render on the context. The render will asynchronously apply all changes made in the session (and therefore editor)
    // to the context's image. It will not complete until some point after the session closes (i.e. the editor hits done or
    // cancel in the editor). When rendering does complete, the completion block will be called with the result image if changes
    // were made to it, or `nil` if no changes were made. In this case, we write the image to the user's photo album, and release
    // our reference to the session. 
    [context render:^(UIImage *result) {
        if (result) {
            UIImageWriteToSavedPhotosAlbum(result, nil, nil, NULL);
        }
        
        [[blockSelf sessions] removeObject:session];
        
        blockSelf = nil;
        session = nil;
        
    }];
}

#pragma Photo Editor Delegate Methods

// This is called when the user taps "Done" in the photo editor. 
- (void) photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image
{
    BOOL *displayInk = [Ink appShouldReturn] && image;
    //If showing ink, don't animate
    [self dismissViewControllerAnimated:!displayInk completion:^{
        if (displayInk) {
            //Wait for the view controller to go away
            NSData *imageData = UIImagePNGRepresentation(image);
            INKBlob *blob = [INKBlob blobFromData:imageData];
            blob.filename = @"EditedPhoto.png";
            blob.uti = @"public.png";
            [Ink showWorkspaceWithBlob:blob];
        } else {
            [self saveNewUIImage:image];
        }
    }];
}

// This is called when the user taps "Cancel" in the photo editor.
- (void) photoEditorCanceled:(AFPhotoEditorController *)editor
{
    BOOL *displayInk = [Ink appShouldReturn] && currentImage;
    [self dismissViewControllerAnimated:!displayInk completion:^{
        if (displayInk) {
            NSData *imageData = UIImagePNGRepresentation(currentImage);
            INKBlob *blob = [INKBlob blobFromData:imageData];
            blob.filename = @"EditedPhoto.png";
            blob.uti = @"public.png";
            [Ink showWorkspaceWithBlob:blob];
        }
    }];
}

#pragma mark - Photo Editor Customization

- (void) setPhotoEditorCustomizationOptions
{
    // Set Tool Order
    NSArray * toolOrder = @[kAFEffects, kAFFocus, kAFFrames, kAFStickers, kAFEnhance, kAFOrientation, kAFCrop, kAFAdjustments, kAFSplash, kAFDraw, kAFText, kAFRedeye, kAFWhiten, kAFBlemish, kAFMeme];
    [AFPhotoEditorCustomization setToolOrder:toolOrder];
    
    // Set Custom Crop Sizes
    [AFPhotoEditorCustomization setCropToolOriginalEnabled:NO];
    [AFPhotoEditorCustomization setCropToolCustomEnabled:YES];
    NSDictionary * fourBySix = @{kAFCropPresetHeight : @(4.0f), kAFCropPresetWidth : @(6.0f)};
    NSDictionary * fiveBySeven = @{kAFCropPresetHeight : @(5.0f), kAFCropPresetWidth : @(7.0f)};
    NSDictionary * square = @{kAFCropPresetName: @"Square", kAFCropPresetHeight : @(1.0f), kAFCropPresetWidth : @(1.0f)};
    [AFPhotoEditorCustomization setCropToolPresets:@[fourBySix, fiveBySeven, square]];
        
    // Set Supported Orientations
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        NSArray * supportedOrientations = @[@(UIInterfaceOrientationPortrait), @(UIInterfaceOrientationPortraitUpsideDown), @(UIInterfaceOrientationLandscapeLeft), @(UIInterfaceOrientationLandscapeRight)];
        [AFPhotoEditorCustomization setSupportedIpadOrientations:supportedOrientations];
    }
}

#pragma mark - ALAssets Helper Methods

- (UIImage *)editingResImageForAsset:(ALAsset*)asset
{
    CGImageRef image = [[asset defaultRepresentation] fullScreenImage];
    
    return [UIImage imageWithCGImage:image scale:1.0 orientation:UIImageOrientationUp];
}

- (UIImage *)highResImageForAsset:(ALAsset*)asset
{
    ALAssetRepresentation * representation = [asset defaultRepresentation];
    
    CGImageRef image = [representation fullResolutionImage];
    UIImageOrientation orientation = [representation orientation];
    CGFloat scale = [representation scale];
    
    return [UIImage imageWithCGImage:image scale:scale orientation:orientation];
}

#pragma mark - Interface Actions

- (IBAction)scrollAlbums:(id)sender {
    int index = albumSlider.value * [photoIndexOrder count];
    NSLog(@"Scroll to: %d", index);
    NSLog(@"Value: %f", albumSlider.value);
    [carousel scrollToItemAtIndex:index animated:NO];
}

#pragma mark - Rotation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationIsPortrait(interfaceOrientation);
    }else{
        return YES;
    }
}

- (BOOL) shouldAutorotate
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setShouldReleasePopover:NO];
    [[self popover] dismissPopoverAnimated:YES];
}

#pragma mark - Private Helper Methods

- (BOOL) hasValidAPIKey
{
    NSString * key = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Aviary-API-Key"];
    if ([key isEqualToString:@"<YOUR_API_KEY>"]) {
        [[[UIAlertView alloc] initWithTitle:@"Oops!" message:@"You forgot to add your API key!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return NO;
    }
    return YES;
}

- (void)setupView
{
    //Setup Carousel
    carousel.type = iCarouselTypeWheel;
    carousel.vertical = NO;
    
    // Set View Background Color
    UIColor * backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
    [[self view] setBackgroundColor:backgroundColor];
}

#pragma mark iCarousel data source methods
- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)_carousel
{
    NSLog(@"Count: %d", [photoIndexOrder count]);
    return [photoIndexOrder count];
}

- (UIView *)carousel:(iCarousel *)_carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view {
    
    UIImageView *imageView = nil;
    
    NSIndexPath *indexPath = [photoIndexOrder objectAtIndex:index];
    ALAsset* asset = [photos objectForKey:indexPath];
    UIImage *image;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]
        && [[UIScreen mainScreen] scale] == 2.0) {
        // Retina
        image = [UIImage imageWithCGImage:[asset thumbnail]];

    } else {
        // Not Retina

        image = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
    }
    
    CGFloat borderOffset = 4.f;
    //create new view if no view is available for recycling
    if (view == nil)
    {
        CGRect viewFrame = CGRectMake(0,0,image.size.width + borderOffset * 2, image.size.height + borderOffset * 2);
        view = [[UIView alloc] initWithFrame:viewFrame];
        view.backgroundColor = [UIColor clearColor];
        imageView =[[UIImageView alloc] initWithFrame:CGRectMake(borderOffset, borderOffset, image.size.width, image.size.height)];
        imageView.tag = 1;
        imageView.layer.cornerRadius = 8.f;
        imageView.layer.borderColor = [UIColor blackColor].CGColor;
        imageView.layer.borderWidth = 2.f;
        imageView.layer.masksToBounds = YES;
        [imageView.layer setShadowColor:[UIColor whiteColor].CGColor];
        [imageView.layer setShadowOpacity:0.6];
        [imageView.layer setShadowRadius:6.0];
        
        [view addSubview:imageView];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragPhoto:)];
        [view addGestureRecognizer:panGesture];
        [view INKEnableWithUTI:@"public.png" dynamicBlob:^INKBlob *{
            int currIndex = [self.carousel indexOfItemView:view];
            NSIndexPath *indexPath = [photoIndexOrder objectAtIndex:currIndex];
            ALAsset *photo = [photos objectForKey:indexPath];
            return [self blobForAsset:photo];
        }];
    }
    else
    {
        //get a reference to the label in the recycled view
        imageView = (UIImageView *)[view viewWithTag:1];
    }
    //set item label
    //remember to always set any properties of your carousel item
    //views outside of the `if (view == nil) {...}` check otherwise
    //you'll get weird issues with carousel item content appearing
    //in the wrong place in the carousel
    imageView.image = image;
    
    view.frame = CGRectMake(0,0,image.size.width + borderOffset * 2, image.size.height + borderOffset * 2);
    imageView.frame = CGRectMake(borderOffset, borderOffset, image.size.width, image.size.width);
    
    return view;
}

- (void) dragPhoto:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        carousel.scrollEnabled = NO;
        UIView *currentItem = carousel.currentItemView;
        [gesture setTranslation:currentItem.frame.origin inView:[currentItem superview]];
        self.inkButton.highlighted = YES;
        self.editButton.highlighted = YES;
    }
    if (gesture.state == UIGestureRecognizerStateChanged) {
        UIView *currentItem = carousel.currentItemView;
        CGPoint point = [gesture translationInView:[currentItem superview]];
        CGSize size = currentItem.frame.size;
        //Move the item
        currentItem.frame = CGRectMake(point.x, point.y, size.width, size.height);
    }
    if (gesture.state == UIGestureRecognizerStateEnded) {
        self.inkButton.highlighted = NO;
        self.editButton.highlighted = NO;
        //Hit detection
        CGPoint endPoint = [gesture locationInView:self.view];
        if ([self.inkButton pointInside:[self.inkButton convertPoint:endPoint fromView:self.view] withEvent:nil]) {
            [self launchInkForCurrentPhoto:nil];
        } else if ([self.editButton pointInside:[self.editButton convertPoint:endPoint fromView:self.view] withEvent:nil]) {
            NSLog(@"on the edit button");
            NSIndexPath *indexPath = [photoIndexOrder objectAtIndex:self.carousel.currentItemIndex];
            ALAsset *photo = [photos objectForKey:indexPath];
            [self launchEditorWithAsset:photo];
        }
        UIView *currentItem = carousel.currentItemView;
        CGSize size = currentItem.frame.size;
        [UIView animateWithDuration:0.6f animations:^{
            currentItem.frame = CGRectMake(0, 0, size.width, size.height);
            carousel.scrollEnabled = YES;
        }];
    }
}

- (IBAction)launchInkForCurrentPhoto:(id)sender {
    NSIndexPath *indexPath = [photoIndexOrder objectAtIndex:self.carousel.currentItemIndex];
    ALAsset *photo = [photos objectForKey:indexPath];
    [Ink showWorkspaceWithUTI:@"public.png" dynamicBlob:^INKBlob *{
        return [self blobForAsset:photo];
    }];
}

- (INKBlob*) blobForAsset:(ALAsset*) asset {
    CGImageRef image = [[asset defaultRepresentation] fullScreenImage];
    
    UIImage *uiimage = [UIImage imageWithCGImage:image scale:1.0 orientation:UIImageOrientationUp];
    NSData *imageData = UIImagePNGRepresentation(uiimage);
    INKBlob *blob = [INKBlob blobFromData:imageData];
    blob.uti = @"public.png";
    blob.filename = @"photo.png";
    return blob;
}

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)_carousel {
    NSIndexPath* indexPath = [photoIndexOrder objectAtIndex:_carousel.currentItemIndex];
    int albumIndex = [indexPath indexAtPosition:0];
    ALAssetsGroup* album = [albums objectAtIndex:albumIndex];

    albumSlider.value = (_carousel.currentItemIndex+ 0.f) / [photoIndexOrder count];
    
    albumName.text = [album valueForProperty:ALAssetsGroupPropertyName];
}

- (IBAction)launchEditorForCurrentPhoto:(id)sender {
    NSIndexPath *indexPath = [photoIndexOrder objectAtIndex:self.carousel.currentItemIndex];
    ALAsset *photo = [photos objectForKey:indexPath];
    [self launchEditorWithAsset:photo];
}

- (void)carousel:(iCarousel *)_carousel didSelectItemAtIndex:(NSInteger)index {
    #define RADIANS(degrees) ((degrees * M_PI) / 180.0)
    
    CGAffineTransform leftWobble = CGAffineTransformRotate(CGAffineTransformIdentity, RADIANS(-5.0));
    CGAffineTransform rightWobble = CGAffineTransformRotate(CGAffineTransformIdentity, RADIANS(5.0));
    
    self.editButton.transform = leftWobble;  // starting point
    self.inkButton.transform = leftWobble;  // starting point
    
    self.editButton.highlighted = YES;
    self.inkButton.highlighted = YES;
    
    [UIView beginAnimations:@"wobble" context:nil];
    [UIView setAnimationRepeatAutoreverses:YES]; // important
    [UIView setAnimationRepeatCount:3];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(wobbleEnded:finished:context:)];
    
    self.editButton.transform = rightWobble; // end here & auto-reverse
    self.inkButton.transform = rightWobble;
    
    [UIView commitAnimations];
}

- (void) wobbleEnded:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    if ([finished boolValue]) {
        [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveLinear animations:^{
            self.editButton.transform = CGAffineTransformIdentity;
            self.inkButton.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            self.editButton.highlighted = NO;
            self.inkButton.highlighted = NO;
        }];
    }
}

- (CATransform3D) carousel:(iCarousel *)_carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform {
    CGFloat scale = 1.25f - (abs(offset)/2.5f);
    transform = CATransform3DScale(transform, scale, scale, 1.f);
    return transform;
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)_carousel {
    raisedView = _carousel.currentItemView;
    [UIView animateWithDuration:0.5f animations:^{
        CGRect currFrame = raisedView.frame;
        raisedView.frame = CGRectMake(0, -75.f, currFrame.size.width, currFrame.size.height);
    }];
}

- (void)carouselWillBeginScrollingAnimation:(iCarousel *)_carousel {
    NSLog(@"Began Scrolling, %@", raisedView);
    if (raisedView && raisedView.frame.origin.y < 0.f) {
        [UIView animateWithDuration:0.2f animations:^{
            CGRect currFrame = raisedView.frame;
            raisedView.frame = CGRectMake(0, 0, currFrame.size.width, currFrame.size.height);
            raisedView = nil;
        }];
    }
}

- (CGFloat)carousel:(iCarousel *)_carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    switch (option)
    {
        case iCarouselOptionWrap:
        {
            return NO;
        }
        case iCarouselOptionFadeMax:
        {
            if (carousel.type == iCarouselTypeCustom)
            {
                return 0.0f;
            }
            return value;
        }
        case iCarouselOptionArc:
        {
            return 2 * M_PI * 1.f;
        }
        case iCarouselOptionRadius:
        {
            return value * 2.f;
        }
        case iCarouselOptionSpacing:
        {
            return value * 0.65f;
        }
        default:
        {
            return value;
        }
    }
}


@end
