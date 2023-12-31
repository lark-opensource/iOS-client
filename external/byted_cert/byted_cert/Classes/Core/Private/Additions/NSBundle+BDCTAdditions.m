//
//  NSBundle+BDCTAdditions.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2022/2/6.
//

#import "NSBundle+BDCTAdditions.h"


@implementation NSBundle (BDCTAdditions)

+ (NSBundle *)bdct_bundle {
    return [NSBundle bundleWithPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"byted_cert.bundle"]];
}

@end
