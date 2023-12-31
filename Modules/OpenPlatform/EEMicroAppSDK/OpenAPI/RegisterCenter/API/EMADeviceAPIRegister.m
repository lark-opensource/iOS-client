//
//  EMADeviceAPIRegister.m
//  EEMicroAppSDK
//
//  Created by lixiaorui on 2020/5/20.
//

#import <Foundation/Foundation.h>
#import "EMADeviceAPIRegister.h"
#import <TTMicroApp/TMAPluginDevice.h>
#import <OPPluginManagerAdapter/OPBridgeRegisterOpt.h>

@implementation EMADeviceAPIRegister

@BDPBootstrapLaunch(EMADeviceAPIRegister,
{
    [BDPJSBridgeCenter registerInstanceMethod:@"getNetworkType" isSynchronize:NO isOnMainThread:NO class:[TMAPluginDevice class] type:BDPJSBridgeMethodTypeAll];
    if ([OPBridgeRegisterOpt bridgeRegisterOptDisable]) {
        [BDPJSBridgeCenter registerInstanceMethod:@"getGeneralInfo" isSynchronize:NO isOnMainThread:NO class:[TMAPluginDevice class] type:BDPJSBridgeMethodTypeAll];
    }
});

@end
