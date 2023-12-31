//
//  IESGurdResourceManager.h
//  IESGurdKit
//
//  Created by 01 on 17/6/30.
//

#import "IESGeckoDefines.h"
#import "IESGurdNetworkResponse+Private.h"


NS_ASSUME_NONNULL_BEGIN

extern NSString *IESGurdDownloadInfoDurationKey;    //下载时长key
extern NSString *IESGurdDownloadInfoURLKey;         //下载地址key

typedef void(^IESGurdHTTPRequestCompletion)(IESGurdNetworkResponse * _Nonnull response);

@class IESGurdDownloadInfoModel;

@interface IESGurdResourceManager : NSObject

/**
 * 下载包, 失败后重试
 */
+ (void)downloadPackageWithDownloadInfoModel:(IESGurdDownloadInfoModel *)downloadInfoModel
                                  completion:(IESGurdDownloadResourceCompletion)completion;

/**
 发送GET请求
 */
+ (void)GETWithURLString:(NSString * _Nonnull)URLString
                  params:(NSDictionary * _Nullable)params
              completion:(IESGurdHTTPRequestCompletion)completion;

/**
 发送POST请求
 */
+ (void)POSTWithURLString:(NSString * _Nonnull)URLString
                   params:(NSDictionary * _Nullable)params
               completion:(nullable IESGurdHTTPRequestCompletion)completion;

/**
 取消下载请求
 */
+ (void)cancelDownloadWithIdentity:(NSString *)identity;

+ (void)realRequestWithMethod:(NSString * _Nonnull)method
                    URLString:(NSString * _Nonnull)URLString
                       params:(NSDictionary * _Nullable)params
                   completion:(IESGurdHTTPRequestCompletion)completion;

@end

NS_ASSUME_NONNULL_END
