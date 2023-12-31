//
//  TMABrightness.m
//  OPPluginBiz
//
//  Created by bupozhuang on 2019/1/2.
//

#import "TMABrightness.h"

@implementation TMABrightness

+ (instancetype)sharedBrightness
{
    static TMABrightness *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TMABrightness alloc] init];
    });
    return instance;
}

@end
