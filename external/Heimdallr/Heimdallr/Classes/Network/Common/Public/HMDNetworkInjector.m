//
//  HMDNetworkInjector.m
//  Heimdallr
//
//  Created by fengyadong on 2021/5/18.
//

#import "HMDNetworkInjector.h"

static HMDNetworkInjector *instance = nil;

@interface HMDNetworkInjector()
@property (atomic, copy, nullable) HMDNetEncryptBlock injectedEncryptBlock;
@end

@implementation HMDNetworkInjector

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDNetworkInjector alloc] init];
    });
    return instance;
}

- (void)configEncryptBlock:(HMDNetEncryptBlock _Nullable)encryptBlock {
    self.injectedEncryptBlock = encryptBlock;
}

- (HMDNetEncryptBlock _Nullable)encryptBlock {
    return self.injectedEncryptBlock;
}

@end
