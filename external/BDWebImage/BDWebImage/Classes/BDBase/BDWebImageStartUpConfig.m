//
//  BDWebImageStartUpConfig.m
//  BDWebImageToB
//
//  Created by 陈奕 on 2020/10/22.
//

#import "BDWebImageStartUpConfig.h"

@implementation BDWebImageStartUpConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isInBoe = NO;
        self.appID = @"";
        self.serviceVendor = BDImageServiceVendorCN;
        self.token = @"";
        self.authCodes = [NSArray array];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    BDWebImageStartUpConfig *config = [[self class] allocWithZone:zone];
    config.isInBoe = self.isInBoe;
    config.appID = self.appID;
    config.serviceVendor = self.serviceVendor;
    config.token = self.token;
    config.authCodes = self.authCodes;
    return config;
}

@end
