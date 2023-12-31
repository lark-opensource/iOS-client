//
//  NSURL+CJExtension.m
//  Pods
//
//  Created by xiuyuanLee on 2021/4/11.
//

#import "NSURL+CJPay.h"
#import "NSString+CJPay.h"

#import <ByteDanceKit/ByteDanceKit.h>

@implementation NSURL (CJPay)

+ (instancetype)cj_URLWithString:(NSString *)urlString {
    return [NSURL btd_URLWithString:[urlString cj_safeURLString]];
}

- (NSString *)cj_getHostAndPath {
    return [self.absoluteString componentsSeparatedByString:@"?"].firstObject;
}

@end
