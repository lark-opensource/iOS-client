//
//  EMATrackAPIRegister.m
//  EEMicroAppSDK
//
//  Created by lixiaorui on 2020/5/20.
//

#import <Foundation/Foundation.h>
#import "EMATrackAPIRegister.h"
#import <OPFoundation/BDPBootstrapHeader.h>
#import <OPPluginManagerAdapter/BDPJSBridgeCenter.h>
#import <TTMicroApp/TMAPluginTracker.h>
#import "BDPPluginPerformance.h"
#import <OPPluginManagerAdapter/OPBridgeRegisterOpt.h>

@implementation EMATrackAPIRegister

@BDPBootstrapLaunch(EMATrackAPIRegister,
{
    /*-----------------------------------------------*/
    //              Track相关
    /*-----------------------------------------------*/
    if ([OPBridgeRegisterOpt bridgeRegisterOptDisable]) {
        [BDPJSBridgeCenter registerInstanceMethod:@"reportTimeline" isSynchronize:NO isOnMainThread:NO class:[TMAPluginTracker class] type:BDPJSBridgeMethodTypeAll];
        [BDPJSBridgeCenter registerInstanceMethod:@"postErrors" isSynchronize:NO isOnMainThread:NO class:[TMAPluginTracker class] type:BDPJSBridgeMethodTypeAll];
    }
    /*-----------------------------------------------*/
    //              Performance相关
    /*-----------------------------------------------*/
    [BDPJSBridgeCenter registerInstanceMethod:@"getPerformance" isSynchronize:YES isOnMainThread:YES class:[BDPPluginPerformance class] type:BDPJSBridgeMethodTypeAll];
});

@end
