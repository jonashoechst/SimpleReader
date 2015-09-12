//
//  AppDelegate.m
//  Simple Reader
//
//  Created by Jonas Höchst on 08.07.15.
//  Copyright (c) 2015 vcp. All rights reserved.
//

#import "AppDelegate.h"
#import "Edition.h"
#import "PreviewTableViewController.h"
#import "Keychain.h"

@interface AppDelegate ()

@end

@implementation AppDelegate
{
    NSMutableArray *_editions;
}

#define SERVICE_NAME @"SimpleReader"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // If the App is opened for the first time, a uuid is generated to identify the device.
    // The generated uuid is then stored in the keychain, so it can't be removed.
    Keychain * keychain = [[Keychain alloc] initWithService:SERVICE_NAME withGroup:nil];
    NSString *key= @"SimpleReader Device UUID";
    NSData *uuid_data =[keychain findDataForKey: key];
    NSString *uuid;
    
    if(uuid_data == nil) {
        uuid = [[NSUUID UUID] UUIDString];
        uuid_data = [uuid dataUsingEncoding:NSUTF8StringEncoding];
        
        [keychain insertData:uuid_data forKey:key];
    } else {
        uuid = [[NSString alloc] initWithData:uuid_data encoding:NSUTF8StringEncoding];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:uuid forKey:@"uuid"];
    [defaults synchronize];
    
    // Ask for push notification permissions
    UIUserNotificationSettings *settings =
        [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound) categories: nil];
    [application registerUserNotificationSettings:settings];

    return YES;
}

//- (void)applicationWillResignActive:(UIApplication *)application {
//    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
//    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//}
//
//- (void)applicationDidEnterBackground:(UIApplication *)application {
//    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
//    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//}
//
//- (void)applicationWillEnterForeground:(UIApplication *)application {
//    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//}
//
//- (void)applicationDidBecomeActive:(UIApplication *)application {
//    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//}
//
//- (void)applicationWillTerminate:(UIApplication *)application {
//    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//}

-(void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler{
    
    self.backgroundTransferCompletionHandler = completionHandler;
    
}

# pragma mark Push Notifications

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    //register to receive notifications
    [application registerForRemoteNotifications];
}

//- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler {
//    //handle the actions
////    if ([identifier isEqualToString:@"declineAction"]){
////    }
////    else if ([identifier isEqualToString:@"answerAction"]){
////    }
//}

- (void)application:(UIApplication*) application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*) deviceToken{
    
    // Remove bracets and spaces from apns token
    NSString* apns_token = [NSString stringWithFormat:@"%@", deviceToken];
    apns_token = [apns_token stringByReplacingOccurrencesOfString:@" " withString:@""];
    apns_token = [[apns_token substringToIndex:[apns_token length] - 1] substringFromIndex:1];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:apns_token forKey:@"apns_token"];
    [defaults synchronize];
    
//    NSLog(@"apns_token: %@", apns_token);
}

- (void)application:(UIApplication*) application didFailToRegisterForRemoteNotificationsWithError:(NSError*) error{
    NSLog(@"Did fail to register for remote notifications: %@, %@", error, error.localizedDescription);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"apns_token"];
    [defaults synchronize];
}

- (void)application:(UIApplication*) application didReceiveRemoteNotification:(NSDictionary*) notification {
//    NSLog(@"Recieved Message in foreground: %@", notification);
    
    NSString* status = [notification objectForKey:@"status"];
    if ( status ){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:status forKey:@"status"];
    }
    
    NSString* message = [[notification objectForKey:@"aps"] objectForKey:@"alert"];
    if ( message ) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Hesseblättche" message:message delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    }
    
    UINavigationController *navigationController = (UINavigationController*) self.window.rootViewController;
    [navigationController popViewControllerAnimated:YES];
    PreviewTableViewController *previewTableViewController = [navigationController.viewControllers objectAtIndex:0];
    [previewTableViewController checkStatus];


}

@end
