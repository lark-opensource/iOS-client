//
//  IESBridgeDefines.h
//  Pods
//
//  Created by li keliang on 2019/4/8.
//

#ifndef IESBridgeDefines_h
#define IESBridgeDefines_h

#if __has_include(<IESJSBridgeCore/IESJSBridgeCore_Rename.h>)
#import <IESJSBridgeCore/IESJSBridgeCore_Rename.h>
#endif

@class IESBridgeMessage;

#define IESConcat_(A, B) A ## B
#define IESConcat(A, B) IESConcat_(A, B)

typedef NS_ENUM(NSInteger, IESPiperStatusCode) {
    IESPiperStatusCodeUnknownError   = -1000,// 未知错误
    IESPiperStatusCodeManualCallback = -999, // 业务方回调
    IESPiperStatusCodeUndefined      = -998, // 前端方法未定义
    IESPiperStatusCode404            = -997, // 前端返回 404
    IESPiperStatusCodeNamespaceError = -4,   // 错误命名空间
    IESPiperStatusCodeParameterError = -3,   // 参数错误
    IESPiperStatusCodeNoHandler      = -2,   // 未注册方法
    IESPiperStatusCodeNotAuthroized  = -1,   // 未授权
    IESPiperStatusCodeFail           = 0,    // 失败
    IESPiperStatusCodeSucceed        = 1     // 成功
};

typedef void (^IESBridgeResponseBlock)(IESPiperStatusCode status, NSDictionary * _Nullable response);

typedef void (^IESBridgeHandler)(IESBridgeMessage * _Nonnull message, IESBridgeResponseBlock _Nonnull responseBlock);

#define IES_BRIDGE_INVOKE_FAILED_CALLBACK(block) (block?:block(IESPiperStatusCodeFail, nil));

#define IES_BRIDGE_INVOKE_SUCCEED_CALLBACK(block, response) (block?:block(IESPiperStatusCodeSucceed, response));


typedef NSString * IESPiperProtocolVersion;

#import <BDAlogProtocol/BDAlogProtocol.h>

#define IESPiperCoreLogTag @"IESWebKit"
#define IESPiperCoreInfoLog(format, ...)   BDALOG_PROTOCOL_INFO_TAG(IESPiperCoreLogTag, format, ##__VA_ARGS__)
#define IESPiperCoreErrorLog(format, ...)  BDALOG_PROTOCOL_ERROR_TAG(IESPiperCoreLogTag, format, ##__VA_ARGS__)

#define IESPiperCoreBridgeHostnameDispatchMessage @"dispatch_message"

#define stringify(s) #s

#endif /* IESBridgeDefines_h */
