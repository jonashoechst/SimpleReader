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
#import "AppDelegate.h"
#import "PDFViewController.h"

@interface PreviewTableViewController ()

@property (nonatomic) NSInteger toDownloadIndex;

@end


@implementation PreviewTableViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        self.feedPath = [documentDir stringByAppendingPathComponent:@"feed.json"];
        self.feedURL = [NSString stringWithFormat:@"https://hb.jonashoechst.de/feed.json"];
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

#pragma mark own methods

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
//    NSLog(@"%@",[[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding]);
    [self reloadJSONFeed];
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
    
}
               
- (void) reloadJSONFeed {

    NSData *json = [[NSData alloc] initWithContentsOfFile:self.feedPath];
    NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:json options:kNilOptions error:nil];
    
    NSMutableArray *newEditions = [[NSMutableArray alloc] initWithCapacity:20];

    for(NSString *key in jsonDict) {
        [newEditions addObject:[self parseEditionDict:[jsonDict objectForKey:key]]];
    }
    
    self.editions = newEditions;
}


- (Edition *) parseEditionDict:(NSMutableDictionary *)editionDict {
    
    Edition *edition = [[Edition alloc] init];
    
    edition.title = [editionDict objectForKey:@"title"];
    edition.shortDescription = [editionDict objectForKey:@"shortDescription"];
    // using @2x relation from json file
    edition.previewUrl = [editionDict objectForKey:@"previewUrl"];
    edition.pdfUrl = [editionDict objectForKey:@"pdfUrl"];
    edition.filesize = [editionDict objectForKey:@"filesize"];
    
    NSString *releaseDateString = [editionDict objectForKey:@"releaseDate"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZ"];
    edition.releaseDate = [dateFormatter dateFromString:releaseDateString];
    
    NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    // Check preview availability
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
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:pdfFilePath]){
        edition.status = downloaded;
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
            NSLog(@"Download Error:%@",error.description);
        }
        if (data) {
            [data writeToFile:filePath atomically:YES];
            edition.previewImage  = [UIImage imageNamed:filePath];
            // TODO: Reload Cell at index.
            [self.tableView reloadData];
            NSLog(@"File is saved to %@",filePath);
        }
    }];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.editions == nil || [self.editions count] == 0){
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        
        messageLabel.text = @"Es sind noch keine Veröffentlichungen vorhanden.\n\n Bitte ziehen um den Feed zu aktualisieren.";
        messageLabel.textColor = [UIColor blackColor];
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont fontWithName:@"Palatino-Italic" size:20];
        [messageLabel sizeToFit];
        
        self.tableView.backgroundView = messageLabel;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.editions count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PreviewTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PreviewCell"];
    
    Edition *edition= self.editions[indexPath.row];
    cell.title.text = edition.title;
    cell.descriptionText.text = edition.shortDescription;
    cell.coverImageView.image = edition.previewImage;
    
    UIProgressView *progressView = cell.downloadProgessView;
    progressView.progress = edition.downloadProgress;
    
    [cell setStatus:edition.status];

    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Edition* editon = self.editions[indexPath.row];
    if (editon.status == downloaded)
        return YES;
    
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        Edition* selected = [self.editions objectAtIndex:indexPath.row];
        if (selected.status == downloaded){
            NSError *error;
            NSFileManager *fileManager =[NSFileManager defaultManager];
            NSURL *destinationURL = [NSURL fileURLWithPath:selected.pdfPath];
            
            if ([fileManager fileExistsAtPath:[destinationURL path]])
                [fileManager removeItemAtURL:destinationURL error:&error];
            
            if (error != nil) NSLog(@"Error removing file: %@", error);
            
            selected.status = available;
            selected.downloadProgress = 0.0;
            
            NSArray* indexPaths = [[NSArray alloc] initWithObjects:indexPath, nil];
            [tableView reloadRowsAtIndexPaths: indexPaths withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    Edition *selected = self.editions[self.tableView.indexPathForSelectedRow.row];
    
    if(selected.status == downloaded){
        return YES;
    } else if (selected.status == available) {
        NSString *question = [NSString stringWithFormat:@"Möchtest du die Ausgabe \"%@\" jetzt herunterladen? (%@)", [selected title], [selected filesize]];
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Download" message:question delegate:self cancelButtonTitle:@"Abbrechen" otherButtonTitles:@"Herunterladen",nil];
        alert.tag = 1;
        self.toDownloadIndex = self.tableView.indexPathForSelectedRow.row;
        [alert show];
        
        return NO;
    } else if (selected.status == downloading){
        NSString *status = [NSString stringWithFormat:@"Die Ausgabe \"%@\" wird gerade herunterladen...", [selected title]];
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Download läuft" message:status delegate:self cancelButtonTitle:@"Fortfahren" otherButtonTitles:@"Pausieren",nil];
        alert.tag = 2;
        self.toDownloadIndex = self.tableView.indexPathForSelectedRow.row;
        [alert show];
        return NO;
        
    } else if (selected.status == paused) {
        selected.downloadTask = [self.session downloadTaskWithResumeData:selected.taskResumeData];
        [selected.downloadTask resume];
        selected.taskIdentifier = selected.downloadTask.taskIdentifier;
        
        return NO;
    } else if (selected.status == unavailable){
        NSString *question = [NSString stringWithFormat:@"Beim Download der Ausgabe \"%@\" scheint etwas schief gelaufen zu sein. Möchtest du es erneut versuchen? (%@)", [selected title], [selected filesize]];
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Download" message:question delegate:self cancelButtonTitle:@"Abbrechen" otherButtonTitles:@"Herunterladen",nil];
        alert.tag = 1;
        self.toDownloadIndex = self.tableView.indexPathForSelectedRow.row;
        [alert show];
        return NO;
    } else {
        return NO;
    }
}


// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    Edition *selected = self.editions[self.tableView.indexPathForSelectedRow.row];
    PDFViewController *pdfViewController = segue.destinationViewController;
    
    pdfViewController.edition = selected;
}

#pragma mark Alert View Reaction

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // the user clicked OK
    if (alertView.tag == 1) {
        if (buttonIndex == 0) {
            NSLog(@"Download abgebrochen.");
        } else {
            NSLog(@"Download gewollt!");
            Edition *edition = self.editions[self.toDownloadIndex];
            if(edition.taskIdentifier == -1){
                edition.downloadTask = [self.session downloadTaskWithURL:[NSURL URLWithString:edition.pdfUrl]];
                edition.taskIdentifier = edition.downloadTask.taskIdentifier;
                edition.status = downloading;
                [edition.downloadTask resume];
                edition.downloadProgress = 0.0;
                NSArray* indexPaths = [[NSArray alloc] initWithObjects:[NSIndexPath indexPathForRow:self.toDownloadIndex inSection:0], nil];
                [self.theTableView reloadRowsAtIndexPaths: indexPaths withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    }
    if (alertView.tag == 2) {
        if (buttonIndex == 0) {
            NSLog(@"Download wird fortgefahren.");
        } else {
            NSLog(@"Download pausieren!");
            Edition *edition = self.editions[self.toDownloadIndex];
            [edition.downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
                if (resumeData != nil) {
                    edition.taskResumeData = [[NSData alloc] initWithData:resumeData];
                }
            }];
        }
    }
    
}

#pragma mark URL Session Delegate Helpers 
-(int) getEditionIndexWithTaskIdentifier:(NSUInteger) identifier{
    for(int i = 0; i < [self.editions count]; i++){
        if (((Edition*)self.editions[i]).taskIdentifier == identifier) {
            return i;
        }
    }
    return -1;
}

#pragma mark URL Session Delegates

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    if (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) {
        NSLog(@"Unknown transfer size");
    }
    else{
        int index = [self getEditionIndexWithTaskIdentifier:downloadTask.taskIdentifier];
        Edition *edition = [self.editions objectAtIndex:index];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            edition.downloadProgress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
            
            NSArray* indexPaths = [[NSArray alloc] initWithObjects:[NSIndexPath indexPathForRow:index inSection:0], nil];
            [self.theTableView reloadRowsAtIndexPaths: indexPaths withRowAnimation:UITableViewRowAnimationNone];
        }];
        
    }    
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSError *error;
    NSFileManager *fileManager =[NSFileManager defaultManager];
    
    int index = [self getEditionIndexWithTaskIdentifier:downloadTask.taskIdentifier];
    Edition *edition = self.editions[index];
    
    NSURL *destinationURL = [NSURL fileURLWithPath:edition.pdfPath];
    
    if ([fileManager fileExistsAtPath:[destinationURL path]])
        [fileManager removeItemAtURL:destinationURL error:&error];
    
    if (error != nil) {
        NSLog(@"Error removing file: %@", error);
    }

    BOOL success = [fileManager copyItemAtURL:location toURL:destinationURL error:&error];
    
    if (success) {
        edition.status = downloaded;
        edition.downloadProgress = 100.0;
        edition.taskIdentifier = -1;
        edition.taskResumeData = nil;
        
        [self.theTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
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
