//
//  VCABRConfig.m
//  ABRInterface
//
//  Created by shen chen on 2020/8/20.
//

#import "VCABRConfig.h"

static NSInteger s4GMaxBitrate;

@implementation VCABRConfig

+ (void)set4GMaxBitrate:(NSInteger)maxbitrate {
    s4GMaxBitrate = maxbitrate;
}

+ (NSInteger)get4GMaxBitrate {
    return s4GMaxBitrate;
}

@end
