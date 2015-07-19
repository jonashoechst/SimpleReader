//
//  PreviewTableViewController.h
//  Simple Reader
//
//  Created by Jonas Höchst on 08.07.15.
//  Copyright (c) 2015 vcp. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum AlertType : NSUInteger {
    downloadQuestion,
    pauseQuestion,
    continueQuestion
} AlertType;

@interface PreviewTableViewController : UITableViewController <UIAlertViewDelegate, NSURLSessionDelegate>

@property (nonatomic, strong) NSMutableArray *editions;
@property (nonatomic, strong) NSString* feedPath;
@property (nonatomic, strong) NSString* feedURL;

@property (nonatomic, strong) NSURLSession *session;
//@property (nonatomic, strong) NSMutableArray *arrFileDownloadData;
//@property (nonatomic, strong) NSURL *docDirectoryURL;

- (void) reloadJSONFeed;


@end
