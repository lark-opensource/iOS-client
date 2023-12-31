//
//  EMAOpenAPIRegister.m
//  EEMicroAppSDK
//
//  Created by lixiaorui on 2020/5/20.
//

#import <Foundation/Foundation.h>
#import "EMAOpenAPIRegister.h"
#import <OPFoundation/BDPBootstrapHeader.h>
#import <OPPluginManagerAdapter/BDPJSBridgeCenter.h>
#import "EMAPluginLark.h"
#import <OPPluginManagerAdapter/OPBridgeRegisterOpt.h>

@implementation EMAOpenAPIRegister

@BDPBootstrapLaunch(EMAOpenAPIRegister,
{
    if ([OPBridgeRegisterOpt bridgeRegisterOptDisable]) {
        [BDPJSBridgeCenter registerInstanceMethod:@"hasWatermark" isSynchronize:NO isOnMainThread:YES class:[EMAPluginLark class] type:BDPJSBridgeMethodTypeAll];
    }
});

@end
