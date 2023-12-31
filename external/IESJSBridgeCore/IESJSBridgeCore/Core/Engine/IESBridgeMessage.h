//
//  IESBridgeMessage.h
//  IESWebKit
//
//  Created by li keliang on 2019/4/8.
//

#import <Foundation/Foundation.h>
#import "IESBridgeDefines.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const IESJSMessageTypeEvent;
FOUNDATION_EXTERN NSString *const IESJSMessageTypeCall;
FOUNDATION_EXTERN NSString *const IESJSMessageTypeCallback;


extern IESPiperProtocolVersion const IESPiperProtocolVersion1_0;// 基于 schema 拦截实现前端调用客户端，js 对象为 ToutiaoPiper 的 JSB 协议
extern IESPiperProtocolVersion const IESPiperProtocolVersion2_0;// 2.0 版本协议，主要头条在用
extern IESPiperProtocolVersion const IESPiperProtocolVersion3_0;// 抖音 & 头条均支持的 JSB协议
extern IESPiperProtocolVersion const IESPiperProtocolVersionUnknown;


typedef NS_ENUM (NSUInteger, IESBridgeFrom) {
    IESBridgeMessageFromIframe = 0,
    IESBridgeMessageFromJSCall
};

typedef void (^IESBridgeMessageCallback)(NSString * _Nullable result);

@interface IESBridgeMessage : NSObject

@property (nonatomic, copy) NSString *messageType;
@property (nonatomic, copy) NSString *eventID;
@property (nonatomic, copy) NSString *callbackID;
@property (nonatomic, copy) NSDictionary *invokeParams; // 该字段用于在调用jsb后保存前端调用jsb时的参数信息
@property (nonatomic, copy) NSDictionary *params;
@property (nonatomic, copy) NSString *methodName;
@property (nonatomic, copy) NSString *methodNamespace;
@property (nonatomic, copy) NSString *JSSDKVersion;
@property (nonatomic, copy) NSString *beginTime;
@property (nonatomic, copy) NSString *endTime;
@property(nonatomic, assign) IESPiperStatusCode statusCode;
@property (nonatomic, assign) IESBridgeFrom from;
@property (nonatomic, copy) IESPiperProtocolVersion protocolVersion;
@property(nonatomic, copy) NSString *iframeURLString;
@property(nonatomic, strong, readonly) NSString *statusDescription;

@property (nonatomic, copy) IESBridgeMessageCallback callback;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict callback:(nullable IESBridgeMessageCallback)callback;

- (NSString *)wrappedParamsString;
+ (NSString *)statusDescriptionWithStatusCode:(IESPiperStatusCode)statusCode;


@end

NS_ASSUME_NONNULL_END
