//
//  MODNetworkService.h
//  Modeo
//
//  Created by yansong li on 2020/12/28.
//

#import <AWEBaseModel/AWEBaseApiModel.h>
#import <Foundation/Foundation.h>
#import <TTNetworkManager/TTHttpTask.h>
#import <TTNetworkManager/TTNetworkManager.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^MODNetworkServiceCompletionBlock)(id _Nullable model, NSError * _Nullable error);

FOUNDATION_EXPORT NSString * _Nonnull const MODNetworkServiceParseErrorDomain;
typedef NS_ENUM(NSInteger, MODNetworkServiceErrorType) {
    MODNetworkServiceErrorTypeAttribute = 1,
    MODNetworkServiceErrorTypeModel,
};

@interface MODNetworkService : NSObject

+ (TTHttpTask *)requestWithURLString:(NSString *)urlString
                              params:(NSDictionary * _Nullable)params
                              method:(NSString *)method
                    needCommonParams:(BOOL)needCommonParams
                          modelClass:(Class _Nullable)objectClass
                    targetAttributes:(NSArray<NSString *> * _Nullable)targetAttributes
                             timeout:(NSTimeInterval)timeout
                  responseSerializer:(Class<TTJSONResponseSerializerProtocol> _Nullable)responseSerializer
                       responseBlock:(MODNetworkServiceCompletionBlock _Nullable)responseBlock
                     completionBlock:(MODNetworkServiceCompletionBlock _Nullable)completionBlock;

/**
 POST请求
 
 @param urlString     请求url
 @param params        请求参数
 @param block         请求回调block
 @return              请求task
 */
+ (TTHttpTask *)postWithURLString:(NSString * _Nonnull)urlString
                           params:(NSDictionary * _Nullable)params
                       completion:(MODNetworkServiceCompletionBlock _Nullable)block;

/**
 POST请求
 
 @param urlString     请求url
 @param params        请求参数
 @param objectClass   请求数据解析的model class
 @param block         请求回调block
 @return              请求task
 */
+ (TTHttpTask *)postWithURLString:(NSString * _Nonnull)urlString
                           params:(NSDictionary * _Nullable)params
                       modelClass:(Class _Nullable)objectClass
                       completion:(MODNetworkServiceCompletionBlock _Nullable)block;

/**
 POST请求
 
 @param urlString           请求url
 @param params              请求参数
 @param needCommonParams    是否需要公共参数
 @param block               请求回调block
 @return                    请求task
 */
+ (TTHttpTask *)postWithURLString:(NSString * _Nonnull)urlString
                           params:(NSDictionary * _Nullable)params
                 needCommonParams:(BOOL)needCommonParams
                       completion:(MODNetworkServiceCompletionBlock _Nullable)block;

/**
 POST请求
 
 @param urlString         请求url
 @param params            请求参数
 @param responseBlock     请求回调response block
 @param completionBlock             请求回调block
 @return                  请求task
 */
+ (TTHttpTask *)postWithURLString:(NSString *)urlString
                           params:(NSDictionary *)params
                    responseBlock:(MODNetworkServiceCompletionBlock)responseBlock
                  completionBlock:(MODNetworkServiceCompletionBlock)completionBlock;

/**
  GET请求
 
 @param urlString     请求url
 @param params        请求参数
 @param block         请求回调block
 @return              请求task
 */
+ (TTHttpTask *)getWithURLString:(NSString * _Nonnull)urlString
                          params:(NSDictionary * _Nullable)params
                      completion:(MODNetworkServiceCompletionBlock _Nullable)block;

/**
 GET请求

 @param urlString           请求url
 @param params              请求参数
 @param needCommonParams    是否需要公共参数
 @param block               请求回调block
 @return                    请求task
 */
+ (TTHttpTask *)getWithURLString:(NSString * _Nonnull)urlString
                          params:(NSDictionary * _Nullable)params
                needCommonParams:(BOOL)needCommonParams
                      completion:(MODNetworkServiceCompletionBlock _Nullable)block;


/**
 GET请求

 @param urlString        请求url
 @param params           请求参数
 @param responseBlock    请求回调response block
 @param block            请求回调block
 @return                 请求task
 */
+ (TTHttpTask *)getWithURLString:(NSString * _Nonnull)urlString
                          params:(NSDictionary *)params
                   responseBlock:(MODNetworkServiceCompletionBlock)responseBlock
                 completionBlock:(MODNetworkServiceCompletionBlock)block;


/**
 GET 请求

 @param urlString       请求url
 @param params          请求参数
 @param objectClass     请求数据解析的 model class
 @param block           请求回调block
 @return                请求task
 */
+ (TTHttpTask *)getWithURLString:(NSString * _Nonnull)urlString
                          params:(NSDictionary * _Nullable)params
                      modelClass:(Class _Nullable)objectClass
                      completion:(MODNetworkServiceCompletionBlock _Nullable)block;



@end

NS_ASSUME_NONNULL_END
