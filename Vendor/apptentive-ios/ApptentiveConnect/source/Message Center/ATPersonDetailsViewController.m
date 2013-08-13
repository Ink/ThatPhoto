//
//  ATPersonDetailsViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/19/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATPersonDetailsViewController.h"
#import "ATBackend.h"
#import "ATConnect_Private.h"
#import "ATPersonInfo.h"
#import "ATInfoViewController.h"
#import "ATUtilities.h"

enum kPersonDetailsTableSections {
	kContactInfoSection,
	kForgetInfoSection,
	kSectionCount
};


@interface ATPersonDetailsViewController ()
- (BOOL)emailIsValid;
- (BOOL)savePersonData;
- (void)registerForKeyboardNotifications;
- (void)keyboardWillBeShown:(NSNotification *)aNotification;
- (void)keyboardWillBeHidden:(NSNotification *)aNotification;
@end

@implementation ATPersonDetailsViewController {
	UIEdgeInsets previousScrollInsets;
	UILabel *emailValidationLabel;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_tableView release];
	[_logoButton release];
	[_emailCell release];
	[_nameCell release];
	[_emailTextField release];
	[_nameTextField release];
	[_poweredByLabel release];
	[_logoImage release];
	[super dealloc];
}

- (void)viewDidUnload {
	self.nameTextField.delegate = nil;
	self.emailTextField.delegate = nil;
	[self setTableView:nil];
	[self setLogoButton:nil];
	[self setEmailCell:nil];
	[self setNameCell:nil];
	[self setEmailTextField:nil];
	[self setNameTextField:nil];
	[self setPoweredByLabel:nil];
	[self setLogoImage:nil];
	[emailValidationLabel release], emailValidationLabel = nil;
	[super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	if ([ATPersonInfo personExists]) {
		ATPersonInfo *person = [ATPersonInfo currentPerson];
		self.nameTextField.text = person.name;
		self.emailTextField.text = person.emailAddress;
	}
	self.navigationItem.title = ATLocalizedString(@"Contact Settings", @"Title of contact information edit screen");
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)] autorelease];
	self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.logoButton.bounds.size.height, 0);
	self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
	previousScrollInsets = self.tableView.contentInset;
	UIImage *buttonBackgroundImage = [[ATBackend imageNamed:@"at_contact_button_bg"] stretchableImageWithLeftCapWidth:1 topCapHeight:40];
	[self.logoButton setBackgroundImage:buttonBackgroundImage forState:UIControlStateNormal];
	self.logoImage.image = [ATBackend imageNamed:@"at_apptentive_logo"];
	self.poweredByLabel.text = ATLocalizedString(@"Message Center Powered By", @"Text above Apptentive logo");
	[self registerForKeyboardNotifications];
	[self.emailTextField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
	emailValidationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width - 10, 20)];
	emailValidationLabel.text = ATLocalizedString(@"Please enter a valid email address.", @"Table footer asking for a valid email address.");
	emailValidationLabel.textColor = [UIColor redColor];
	emailValidationLabel.font = [UIFont systemFontOfSize:15];
	emailValidationLabel.shadowColor = [UIColor whiteColor];
	emailValidationLabel.shadowOffset = CGSizeMake(0, 1);
	emailValidationLabel.textAlignment = UITextAlignmentCenter;
	emailValidationLabel.numberOfLines = 0;
	emailValidationLabel.lineBreakMode = UILineBreakModeWordWrap;
	emailValidationLabel.backgroundColor = [UIColor clearColor];
	emailValidationLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	CGSize s = [emailValidationLabel sizeThatFits:CGSizeMake(self.tableView.bounds.size.width - 10, 1000)];
	s.height = MAX(s.height, 25);
	CGRect f = emailValidationLabel.frame;
	f.size = s;
	emailValidationLabel.frame = f;
	
	emailValidationLabel.hidden = [self emailIsValid];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.emailTextField resignFirstResponder];
	[self.nameTextField resignFirstResponder];
	[self savePersonData];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[self.emailTextField resignFirstResponder];
	[self.nameTextField resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)savePersonData {
	if (![self emailIsValid]) {
		return NO;
	}
	ATPersonInfo *person = nil;
	if ([ATPersonInfo personExists]) {
		person = [ATPersonInfo currentPerson];
	} else {
		person = [[[ATPersonInfo alloc] init] autorelease];
	}
	NSString *emailAddress = self.emailTextField.text;
	NSString *name = self.nameTextField.text;
	if (emailAddress && ![emailAddress isEqualToString:person.emailAddress]) {
		person.emailAddress = emailAddress;
		person.needsUpdate = YES;
	}
	if (name && ![name isEqualToString:person.name]) {
		person.name = name;
		person.needsUpdate = YES;
	}
	[person saveAsCurrentPerson];
	return YES;
}

- (BOOL)emailIsValid {
	NSString *email = self.emailTextField.text;
	if (email && [email length] > 0) {
		return [ATUtilities emailAddressIsValid:email];
	}
	return YES;
}

- (IBAction)donePressed:(id)sender {
	if ([self savePersonData]) {
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (IBAction)logoPressed:(id)sender {
	ATInfoViewController *vc = [[ATInfoViewController alloc] init];
	[self presentModalViewController:vc animated:YES];
	[vc release], vc = nil;
}

- (BOOL)disablesAutomaticKeyboardDismissal {
	return NO;
}

#pragma mark - UITableViewDataSource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == kContactInfoSection) {
        return 2;
    } else if (section == kForgetInfoSection) {
		return 1;
	}
	return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	if (section == kContactInfoSection) {
		return emailValidationLabel;
	}
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	if (section == kContactInfoSection) {
		return emailValidationLabel.bounds.size.height;
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ATForgetInfoCellIdentifier = @"ATForgetInfoCell";
	
	UITableViewCell *cell = nil;
	if (indexPath.section == kForgetInfoSection) {
		cell = [tableView dequeueReusableCellWithIdentifier:ATForgetInfoCellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ATForgetInfoCellIdentifier] autorelease];
			cell.accessoryView = nil;
			cell.textLabel.textAlignment = UITextAlignmentCenter;
		}
		cell.textLabel.textColor = [UIColor blackColor];
		cell.textLabel.text = ATLocalizedString(@"Forget Info", @"Title of button to forget contact information");
	} else if (indexPath.section == kContactInfoSection) {
		if (indexPath.row == 0) {
			cell = self.emailCell;
		} else if (indexPath.row == 1) {
			cell = self.nameCell;
		}
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == kForgetInfoSection) {
		self.emailTextField.text = @"";
		self.nameTextField.text = @"";
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *title = nil;
	if (section == kContactInfoSection) {
		title = ATLocalizedString(@"Contact Info", @"Title of contact information section");
	}
	return title;
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if ([textField isEqual:self.emailTextField]) {
		[self.nameTextField becomeFirstResponder];
		return YES;
	} else if ([textField isEqual:self.nameTextField]) {
		[self.nameTextField resignFirstResponder];
		return YES;
	}
	return YES;
}

- (void)textFieldChanged:(id)sender {
	emailValidationLabel.hidden = [self emailIsValid];
}

#pragma mark Keyboard Handling

- (void)registerForKeyboardNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeShown:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

+ (UIView *)topLevelViewForView:(UIView *)v {
	if (v.superview == nil) {
		return v;
	} else if ([v.superview isKindOfClass:[UIWindow class]]) {
		return v;
	} else {
		return [self topLevelViewForView:v.superview];
	}
}

- (void)keyboardWillBeShown:(NSNotification *)aNotification {
	NSDictionary *info = [aNotification userInfo];
	CGRect kbFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect kbAdjustedFrame = [self.tableView.window convertRect:kbFrame toView:self.tableView];
	
	CGRect scrollFrame = self.tableView.frame;
	CGRect intersection = CGRectIntersection(kbAdjustedFrame, scrollFrame);
	CGFloat offset = intersection.size.height;
	UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 0, offset, 0);
	self.tableView.contentInset = contentInsets;
	self.tableView.scrollIndicatorInsets = contentInsets;
	
	UITextField *activeField = nil;
	if ([self.emailTextField isFirstResponder]) {
		activeField = self.emailTextField;
	} else if ([self.nameTextField isFirstResponder]) {
		activeField = self.nameTextField;
	}
	if (activeField) {
		CGRect scrollFrame = self.tableView.frame;
		scrollFrame.size.height -= offset;
		CGRect visibleRect = [self.tableView convertRect:activeField.frame fromView:activeField.superview];
		if (!CGRectContainsRect(scrollFrame, visibleRect)) {
			[self.tableView scrollRectToVisible:visibleRect animated:YES];
		}
	}
	self.tableView.showsVerticalScrollIndicator = YES;
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
	NSNumber *duration = [[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSNumber *curve = [[aNotification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	
	UITableView *t = self.tableView;
	[UIView animateWithDuration:[duration floatValue] delay:0 options:[curve intValue] animations:^{
		t.contentInset = previousScrollInsets;
		t.scrollIndicatorInsets = previousScrollInsets;
	} completion:NULL];
}
@end
