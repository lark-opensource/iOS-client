//
//  EMANetworkManager.h
//  EEMicroAppSDK
//
//  Created by owen on 2018/11/20.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class OPTrace;
@interface EMANetworkManager : NSObject
+ (instancetype)shared;
@property (nonatomic, strong, readonly, nonnull) NSURLSession *urlSession;

/// 设置网络代理是否走Rust SDK
- (void)configSharedURLSessionConfigurationOverRustChannel:(BOOL)shouldNetworkTransmitOverRustChannel;
/// 网络代理是否走Rust SDK
- (BOOL)isNetworkTransmitOverRustChannel;

- (NSURLSessionTask *)postUrl:(NSString *)urlString
                       params:(NSDictionary *)params
                       header:(NSDictionary *)header
            completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                    eventName:(NSString *)eventName
               requestTracing:(OPTrace * _Nullable)tracing;
- (NSURLSessionTask *)postUrl:(NSString *)urlString
                       params:(NSDictionary *)params
            completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                    eventName:(NSString *)eventName
               requestTracing:(OPTrace * _Nullable)tracing;
- (NSURLSessionTask *)postUrl:(NSString *)urlString
                       params:(NSDictionary *)params
                       header:(NSDictionary *)header
       completionWithJsonData:(void (^)(NSDictionary * _Nullable json, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                    eventName:(NSString *)eventName
               requestTracing:(OPTrace * _Nullable)tracing;
- (NSURLSessionTask *)postUrl:(NSString *)urlString
                       params:(NSDictionary *)params
       completionWithJsonData:(void (^)(NSDictionary * _Nullable json, NSError * _Nullable error))completionHandler
                    eventName:(NSString *)eventName
               requestTracing:(OPTrace * _Nullable)tracing;;
- (NSURLSessionTask *)getUrl:(NSString *)urlString
                      params:(NSDictionary *)params
      completionWithJsonData:(void (^)(NSDictionary * _Nullable json, NSError * _Nullable error))completionHandler
                   eventName:(NSString *)eventName;
- (NSURLSessionTask *)dataTaskWithMutableRequest:(NSMutableURLRequest *)request
                               completionHandler:(void (^ _Nonnull)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                                       eventName:(NSString * _Nonnull)eventName
                                      autoResume:(BOOL)autoResume
                                  requestTracing:(OPTrace * _Nullable)tracing;
- (NSURLSessionTask *)requestUrl:(NSString *)urlString
                          method:(NSString *)method
                          params:(NSDictionary *)params
                          header:(NSDictionary *)header
               completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                       eventName:(NSString *)eventName
                      autoResume:(BOOL)autoResume
                         timeout:(NSTimeInterval)timeout
                  requestTracing:(OPTrace * _Nullable)tracing;
- (NSURLSessionTask *)requestUrl:(NSString *)urlString
                          method:(NSString *)method
                          params:(NSDictionary *)params
                          header:(NSDictionary *)header
               completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                       eventName:(NSString *)eventName
                  requestTracing:(OPTrace * _Nullable)tracing;
- (NSURLSessionTask *)requestUrl:(NSString *)urlString
                          method:(NSString *)method
                          params:(NSDictionary *)params
                          header:(NSDictionary *)header
          completionWithJsonData:(void (^)(NSDictionary * _Nullable json, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                       eventName:(nonnull NSString *)eventName
                      autoResume:(BOOL)autoResume
                         timeout:(NSTimeInterval)timeout
                  requestTracing:(OPTrace * _Nullable)tracing;;
- (NSURLSessionTask *)requestUrl:(NSString *)urlString
                          method:(NSString *)method
                          params:(NSDictionary *)params
                          header:(NSDictionary *)header
          completionWithJsonData:(void (^)(NSDictionary * _Nullable json, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                       eventName:(nonnull NSString *)eventName
                  requestTracing:(OPTrace * _Nullable)tracing;
@end

NS_ASSUME_NONNULL_END
