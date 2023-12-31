//
//  BDWebKitVersion.m
//  BDWebKit
//
//  Created by wealong on 2020/1/5.
//

#import "BDWebKitVersion.h"

#ifndef BDWebKit_POD_VERSION
#define BDWebKit_POD_VERSION @"0_0.1.0"
#endif

NSString *_BDWebKitVersion() {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\d+_(\\d+(\\.\\d+){0,2})" options:NSRegularExpressionCaseInsensitive error:nil];

    __block NSString *shortVersion = nil;
    [regex enumerateMatchesInString:BDWebKit_POD_VERSION options:0 range:NSMakeRange(0, BDWebKit_POD_VERSION.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        shortVersion = [BDWebKit_POD_VERSION substringWithRange:[result rangeAtIndex:1]];
        *stop = YES;
    }];

    return shortVersion ?: @"0";
}
