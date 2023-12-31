//
//  NSAttributedString+BTDAdditions.m
//  ByteDanceKit
//
//  Created by bytedance on 2020/12/30.
//

#import "NSAttributedString+BTDAdditions.h"

@implementation NSAttributedString (BTDAdditions)

+ (instancetype)btd_attributedStringWithString:(NSString *)str {
    NSParameterAssert(str != nil);
    if (!str) {
        return nil;
    }
    return [[self alloc] initWithString:str];
}

+ (instancetype)btd_attributedStringWithString:(NSString *)str attributes:(NSDictionary<NSAttributedStringKey, id> *)attrs {
    NSParameterAssert(str != nil);
    if (!str) {
        return nil;
    }
    return [[self alloc] initWithString:str attributes:attrs];
}

@end

