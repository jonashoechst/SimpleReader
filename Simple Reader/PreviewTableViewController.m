//
//  PreviewTableViewController.m
//  Simple Reader
//
//  Created by Jonas Höchst on 08.07.15.
//  Copyright (c) 2015 vcp. All rights reserved.
//

#import "PreviewTableViewController.h"
#import "PreviewTableViewCell.h"
#import "Edition.h"
#import "FileDownload.h"
#import "AppDelegate.h"
#import "PDFViewController.h"
#import "RegisterViewController.h"

@interface PreviewTableViewController ()
@property (nonatomic) NSInteger toDownloadIndex;
@property (strong, nonatomic) NSMutableArray* fileDownloads;
@end

@implementation PreviewTableViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
//        NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
//        self.feedPath = [documentDir stringByAppendingPathComponent:@"feed.json"];
        self.fileDownloads = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    
    // Take action of a user taking screenshots:
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationUserDidTakeScreenshotNotification object:nil queue:mainQueue usingBlock:^(NSNotification *note)
    {
        // take the time the screenshot was taken
        NSDateFormatter *objDateformat = [[NSDateFormatter alloc] init];
        [objDateformat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZ"];
        NSString *timestamp = [objDateformat stringFromDate:[NSDate date]];

        // Get uuid of device
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *uuid = [defaults stringForKey:@"uuid"];
        
        NSString *post = [NSString stringWithFormat:@"uid=%@&timestamp=%@", uuid, timestamp];
        NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[post length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/api/report", ROOT_URL]]];
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[[NSOperationQueue alloc] init]
                               completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError)
        {
            NSError *error = connectionError;
            
            if (error != nil) {
                NSLog(@"Error in reporting screenshot: %@", error);
                return;
            }
            
            NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            if (error != nil) {
                NSLog(@"Error in parsing json feed: %@", error);
                return;
            }
            
            [defaults setObject:[jsonDict objectForKey:@"status"] forKey:@"status"];
            [defaults setObject:[jsonDict objectForKey:@"lastMessage"] forKey:@"lastMessage"];
            NSMutableArray *pubDict = [jsonDict objectForKey:@"publications"];
            [defaults setObject:pubDict forKey:@"publications"];
            [defaults synchronize];

            
            [self checkStatus];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Hesseblättche" message:[jsonDict objectForKey:@"lastMessage"] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
                [self reloadFeed];
                [self.tableView reloadData];
            });
            
        }];
    }];
    
    // configuring statusButton
    CGRect bounds = self.statusButton.bounds;
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    [circleLayer setBounds:bounds];
    [circleLayer setPosition:  CGPointMake(bounds.size.width/2, bounds.size.height/2)];
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:bounds];
    
    [circleLayer setPath:[path CGPath]];
    [circleLayer setStrokeColor:[[UIColor blackColor] CGColor]];
    [circleLayer setLineWidth:0];
//    [circleLayer setOpacity:0.5];
    [self.statusButton.layer addSublayer:circleLayer];
    [self checkStatus];
    
    // configuring refreshControl
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor darkGrayColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self action:@selector(pulledToRefresh) forControlEvents:UIControlEventValueChanged];
    
    // initializing a NSURLSessionConfiguration
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 5;
    self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    
    [self reloadFeed];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SimpleReader API related methods

// Checks state from NSUserDefaults, sets colour or
- (void) checkStatus{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *status = [defaults stringForKey:@"status"];
    CAShapeLayer *circleLayer = (CAShapeLayer*) [[self.statusButton.layer sublayers] objectAtIndex:0];
    
    if ( status == nil || [status isEqualToString:@"unknown"] ){
        [circleLayer setFillColor:[[UIColor whiteColor] CGColor]];
        
        // Call RegisterView Controller, if device is unknown.
        dispatch_async(dispatch_get_main_queue(), ^{
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
            UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"RegisterView"];
            [self presentViewController:vc animated:YES completion:nil];
        });
    } else if ([status isEqualToString:@"new"] ){
        [circleLayer setFillColor:[[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.5] CGColor]];
    } else if ([status isEqualToString:@"green"] ){
        // Battery Icon Colour
        [circleLayer setFillColor:[[UIColor colorWithRed:76.0/255.0 green:217.0/255.0 blue:100.0/255.0 alpha:1.0] CGColor]];
    } else if ([status isEqualToString:@"yellow"] ){
        // Battery Icon Colour
        [circleLayer setFillColor:[[UIColor colorWithRed:255.0/255.0 green:204.0/255.0 blue:0.0/255.0 alpha:1.0] CGColor]];
    } else if ([status isEqualToString:@"red"]) {
        // Heavy read, battery colour is unknown at this point
        [circleLayer setFillColor:[[UIColor colorWithRed:255.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0] CGColor]];
        
        // Empty publications fromNSUserDefaults
        [defaults setObject:[[NSArray alloc] init] forKey:@"publications"];
        [defaults synchronize];
        
        // If a PDF is viewed, pop it from the navigation controller.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.navigationController.topViewController != self){
                [[self navigationController] setNavigationBarHidden:NO animated:YES];
                [[self navigationController] popViewControllerAnimated:YES];
            }
        });
    }

}

// Simulates the User pulling to refresh
- (void) invokeRefresh{
    [self.refreshControl beginRefreshing];
    [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y-self.refreshControl.frame.size.height) animated:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self pulledToRefresh];
    });
}

// Method to be called after a Pull To Refresh
- (void) pulledToRefresh {
    [self updateFeed];
    [self checkStatus];
    [self reloadFeed];
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}

// Updates the feed from the server
- (void)updateFeed {
    NSError *error = nil;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [defaults stringForKey:@"uuid"];
    
    NSString *post = [NSString stringWithFormat:@"uid=%@", uuid];
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/api/feed", ROOT_URL]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse: nil error: &error];
    if (error != nil) {
        NSLog(@"Error in download from url: %@", error);
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Aktualisieren fehlgeschlagen." message:[error localizedDescription] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        
        return;
    }
    
    NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
    if (error != nil) {
        NSLog(@"Error in parsing json feed: %@", error);
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Aktualisieren fehlgeschlagen." message:[error localizedDescription] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        
        return;
    }
    
    [defaults setObject:[jsonDict objectForKey:@"status"] forKey:@"status"];
    [defaults setObject:[jsonDict objectForKey:@"lastMessage"] forKey:@"lastMessage"];
    [defaults setObject:[jsonDict objectForKey:@"publications"] forKey:@"publications"];
    [defaults synchronize];
}

// reloads the JsonFeed from NSUserDefaults
- (void) reloadFeed{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *pubDict = [defaults objectForKey:@"publications"];
    
    NSMutableArray *newEditions = [[NSMutableArray alloc] init];
    self.categories = [[NSMutableOrderedSet alloc] initWithCapacity:20];
    
    for(NSMutableDictionary *editionDict in pubDict) {
        Edition *edition = [self parseEditionDict:editionDict];
        [newEditions addObject:edition];
        [self.categories addObject:edition.category];
    }
    
    self.allEditions = newEditions;
    [self newFilterCategory: self.filterCategory];
}

- (IBAction)statusButtonPressed:(id)sender {
}

// Creates and shows the category chooser
- (IBAction)categoryButtonPressed:(id)sender {
    UIAlertController * view =   [UIAlertController alertControllerWithTitle:@"Wähle eine Kategorie aus..." message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // Use different Style on iPads
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        view.popoverPresentationController.barButtonItem = sender;
    
    for(NSString *category in self.categories){
        UIAlertAction* option = [UIAlertAction actionWithTitle:category style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self newFilterCategory:category];
            [view dismissViewControllerAnimated:YES completion:nil];
            [self.tableView reloadData];
        }];
        
        [view addAction:option];
    }
    
    UIAlertAction* all = [UIAlertAction actionWithTitle:@"Alles anzeigen" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        [self newFilterCategory:nil];
        [view dismissViewControllerAnimated:YES completion:nil];
        [self.tableView reloadData];
    }];
    
    [view addAction:all];
    [self presentViewController:view animated:YES completion:nil];
}

// sets a new filterCategory and filters the matching editions
- (void) newFilterCategory:(NSString *)category{
    self.filterCategory = category;
    
    if (category == nil) {
        self.filteredEditions = self.allEditions;
        self.title = @"Alle Hefte";
    } else {
        self.title = self.filterCategory;
        self.filteredEditions = [[NSMutableArray alloc] init];
        for (Edition *edition in self.allEditions){
            if ([edition.category isEqualToString:self.filterCategory]){
                [self.filteredEditions addObject:edition];
            }
        }
    }
}

// parses the Editions from a json editionDict
- (Edition *) parseEditionDict:(NSMutableDictionary *)editionDict {
    
    Edition *edition = [[Edition alloc] init];
    
    edition.title = [editionDict objectForKey:@"title"];
    edition.shortDescription = [editionDict objectForKey:@"shortDescription"];
    edition.previewUrl = [editionDict objectForKey:@"previewUrl"];
    edition.pdfUrl = [editionDict objectForKey:@"pdfUrl"];
    edition.filesize = [editionDict objectForKey:@"filesize"];
    edition.category = [editionDict objectForKey:@"category"];
    
    NSString *releaseDateString = [editionDict objectForKey:@"releaseDate"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZ"];
    edition.releaseDate = [dateFormatter dateFromString:releaseDateString];
    
    NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    // Check preview availability, else download image
    NSString *previewFilename = [[edition.previewUrl componentsSeparatedByString:@"/"] lastObject];
    NSString *previewFilePath = [documentDir stringByAppendingPathComponent:previewFilename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:previewFilePath]){
        edition.previewImage = [UIImage imageNamed:previewFilePath];
    } else {
        [self downloadPreviewImageFromURL:edition.previewUrl toFilePath:previewFilePath forEdition:edition];
    }
    
    // Check pdf availability
    NSString *pdfFilename = [[edition.pdfUrl componentsSeparatedByString:@"/"] lastObject];
    NSString *pdfFilePath = [documentDir stringByAppendingPathComponent:pdfFilename];
    edition.pdfPath = pdfFilePath;
    
    FileDownload* download = [self getFileDownloadForUrl:edition.pdfUrl];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:pdfFilePath]){
        edition.status = downloaded;
    } else if (download != nil){
        edition.fileDownload = download;
        edition.status = downloading;
        if (download.isPaused) {
            edition.status = paused;
        }
    } else {
        edition.status = available;
    }
    
    return edition;
}

#pragma mark - Download related Methods

- (void) downloadPreviewImageFromURL:(NSString*) url toFilePath:(NSString*) filePath forEdition:(Edition*) edition{
    NSURLRequest *previewRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    
    [NSURLConnection sendAsynchronousRequest:previewRequest queue:[NSOperationQueue currentQueue] completionHandler:
     ^(NSURLResponse *previewRequest, NSData *data, NSError *error) {
         if (error) {
             NSLog(@"Preview Image Download Error: %@", error);
         }
         if (data) {
             [data writeToFile:filePath atomically:YES];
             edition.previewImage  = [UIImage imageNamed:filePath];
             [self.tableView reloadData];
         }
     }];
}

- (FileDownload*) getFileDownloadForUrl:(NSString *)url{
    for(FileDownload* download in self.fileDownloads){
        if ([download.downloadURL isEqualToString:url])
            return download;
    }
    return nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.filteredEditions == nil || [self.filteredEditions count] == 0){
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        NSString *lastMessage = [defaults objectForKey:@"lastMessage"];
        NSString *text = [NSString stringWithFormat:@"%@\n\nNach unten ziehen um den Feed und den Status zu aktualisieren.", lastMessage];
        
        messageLabel.text = text;
        messageLabel.textColor = [UIColor blackColor];
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont fontWithName:@"Palatino-Italic" size:20];
        [messageLabel sizeToFit];
        
        self.tableView.backgroundView = messageLabel;
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    } else  {
        self.tableView.backgroundView = nil;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.filteredEditions count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PreviewTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PreviewCell"];
    
    Edition *edition= self.filteredEditions[indexPath.row];
    cell.title.text = edition.title;
    cell.descriptionText.text = edition.shortDescription;
    cell.coverImageView.image = edition.previewImage;
    
    [cell setStatus:edition.status];
    if (edition.status == downloading) cell.downloadProgessView.progress = edition.fileDownload.downloadProgress;

    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Edition* editon = self.filteredEditions[indexPath.row];
    if (editon.status == downloaded || editon.status == paused)
        return YES;
    
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        Edition* selected = [self.filteredEditions objectAtIndex:indexPath.row];
        if (selected.status == downloaded){
            NSError *error;
            NSFileManager *fileManager =[NSFileManager defaultManager];
            NSURL *destinationURL = [NSURL fileURLWithPath:selected.pdfPath];
            
            if ([fileManager fileExistsAtPath:[destinationURL path]])
                [fileManager removeItemAtURL:destinationURL error:&error];
            
            if (error != nil) NSLog(@"Error removing file: %@", error);
            
            selected.status = available;
            selected.fileDownload.downloadProgress = 0.0;
            
            NSArray* indexPaths = [[NSArray alloc] initWithObjects:indexPath, nil];
            [tableView reloadRowsAtIndexPaths: indexPaths withRowAnimation:UITableViewRowAnimationNone];
        } else if (selected.status == paused) {
            FileDownload* download = [self getFileDownloadForUrl:selected.pdfUrl];
            
            [download.downloadTask cancel];
            [self.fileDownloads removeObject:download];
            
            selected.status = available;
            NSArray* indexPaths = [[NSArray alloc] initWithObjects:indexPath, nil];
            [tableView reloadRowsAtIndexPaths: indexPaths withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    Edition *selected = self.filteredEditions[self.tableView.indexPathForSelectedRow.row];
    
    if(selected.status == downloaded){
        return YES;
    } else if (selected.status == available) {
        NSString *question = [NSString stringWithFormat:@"Möchtest du die Ausgabe \"%@\" jetzt herunterladen? (%@)", [selected title], [selected filesize]];
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Download" message:question delegate:self cancelButtonTitle:@"Abbrechen" otherButtonTitles:@"Herunterladen",nil];
        alert.tag = downloadQuestion;
        self.toDownloadIndex = self.tableView.indexPathForSelectedRow.row;
        [alert show];
        
        return NO;
    } else if (selected.status == downloading){
        NSString *status = [NSString stringWithFormat:@"Die Ausgabe \"%@\" wird gerade herunterladen... Möchtest den Download anhalten?", [selected title]];
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Download läuft" message:status delegate:self cancelButtonTitle:@"Fortfahren" otherButtonTitles:@"Pausieren",nil];
        alert.tag = pauseQuestion;
        self.toDownloadIndex = self.tableView.indexPathForSelectedRow.row;
        [alert show];
        return NO;
        
    } else if (selected.status == paused) {
        NSString *status = [NSString stringWithFormat:@"Der Download der Ausgabe \"%@\" ist angehalten. Möchtest den Download fortfahren?", [selected title]];
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Download läuft" message:status delegate:self cancelButtonTitle:@"Abbrechen" otherButtonTitles:@"Fortfahren",nil];
        alert.tag = continueQuestion;
        self.toDownloadIndex = self.tableView.indexPathForSelectedRow.row;
        [alert show];
        return NO;
    } else if (selected.status == unavailable){
        NSString *question = [NSString stringWithFormat:@"Beim Download der Ausgabe \"%@\" scheint etwas schief gelaufen zu sein. Möchtest du es erneut versuchen? (%@)", [selected title], [selected filesize]];
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Download" message:question delegate:self cancelButtonTitle:@"Abbrechen" otherButtonTitles:@"Herunterladen",nil];
        alert.tag = downloadQuestion;
        self.toDownloadIndex = self.tableView.indexPathForSelectedRow.row;
        [alert show];
        return NO;
    } else {
        NSLog(@"Undefined status of Edition: %lu", (unsigned long)selected.status);
        return NO;
    }
}


// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    Edition *selected = self.filteredEditions[self.tableView.indexPathForSelectedRow.row];
    PDFViewController *pdfViewController = segue.destinationViewController;
    pdfViewController.edition = selected;
}

#pragma mark Alert View Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    Edition *edition;
    if ([self.filteredEditions count] > self.toDownloadIndex)
        edition = self.filteredEditions[self.toDownloadIndex];
    
    if (alertView.tag == downloadQuestion) {
        if (buttonIndex == 1) {
            NSLog(@"Download wurde angefordert.");
            
            FileDownload *download = [[FileDownload alloc] initWithFilePath:edition.pdfPath andDownloadURL:edition.pdfUrl];
            download.downloadTask = [self.session downloadTaskWithURL:[NSURL URLWithString:edition.pdfUrl]];
//            download.taskIdentifier = download.downloadTask.taskIdentifier;
            download.downloadProgress = 0.0;
            
            edition.status = downloading;
            edition.fileDownload = download;
            
            [download.downloadTask resume];
            
            [self.fileDownloads addObject:download];
            
            NSArray* indexPaths = [[NSArray alloc] initWithObjects:[NSIndexPath indexPathForRow:self.toDownloadIndex inSection:0], nil];
            [self.tableView reloadRowsAtIndexPaths: indexPaths withRowAnimation:UITableViewRowAnimationNone];
        }
    } else if (alertView.tag == pauseQuestion) {
        if (buttonIndex == 1) {
            NSLog(@"Download soll pausiert werden.");
            
            edition.status = paused;
            [edition.fileDownload.downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
                if (resumeData != nil) {
                    edition.fileDownload.taskResumeData = [[NSData alloc] initWithData:resumeData];
                }
            }];
            
            NSArray* indexPaths = [[NSArray alloc] initWithObjects:[NSIndexPath indexPathForRow:self.toDownloadIndex inSection:0], nil];
            [self.tableView reloadRowsAtIndexPaths: indexPaths withRowAnimation:UITableViewRowAnimationNone];
        }
    } else if (alertView.tag == continueQuestion){
        if (buttonIndex == 1) {
            NSLog(@"Download soll fortgefahren werden.");
            
            edition.status = downloading;
            
            edition.fileDownload.downloadTask = [self.session downloadTaskWithResumeData:edition.fileDownload.taskResumeData];
            [edition.fileDownload.downloadTask resume];
//            edition.fileDownload.taskIdentifier = edition.fileDownload.downloadTask.taskIdentifier;
            
            NSArray* indexPaths = [[NSArray alloc] initWithObjects:[NSIndexPath indexPathForRow:self.toDownloadIndex inSection:0], nil];
            [self.tableView reloadRowsAtIndexPaths: indexPaths withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

#pragma mark URL Session Delegate Helpers 
-(Edition*) getEditionForDownloadTaskIdentifier:(NSUInteger) taskIdentifier{
    for(Edition* edition in self.filteredEditions){
        if (edition.fileDownload.downloadTask.taskIdentifier == taskIdentifier)
            return edition;
    }
    
    return nil;
}

#pragma mark URL Session Delegates

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    if (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) {
        NSLog(@"Unknown transfer size");
    }
    else{
        Edition* edition = [self getEditionForDownloadTaskIdentifier:downloadTask.taskIdentifier];
        long index = [self.filteredEditions indexOfObject:edition];

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            edition.fileDownload.downloadProgress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
            
            NSArray* indexPaths = [[NSArray alloc] initWithObjects:[NSIndexPath indexPathForRow:index inSection:0], nil];
            [self.tableView reloadRowsAtIndexPaths: indexPaths withRowAnimation:UITableViewRowAnimationNone];
        }];
    }    
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSError *error;
    NSFileManager *fileManager =[NSFileManager defaultManager];
    
    Edition* edition = [self getEditionForDownloadTaskIdentifier:downloadTask.taskIdentifier];
    NSURL *destinationURL = [NSURL fileURLWithPath:edition.pdfPath];
    
    if ([fileManager fileExistsAtPath:[destinationURL path]]) [fileManager removeItemAtURL:destinationURL error:&error];
    if (error != nil) NSLog(@"Error removing file: %@", error);

    BOOL success = [fileManager copyItemAtURL:location toURL:destinationURL error:&error];
    if (success) {
        edition.status = downloaded;
        edition.fileDownload.downloadProgress = 100.0;
        edition.fileDownload.taskResumeData = nil;
        [self.fileDownloads removeObject:edition.fileDownload];
        
        [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    } else {
        NSLog(@"Downloaded file could not be copied: %@", error);
    }
}

-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    // Check if all download tasks have been finished.
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        if ([downloadTasks count] == 0) {
            if (appDelegate.backgroundTransferCompletionHandler != nil) {
                // Copy locally the completion handler.
                void(^completionHandler)() = appDelegate.backgroundTransferCompletionHandler;
                
                // Make nil the backgroundTransferCompletionHandler.
                appDelegate.backgroundTransferCompletionHandler = nil;
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    // Call the completion handler to tell the system that there are no other background transfers.
                    completionHandler();
                    
                    // Show a local notification when all downloads are over.
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.alertBody = @"Alle Downloads erfolgreich abgeschlossen.";
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                }];
            }
        }
    }];
}


@end
