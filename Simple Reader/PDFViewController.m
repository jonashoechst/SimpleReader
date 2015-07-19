//
//  PDFViewController.m
//  Simple Reader
//
//  Created by Jonas Höchst on 09.07.15.
//  Copyright (c) 2015 vcp. All rights reserved.
//

#import "PDFViewController.h"

@interface PDFViewController ()

@end

@implementation PDFViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.edition.title;
    
    NSURL *url = [NSURL fileURLWithPath:self.edition.pdfPath];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [_webView loadRequest:request];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
