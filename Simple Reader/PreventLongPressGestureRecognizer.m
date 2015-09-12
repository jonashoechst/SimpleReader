//
//  PreventLongPressGestureRecognizer.m
//  Simple Reader
//
//  Created by Jonas Höchst on 12.09.15.
//  Copyright (c) 2015 vcp. All rights reserved.
//

#import "PreventLongPressGestureRecognizer.h"

@implementation PreventLongPressGestureRecognizer

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer*)preventedGestureRecognizer {
    return NO;
}

@end
