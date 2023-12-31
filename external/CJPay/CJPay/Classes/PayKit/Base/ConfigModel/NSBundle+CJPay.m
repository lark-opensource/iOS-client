//
//  NSBundle+CJPay.m
//  CJPay
//
//  Created by 王新华 on 2019/5/14.
//

#import "NSBundle+CJPay.h"
#import "CJPayCommonUtil.h"

static NSString * const CJPayBundleRalativeAddress = @"/CJPay.bundle";

@implementation NSBundle(CJPay)

+ (NSBundle *)cj_customPayBundle {
    NSString *path = [[NSBundle bundleForClass:[CJPayCommonUtil class]].resourcePath stringByAppendingPathComponent:CJPayBundleRalativeAddress];
    NSBundle *resource_bundle = [NSBundle bundleWithPath:path];
    return resource_bundle;
}

@end
