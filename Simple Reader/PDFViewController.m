//
//  PDFViewController.m
//  Simple Reader
//
//  Created by Jonas Höchst on 09.07.15.
//  Copyright (c) 2015 vcp. All rights reserved.
//

#import "PDFViewController.h"
#import "PreventLongPressGestureRecognizer.h"

@interface PDFViewController ()

@end

@implementation PDFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.edition.title;
    
    [self.navigationController setHidesBarsOnSwipe:YES];
    [self.navigationController setHidesBarsOnTap:YES];
    [self.navigationController setHidesBarsWhenVerticallyCompact:YES];
    
    
    NSURL *url = [NSURL fileURLWithPath:self.edition.pdfPath];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [_webView loadRequest:request];
    
    // Prevent Copy/Paste Menu, with own Recognizer
    PreventLongPressGestureRecognizer *longPress = [[PreventLongPressGestureRecognizer alloc] initWithTarget:self action:nil];
    [_webView addGestureRecognizer:longPress];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController setHidesBarsOnSwipe:NO];
    [self.navigationController setHidesBarsOnTap:NO];
    [self.navigationController setHidesBarsWhenVerticallyCompact:NO];
    
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    return YES;
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
