//
//  NSArray+OK.m
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "NSArray+OK.h"
#import "NSObject+OK.h"

@implementation NSArray (OK)

- (id)ok_safeJsonObject {
    NSMutableArray *safeEncodingArray = [NSMutableArray array];
    for (id arrayValue in self) {
        id safe = [arrayValue ok_safeJsonObject];
        if (safe) {
            [safeEncodingArray addObject:safe];
        }
    }
    
    return safeEncodingArray.copy;
}

@end
