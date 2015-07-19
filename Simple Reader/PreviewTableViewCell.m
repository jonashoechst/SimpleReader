//
//  PreviewTableViewCell.m
//  Simple Reader
//
//  Created by Jonas Höchst on 09.07.15.
//  Copyright (c) 2015 vcp. All rights reserved.
//

#import "PreviewTableViewCell.h"

@implementation PreviewTableViewCell
@synthesize status;

- (void)setStatus:(FileStatus) setStatus {
    status = setStatus;
    
    switch (setStatus) {
        case available:
            self.statusImageView.image = [UIImage imageNamed:@"cloud@2x.png"];
            self.downloadProgessView.hidden = YES;
            break;
        case downloading:
            self.statusImageView.image = [UIImage imageNamed:@"downloading1@2x.png"];
            self.downloadProgessView.hidden = NO;
            break;
        case downloaded:
            self.statusImageView.image = [UIImage imageNamed:@"okay@2x.png"];
            self.downloadProgessView.hidden = YES;
            break;
        case unavailable:
            self.statusImageView.image = nil;
            self.downloadProgessView.hidden = YES;
            break;
        case paused:
            self.statusImageView.image = [UIImage imageNamed:@"paused@2x.png"];
            self.downloadProgessView.hidden = NO;
            break;
        default:
            self.statusImageView.image = nil;
            self.downloadProgessView.hidden = YES;
            break;
    }
}

- (void)awakeFromNib {
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
//    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
