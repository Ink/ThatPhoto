//
//  ATAppRatingFlow+Internal.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATAppRatingFlow.h"

@interface ATAppRatingFlow (Internal)
#if TARGET_OS_IPHONE
/*!
 Call if you want to show the enjoyment dialog directly. This enters the flow
 for either bringing up the feedback view or the rating dialog.
 */
- (void)showEnjoymentDialog:(UIViewController *)vc;

/*!
 Call if you want to show the rating dialog directly.
 */
- (IBAction)showRatingDialog:(UIViewController *)vc;
#elif TARGET_OS_MAC
/*!
 Call if you want to show the enjoyment dialog directly. This enters the flow
 for either bringing up the feedback view or the rating dialog.
 */
- (IBAction)showEnjoymentDialog:(id)sender;

/*!
 Call if you want to show the rating dialog directly.
 */
- (IBAction)showRatingDialog:(id)sender;
#endif
@end
