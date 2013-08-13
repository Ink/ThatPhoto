Apptentive iOS SDK
==================

This iOS library allows you to add a quick and easy in-app-feedback mechanism
to your iOS applications. Feedback is sent to the Apptentive web service.

There have been many recent API changes for the 1.0 release. Please see `docs/APIChanges.md`.

For developers with apps created before June 28, 2013, please contact us to have your account
upgraded to the new Message Center UI on our website.

Quickstart
==========

There are no external dependencies for this SDK.

Sample Application
------------------
The sample application FeedbackDemo demonstrates how to integrate the SDK
with your application.

The demo app includes integration of the message center, surveys, and the
ratings flow. You use it by editing the `defines.h` file and entering in
the Apple ID for your app and your Apptentive API token. 

The rating flow can be activated by clicking on the Ratings button. It asks
the user if they are happy with the app. If not, then a simplified feedback
window is opened. If they are happy with the app, they are prompted to rate
the app in the App Store:

![Popup](etc/screenshots/rating.png?raw=true)


Required Frameworks
-------------------
In order to use `ApptentiveConnect`, your project must link against the
following frameworks:

* CoreData
* CoreText
* CoreGraphics
* CoreTelephony
* Foundation
* QuartzCore
* StoreKit
* SystemConfiguration
* UIKit

*Note:* If your app uses Core Data and you listen for Core Data related notifications, you will
want to filter them based upon your managed object context. [Learn more from Apple's documentation.](https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html)

Project Settings for Xcode 4
----------------------------
The instructions below are for source integration. For binary releases, see our [Binary Distributions](https://github.com/apptentive/apptentive-ios/wiki/Binary-Distributions) page.

There is a video demoing integration in Xcode 4 here:

http://vimeo.com/23710908

Drag the `ApptentiveConnect.xcodeproj` project to your project in Xcode 4 and
add it as a subproject. You can do the same with a workspace.

In your target's `Build Settings` section, add the following to your 
`Other Linker Flags` settings:

    -ObjC -all_load

In your target's `Build Phases` section, add the `ApptentiveConnect` and
`ApptentiveResources` targets to your `Target Dependencies`.

Then, add `libApptentiveConnect.a` to `Link Binary With Libraries`

Build the `ApptentiveResources` target for iOS devices. Then, add the
`ApptentiveResources.bundle` from the `ApptentiveConnect` products in the
file navigator into your `Copy Bundle Resources` build phase. Building
for iOS devices first works around a bug in Xcode 4.

Now, drag `ATConnect.h` from `ApptentiveConnect.xcodeproj` to your app's 
file list.

Now see "Using the Library", below, for instructions on using the library in your code.

Using the Library
-----------------

`ApptentiveConnect` queues feedback and attempts to upload in the background. This
is intended to provide as quick a mechanism for submitting feedback as possible.

In order for queued/interrupted feedback uploads to continue uploading, we 
recommending instantiating `ATConnect` and setting the API key at application
startup, like:

``` objective-c
#include "ATConnect.h"
// ...
- (void)applicationDidFinishLaunching:(UIApplication *)application /* ... */ {
    ATConnect *connection = [ATConnect sharedConnection];
    connection.apiKey = kApptentiveAPIKey;
    // ...
}
```

Where `kApptentiveAPIKey` is an `NSString` containing your API key. As soon
as you set the API key on the shared connection object, any queued feedback
will start to upload, pending network availability. You also should not have
to set the API key again on the shared connection object.

Now, you can show the Apptentive feedback UI from a `UIViewController` with:

``` objective-c
#include "ATConnect.h"
// ...
ATConnect *connection = [ATConnect sharedConnection];
[connection presentMessageCenterFromViewController:self];
```

![Message Center initial feedback](etc/screenshots/messageCenter_giveFeedback.png?raw=true)

![Message Center response](etc/screenshots/messageCenter_response.png?raw=true)

Easy!


App Rating Flow
---------------
`ApptentiveConnect` now provides an app rating flow similar to other projects
such as [appirator](https://github.com/arashpayan/appirater). This uses the number
of launches of your application, the amount of time users have been using it, and
the number of significant events the user has completed (for example, levels passed)
to determine when to display a ratings dialog.

To use it, add the `ATAppRatingFlow.h` header file to your project.

Then, at startup, instantiate a shared `ATAppRatingFlow` object with your 
iTunes app ID (see "Finding Your iTunes App ID" below):

``` objective-c
#include "ATAppRatingFlow.h"
// ...
- (void)applicationDidFinishLaunching:(UIApplication *)application /* ... */ {
    ATAppRatingFlow *sharedFlow = [ATAppRatingFlow sharedRatingFlow];
    sharedFlow.appID = @"<your iTunes app ID>";
    // ...
}
```

The ratings flow won't show unless you call the following:

``` objective-c
[[ATAppRatingFlow sharedRatingFlow] showRatingFlowFromViewControllerIfConditionsAreMet:viewController];
```

The `viewController` parameter is necessary in order to be able to show the 
feedback view controller if a user is unhappy with your app.

You'll want to add calls to `-showRatingFlowFromViewControllerIfConditionsAreMet:` wherever it makes sense in the context of your app.

If you're using significant events to determine when to show the ratings flow, you can
increment the number of significant events by calling:

```
[sharedFlow logSignificantEvent];
```

You can modify the parameters which determine when the ratings dialog will be
shown in your app settings on apptentive.com.


Metrics
-------
Metrics provide insight into exactly where people begin and end interactions
with your app and with feedback, ratings, and surveys. You can enable and disable
metrics on your app settings page on apptentive.com.


Surveys
-------
To use surveys, add the `ATSurveys.h` header to your project.

New surveys will be retrieved automatically. When a new survey becomes available,
the `ATSurveyNewSurveyAvailableNotification` notification will be sent.

There are both tagged surveys and untagged surveys. Tags are useful for defining
surveys that should be shown only in certain locations, whereas untagged surveys
are more general.

To check if a survey with a given set of tags is available to be shown, call:

```objective-c
if ([ATSurveys hasSurveyAvailableWithTags:tags]) {
    [ATSurveys presentSurveyControllerWithTags:tags fromViewController:viewController];
}
```

where tags is an `NSSet` consisting of strings like `aftervideo` that you set as tags
on your survey on the Apptentive website.

To show a survey without tags, use:

```objective-c
if ([ATSurveys hasSurveyAvailableWithNoTags]) {
    [ATSurveys presentSurveyControllerWithNoTagsFromViewController:viewController];
}
```

So, the full flow looks like:

```objective-c
#include "ATSurveys.h"
// ...
- (void)applicationDidFinishLaunching:(UIApplication *)application /* ... */ {
    // ...
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyBecameAvailable:) name:ATSurveyNewSurveyAvailableNotification object:nil];
}

- (void)surveyBecameAvailable:(NSNotification *)notification {
	// Present survey here as appropriate.
}
```


**Finding Your iTunes App ID**
In [iTunesConnect](https://itunesconnect.apple.com/), go to "Manage Your 
Applications" and click on your application. In the "App Information" 
section of the page, look for the "Apple ID". It will be a number. This is
your iTunes application ID.

Contributing
------------
We love contributions!

Any contributions to the master apptentive-ios project must sign the [Individual Contributor License Agreement (CLA)](https://docs.google.com/a/apptentive.com/spreadsheet/viewform?formkey=dDhMaXJKQnRoX0dRMzZNYnp5bk1Sbmc6MQ#gid=0). It's a doc that makes our lawyers happy and ensures we can provide a solid open source project.

When you want to submit a change, send us a [pull request](https://github.com/apptentive/apptentive-ios/pulls). Before we merge, we'll check to make sure you're on the list of people who've signed our CLA.

Thanks!
