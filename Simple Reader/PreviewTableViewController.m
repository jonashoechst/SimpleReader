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

@interface PreviewTableViewController ()
@property (nonatomic) NSInteger toDownloadIndex;
@property (strong, nonatomic) NSMutableArray* fileDownloads;
@end

@implementation PreviewTableViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        self.feedPath = [documentDir stringByAppendingPathComponent:@"feed.json"];
        self.feedURL = [NSString stringWithFormat:@"https://hb.jonashoechst.de/feed.json"];
        self.fileDownloads = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor darkGrayColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self action:@selector(updateFeed) forControlEvents:UIControlEventValueChanged];
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"de.vcp.hessen.Downloader"];
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 5;
    self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    
    [self reloadJSONFeed];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Feed related methods

- (void)updateFeed {
    NSError *error = nil;
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.feedURL]];
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse: nil error: &error];
    
    if (error != nil) {
        [self.refreshControl endRefreshing];
        NSLog(@"Error in download from url %@ - %@", self.feedURL, error);
        return;
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:self.feedPath error:&error];
    if (error != nil) {
        NSLog(@"Error in deleting old feed: %@", error);
    }
    
    [responseData writeToFile:self.feedPath atomically:YES];
    [self reloadJSONFeed];
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
    
}
               
- (void) reloadJSONFeed {
    NSError *error = nil;
    NSData *json = [[NSData alloc] initWithContentsOfFile:self.feedPath];
    if (json == nil){
        NSLog(@"No JSON Feed available: %@", error);
        return;
    }
    
    NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:json options:kNilOptions error:&error];
    
    if (error != nil) {
        [self.refreshControl endRefreshing];
        NSLog(@"Error in parsing json feed: %@", error);
        return;
    }
    
    NSMutableArray *newEditions = [[NSMutableArray alloc] init];

    for(NSMutableDictionary *editionDict in jsonDict) {
        [newEditions addObject:[self parseEditionDict:editionDict]];
    }
    
    self.categories = [[NSMutableOrderedSet alloc] initWithCapacity:20];
    
    for(Edition *edition in newEditions){
        [self.categories addObject:edition.category];
    }
    self.allEditions = newEditions;
    
    [self newFilterCategory: self.filterCategory];
}

- (IBAction)categoryButtonPressed:(id)sender {
    
    UIAlertController * view=   [UIAlertController alertControllerWithTitle:@"Wähle eine Kategorie aus..." message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for(NSString *category in self.categories){
        UIAlertAction* option = [UIAlertAction actionWithTitle:category style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            //Do some thing here
            [self newFilterCategory:category];
            [view dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [view addAction:option];
        
    }
    
    
    UIAlertAction* all = [UIAlertAction actionWithTitle:@"Alles anzeigen" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                                [self newFilterCategory:nil];
                                [view dismissViewControllerAnimated:YES completion:nil];
                            }];
    
    [view addAction:all];
    [self presentViewController:view animated:YES completion:nil];
}

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
    
    [self.tableView reloadData];
    
}


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

#pragma mark - Download related Methods

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
        
        messageLabel.text = @"Es sind noch keine Veröffentlichungen vorhanden.\n\n Bitte ziehen um den Feed zu aktualisieren.";
        messageLabel.textColor = [UIColor blackColor];
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont fontWithName:@"Palatino-Italic" size:20];
        [messageLabel sizeToFit];
        
        self.tableView.backgroundView = messageLabel;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    } else  {
        self.tableView.backgroundView = nil;
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
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
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
        NSLog(@"Undefined status of Edition: %lu", selected.status);
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
    
    Edition *edition = self.filteredEditions[self.toDownloadIndex];
    
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

#pragma mark 

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSLog(@"Desicion made");
    
//    switch (popup.tag) {
//        case 1: {
//            switch (buttonIndex) {
//                case 0:
//                    [self FBShare];
//                    break;
//                case 1:
//                    [self TwitterShare];
//                    break;
//                case 2:
//                    [self emailContent];
//                    break;
//                case 3:
//                    [self saveContent];
//                    break;
//                case 4:
//                    [self rateAppYes];
//                    break;
//                default:
//                    break;
//            }
//            break;
//        }
//        default:
//            break;
//    }
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
                    localNotification.alertBody = @"Alle Downloads sind fertig!";
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                }];
            }
        }
    }];
}


@end
