//
//  EMAPluginLark.m
//  TTMicroApp
//
//  Created by yin on 2018/9/4.
//

#import "EMAPluginLark.h"
#import "EERoute.h"
#import <OPFoundation/OPFoundation-Swift.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <OPPluginManagerAdapter/OPPluginManagerAdapter-Swift.h>

@implementation EMAPluginLark

+ (BDPJSBridgePluginMode)pluginMode {
    return BDPJSBridgePluginModeGlobal;
}

#pragma mark --小程序&Web应用 checkWatermark

- (void)hasWatermarkWithParam:(NSDictionary *)param
                       callback:(BDPJSBridgeCallback)callback
                        context:(BDPPluginContext)context {
    OP_API_RESPONSE(OPAPIResponse)
    id<EMAProtocol> delegate = [EMARouteProvider getEMADelegate];
    BOOL hasWatermark = [delegate hasWatermark];
    
    logger.logInfo(@"call lark api, has watermark result is %@", @(hasWatermark));
    response.data = @{@"hasWatermark": @(hasWatermark)};
    [response callback:OPGeneralAPICodeOk];
}

@end
