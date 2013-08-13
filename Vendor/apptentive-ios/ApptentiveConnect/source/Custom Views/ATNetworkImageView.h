//
//  ATNetworkImageView.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 4/17/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATNetworkImageView : UIImageView <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property (nonatomic, copy) NSURL *imageURL;
@end
