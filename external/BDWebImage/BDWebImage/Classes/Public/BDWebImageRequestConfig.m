//
//  BDWebImageRequestConfig.m
//  BDWebImage
//
//  Created by 陈奕 on 2020/10/30.
//

#import "BDWebImageRequestConfig.h"

@implementation BDWebImageRequestConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.size = CGSizeZero;
        self.timeoutInterval = 15;
        self.cacheName = nil;
        self.transformer = nil;
        self.userInfo = nil;
        self.sceneTag = nil;
        self.randomSamplingPointCount = 30;
        self.transitionDuration = 0.2;
        self.requestHeaders = [NSDictionary dictionary];
    }
    return self;
}

@end
