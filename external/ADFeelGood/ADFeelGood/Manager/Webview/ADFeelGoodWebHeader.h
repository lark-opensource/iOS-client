//
//  ADFeelGoodWebHeader.h
//  Pods
//
//  Created by cuikeyi on 2021/3/11.
//

#ifndef ADFeelGoodWebHeader_h
#define ADFeelGoodWebHeader_h

typedef NS_ENUM(NSInteger, ADFGBridgeMsg){
    ADFGBridgeMsgUnknownError   = -1000,// 未知错误
    ADFGBridgeMsgManualCallback = -999, // 业务方回调
    ADFGBridgeMsgCodeUndefined      = -998, // 前端方法未定义
    ADFGBridgeMsgCode404            = -997, // 前端返回 404
    ADFGBridgeMsgFailed = 1,
    ADFGBridgeMsgSuccess = 0,
    ADFGBridgeMsgParamError = -3,
    ADFGBridgeMsgNoHandler = -2,
    ADFGBridgeMsgNoPermission = -1
};

typedef void(^ADFGBridgeCallback)(ADFGBridgeMsg msg, NSDictionary * _Nullable params, void(^ _Nullable resultBlock)(NSString *result));

#endif /* ADFeelGoodWebHeader_h */
