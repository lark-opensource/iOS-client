//
//  AWECloudCommandNetworkUtility.h
//  AWECloudCommand
//
//  Created by wangdi on 2018/3/25.
//

#import <Foundation/Foundation.h>
#import "AWECloudCommandMultiData.h"

NS_ASSUME_NONNULL_BEGIN

//ran is the key for aes
typedef void (^successBlock)(id _Nullable responseObject, NSData *data, NSString *ran);
typedef void (^failureBlock)(NSError * _Nullable error);

typedef NS_ENUM(NSInteger, AWECloudCommandRequestMethod)
{
    AWECloudCommandRequestMethodGet = 0,
    AWECloudCommandRequestMethodPost = 1,
};

@interface AWECloudCommandNetworkUtility : NSObject

+ (void)requestWithUrl:(NSString *)url
         requestMethod:(AWECloudCommandRequestMethod)requestMethod
                params:(NSDictionary * _Nullable)params
        requestHeaders:(NSDictionary * _Nullable)requestHeaders
               success:(successBlock   _Nullable)success
               failure:(failureBlock   _Nullable)failure;

+ (void)requestWithUrl:(NSString *)url
         requestMethod:(AWECloudCommandRequestMethod)requestMethod
                params:(NSDictionary * _Nullable)params
        requestHeaders:(NSDictionary * _Nullable)requestHeaders
needDecodeResponseData:(BOOL)needDecodeResponseData
               success:(successBlock   _Nullable)success
               failure:(failureBlock   _Nullable)failure;

+ (NSString *)fileMimeTypeWithPath:(NSString *)filePath;

+ (void)uploadDataWithUrl:(NSString *)url
                 fileName:(NSString *)fileName
                     data:(NSData *)data
                   params:(NSDictionary * _Nullable)params
                 mimeType:(NSString *)mimeType
           requestHeaders:(NSDictionary * _Nullable)requestHeaders
                  success:(successBlock   _Nullable)success
                  failure:(failureBlock   _Nullable)failure;

+ (void)uploadDataWithUrl:(NSString *)url
                 fileName:(NSString *)fileName
                 fileType:(NSString *     _Nullable)fileType
                     data:(NSData *)data
                   params:(NSDictionary * _Nullable)params
             commonParams:(NSDictionary * _Nullable)commonParams
                 mimeType:(NSString *)mimeType
           requestHeaders:(NSDictionary * _Nullable)requestHeaders
                  success:(successBlock   _Nullable)success
                  failure:(failureBlock   _Nullable)failure;

+ (void)uploadMultiDataWithUrl:(NSString *)url
                     dataArray:(NSArray<AWECloudCommandMultiData *> *)dataArray
                        params:(NSDictionary * _Nullable)params
                  commonParams:(NSDictionary * _Nullable)commonParams
                requestHeaders:(NSDictionary * _Nullable)requestHeaders
                       success:(successBlock   _Nullable)success
                       failure:(failureBlock   _Nullable)failure;

@end

NS_ASSUME_NONNULL_END
