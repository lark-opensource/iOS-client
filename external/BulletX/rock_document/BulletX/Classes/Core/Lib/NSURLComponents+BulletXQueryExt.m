//
//  NSURLComponents+BulletXQueryExt.m
//  AAWELaunchOptimization
//
//  Created by duanefaith on 2019/10/12.
//

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import "NSURLComponents+BulletXQueryExt.h"

@implementation NSURLComponents (BulletXQueryExt)

- (void)bullet_appendQueryItem:(NSURLQueryItem *)queryItem
{
    NSMutableArray<NSURLQueryItem *> *queryItems = [[NSMutableArray alloc] initWithArray:self.queryItems];
    [queryItems btd_addObject:queryItem];
    self.queryItems = queryItems;
}

- (void)bullet_prependQueryItem:(NSURLQueryItem *)queryItem
{
    NSMutableArray<NSURLQueryItem *> *queryItems = [[NSMutableArray alloc] initWithArray:self.queryItems];
    [queryItems btd_insertObject:queryItem atIndex:0];
    self.queryItems = queryItems;
}

@end
