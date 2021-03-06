//
//  DSPAuthenticationTVC.m
//  DissociatedPress-iOS
//
//  Created by Joseph Wilkerson on 12/10/14.
//
//

#import "DSPAuthenticationTVC.h"
#import <RedditKit/RedditKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "DSPAuthenticationManager.h"
#import "DSPWebViewController.h"
#import <iAd/iAd.h>
#import "IAPHelper.h"

@interface DSPAuthenticationTVC () <UITextFieldDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) UIBarButtonItem *doneButton;
@property (strong, nonatomic) UIBarButtonItem *signOutButton;
@property (strong, nonatomic) UITextField *usernameTextField;
@property (strong, nonatomic) UITextField *passwordTextField;
@property (strong, nonatomic) UIButton *createAccountButton;
@property (strong, nonatomic) UIButton *redditInfoButton;
@end

@implementation DSPAuthenticationTVC



- (UITextField *)usernameTextField
{
    if (!_usernameTextField) {
        UITextField *usernameTextField = [[UITextField alloc] init];
        usernameTextField.delegate = self;
        usernameTextField.placeholder = @"Username";
        usernameTextField.translatesAutoresizingMaskIntoConstraints = NO;
        usernameTextField.backgroundColor = [UIColor whiteColor];
        usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        usernameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        usernameTextField.borderStyle = UITextBorderStyleBezel;
        [usernameTextField addTarget:self action:@selector(updateDoneButtonStatus) forControlEvents:UIControlEventEditingChanged];
        
        _usernameTextField = usernameTextField;
    }
    return _usernameTextField;
}

- (UITextField *)passwordTextField
{
    if (!_passwordTextField) {
        UITextField *passwordTextField = [[UITextField alloc] init];
        passwordTextField.delegate = self;
        passwordTextField.placeholder = @"Password";
        passwordTextField.translatesAutoresizingMaskIntoConstraints = NO;
        passwordTextField.backgroundColor = [UIColor whiteColor];
        passwordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        passwordTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        passwordTextField.secureTextEntry = YES;
        passwordTextField.borderStyle = UITextBorderStyleBezel;
        [passwordTextField addTarget:self action:@selector(updateDoneButtonStatus) forControlEvents:UIControlEventEditingChanged];
        
        _passwordTextField = passwordTextField;
    }
    return _passwordTextField;
}

- (UIButton *)createAccountButton
{
    if (!_createAccountButton) {
        UIButton *createAccountButton = [[UIButton alloc] init];
        [createAccountButton setTitle:@"Create a reddit account" forState:UIControlStateNormal];
        [createAccountButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [createAccountButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        createAccountButton.backgroundColor = [UIColor groupTableViewBackgroundColor];
        createAccountButton.translatesAutoresizingMaskIntoConstraints = NO;
        [createAccountButton addTarget:self action:@selector(didPressCreateAccountButton) forControlEvents:UIControlEventTouchUpInside];
        _createAccountButton = createAccountButton;
    }
    return _createAccountButton;
}

- (UIButton *)redditInfoButton
{
    if (!_redditInfoButton) {
        UIButton *redditInfoButton = [[UIButton alloc] init];
        [redditInfoButton setTitle:@"What is reddit?" forState:UIControlStateNormal];
        [redditInfoButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [redditInfoButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        redditInfoButton.backgroundColor = [UIColor groupTableViewBackgroundColor];
        redditInfoButton.translatesAutoresizingMaskIntoConstraints = NO;
        [redditInfoButton addTarget:self action:@selector(didPressRedditInfoButton) forControlEvents:UIControlEventTouchUpInside];
        _redditInfoButton = redditInfoButton;
    }
    return _redditInfoButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.navigationItem.title = @"Sign in to reddit";
    
    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.navigationItem.rightBarButtonItem = self.doneButton;
    
    self.signOutButton = [[UIBarButtonItem alloc] initWithTitle:@"Sign out" style:UIBarButtonItemStylePlain target:self action:@selector(signOut)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationStateDidChange) name:@"authenticationStateDidChange" object:nil];
    
    [self authenticationStateDidChange];
    
    [self updateIAPStatus:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateIAPStatus:) name:IAPHelperProductPurchasedNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"%@ %@",[self class], NSStringFromSelector(_cmd));
    // Dispose of any resources that can be recreated.
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)authenticationStateDidChange
{
    NSString *username = [DSPAuthenticationManager usernameForDissociatedPress];
    if ([username length] > 0) {
        self.usernameTextField.text = username;
    } else self.usernameTextField.text = nil;
    
    NSString *password = [DSPAuthenticationManager passwordForDissociatedPress];
    if ([password length] > 0) {
        self.passwordTextField.text = password;
    } else self.passwordTextField.text = nil;
    
    if ([[RKClient sharedClient] isSignedIn]) {
        self.navigationItem.rightBarButtonItem = self.signOutButton;
        self.usernameTextField.enabled = NO;
        self.passwordTextField.enabled = NO;
        self.usernameTextField.backgroundColor = [UIColor groupTableViewBackgroundColor];
        self.passwordTextField.backgroundColor = [UIColor groupTableViewBackgroundColor];
    } else {
        self.navigationItem.rightBarButtonItem = self.doneButton;
        self.usernameTextField.enabled = YES;
        self.passwordTextField.enabled = YES;
        self.usernameTextField.backgroundColor = [UIColor whiteColor];
        self.passwordTextField.backgroundColor = [UIColor whiteColor];
        [self updateDoneButtonStatus];
    }
}

- (void)signOut
{
    UIAlertView *signOutAlert = [[UIAlertView alloc] initWithTitle:@"Really sign out?"
                                                           message:@"Just making sure"
                                                          delegate:self
                                                 cancelButtonTitle:@"No"
                                                 otherButtonTitles:@"Sign out", nil];
    [signOutAlert show];
}

- (void)done
{
    if (self.usernameTextField.text.length <= 0 || self.passwordTextField.text.length <= 0) {
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    __weak __typeof(self)weakSelf = self;
    [DSPAuthenticationManager signInWithUsername:weakSelf.usernameTextField.text password:weakSelf.passwordTextField.text completion:^(NSError *error){
        [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
        
        if (error) {
            UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Login error"
                                                                     message:error.localizedFailureReason
                                                                    delegate:nil
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
            [errorAlertView show];
        }
        
        if ([[RKClient sharedClient] isSignedIn]) {
            NSString *username = [[[RKClient sharedClient] currentUser] username];
            NSString *alertMessage = [NSString stringWithFormat:@"Logged in as %@",username];
            UIAlertView *loginAlertView = [[UIAlertView alloc] initWithTitle:@"Logged in"
                                                                     message:alertMessage
                                                                    delegate:weakSelf
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
            [loginAlertView show];
        }
    }];
}



- (void)updateDoneButtonStatus
{
    if (self.usernameTextField.text.length <= 0 || self.passwordTextField.text.length <= 0) {
        self.doneButton.enabled = NO;
    } else {
        self.doneButton.enabled = YES;
    }
}

- (void)didPressCreateAccountButton
{
    DSPWebViewController *webVC = [[DSPWebViewController alloc] initWithURL:[NSURL URLWithString:@"https://www.reddit.com/login"]];
    [self.navigationController pushViewController:webVC animated:YES];
}

- (void)didPressRedditInfoButton
{
    DSPWebViewController *webVC = [[DSPWebViewController alloc] initWithURL:[NSURL URLWithString:@"https://www.reddit.com/wiki/reddit_101"]];
    [self.navigationController pushViewController:webVC animated:YES];
}

- (void)updateIAPStatus:(NSNotification *)notification
{
    if ([[IAPHelper sharedInstance] productPurchased:IAPHelperProductRemoveAds]) {
        self.canDisplayBannerAds = NO;
    }
    else {
        self.canDisplayBannerAds = YES;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellReuseIdentifier = @"signInCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier];
    if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseIdentifier];
    
    cell.backgroundColor = [UIColor groupTableViewBackgroundColor];
    if (indexPath.row == 0) {
        [cell.contentView addSubview:self.usernameTextField];
        [self pinView:self.usernameTextField toSuperview:cell.contentView];
    } else if (indexPath.row == 1) {
        [cell.contentView addSubview:self.passwordTextField];
        [self pinView:self.passwordTextField toSuperview:cell.contentView];
    } else if (indexPath.row == 2) {
        [cell.contentView addSubview:self.createAccountButton];
        [self pinView:self.createAccountButton toSuperview:cell.contentView];
    } else if (indexPath.row == 3) {
        [cell.contentView addSubview:self.redditInfoButton];
        [self pinView:self.redditInfoButton toSuperview:cell.contentView];
    }
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

- (void)pinView:(UIView *)view toSuperview:(UIView *)superview
{
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:superview
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1
                                                           constant:8]];
    
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:superview
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1
                                                           constant:8]];
    
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:superview
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:view
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1
                                                           constant:8]];
    
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:superview
                                                          attribute:NSLayoutAttributeTrailing
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:view
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1
                                                           constant:8]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    [self done];
    
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Logged in"]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    if ([alertView.title isEqualToString:@"Really sign out?"]) {
        if (buttonIndex == 1) {
            [DSPAuthenticationManager signOut];
        }
    }
}

@end
