//
//  RegisterViewController.h
//  Simple Reader
//
//  Created by Jonas Höchst on 11.09.15.
//  Copyright (c) 2015 vcp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RegisterViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UILabel *uuidLabel;
@property (weak, nonatomic) IBOutlet UIView *overlayView;
- (IBAction)registerButtonPressed:(id)sender;

+ (BOOL) isValidEmailAdress:(NSString *) checkString;

@end
