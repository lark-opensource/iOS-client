//
//  DYOpenNetworkService.h
//  BDAlogProtocol
//
//  Created by arvitwu on 2022/12/14.
//

#import <Foundation/Foundation.h>
#import "DouyinOpenSDKConstants.h"

/// 网络请求回调
typedef void (^DYOpenNetworkFinishBlock)(NSDictionary * _Nullable respDict, NSError * _Nullable originError, NSURLRequest * _Nullable urlReq, NSURLResponse * _Nullable urlResp);

NS_ASSUME_NONNULL_BEGIN

@interface DYOpenNetworkService : NSObject

/// GET 请求
/// @param extraReq 业务可额外配置 req，如果返回 error 为 nil 才会发起请求，否则不会发起请求（但 completion 仍会将此处的 error 回调出去）
/// @return 发起请求的实例，如果没发起请求则返回 nil
+ (NSURLSessionTask *_Nullable)GET:(nonnull NSString *)urlPath
                      paramsString:(nullable NSString *)paramsString
                          extraReq:(NSError *_Nullable(^_Nullable)(NSMutableURLRequest *request))extraReq
                        completion:(DYOpenNetworkFinishBlock)completion;

/// POST 请求
/// @param extraReq 业务可额外配置 req，如果返回 error 为 nil 才会发起请求，否则不会发起请求（但 completion 仍会将此处的 error 回调出去）
/// @return 发起请求的实例，如果没发起请求则返回 nil
+ (NSURLSessionTask *_Nullable)POST:(nonnull NSString *)urlPath
                           bodyDict:(nullable NSDictionary *)bodyDict
                        contentType:(DYOpenNetworkContentType)contentType
                           extraReq:(NSError *_Nullable(^_Nullable)(NSMutableURLRequest *request))extraReq
                         completion:(DYOpenNetworkFinishBlock)completion;

/// 取消请求
/// @param task 发起请求的任务实例
+ (void)cancelTask:(NSURLSessionDataTask *)task;

/// 请求域名
+ (NSString *_Nonnull)networkDomain;

@end

NS_ASSUME_NONNULL_END
