//
//  EMAStorageAPIRegister.m
//  EEMicroAppSDK
//
//  Created by lixiaorui on 2020/5/20.
//

#import <Foundation/Foundation.h>
#import "EMAStorageAPIRegister.h"
#import <OPFoundation/BDPBootstrapHeader.h>
#import <TTMicroApp/TMAPluginStorage.h>
#import <OPPluginManagerAdapter/OPBridgeRegisterOpt.h>

@implementation EMAStorageAPIRegister

@BDPBootstrapLaunch(EMAStorageAPIRegister,
{
    if ([OPBridgeRegisterOpt bridgeRegisterOptDisable]) {
        [BDPJSBridgeCenter registerInstanceMethod:@"operateInternalStorageSync" isSynchronize:YES isOnMainThread:NO class:[TMAPluginStorage class] type:BDPJSBridgeMethodTypeAll];
    }
});

@end
