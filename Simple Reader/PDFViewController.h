//
//  PDFViewController.h
//  Simple Reader
//
//  Created by Jonas Höchst on 09.07.15.
//  Copyright (c) 2015 vcp. All rights reserved.
//

#import "Edition.h"

@interface PDFViewController : UIViewController <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (strong, nonatomic) Edition *edition;

@end
