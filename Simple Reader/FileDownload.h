//
//  FileDownloadInfo .h
//  Simple Reader
//
//  Created by Jonas Höchst on 11.07.15.
//  Copyright (c) 2015 vcp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileDownload : NSObject

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *downloadURL;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, strong) NSData *taskResumeData;
@property (nonatomic) double downloadProgress;
//@property (nonatomic) unsigned long taskIdentifier;
@property (nonatomic) BOOL isPaused;

- (id)initWithFilePath:(NSString *)path andDownloadURL:(NSString *)url;
- (BOOL)downloadComplete;

@end