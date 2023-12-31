//
//  NSString+HMDSafe.m
//  AFgzipRequestSerializer-iOS13.0
//
//  Created by xuminghao.eric on 2019/11/18.
//

#import "NSString+HMDSafe.h"

@implementation NSString (HMDSafe)

- (BOOL)hmd_characterAtIndex:(NSInteger)index writeToChar:(char *)charactor{
    if(index >= [self length]){
        return false;
    } else {
        *charactor = [self characterAtIndex:index];
        return true;
    }
}

- (NSString *)hmd_substringToIndex:(NSInteger)index{
    if(index > [self length]){
        return nil;
    } else {
        return [self substringToIndex:index];
    }
}

- (NSString *)hmd_substringWithRange:(NSRange)range{
    if(range.length == 0){
        return nil;
    }
    if((range.length + range.location) > [self length]){
        return nil;
    } else {
        return [self substringWithRange:range];
    }
}

@end
