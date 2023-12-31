//
//  NSArray+CJExtension.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/19.
//

#import "NSArray+CJPay.h"

@implementation NSArray (CJPay)

- (id)cj_objectAtIndex:(NSInteger)index {
    if (index >= 0 && self.count > 0 && index + 1 <= self.count) {
        return [self objectAtIndex:index];
    }
    return nil;
}

- (NSArray *)cj_subarrayWithRange:(NSRange)range {
    if (range.location >= 0 && self.count > 0 && range.location + range.length <= self.count) {
        return [self subarrayWithRange:range];
    }
    return nil;
}

@end
