//
//  TPMainViewController.h
//  ThatPhoto
//
//  Created by Brett van Zuiden
//  Copyright (c) 2013 Ink (Cloudtop Inc). All rights reserved.
//
//  Portions of the code derived from AFSDKDemoViewController.m, part of the AviaryDemo-iOS project, created by Michael
//  Vitrano on 1/23/13. Copyright (c) 2013 Aviary. All rights reserved.
//

#import "TPMainViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import "AFPhotoEditorController.h"
#import "AFPhotoEditorCustomization.h"
#import "AFOpenGLManager.h"
#import "ATConnect.h"
#import "INKWelcomeViewController.h"
#import "StandaloneStatsEmitter.h"

#import <INK/Ink.h>

@interface TPMainViewController () <UINavigationControllerDelegate, AFPhotoEditorControllerDelegate, iCarouselDataSource, iCarouselDelegate>

@property (nonatomic, strong) ALAssetsLibrary * assetLibrary;
@property (nonatomic, strong) NSMutableArray * editorSessions;

@property (nonatomic, strong) NSMutableDictionary *photos;
@property (nonatomic, strong) NSMutableArray *photoIndexOrder;
@property (nonatomic, strong) UIView *raisedView;

@end

@implementation TPMainViewController

@synthesize carousel, albums, albumName, albumSlider, photos, photoIndexOrder, raisedView;

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
    [self setEditorSessions:sessions];
    
    // Start the Aviary Editor OpenGL Load
    [AFOpenGLManager beginOpenGLLoad];
    
    [self setupView];
    
    //Register for the app switch focus event. Reload the data so things show up immeadiately.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadPhotoData) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self loadPhotoData];
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

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //Once the app is all ready to go, run the welcome flow
    if ([INKWelcomeViewController shouldRunWelcomeFlow]) {
        INKWelcomeViewController *welcomeViewController = [[INKWelcomeViewController alloc] initWithNibName:@"INKWelcomeViewController" bundle:nil];
        [self presentViewController:welcomeViewController animated:NO completion:^{}];
    }
    [[StandaloneStatsEmitter sharedEmitter] setAppKey:@"AjTXjeBephotoqTdTUPz"];
    [[StandaloneStatsEmitter sharedEmitter] sendStat:@"app_launched" withAdditionalStatistics:nil];
}

- (void)loadPhotoData {
    //We load references to every photo into memory. This isn't as bad as it sounds, as we're not
    //Loading the _actual_ photos into memory, just pointers to them, and the camera roll won't be
    //holding more than 100,000 images
    NSMutableArray *albumCollector = [[NSMutableArray alloc] initWithCapacity:1];
    //Holding a place for camera roll because we want it to be first
    [albumCollector setObject:[[NSObject alloc] init] atIndexedSubscript:0];
    ALAssetsLibrary *al = self.assetLibrary;
    
    [al enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:
     ^(ALAssetsGroup *group, BOOL *stop) {
         if (group == nil) {
             return;
         }
         
         NSString *sGroupPropertyName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
         NSUInteger nType = [[group valueForProperty:ALAssetsGroupPropertyType] intValue];
         
         //Grab all the photos (but no video, etc.)
         [group setAssetsFilter:[ALAssetsFilter allPhotos]];
         
         int groupIndex = 0;
         //If we're the camera roll, put the photos first
         if ([[sGroupPropertyName lowercaseString] isEqualToString:@"camera roll"] && nType == ALAssetsGroupSavedPhotos) {
             [albumCollector setObject:group atIndexedSubscript:0]; //already held
         } else { //Otherwise, add the album on to the stack
             [albumCollector addObject:group];
             groupIndex = [albumCollector count] - 1;
         }
         
         //Then, fetch the photos in the album
         [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
             if (result == nil) {
                 return;
             }
             //For each photo, we store a tuple of (album_id, photo_id) so that we can look up the photo later
             //Because Objective-C doesn't have tuples, we use an index path, which is reasonably appropriate
             //and probably more correct than just doing an array
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
         //Reload the carousel with the new data
         [self reloadCarousel];
     } failureBlock:^(NSError *error) {
         NSLog(@"There was an error with the ALAssetLibrary: %@", error);
     }
     ];
}

- (void) reloadCarousel {
    //refresh
    [carousel reloadData];
}

#pragma mark - Photo Editor Launch Methods

- (void) launchEditorWithBlob:(INKBlob *)blob action:(INKAction*)action error:(NSError*)error
{
    //When we're launched via Ink, the left and right nav buttons bring up Ink to take the user
    //back to where they came from, so the language on the buttons should reflect that.
    [AFPhotoEditorCustomization setLeftNavigationBarButtonTitle:kAFLeftNavigationTitlePresetExit];
    [AFPhotoEditorCustomization setRightNavigationBarButtonTitle:kAFRightNavigationTitlePresetDone];

    //Constructing the image with the data out of the blob. Pretty darn easy.
    UIImage *photo = [UIImage imageWithData:blob.data];
    
    //Launch the photo editor
    [self launchPhotoEditorWithImage:photo highResolutionImage:nil];
}

- (void) launchEditorWithAsset:(ALAsset *)asset
{
    //When the editor is launched via the edit button, the left button closes the editor but remains in the app,
    //and the right button saves the edited image to the camera roll
    [AFPhotoEditorCustomization setLeftNavigationBarButtonTitle:kAFLeftNavigationTitlePresetCancel];
    [AFPhotoEditorCustomization setRightNavigationBarButtonTitle:kAFRightNavigationTitlePresetSave];
    UIImage * editingResImage = [self editingResImageForAsset:asset];
    UIImage * highResImage = [self highResImageForAsset:asset];
    [[StandaloneStatsEmitter sharedEmitter] sendStat:@"editor_pressed" withAdditionalStatistics:nil];

    [self launchPhotoEditorWithImage:editingResImage highResolutionImage:highResImage];
}

- (void) saveBlob:(INKBlob *)blob action:(INKAction*)action error:(NSError*)error
{
    //Saving the data to the camera roll
    UIImage *image = [UIImage imageWithData:blob.data];
    [self saveNewUIImage:image];
}

//Takes a UIImage and saves it to the camera roll as the most recent object
- (void) saveNewUIImage:(UIImage*) image{
    //The new image always goes as the most recent item (therefore first) item on the camera
    //roll, so we scroll to show the first item.
    [self.carousel scrollToItemAtIndex:0 animated:NO];
    
    ALAssetsGroup *album = [albums objectAtIndex:0]; //Album for the photo roll
    
    [self.assetLibrary writeImageToSavedPhotosAlbum:[image CGImage] metadata:[NSDictionary dictionary] completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error.code == 0) {
            NSLog(@"saved image completed:\nurl: %@", assetURL);
            
            // try to get the asset
            [self.assetLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                //We're the last item on the first album
                NSUInteger indexArr[] = {0, [album numberOfAssets]};
                NSIndexPath *newIndex = [NSIndexPath indexPathWithIndexes:indexArr length:2];
                [photoIndexOrder insertObject:newIndex atIndex:0];
                [photos setObject:asset forKey:newIndex];
                //Show the photo being added
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
    [[self editorSessions] addObject:session];
    
    // Create a context from the session with the high res image.
    AFPhotoEditorContext *context = [session createContextWithImage:highResImage];
    
    __block TPMainViewController * blockSelf = self;
    
    // Call render on the context. The render will asynchronously apply all changes made in the session (and therefore editor)
    // to the context's image. It will not complete until some point after the session closes (i.e. the editor hits done or
    // cancel in the editor). When rendering does complete, the completion block will be called with the result image if changes
    // were made to it, or `nil` if no changes were made. In this case, we write the image to the user's photo album, and release
    // our reference to the session. 
    [context render:^(UIImage *result) {
        if (result) {
            UIImageWriteToSavedPhotosAlbum(result, nil, nil, NULL);
        }
        
        [[blockSelf editorSessions] removeObject:session];
        
        blockSelf = nil;
        session = nil;
        
    }];
}

#pragma Photo Editor Delegate Methods

// This is called when the user taps "Done" in the photo editor. 
- (void) photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image
{
    BOOL *displayInk = [Ink appShouldReturn] && image;
    //If showing ink, don't animate because Ink will animate up.
    [self dismissViewControllerAnimated:!displayInk completion:^{
        [[StandaloneStatsEmitter sharedEmitter] sendStat:@"done_pressed" withAdditionalStatistics:nil];
        if (displayInk) {
            //Wait for the view controller to go away so we don't add on top of that while it's closing
            NSData *imageData = UIImagePNGRepresentation(image);
            INKBlob *blob = [INKBlob blobFromData:imageData];
            //We make up a filename. We could lead this off, but we're being a better citizen by adding it.
            blob.filename = @"EditedPhoto.png";
            blob.uti = @"public.png";
            //We're done! Return the data
            [Ink returnBlob:blob];
        } else {
            [self saveNewUIImage:image];
        }
    }];
}

// This is called when the user taps "Cancel" in the photo editor.
- (void) photoEditorCanceled:(AFPhotoEditorController *)editor
{
    [[StandaloneStatsEmitter sharedEmitter] sendStat:@"cancel_pressed" withAdditionalStatistics:nil];

    BOOL *displayInk = [Ink appShouldReturn];
    [self dismissViewControllerAnimated:!displayInk completion:^{
        if (displayInk) {
            //We want to show Ink when we cancel as well to allow the user to go back
            [Ink return];
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
    //We don't animate because things get jerky
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
}

#pragma mark iCarousel data source methods
- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)_carousel
{
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
        
        //Setting up the recognizer to allow the user to drag the photo onto either the edit or the Ink action
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragPhoto:)];
        [view addGestureRecognizer:panGesture];
        
        //Enabling Ink on the view so you can double-tap to open the photo. Sometimes hard because of the small target size
        [view INKEnableWithUTI:@"public.png" dynamicBlob:^INKBlob *{
            int currIndex = [self.carousel indexOfItemView:view];
            NSIndexPath *indexPath = [photoIndexOrder objectAtIndex:currIndex];
            ALAsset *photo = [photos objectForKey:indexPath];
            return [self blobForAsset:photo];
        }]; //We don't need a return block because we handle it centrally with saveBlob (see app delegate)
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
    [[StandaloneStatsEmitter sharedEmitter] sendStat:@"photo_dragged" withAdditionalStatistics:nil];

    //The user can drag the photo around and drop it on either the Ink button or the Edit button
    if (gesture.state == UIGestureRecognizerStateBegan) {
        carousel.scrollEnabled = NO;
        UIView *currentItem = carousel.currentItemView;
        [gesture setTranslation:currentItem.frame.origin inView:[currentItem superview]];
        self.inkButton.highlighted = YES;
        self.editButton.highlighted = YES;
    }
    if (gesture.state == UIGestureRecognizerStateChanged) {
        UIView *currentItem = carousel.currentItemView;
        //Note that we're using translation rather than point so we can get the offset. Much easier than trying to
        //store and increment positional changes ourselves
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
    if (self.carousel.currentItemIndex == -1){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Select a photo"
                                                        message:@"You must have some items in the photo gallery in order to proceed. If you're on a device, you can use the Camera to take a photo. If you're on a simulator, you can use Safari and long press to save an image into the gallery."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    NSIndexPath *indexPath = [photoIndexOrder objectAtIndex:self.carousel.currentItemIndex];
    ALAsset *photo = [photos objectForKey:indexPath];
    [[StandaloneStatsEmitter sharedEmitter] sendStat:@"inkdot_pressed" withAdditionalStatistics:nil];

    [Ink showWorkspaceWithUTI:@"public.png" dynamicBlob:^INKBlob *{
        return [self blobForAsset:photo];
    }];
}

//Utility method to convert an asset into an Ink blob. This can take some time, so is best done in
//a callback block or other background thread that doesn't block the UI
- (INKBlob*) blobForAsset:(ALAsset*) asset {
    CGImageRef image = [[asset defaultRepresentation] fullScreenImage];
    
    UIImage *uiimage = [UIImage imageWithCGImage:image scale:1.0 orientation:UIImageOrientationUp];
    NSData *imageData = UIImagePNGRepresentation(uiimage);
    INKBlob *blob = [INKBlob blobFromData:imageData];
    blob.uti = @"public.png";
    //We don't _need_ a filename per-say, but we're being a better citizen by adding one.
    blob.filename = @"photo.png";
    return blob;
}

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)_carousel {
    //when the carousel slides, we update the slider and see if we've changed albums
    NSIndexPath* indexPath = [photoIndexOrder objectAtIndex:_carousel.currentItemIndex];
    int albumIndex = [indexPath indexAtPosition:0];
    ALAssetsGroup* album = [albums objectAtIndex:albumIndex];

    albumSlider.value = (_carousel.currentItemIndex+ 0.f) / [photoIndexOrder count];
    albumName.text = [album valueForProperty:ALAssetsGroupPropertyName];
}

- (IBAction)launchEditorForCurrentPhoto:(id)sender {
    if (self.carousel.currentItemIndex == -1){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Select a photo"
                                                        message:@"You must have some items in the photo gallery in order to proceed. If you're on a device, you can use the Camera to take a photo. If you're on a simulator, you can use Safari and long press to save an image into the gallery."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    NSIndexPath *indexPath = [photoIndexOrder objectAtIndex:self.carousel.currentItemIndex];
    ALAsset *photo = [photos objectForKey:indexPath];
    [self launchEditorWithAsset:photo];
}

- (void)carousel:(iCarousel *)_carousel didSelectItemAtIndex:(NSInteger)index {
    //It's not immediately obvious that the Ink dot and the edit icon are buttons.
    //To help signal this, when a user taps on a photo, we "wiggle" both the edit icon
    //and the Ink dot.
    #define RADIANS(degrees) ((degrees * M_PI) / 180.0)
    
    CGAffineTransform leftWobble = CGAffineTransformRotate(CGAffineTransformIdentity, RADIANS(-5.0));
    CGAffineTransform rightWobble = CGAffineTransformRotate(CGAffineTransformIdentity, RADIANS(5.0));
    
    self.editButton.transform = leftWobble;  // starting point
    self.inkButton.transform = leftWobble;  // starting point
    
    self.editButton.highlighted = YES;
    self.inkButton.highlighted = YES;
    
    //Wobble animation: Shake 3 times, then settle to normal
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
    //Settling to normal
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
    //Having all the images in the carousel doesn't look as good, so we have the ones that are futher away from center scale down a bit.
    CGFloat scale = 1.25f - (abs(offset)/2.5f);
    transform = CATransform3DScale(transform, scale, scale, 1.f);
    return transform;
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)_carousel {
    //Further signaling to the user what's going on: when the carousel stops spinning,
    //we raise the current, middle item to make it clear that this is the item we're now "acting" on
    raisedView = _carousel.currentItemView;
    [UIView animateWithDuration:0.5f animations:^{
        CGRect currFrame = raisedView.frame;
        raisedView.frame = CGRectMake(0, -75.f, currFrame.size.width, currFrame.size.height);
    }];
}

- (void)carouselWillBeginScrollingAnimation:(iCarousel *)_carousel {
    NSLog(@"Began Scrolling, %@", raisedView);
    //Undoing the raise when we start scrolling
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
