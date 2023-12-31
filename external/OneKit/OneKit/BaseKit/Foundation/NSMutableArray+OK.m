//
//  NSMutableArray+OK.m
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "NSMutableArray+OK.h"

@implementation NSMutableArray (OK)

- (void)ok_addObject:(id)anObject {
    if (anObject != nil) {
        [self addObject:anObject];
    }
}

@end
