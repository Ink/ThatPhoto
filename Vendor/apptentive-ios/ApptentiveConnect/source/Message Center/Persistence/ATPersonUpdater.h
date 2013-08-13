//
//  ATPersonUpdater.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ATAPIRequest.h"
#import "ATPersonInfo.h"

@protocol ATPersonUpdaterDelegate;

@interface ATPersonUpdater : NSObject <ATAPIRequestDelegate> {
@private
	NSObject<ATPersonUpdaterDelegate> *delegate;
	ATAPIRequest *request;
}
@property (nonatomic, assign) NSObject<ATPersonUpdaterDelegate> *delegate;

+ (BOOL)shouldUpdate;

- (id)initWithDelegate:(NSObject<ATPersonUpdaterDelegate> *)delegate;
- (void)update;
- (void)cancel;
- (float)percentageComplete;
@end

@protocol ATPersonUpdaterDelegate <NSObject>
- (void)personUpdater:(ATPersonUpdater *)personUpdater didFinish:(BOOL)success;
@end
