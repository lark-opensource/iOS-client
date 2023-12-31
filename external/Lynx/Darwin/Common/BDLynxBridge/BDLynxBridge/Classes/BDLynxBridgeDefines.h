//
//  BDLynxBridgeDefines.h
//  LynxExample
//
//  Created by li keliang on 2020/2/9.
//  Copyright © 2020 Lynx. All rights reserved.
//

@class LynxView;
@class LynxServiceInfo;
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDLynxBridgeStatusCode) {
  BDLynxBridgeCodeUnknownError = -1000,   // 未知错误
  BDLynxBridgeCodeManualCallback = -999,  // 业务方回调
  BDLynxBridgeCodeUndefined = -998,       // 前端方法未定义
  BDLynxBridgeCode404 = -997,             // 前端返回 404
  BDLynxBridgeCodeParameterError = -3,    // 参数错误
  BDLynxBridgeCodeNoHandler = -2,         // 未注册方法
  BDLynxBridgeCodeNotAuthroized = -1,     // 未授权
  BDLynxBridgeCodeFail = 0,               // 失败
  BDLynxBridgeCodeSucceed = 1             // 成功
};

typedef void (^BDLynxBridgeHandler)(LynxView *_Nullable lynxView, NSString *name,
                                    NSDictionary *_Nullable params,
                                    void (^callback)(BDLynxBridgeStatusCode code,
                                                     id _Nullable data));
typedef void (^BDLynxBridgeSessionHandler)(LynxView *_Nullable lynxView, NSString *name,
                                           NSDictionary *_Nullable params, LynxServiceInfo *context,
                                           void (^callback)(BDLynxBridgeStatusCode code,
                                                            id _Nullable data));

typedef void (^BDLynxBridgeCallback)(BDLynxBridgeStatusCode code, NSDictionary *_Nullable data);

extern NSString *const BDLynxBridgeDefaultNamescope;

NS_ASSUME_NONNULL_END
