//
//  IESGurdSettingsRequest.m
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/21.
//

#import "IESGeckoKit+Private.h"
#import "IESGeckoDefines+Private.h"
#import "IESGurdSettingsRequest.h"
#import "IESGurdSettingsCacheManager.h"
#import "IESGurdRegisterManager.h"

@implementation IESGurdSettingsRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        IESGurdKit *instance = IESGurdKitInstance;
        self.env = instance.env;
        self.requestType = IESGurdSettingsRequestTypeNormal;
    }
    return self;
}

+ (instancetype)request
{
    return [[IESGurdSettingsRequest alloc] init];
}

- (NSDictionary *)paramsForRequest
{
    BOOL isColdLaunch = (self.requestType == IESGurdSettingsRequestTypeNormal);
    NSMutableDictionary *customParams = [NSMutableDictionary dictionary];
    [[[IESGurdRegisterManager sharedManager] allRegisterModels] enumerateObjectsUsingBlock:^(IESGurdRegisterModel *registerModel, NSUInteger idx, BOOL *stop) {
        if (registerModel.version.length) {
            customParams[registerModel.accessKey] = @{ IESGurdCustomParamKeyBusinessVersion: registerModel.version };
        }
    }];
    return @{ kIESGurdSettingsRequestKey : @{ @"env": @(self.env),
                                              @"version": @(self.version) },
              kIESGurdRequestConfigRequestMetaKey : @{
                  kIESGurdRequestColdLaunchKey : @(isColdLaunch ? 1 : 0),
                  @"req_type": @(self.requestType),
              },
              kIESGurdRequestConfigCustomInfoKey: [customParams copy] };
}

- (NSDictionary *)logInfo
{
    return @{ @"req_type" : @(self.requestType) };
}

@end
