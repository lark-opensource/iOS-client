//
//  JSWorkerBridgeDefines.h
//  TTBridgeUnify
//
//  Created by bytedance on 2021/10/14.
//

@class JsWorkerIOS;

typedef NS_ENUM(NSInteger, JSWorkerBridgeStatusCode) {
  JSWorkerBridgeCodeUnknownError = -1000,   // 未知错误
  JSWorkerBridgeCodeManualCallback = -999,  // 业务方回调
  JSWorkerBridgeCodeUndefined = -998,       // 前端方法未定义
  JSWorkerBridgeCode404 = -997,             // 前端返回 404
  JSWorkerBridgeCodeParameterError = -3,    // 参数错误
  JSWorkerBridgeCodeNoHandler = -2,         // 未注册方法
  JSWorkerBridgeCodeNotAuthroized = -1,     // 未授权
  JSWorkerBridgeCodeFail = 0,               // 失败
  JSWorkerBridgeCodeSucceed = 1             // 成功
};

typedef void (^JSWorkerBridgeHandler)(JsWorkerIOS *worker, NSString *name,
                                    NSDictionary *_Nullable params,
                                    void (^callback)(JSWorkerBridgeStatusCode code,
                                                     id _Nullable data));

typedef void (^JSWorkerBridgeCallback)(JSWorkerBridgeStatusCode code, NSDictionary *_Nullable data);
