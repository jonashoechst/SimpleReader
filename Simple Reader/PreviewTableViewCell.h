//
//  PreviewTableViewCell.h
//  Simple Reader
//
//  Created by Jonas Höchst on 09.07.15.
//  Copyright (c) 2015 vcp. All rights reserved.
//

#import "Edition.h"

@interface PreviewTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *title;
@property (nonatomic, weak) IBOutlet UITextView *descriptionText;
@property (nonatomic, weak) IBOutlet UIImageView *coverImageView;
@property (nonatomic, weak) IBOutlet UIImageView *statusImageView;
@property (nonatomic, weak) IBOutlet UIProgressView *downloadProgessView;
@property (nonatomic) FileStatus status;


@end
