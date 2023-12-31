//
//  NSURLSession+TMA.h
//  Timor
//
//  Created by houjihu on 2018/10/8.
//

#import <Foundation/Foundation.h>
#import <ECOProbe/OPTrace.h>

NS_ASSUME_NONNULL_BEGIN
@interface NSURLSession (TMA)

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                                    eventName:(NSString * _Nullable)eventName
                               requestTracing:(OPTrace * _Nullable)tracing;

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url
                        completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                                eventName:(NSString * _Nullable)eventName
                           requestTracing:(OPTrace * _Nullable)tracing;

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                                    eventName:(NSString * _Nullable)eventName
                               requestTracing:(OPTrace * _Nullable)tracing;

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                            eventName:(NSString * _Nullable)eventName
                                       requestTracing:(OPTrace * _Nullable)tracing;

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                    completionHandler:(void (^)(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                                            eventName:(NSString * _Nullable)eventName
                                       requestTracing:(OPTrace * _Nullable)tracing;

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                    completionHandler:(void (^)(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                                            eventName:(NSString * _Nullable)eventName
                                          preloadPath:(NSString *)preloadPath
                                       requestTracing:(OPTrace * _Nullable)tracing;

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(nullable NSData *)bodyData
                                completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                                        eventName:(NSString * _Nullable)eventName
                                   requestTracing:(OPTrace * _Nullable)tracing;
@end

NS_ASSUME_NONNULL_END
