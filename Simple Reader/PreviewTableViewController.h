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

@interface PreviewTableViewController : UITableViewController <UIAlertViewDelegate, NSURLSessionDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) NSMutableArray *filteredEditions;
@property (nonatomic, strong) NSMutableArray *allEditions;
@property (nonatomic, strong) NSMutableOrderedSet *categories;
@property (nonatomic, strong) NSString* feedPath;
//@property (nonatomic, strong) NSString* feedURL;
@property (nonatomic, strong) NSString* filterCategory;

@property (nonatomic, strong) NSURLSession *session;
//@property (nonatomic, strong) NSMutableArray *arrFileDownloadData;
//@property (nonatomic, strong) NSURL *docDirectoryURL;

- (IBAction)categoryButtonPressed:(id)sender;
- (void) checkStatus;
- (void) invokeRefresh;
- (void) reloadFeed;


@end
