//
//  EMANetworkAPIRegister.m
//  EEMicroAppSDK
//
//  Created by lixiaorui on 2020/5/20.
//

#import "EMANetworkAPIRegister.h"
#import <OPFoundation/BDPBootstrapHeader.h>
#import <TTMicroApp/TMAPluginNetwork.h>
#import <TTMicroApp/TMAPluginWebSocket.h>
#import <OPPluginManagerAdapter/OPBridgeRegisterOpt.h>

@implementation EMANetworkAPIRegister

@BDPBootstrapLaunch(EMANetworkAPIRegister,
{
    /*-----------------------------------------------*/
    //                Request相关
    /*-----------------------------------------------*/
    [BDPJSBridgeCenter registerInstanceMethod:@"createRequestTask" isSynchronize:YES isOnMainThread:NO class:[TMAPluginNetwork class] type:BDPJSBridgeMethodTypeAll|BDPJSBridgeMethodTypeBlock];
    [BDPJSBridgeCenter registerInstanceMethod:@"operateRequestTask" isSynchronize:NO isOnMainThread:NO class:[TMAPluginNetwork class] type:BDPJSBridgeMethodTypeAll|BDPJSBridgeMethodTypeBlock];
    if ([OPBridgeRegisterOpt bridgeRegisterOptDisable]) {
        // Modal Webview 内部接口
        [BDPJSBridgeCenter registerInstanceMethod:@"createInnerRequestTask" isSynchronize:YES isOnMainThread:NO class:[TMAPluginNetwork class] type:BDPJSBridgeMethodTypeAll];
        // Modal Webview 内部接口
        [BDPJSBridgeCenter registerInstanceMethod:@"operateInnerRequestTask" isSynchronize:YES isOnMainThread:NO class:[TMAPluginNetwork class] type:BDPJSBridgeMethodTypeAll];
    }

    /*-----------------------------------------------*/
    //                Upload相关
    /*-----------------------------------------------*/
    [BDPJSBridgeCenter registerInstanceMethod:@"createUploadTask" isSynchronize:YES isOnMainThread:NO class:[TMAPluginNetwork class] type:BDPJSBridgeMethodTypeAll];
    [BDPJSBridgeCenter registerInstanceMethod:@"operateUploadTask" isSynchronize:NO isOnMainThread:NO class:[TMAPluginNetwork class] type:BDPJSBridgeMethodTypeAll];

    /*-----------------------------------------------*/
    //                Download相关
    /*-----------------------------------------------*/
    [BDPJSBridgeCenter registerInstanceMethod:@"createDownloadTask" isSynchronize:YES isOnMainThread:NO class:[TMAPluginNetwork class] type:BDPJSBridgeMethodTypeAll];
    [BDPJSBridgeCenter registerInstanceMethod:@"operateDownloadTask" isSynchronize:NO isOnMainThread:NO class:[TMAPluginNetwork class] type:BDPJSBridgeMethodTypeAll];

    /*-----------------------------------------------*/
    //                WebSocket相关
    /*-----------------------------------------------*/
    [BDPJSBridgeCenter registerInstanceMethod:@"createSocketTask" isSynchronize:YES isOnMainThread:NO class:[TMAPluginWebSocket class] type:BDPJSBridgeMethodTypeAll|BDPJSBridgeMethodTypeCard|BDPJSBridgeMethodTypeBlock];
    [BDPJSBridgeCenter registerInstanceMethod:@"operateSocketTask" isSynchronize:YES isOnMainThread:NO class:[TMAPluginWebSocket class] type:BDPJSBridgeMethodTypeAll|BDPJSBridgeMethodTypeCard|BDPJSBridgeMethodTypeBlock];

});


@end
