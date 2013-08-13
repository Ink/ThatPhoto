//
//  ATPersonDetailsViewController.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/19/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATPersonDetailsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) IBOutlet UIButton *logoButton;
@property (retain, nonatomic) IBOutlet UITableViewCell *emailCell;
@property (retain, nonatomic) IBOutlet UITableViewCell *nameCell;
@property (retain, nonatomic) IBOutlet UITextField *emailTextField;
@property (retain, nonatomic) IBOutlet UITextField *nameTextField;
@property (retain, nonatomic) IBOutlet UILabel *poweredByLabel;
@property (retain, nonatomic) IBOutlet UIImageView *logoImage;

- (IBAction)donePressed:(id)sender;
- (IBAction)logoPressed:(id)sender;
@end
