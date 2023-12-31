//
//  CJPayBridgePlugin_forceUpdateChannel.m
//  CJPay
//
//  Created by liyu on 2023/8/31.
//

#import "CJPayBridgePlugin_forceUpdateChannel.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import <IESGeckoKit/IESGeckoKit.h>
#import "CJPaySDKMacro.h"
#import "CJPayGurdManager.h"
#import "NSDictionary+CJPay.h"

@implementation CJPayBridgePlugin_forceUpdateChannel

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_forceUpdateChannel, forceUpdateChannel), @"ttcjpay.forceUpdateChannel");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)forceUpdateChannelWithParam:(NSDictionary *)data
                           callback:(TTBridgeCallback)callback
                             engine:(id<TTBridgeEngine>)engine
                         controller:(UIViewController *)controller
{
    if (![IESGeckoKit didSetup]){
        TTBRIDGE_CALLBACK_WITH_MSG(TTBridgeMsgFailed, @"gecko未初始化")
        return;
    }
    
    NSArray *channels = [data cj_arrayValueForKey:@"channels"];
    if (channels.count == 0) {
        TTBRIDGE_CALLBACK_WITH_MSG(TTBridgeMsgFailed, @"channels为空")
        return;
    }
    __block BOOL valid = YES;
    [channels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:[NSString class]]) {
            valid = NO;
            *stop = YES;
        }
    }];
    if (!valid) {
        TTBRIDGE_CALLBACK_WITH_MSG(TTBridgeMsgFailed, @"channels不合法")
        return;
    }
    
    BOOL disableThrottle = [data cj_boolValueForKey:@"disable_throttle"];

    [IESGeckoKit registerAccessKey:[CJPayGurdManager defaultService].accessKey SDKVersion:CJString([CJSDKParamConfig defaultConfig].version)];
    
    @CJWeakify(self)
    [IESGeckoKit syncResourcesWithParamsBlock:^(IESGurdFetchResourcesParams * _Nonnull params) {
        @CJStrongify(self)
        params.accessKey = [[CJPayGurdManager defaultService] accessKey];
        params.channels = channels;
        params.disableThrottle = disableThrottle;
        params.downloadPriority = IESGurdDownloadPriorityUserInteraction;
    } completion:^(BOOL succeed, IESGurdSyncStatusDict  _Nonnull dict) {
        CJPayLogInfo(@"forceUpdateChannel:%@, result:%@, status:%@", channels, @(succeed), dict);
        if ([channels containsObject:@"cpay"]) {
            NSInteger code = dict[@"cpay"] ? [dict cj_integerValueForKey:@"cpay"] : -9999;
            [CJTracker event:@"wallet_rd_force_update_channel_result" params:@{
                @"cpay_channel_result" : @(code),
                @"cpay_channel_is_success" : @(succeed),
                @"scene" : @"forceUpdateChannel"
            }];
        }
    }];
    
    TTBRIDGE_CALLBACK_SUCCESS
}

@end
