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
    // Saving scroll position
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *contentOffsetString = NSStringFromCGPoint(_webView.scrollView.contentOffset);
    CGFloat zoomScale = _webView.scrollView.zoomScale;
    [defaults setObject:contentOffsetString forKey:[NSString stringWithFormat:@"%@-contentOffset", self.edition.pdfPath]];
    [defaults setFloat:zoomScale forKey:[NSString stringWithFormat:@"%@-zoomScale", self.edition.pdfPath]];
    [defaults synchronize];
    
    // Resetting navigationBar / properties
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    [super viewWillDisappear:animated];
    
    [self.navigationController setHidesBarsOnSwipe:NO];
    [self.navigationController setHidesBarsOnTap:NO];
    [self.navigationController setHidesBarsWhenVerticallyCompact:NO];
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    // Restoring scroll / zoom position
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *contentOffsetString = [defaults objectForKey:[NSString stringWithFormat:@"%@-contentOffset", self.edition.pdfPath]];
    CGFloat zoomScale = [defaults floatForKey:[NSString stringWithFormat:@"%@-zoomScale", self.edition.pdfPath]];
    
    CGPoint contentOffset;
    if (contentOffsetString)
        contentOffset = CGPointFromString(contentOffsetString);
    else
        contentOffset = CGPointMake(0, -self.navigationController.navigationBar.frame.size.height);
    
    _webView.scrollView.zoomScale = zoomScale;
    _webView.scrollView.contentOffset = contentOffset;
}


@end
