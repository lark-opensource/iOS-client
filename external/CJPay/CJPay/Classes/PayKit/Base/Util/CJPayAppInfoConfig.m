//
//  CJPayAppInfoConfig.m
//  CJPay
//
//  Created by 尚怀军 on 2019/8/21.
//

#import "CJPayAppInfoConfig.h"

@implementation CJPayAppInfoConfig

- (instancetype)copyWithZone:(NSZone *)zone {
    CJPayAppInfoConfig *config = [[[self class] alloc] init];
    config.appId = [self.appId copy];
    config.appName = [self.appName copy];
    config.deviceIDBlock = [self.deviceIDBlock copy];
    config.userIDBlock = [self.userIDBlock copy];
    config.userNicknameBlock = [self.userNicknameBlock copy];
    config.userPhoneNumberBlock = [self.userPhoneNumberBlock copy];
    config.userAvatarBlock = [self.userAvatarBlock copy];
    config.secLinkDomain = [self.secLinkDomain copy];
    config.transferSecLinkSceneBlock = [self.transferSecLinkSceneBlock copy];
    config.infoConfigBlock = [self.infoConfigBlock copy];
    return config;
}

@end
