//
//  HMDInfo.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDInfo.h"

@implementation HMDInfo

+ (instancetype)defaultInfo {
    static HMDInfo *device = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        device = [[HMDInfo alloc] init];
    });
    return device;
}

@end
