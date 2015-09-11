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
    
    Keychain * keychain = [[Keychain alloc] initWithService:SERVICE_NAME withGroup:nil];
    
    NSString *key= @"SimpleReader Device UUID";
    NSData *uuid_data =[keychain findDataForKey: key];
    NSString *uuid;
    
    if(uuid_data == nil) {
        uuid = [[NSUUID UUID] UUIDString];
        uuid_data = [uuid dataUsingEncoding:NSUTF8StringEncoding];
        
        [keychain insertData:uuid_data forKey:key];
        NSLog(@"UUID not found, generated new one: %@", uuid);
    } else {
        uuid = [[NSString alloc] initWithData:uuid_data encoding:NSUTF8StringEncoding];
        NSLog(@"UUID found: %@", uuid);
    }
    
    UIUserNotificationSettings *settings =
        [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound)
                                          categories:nil];
    
    [application registerUserNotificationSettings:settings];
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:uuid forKey:@"uuid"];
    
    [defaults synchronize];
    
    
//    _editions = [NSMutableArray arrayWithCapacity:20];
//    
//    Edition *sommer2015 = [[Edition alloc] init];
//    sommer2015.title = @"Sommer 2015";
//    sommer2015.shortDescription = @"Features:\n - Nummer Zwei\n - Spezial-Teil\n - Der letzte Rest\n\nUnd hier kommt dann noch der super spezielle Text hin, der das ganze Heft zusammenfasst und für alle echt wichtig ist! Doch was passiert eigentlich, wenn das Textfeld voll ist? Wohin geht der Text dann?";
//    sommer2015.previewImage = [UIImage imageNamed:[[NSBundle mainBundle] pathForResource:@"sommer2015@2x" ofType:@"jpg"]];
//    sommer2015.pdfPath = [[NSBundle mainBundle] pathForResource:@"sommer2015" ofType:@"pdf"];
//    sommer2015.filesize = @"22.6 MB";
//    sommer2015.status = downloaded;
//    
//    NSLog(@"Created Number: %@", [NSNumber numberWithFloat:22.6f]);
//    
//    [_editions addObject:sommer2015];
//    
//    
//    Edition *landbote2014 = [[Edition alloc] init];
//    landbote2014.title = @"KH Landbote 2014";
//    landbote2014.shortDescription = @"Mit dem besten aus dem ganzen Jahr...\n\n- Berichte\n- Bilder\n- und vieles mehr...";
//    landbote2014.previewImage = [UIImage imageNamed:[[NSBundle mainBundle] pathForResource:@"landbote2014@2x" ofType:@"jpg"]];
//    landbote2014.pdfPath = [[NSBundle mainBundle] pathForResource:@"landbote2014" ofType:@"pdf"];
//    landbote2014.filesize = @"10 MB";
//    landbote2014.status = downloaded;
//    
//    [_editions addObject:landbote2014];
    
    
    //UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    //UINavigationController *navigationController = [tabBarController viewControllers][0];
//    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
//    PreviewTableViewController *previewTableViewController = [navigationController viewControllers][0];
//    [previewTableViewController reloadJSONFeed];
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler{
    
    self.backgroundTransferCompletionHandler = completionHandler;
    
}

# pragma mark Push Notifications

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    //register to receive notifications
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler {
    //handle the actions
//    if ([identifier isEqualToString:@"declineAction"]){
//    }
//    else if ([identifier isEqualToString:@"answerAction"]){
//    }
}

- (void)application:(UIApplication*) application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*) deviceToken{
    
}

- (void)application:(UIApplication*) application didFailToRegisterForRemoteNotificationsWithError:(NSError*) error{
    
}

@end
