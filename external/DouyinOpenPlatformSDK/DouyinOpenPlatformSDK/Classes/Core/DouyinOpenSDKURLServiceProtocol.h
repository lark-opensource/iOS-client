//
//  DouyinOpenSDKURLServiceProtocol.h
//
//
//  Created by Spiker on 2019/7/8.
//

#import "DouyinOpenSDKObjects.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DouyinOpenSDKURLServiceProtocol <NSObject>
@required

/**
 @return 服务名称
 */
+ (nonnull NSString *)serviceName;
+ (nonnull NSString *)reqClassName;

@optional

#pragma mark - 处理来自平台的GetReq
/**
 Douyin通过URL Scheme方式打开第三方应用，将URL根据不同的服务转化为相应的DouyinOpenSDKBaseReq对象
 
 @attention 同步处理
 
 @param url Douyin打开第三方应用的Scheme URL
 @return 返回url对应服务的DouyinOpenSDKBaseReq对象
 */
+ (nonnull DouyinOpenSDKBaseRequest *)providerGetReqFromURL:(NSURL * _Nonnull)url;

/**
 第三方应用程序收到Douyin的请求后，进行处理并将处理结果通过Scheme方式返回给Douyin
 
 @param consumerGetResp 第三方应用处理Douyin请求的响应结果
 @return 返回第三方应用处理Douyin请求后的结果URL
 */
+ (nonnull NSURL *)URLFromConsumerGetResp:(DouyinOpenSDKBaseRequest * _Nonnull)consumerGetResp;

#pragma mark - 处理第三方应用发送消息至平台的SendReq

/**
 处理第三方应用通过SDK发送的请求，将DouyinOpenSDKBaseReq转化为NSURL，并通过改url打开Douyin
 
 @param consumerReq 第三方应用发送的请求
 @return 返回打开Douyin的URL
 */
+ (nonnull NSArray<NSURL *> *)URLArrayFromConsumerSendReq:(DouyinOpenSDKBaseRequest * _Nonnull)consumerReq;

#pragma mark - 第三方应用发送消息至Douyin后，处理Douyin回送消息至第三方应用的SendResp

/**
 解析Douyin使用URL打开第三方应用时捎带的数据，生成DouyinOpenSDKBaseResp对象
 
 @param url Douyin打开第三方应用时使用的URL
 @return 返回由url生成的DouyinOpenSDKBaseResp对象
 */
+ (nonnull DouyinOpenSDKBaseResponse *)consumerSendRespFromURL:(NSURL * _Nonnull)url;

@end

NS_ASSUME_NONNULL_END
