//
//  ThatPhotoAppDelegate.m
//  ThatPhoto
//
//  Created by Brett van Zuiden
//  Copyright (c) 2013 Ink (Cloudtop Inc). All rights reserved.
//

#import "ThatPhotoAppDelegate.h"

#import "TPMainViewController.h"
#import <INK/INK.h>

#import "ATConnect.h"
#define kApptentiveAPIKey @"44730bd9ca91a0e85e6f9fb7e139d47654d05300c270d65fcca2e6eba7b3ae78"
#import "INKWelcomeViewController.h"


@implementation ThatPhotoAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setWindow:[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]]];

    ATConnect *connection = [ATConnect sharedConnection];
    connection.apiKey = kApptentiveAPIKey;
    
    TPMainViewController * viewController;
    viewController = [[TPMainViewController alloc] initWithNibName:@"TPMainViewController_iPad" bundle:nil];
    
    //Setting up Ink with the ThatPhoto app key
    [Ink setupWithAppKey:@"AjTXjeBephotoqTdTUPz"];
    //XXX - Because we now use the ink-<apikey> url schemes, apps should not need to register
    //additional url schemes that they listen for Ink actions on. This is just for backwards compatibility
    //with the earliest versions of the sample apps, and should be removed asap.
    [[INKCoreManager sharedManager] registerAdditionalURLScheme:@"thatphoto"];
    
    //Registering the action to edit a photo in this app
    INKAction *edit = [INKAction action:@"Edit Image in ThatPhoto" type:INKActionType_Edit];
    [Ink registerAction:edit withTarget:viewController selector:@selector(launchEditorWithBlob:action:error:)];

    //Registering the action to save a photo to the camera roll
    INKAction *save = [INKAction action:@"Save to your Camera Roll" type:INKActionType_Save];
    [Ink registerAction:save withTarget:viewController selector:@selector(saveBlob:action:error:)];
    
    //Registering what happens when we send a photo out of that photo into another app and return back.
    INKAction *ret = [INKAction action:@"Save to ThatPhoto" type:INKActionType_Return];
    [Ink registerAction:ret withTarget:viewController selector:@selector(saveBlob:action:error:)];

    [self setViewController:viewController];
    [[self window] setRootViewController:viewController];
    [[self window] makeKeyAndVisible];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    //When launched, we first hand the request out to Ink to see if it can handle it
    if ([Ink openURL:url sourceApplication:sourceApplication annotation:annotation]) {
        //If we're opened via a url, make sure we don't show welcome flow, etc. - user should be taken directly to action
        [INKWelcomeViewController setShouldRunWelcomeFlow:NO];
        return YES;
    }
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
