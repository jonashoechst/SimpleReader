//
//  FileDownloadInfo .m
//  Simple Reader
//
//  Created by Jonas Höchst on 11.07.15.
//  Copyright (c) 2015 vcp. All rights reserved.
//

#import "FileDownload.h"

@implementation FileDownload


-(id)initWithFilePath:(NSString *)path andDownloadURL:(NSString *)url{
    if (self == [super init]) {
        self.filePath = path;
        self.downloadURL = url;
        self.downloadProgress = 0.0;
//        self.taskIdentifier = -1;
        self.isPaused = false;
    }
    
    return self;
}

- (BOOL)downloadComplete{
    return self.downloadProgress == 100.0f;
}



@end
