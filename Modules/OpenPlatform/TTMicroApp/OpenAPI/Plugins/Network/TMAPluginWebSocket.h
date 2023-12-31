//
//  TMAPluginWebSocket.h
//  Timor
//
//  Created by muhuai on 2018/1/24.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import "BDPPluginBase.h"

@interface TMAPluginWebSocket : BDPPluginBase

BDP_EXPORT_HANDLER(createSocketTask)
BDP_EXPORT_HANDLER(operateSocketTask)

@end
