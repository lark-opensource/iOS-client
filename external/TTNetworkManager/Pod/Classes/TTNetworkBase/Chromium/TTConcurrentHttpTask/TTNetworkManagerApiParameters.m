//
//  TTNetworkManagerApiParameters.m
//  TTNetworkManager
//
//  Created by dongyangfan on 2020/10/25.
//

#import "TTNetworkManagerApiParameters.h"

#pragma mark - TTNetworkManagerApiParameters
@implementation TTNetworkManagerApiParameters

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
                 progressCallback:(ProgressCallbackBlock)progressCallback
                completionHandler:(DownloadCompletionHandler)completionHandler
                          timeout:(NSTimeInterval)timeout
  redirectHeaderDataCallbackQueue:(dispatch_queue_t)chunk_dispatch_queue
                        nsrequest:(NSURLRequest *)nsRequest
                       mainDocURL:(NSString *)mainDocURL {
    if (self = [super init]) {
        self.URLString = URLString;
        self.model = model;
        self.params = params;
        self.method = method;
        self.needCommonParams = needCommonParams;
        self.headerField = headerField;
        self.enableHttpCache = enableHttpCache;
        self.verifyRequest = verifyRequest;
        self.isCustomizedCookie = isCustomizedCookie;
        self.bodyBlock = bodyBlock;
        self.bodyField = bodyField;
        self.filePath = filePath;
        self.uploadFileOffset = uploadFileOffset;
        self.uploadFileLength = uploadFileLength;
        if (!progress) {
            self.progress = nil;
        } else {
            self.progress = *progress;
        }
        self.requestSerializer = requestSerializer;
        self.modelResponseSerializer = modelResponseSerializer;
        self.useJsonResponseSerializer = useJsonResponseSerializer;
        self.jsonResponseSerializer = jsonResponseSerializer;
        self.binaryResponseSerializer = binaryResponseSerializer;
        self.modelCallback = modelCallback;
        self.modelCallbackWithResponse = modelCallbackWithResponse;
        self.headerCallback = headerCallback;
        self.dataCallback = dataCallback;
        self.callback = callback;
        self.callbackWithResponse = callbackWithResponse;
        self.redirectCallback = redirectCallback;
        self.dispatch_queue = dispatch_queue;
        self.destination = destination;
        self.isAppend = isAppend;
        self.progressCallback = progressCallback;
        self.completionHandler = completionHandler;
        self.timeout = timeout;
        self.chunk_dispatch_queue = chunk_dispatch_queue;
        self.nsrequest = nsRequest;
        self.mainDocURL = mainDocURL;
    }
    return self;
}

@end



#pragma mark - CallbackInfo
@implementation CallbackInfo

- (instancetype)initWithError:(NSError *)error
                          obj:(id)obj
                     response:(TTHttpResponse *)response {
    if (self = [super init]) {
        self.error = error;
        self.obj = obj;
        self.response = response;
    }
    return self;
}

@end


#ifdef FULL_API_CONCURRENT_REQUEST
#pragma mark - ModelCallbackInfo
@implementation ModelCallbackInfo

- (instancetype)initWithError:(NSError *)error
                 reponseModel:(NSObject<TTResponseModelProtocol> *) responseModel {
    if (self = [super init]) {
        self.error = error;
        self.responseModel = responseModel;
    }
    return self;
}

@end



#pragma mark - DownloadCallbackInfo
@implementation DownloadCallbackInfo

- (instancetype)initWithError:(NSError *)error
                     filePath:(NSURL *)filePath
                     response:(TTHttpResponse *)response {
    if (self = [super init]) {
        self.error = error;
        self.filePath = filePath;
        self.response = response;
    }
    return self;
}

@end
#endif /* FULL_API_CONCURRENT_REQUEST */
