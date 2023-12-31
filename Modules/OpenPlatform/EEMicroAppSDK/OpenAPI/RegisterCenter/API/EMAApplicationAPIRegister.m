//
//  EMAApplicationAPIRegister.m
//  EEMicroAppSDK
//
//  Created by lixiaorui on 2020/5/20.
//

#import <Foundation/Foundation.h>
#import "EMAApplicationAPIRegister.h"
#import <OPFoundation/BDPBootstrapHeader.h>
#import <TTMicroApp/BDPPluginApplication.h>

@implementation EMAApplicationAPIRegister

@BDPBootstrapLaunch(EMAApplicationAPIRegister,
{
    /*-----------------------------------------------*/
    //              Menu相关
    /*-----------------------------------------------*/
    [BDPJSBridgeCenter registerInstanceMethod:@"getMenuButtonBoundingClientRect" isSynchronize:YES isOnMainThread:YES class:[BDPPluginApplication class] type:BDPJSBridgeMethodTypeAll];
});

@end
