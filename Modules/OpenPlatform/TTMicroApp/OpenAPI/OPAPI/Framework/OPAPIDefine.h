//
//  OPAPIDefine.h
//  Timor
//
//  Created by yinyuan on 2020/9/8.
//

#ifndef OPAPIDefine_h
#define OPAPIDefine_h

#import <LarkOPInterface/OPContextLogger.h>

/// 基于现有API，定义 OPAPI Response，利用 OPAPI 的 callback 能力和 context 日志能力
#define OP_API_RESPONSE(ResponseType)\
    OPContextLogger *logger = [[OPContextLogger alloc] init];   \
    ResponseType *response = [[ResponseType alloc] initWithJsBridgeCallback:callback logger:logger funcName: [NSString stringWithUTF8String:__FUNCTION__]];   \
    

#endif /* OPAPIDefine_h */
