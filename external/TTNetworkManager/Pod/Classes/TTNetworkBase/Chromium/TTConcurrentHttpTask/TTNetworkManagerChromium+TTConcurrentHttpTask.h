//
//  TTNetworkManagerChromium+TTConcurrentHttpTask.h
//  TTNetworkManager
//
//  Created by dongyangfan on 2020/10/25.
//  this file is used for Exposing TTNetworkManagerChromium's private method,
//  TTConcurrentHttpTask will use those method to manage concurrent task


#import "TTNetworkManagerChromium.h"
#import "TTHttpTaskChromium.h"

@interface TTNetworkManagerChromium (TTConcurrentHttpTask)
//TTNetworkManager's serial queue(ttnet_dispatch_queue) to call user's block back
@property (nonatomic, strong) dispatch_queue_t dispatch_queue;

//In BDTuring verify situation, callbackBlock must dispatch to concurrent queue
@property (nonatomic, strong) dispatch_queue_t concurrent_dispatch_queue;

//TTNetworkManagerChromium's interface callback headerBlock,dataBlock,completeCallback in serial_callback_dispatch_queue
@property (nonatomic, strong) dispatch_queue_t serial_callback_dispatch_queue;

- (UInt64)nextTaskId;

- (void)addTaskWithId_:(UInt64)taskId task:(TTHttpTask *)task;

- (void)removeTaskWithId_:(UInt64)taskId;

//Model request
- (TTHttpTaskChromium *)buildModelHttpTask:(TTRequestModel *)model
                         requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                        responseSerializer:(Class<TTResponseModelResponseSerializerProtocol>)responseSerializer
                                autoResume:(BOOL)autoResume
                                  callback:(TTNetworkResponseModelFinishBlock)callback
                      callbackWithResponse:(TTNetworkModelFinishBlockWithResponse)callbackWithResponse
                            dispatch_queue:(dispatch_queue_t)dispatch_queue;

//JSON request
- (TTHttpTaskChromium *)buildJSONHttpTask:(NSString *)URL
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
                           dispatch_queue:(dispatch_queue_t)dispatch_queue;


- (TTHttpTaskChromium *)buildBinaryHttpTask:(NSString *)URL
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
                             dispatch_queue:(dispatch_queue_t)callback_queue;


- (TTHttpTaskChromium *)buildMemoryUploadHttpTask:(NSString *)URLString
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
                                          timeout:(NSTimeInterval)timeout;


- (TTHttpTaskChromium *)buildFileUploadHttpTask:(NSString *)URLString
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
                                  callbackQueue:(dispatch_queue_t)callbackQueue;


- (TTHttpTaskChromium *)buildDownloadHttpTask:(NSString *)URLString
                                   parameters:(id)parameters
                                  headerField:(NSDictionary *)headerField
                             needCommonParams:(BOOL)needCommonParams
                            requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                     isAppend:(BOOL)isAppend
                             progressCallback:(void (^)(int64_t current, int64_t total))progressCallback
                                     progress:(NSProgress * __autoreleasing *)progress
                                  destination:(NSURL *)destination
                                   autoResume:(BOOL)autoResume
                            completionHandler:(void (^)(TTHttpResponse *response, NSURL *filePath, NSError *error))completionHandler;


- (TTHttpTaskChromium *)buildWebviewHttpTask:(NSURLRequest *)nsRequest
                                  mainDocURL:(NSString *)mainDocURL
                                  autoResume:(BOOL)autoResume
                             enableHttpCache:(BOOL)enableHttpCache
                              headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
                                dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
                        callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                            redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback;

@end
