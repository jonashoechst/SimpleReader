//
//  Edition.m
//  Simple Reader
//
//  Created by Jonas Höchst on 08.07.15.
//  Copyright (c) 2015 vcp. All rights reserved.
//

#import "Edition.h"

@implementation Edition

-(id)init {
    if (self == [super init]) {
        self.downloadProgress = 0.0;
        self.taskIdentifier = -1;
    }
    
    return self;
}


@end
