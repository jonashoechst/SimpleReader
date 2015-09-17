//
//  RegisterViewController.m
//  Simple Reader
//
//  Created by Jonas Höchst on 11.09.15.
//  Copyright (c) 2015 vcp. All rights reserved.
//

#import "RegisterViewController.h"

#define HOST @"http://localhost:5000"

@interface RegisterViewController ()

@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [self.uuidLabel setText:[defaults stringForKey:@"uuid"]];
    [self.nameTextField setText:[defaults stringForKey:@"name"]];
    [self.emailTextField setText:[defaults stringForKey:@"email"]];
    
    [self.nameTextField setKeyboardType:UIKeyboardTypeAlphabet];
    [self.nameTextField setAutocapitalizationType: UITextAutocapitalizationTypeWords];
    [self.emailTextField setKeyboardType:UIKeyboardTypeEmailAddress];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)registerButtonPressed:(id)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *name = [self.nameTextField text];
    NSString *email = [self.emailTextField text];
    
    NSString *parse_error = nil;
    
    if ( [name length] < 5 ){
        parse_error = @"Bitte gib deinen vollen Namen ein, damit wir wissen, wer das Hesseblättche lesen möchte.";
    } else if ([email length] <= 5){
        parse_error = @"Bitte gib deine E-Mail Adresse ein.";
    } else if (![RegisterViewController isValidEmailAdress:email]){
        parse_error = [NSString stringWithFormat:@"Deine E-Mail Adresse ist \"%@\"? Spannend...", email];
    }
    
    if (parse_error){
        UIAlertView *alert =[[UIAlertView alloc ] initWithTitle:@"Eingabe überprüfen"
                                                         message:parse_error
                                                        delegate:self
                                               cancelButtonTitle:@"Zurück"
                                               otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    [defaults setObject:name forKey:@"name"];
    [defaults setObject:email forKey:@"email"];
    [defaults synchronize];
    
    self.overlayView.hidden = NO;
    
    // This has to be done in background.
    NSError *error = nil;
    [self registerDevice: &error];
    if (error) {
        parse_error = [NSString stringWithFormat:@"Gerät konnte nicht registriert werden: %@", [[error userInfo] objectForKey:@"NSLocalizedDescription"]];
        NSLog(@"Error registering Device: %@", error);
        
        UIAlertView *alert =[[UIAlertView alloc ] initWithTitle:@"Fehler..."
                                                         message:parse_error
                                                        delegate:self
                                               cancelButtonTitle:@"Zurück"
                                               otherButtonTitles: nil];
        self.overlayView.hidden = YES;
        [alert show];
        return;
    }
    self.overlayView.hidden = YES;
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}


- (void) registerDevice:(NSError**) error {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [defaults stringForKey:@"uuid"];
    NSString *name = [defaults stringForKey:@"name"];
    NSString *email = [defaults stringForKey:@"email"];
    NSString *apns_token = [defaults stringForKey:@"apns_token"];
    
    NSString *post = [NSString stringWithFormat:@"name=%@&email=%@&uid=%@&apns_token=%@", name, email, uuid, apns_token];
    NSLog(@"post request: %@", post);
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://jonashoechst.de/fcgi-bin/srs/api/register"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];

    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse: nil error: error];
    if (*error) {
        NSLog(@"Error connection to server: %@", *error);
        return;
    }

    
    NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:error];
    if (*error) {
        NSLog(@"Error in parsing json feed: %@", *error);
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSLog(@"Response from server: %@", responseString);
        return;
    }
    
    NSString* status = [jsonDict objectForKey:@"status"];
    [defaults setObject:status forKey:@"status"];
    return;
}

- (BOOL) textFieldShouldReturn:(UITextField*) textField{
    
    if (textField == self.nameTextField) {
        [self.emailTextField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
        [self registerButtonPressed:nil];
    }
    
    return YES;
}

+ (BOOL) isValidEmailAdress:(NSString *)checkString {
    BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

@end
















