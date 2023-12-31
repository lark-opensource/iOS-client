//
//  TTConcurrentHttpTask.h
//  TTNetworkManager
//
//  Created by dongyangfan on 2020/10/25.
//

#ifndef TTConcurrentHttpTask_h
#define TTConcurrentHttpTask_h

#import "TTHttpTask.h"
#import "TTHTTPResponseSerializerProtocol.h"
#import "TTHTTPRequestSerializerProtocol.h"
#import "TTNetworkDefine.h"

@interface TTConcurrentHttpTask : TTHttpTask

#ifdef FULL_API_CONCURRENT_REQUEST
#pragma mark - Model
+ (TTConcurrentHttpTask *)buildModelConcurrentTask:(TTRequestModel *)model
                                 requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                responseSerializer:(Class<TTResponseModelResponseSerializerProtocol>)responseSerializer
                                        autoResume:(BOOL)autoResume
                                          callback:(TTNetworkResponseModelFinishBlock)callback
                              callbackWithResponse:(TTNetworkModelFinishBlockWithResponse)callbackWithResponse
                                    dispatch_queue:(dispatch_queue_t)dispatch_queue
                           concurrentRequestConfig:(NSDictionary *)concurrentRequestConfig;


#pragma mark - Memory Upload
+ (TTConcurrentHttpTask *)buildMemoryUploadConcurrentTask:(NSString *)URLString
                                               parameters:(id)parameters
                                              headerField:(NSDictionary *)headerField
                                constructingBodyWithBlock:(TTConstructingBodyBlock)bodyBlock
                                                 progress:(NSProgress * __autoreleasing *)progress
                                         needcommonParams:(BOOL)needCommonParams
                                        requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                useJsonResponseSerializer:(BOOL)useJsonResponseSerializer
                                   jsonResponseSerializer:(Class<TTJSONResponseSerializerProtocol>)jsonResponseSerializer
                                 binaryResponseSerializer:(Class<TTBinaryResponseSerializerProtocol>)binaryResponseSerializer
                                               autoResume:(BOOL)autoResume
                                                 callback:(TTNetworkJSONFinishBlock)callback
                                     callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                                                  timeout:(NSTimeInterval)timeout
                                  concurrentRequestConfig:(NSDictionary *)concurrentRequestConfig;


#pragma mark - File upload
+ (TTConcurrentHttpTask *)buildFileUploadConcurrentTask:(NSString *)URLString
                                                 method:(NSString *)method
                                            headerField:(NSDictionary *)headerField
                                              bodyField:(NSData *)bodyField
                                               filePath:(NSString *)filePath
                                                 offset:(uint64_t)uploadFileOffset
                                                 length:(uint64_t)uploadFileLength
                                               progress:(NSProgress * __autoreleasing *)progress
                                      requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                     responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                             autoResume:(BOOL)autoResume
                                               callback:(TTNetworkObjectFinishBlockWithResponse)callback
                                                timeout:(NSTimeInterval)timeout
                                concurrentRequestConfig:(NSDictionary *)concurrentRequestConfig
                                          callbackQueue:(dispatch_queue_t)callbackQueue;


#pragma mark - Download
+ (TTConcurrentHttpTask *)buildDownloadConcurrentTask:(NSString *)URLString
                                           parameters:(id)parameters
                                          headerField:(NSDictionary *)headerField
                                     needCommonParams:(BOOL)needCommonParams
                                    requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                             isAppend:(BOOL)isAppend
                                     progressCallback:(void (^)(int64_t current, int64_t total))progressCallback
                                             progress:(NSProgress * __autoreleasing *)progress
                                          destination:(NSURL *)destination
                                           autoResume:(BOOL)autoResume
                                    completionHandler:(void (^)(TTHttpResponse *response, NSURL *filePath, NSError *error))completionHandler
                              concurrentRequestConfig:(NSDictionary *)concurrentRequestConfig;

#endif /* FULL_API_CONCURRENT_REQUEST */



#pragma mark - JSON
+ (TTConcurrentHttpTask *)buildJSONConcurrentTask:(NSString *)URLString
                                           params:(id)params
                                           method:(NSString *)method
                                 needCommonParams:(BOOL)needCommonParams
                                      headerField:(NSDictionary *)headerField
                                requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                               responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                                       autoResume:(BOOL)autoResume
                                    verifyRequest:(BOOL)verifyRequest
                               isCustomizedCookie:(BOOL)isCustomizedCookie
                                         callback:(TTNetworkJSONFinishBlock)callback
                             callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                                   dispatch_queue:(dispatch_queue_t)dispatch_queue
                          concurrentRequestConfig:(NSDictionary *)concurrentRequestConfig;


#pragma mark - Binary
+ (TTConcurrentHttpTask *)buildBinaryConcurrentTask:(NSString *)URLString
                                             params:(id)params
                                             method:(NSString *)method
                                   needCommonParams:(BOOL)needCommonParams
                                        headerField:(NSDictionary *)headerField
                                    enableHttpCache:(BOOL)enableHttpCache
                                  requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                 responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                         autoResume:(BOOL)autoResume
                                 isCustomizedCookie:(BOOL)isCustomizedCookie
                                     headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
                                       dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
                                           callback:(TTNetworkObjectFinishBlock)callback
                               callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                                   redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback
                                           progress:(NSProgress * __autoreleasing *)progress
                                     dispatch_queue:(dispatch_queue_t)callback_queue
                    redirectHeaderDataCallbackQueue:(dispatch_queue_t)chunk_dispatch_queue
                            concurrentRequestConfig:(NSDictionary *)concurrentRequestConfig;

#pragma mark - webview
+ (TTConcurrentHttpTask *)buildWebviewConcurrentTask:(NSURLRequest *)nsRequest
                                          mainDocURL:(NSString *)mainDocURL
                                          autoResume:(BOOL)autoResume
                                     enableHttpCache:(BOOL)enableHttpCache
                                    redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback
                                      headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
                                        dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
                                callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                             concurrentRequestConfig:(NSDictionary *)concurrentRequestConfig;


+ (void)clearMatchRules:(NSDictionary *)concurrentRequestConfig;

@end

#endif /* TTConcurrentHttpTask_h */
