//
//  TTNetworkManagerApiParameters.h
//  TTNetworkManager
//
//  Created by dongyangfan on 2020/10/25.
//

#ifndef TTNetworkManagerApiParameters_h
#define TTNetworkManagerApiParameters_h

#import "TTHTTPResponseSerializerProtocol.h"
#import "TTHTTPRequestSerializerProtocol.h"
#import "TTResponseModelProtocol.h"
#import "TTNetworkDefine.h"

#pragma mark - TTNetworkManagerApiParameters
//user's parameters passed to TTNetworkManager
@interface TTNetworkManagerApiParameters : NSObject

@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, strong) TTRequestModel *model;
@property (nonatomic, strong) id params;
@property (nonatomic, copy) NSString *method;
@property (nonatomic, assign) BOOL needCommonParams;
@property (nonatomic, copy) NSDictionary *headerField;
@property (nonatomic, assign) BOOL enableHttpCache;
@property (nonatomic, assign) BOOL verifyRequest;
@property (nonatomic, assign) BOOL isCustomizedCookie;
@property (nonatomic, copy) TTConstructingBodyBlock bodyBlock;
@property (nonatomic, strong) NSData *bodyField;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, assign) uint64_t uploadFileOffset;
@property (nonatomic, assign) uint64_t uploadFileLength;
@property (nonatomic, strong) NSProgress *progress;
@property (nonatomic, strong) Class<TTHTTPRequestSerializerProtocol> requestSerializer;
@property (nonatomic, strong) Class<TTResponseModelResponseSerializerProtocol> modelResponseSerializer;
@property (nonatomic, assign) BOOL useJsonResponseSerializer;
@property (nonatomic, strong) Class<TTJSONResponseSerializerProtocol> jsonResponseSerializer;
@property (nonatomic, strong) Class<TTBinaryResponseSerializerProtocol> binaryResponseSerializer;
@property (nonatomic, copy) TTNetworkResponseModelFinishBlock modelCallback;
@property (nonatomic, copy) TTNetworkModelFinishBlockWithResponse modelCallbackWithResponse;
@property (nonatomic, copy) TTNetworkChunkedDataHeaderBlock headerCallback;
@property (nonatomic, copy) TTNetworkChunkedDataReadBlock dataCallback;
@property (nonatomic, copy) TTNetworkJSONFinishBlock callback;
@property (nonatomic, copy) TTNetworkObjectFinishBlockWithResponse callbackWithResponse;
@property (nonatomic, copy) TTNetworkURLRedirectBlock redirectCallback;
@property (nonatomic, strong) dispatch_queue_t dispatch_queue;
@property (nonatomic, strong) NSURL *destination;
@property (nonatomic, assign) BOOL isAppend;
@property (nonatomic, copy) ProgressCallbackBlock progressCallback;
@property (nonatomic, copy) DownloadCompletionHandler completionHandler;
@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, strong) dispatch_queue_t chunk_dispatch_queue;
@property (nonatomic, strong) NSURLRequest *nsrequest;
@property (nonatomic, copy) NSString *mainDocURL;

- (instancetype)initWithURLString:(NSString *)URLString
                     requestModel:(TTRequestModel *)model
                           params:(id)params
                           method:(NSString *)method
                 needCommonParams:(BOOL)needCommonParams
                      headerField:(NSDictionary *)headerField
                  enableHttpCache:(BOOL)enableHttpCache
                    verifyRequest:(BOOL)verifyRequest
               isCustomizedCookie:(BOOL)isCustomizedCookie
        constructingBodyWithBlock:(TTConstructingBodyBlock)bodyBlock
                        bodyField:(NSData *)bodyField
                         filePath:(NSString *)filePath
                           offset:(uint64_t)uploadFileOffset
                           length:(uint64_t)uploadFileLength
                         progress:(NSProgress * __autoreleasing *)progress
                requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
          modelResponseSerializer:(Class<TTResponseModelResponseSerializerProtocol>)modelResponseSerializer
        useJsonResponseSerializer:(BOOL)useJsonResponseSerializer
           jsonResponseSerializer:(Class<TTJSONResponseSerializerProtocol>)jsonResponseSerializer
         binaryResponseSerializer:(Class<TTBinaryResponseSerializerProtocol>)binaryResponseSerializer
                    modelCallback:(TTNetworkResponseModelFinishBlock)modelCallback
        modelCallbackWithResponse:(TTNetworkModelFinishBlockWithResponse)modelCallbackWithResponse
                   headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
                     dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
                         callback:(TTNetworkJSONFinishBlock)callback
             callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                 redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback
                   dispatch_queue:(dispatch_queue_t)dispatch_queue
                      destination:(NSURL *)destination
                         isAppend:(BOOL)isAppend
                 progressCallback:(void (^)(int64_t current, int64_t total))progressCallback
                completionHandler:(DownloadCompletionHandler)completionHandler
                          timeout:(NSTimeInterval)timeout
  redirectHeaderDataCallbackQueue:(dispatch_queue_t)chunk_dispatch_queue
                        nsrequest:(NSURLRequest *)nsRequest
                       mainDocURL:(NSString *)mainDocURL;

@end


#pragma mark - CallbackInfo
@interface CallbackInfo : NSObject

@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) id obj;
@property (nonatomic, strong) TTHttpResponse *response;

- (instancetype)initWithError:(NSError *)error
                          obj:(id)obj
                     response:(TTHttpResponse *)response;

@end


#ifdef FULL_API_CONCURRENT_REQUEST
#pragma mark - ModelCallbackInfo
@interface ModelCallbackInfo : NSObject

@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSObject<TTResponseModelProtocol> *responseModel;

- (instancetype)initWithError:(NSError *)error
                 reponseModel:(NSObject<TTResponseModelProtocol> *)responseModel;

@end

#pragma mark - DownloadCallbackInfo
@interface DownloadCallbackInfo : NSObject

@property (nonatomic, strong) TTHttpResponse *response;
@property (nonatomic, strong) NSURL *filePath;
@property (nonatomic, strong) NSError *error;

- (instancetype)initWithError:(NSError *)error
                     filePath:(NSURL *)filePath
                     response:(TTHttpResponse *)response;

@end
#endif /* FULL_API_CONCURRENT_REQUEST */

#endif /* TTNetworkManagerApiParameters_h */
