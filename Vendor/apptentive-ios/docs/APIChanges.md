This document tracks changes to the API between versions.


# 1.0

The following changes from the 0.5.x series were made.

We are moving over to a unified message center, and while breaking the feedback API have decided to take the opportunity to clean up the ratings flow API as well. Below are detailed changes that have been made to the API, but from a simple perspective, you'll want to:

In feedback:

* Replace `-presentFeedbackControllerFromViewController:` with `-presentMessageCenterFromViewController:`.
* Replace `addAdditionalInfoToFeedback:withKey:` with `addCustomData:withKey:`.

In ratings:

* Replace `+sharedRatingFlowWithAppID:` with `+sharedRatingFlow`, and set the `appID` property.
* Remove calls to `-appDidEnterForeground:viewController:` and `-appDidLaunch:viewController:`.
* Add calls to `-showRatingFlowFromViewControllerIfConditionsAreMet:` where you want the ratings flow to show up.
* Replace `-userDidPerformSignificantEvent:viewController:` with `-logSignificantEvent`.

In surveys:

* Replace `+hasSurveyAvailable` with `+hasSurveyAvailableWithNoTags`.
* Remove calls to `+checkForAvailableSurveys`. This is now automatic.

## `ATConnect`

* `initialName` changed to `initialUserName`.
* `initialEmailAddress` changed to `initialUserEmailAddress`
* `+resourceBundle` is now private
* `ATLocalizedString` is now private
* Added `-presentMessageCenterFromViewController:`
* Added `-dismissMessageCenterAnimated:completion:`
* Added `-unreadMessageCount`
* Added `addCustomData:withKey:`
* Added `removeCustomDataWithKey:`

Feedback-related API has been removed.

* `shouldTakeScreenshot`
* `feedbackControllerType`
* `-presentFeedbackControllerFromViewController:`
* `-dismissFeedbackControllerAnimated:completion:`
* `-addAdditionalInfoToFeedback:withKey:`
* `-removeAdditionalInfoFromFeedbackWithKey:`

## `ATSurveys`

* Renamed `+hasSurveyAvailable` to `+hasSurveyAvailableWithNoTags`.
* Renamed `+presentSurveyControllerFromViewController:` to `+presentSurveyControllerWithNoTagsFromViewController:`
* Removed `+checkForAvailableSurveys`

## `ATAppRatingFlow`

* Renamed `+sharedRatingFlowWithAppID:` to `+sharedRatingFlow`
* Added `@property appID`.
* Removed `-appDidEnterForeground:viewController:`
* Removed `-appDidLaunch:viewController:`
* Removed `-userDidPerformSignificantEvent:viewController:`
* Added `-showRatingFlowFromViewControllerIfConditionsAreMet:`
* Added `-logSignificantEvent`
* `-showEnjoymentDialog:` is now private
* `-showRatingDialog:` is now private
