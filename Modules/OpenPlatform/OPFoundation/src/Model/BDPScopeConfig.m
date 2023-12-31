//
//  BDPScopeConfig.m
//  Timor
//
//  Created by liuxiangxin on 2019/6/26.
//

#import "BDPScopeConfig.h"

@implementation BDPScopeConfigEntity

@end

@implementation BDPScopeConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        _album = [BDPScopeConfigEntity new];
        _camera = [BDPScopeConfigEntity new];
        _location = [BDPScopeConfigEntity new];
        _address = [BDPScopeConfigEntity new];
        _phoneNumber = [BDPScopeConfigEntity new];
        _microphone = [BDPScopeConfigEntity new];
        _userInfo = [BDPScopeConfigEntity new];
        _clipboard = [BDPScopeConfigEntity new];
        _appBadge = [BDPScopeConfigEntity new];
        _runData = [BDPScopeConfigEntity new];
    }
    return self;
}

@end
