//
//  TTSmallAppDevice.h
//  TTRexxar
//
//  Created by muhuai on 2017/11/26.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import "BDPPluginBase.h"
#import <OPFoundation/BDPJSBridgeProtocol.h>

@interface TMAPluginDevice : BDPPluginBase

BDP_HANDLER(getNetworkType)
BDP_HANDLER(getGeneralInfo)

@end
