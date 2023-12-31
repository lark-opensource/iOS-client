//
//  NSArray+BDTuring.m
//  BDTuring
//
//  Created by bob on 2020/7/9.
//

#import "NSArray+BDTuring.h"
#import "NSObject+BDTuring.h"

@implementation NSArray (BDTuring)

- (id)turing_safeJsonObject {
    NSMutableArray *safeEncodingArray = [NSMutableArray new];
    for (id arrayValue in self) {
        id safe = [arrayValue turing_safeJsonObject];
        if (safe) {
            [safeEncodingArray addObject:safe];
        }
    }
    
    return safeEncodingArray.copy;
}

@end
