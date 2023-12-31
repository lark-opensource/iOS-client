//
//  EMARouteMediator.m
//  EEMicroAppSDK
//
//  Created by houjihu on 2018/10/22.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "EMARouteMediator.h"

@implementation EMARouteMediator

+ (instancetype)sharedInstance {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

@end
