//
//  BDJSBridgeCoreDefines.h
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2020/1/14.
//

#ifndef BDJSBridgeCoreDefines_h
#define BDJSBridgeCoreDefines_h

typedef NS_ENUM(NSInteger, BDJSBridgeStatus) {
    BDJSBridgeStatusUnknownError   = -1000,// 未知错误
    BDJSBridgeStatusManualCallback = -999, // 业务方回调
    BDJSBridgeStatusUndefined      = -998, // 前端方法未定义
    BDJSBridgeStatus404            = -997, // 前端返回 404
    BDJSBridgeStatusNamespaceError = -4,   // 错误命名空间
    BDJSBridgeStatusParameterError = -3,   // 参数错误
    BDJSBridgeStatusNoHandler      = -2,   // 未注册方法
    BDJSBridgeStatusNotAuthroized  = -1,   // 未授权
    BDJSBridgeStatusFail           = 0,    // 失败
    BDJSBridgeStatusSucceed        = 1     // 成功
};

typedef NS_ENUM(NSUInteger, BDJSBridgeAuthType){
    BDJSBridgeAuthTypeUnegistered,
    BDJSBridgeAuthTypePublic,
    BDJSBridgeAuthTypeProtected,
    BDJSBridgeAuthTypePrivate
};

typedef void(^BDJSBridgeCallback)(BDJSBridgeStatus status, NSDictionary * _Nullable params, void(^ _Nullable resultBlock)(NSString * _Nullable result));

#ifndef stringify
#define stringify(s) #s
#endif

#endif /* BDJSBridgeCoreDefines_h */
