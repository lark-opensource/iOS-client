//
//  EMAComponentRegister.m
//  EEMicroAppSDK
//
//  Created by lixiaorui on 2020/5/20.
//

#import <Foundation/Foundation.h>
#import "EMAComponentRegister.h"
#import "BDPPluginEditorComponent.h"

@implementation EMAComponentRegister

@BDPBootstrapLaunch(EMAComponentRegister,
{
    /*-----------------------------------------------*/
    //              Editor 设置
    /*-----------------------------------------------*/
    [BDPJSBridgeCenter registerInstanceMethod:@"editorFilePathConvert" isSynchronize:NO isOnMainThread:YES class:[BDPPluginEditorComponent class] type:BDPJSBridgeMethodTypeAll];

});

@end

