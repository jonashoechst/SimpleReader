//
//  Edition.h
//  Simple Reader
//
//  Created by Jonas Höchst on 08.07.15.
//  Copyright (c) 2015 vcp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum FileStatus : NSUInteger {
    available,
    downloading,
    downloaded,
    unavailable,
    paused
} FileStatus;

@interface Edition : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *shortDescription;
@property (nonatomic, strong) NSString *pdfUrl;
@property (nonatomic, strong) NSString *pdfPath;
@property (nonatomic, strong) NSString *previewUrl;
@property (nonatomic, strong) UIImage *previewImage;
@property (nonatomic, strong) NSDate *releaseDate;
@property (nonatomic, strong) NSString *filesize;
@property (nonatomic) FileStatus status;


@property (nonatomic) unsigned long taskIdentifier;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, strong) NSData *taskResumeData;
@property (nonatomic) double downloadProgress;


@end
