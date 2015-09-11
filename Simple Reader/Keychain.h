//
//  Keychain.h
//  Simple Reader
//
//  Created by Jonas Höchst on 11.09.15.
//  Copyright (c) 2015 vcp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Keychain : NSObject
{
    NSString * service;
    NSString * group;
}
- (id) initWithService:(NSString *) service_ withGroup:(NSString*) group_;

- (BOOL) insertData:(NSData *) data forKey:(NSString *) key;
- (BOOL) updateData:(NSData *) data forKey:(NSString *) key;
- (BOOL) removeDataForKey:(NSString *) key;
- (NSData*) findDataForKey:(NSString*) key;

@end