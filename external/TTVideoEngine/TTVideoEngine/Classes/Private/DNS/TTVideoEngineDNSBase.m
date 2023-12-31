//
//  TTVideoEngineDNSBase.m
//  Pods
//
//  Created by guikunzhi on 16/12/5.
//
//

#import "TTVideoEngineDNSBase.h"

@implementation TTVideoEngineDNSBase

- (instancetype)initWithHostname:(NSString *)hostname {
    if (self = [super init]) {
        _hostname = hostname;
    }
    return self;
}

- (void)start {
}

- (void)cancel {
}

@end
