//
//  TTSmallAppDevice.m
//  TTRexxar
//
//  Created by muhuai on 2017/11/26.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import "TMAPluginDevice.h"
#import <OPFoundation/BDPUtils.h>

@implementation TMAPluginDevice

+ (BDPJSBridgePluginMode)pluginMode
{
    return BDPJSBridgePluginModeLifeCycle;
}

- (void)getNetworkTypeWithParam:(NSDictionary *)param callback:(BDPJSBridgeCallback)callback context:(BDPPluginContext)context
{
    BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeSuccess, @{@"networkType": BDPCurrentNetworkType()})
}

- (void)getGeneralInfoWithParam:(NSDictionary *)param callback:(BDPJSBridgeCallback)callback context:(BDPPluginContext)context
{
    // lark没有使用对应能力的网络库，目前API属于废弃状态
    BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, @"can not get general info")
}

@end
