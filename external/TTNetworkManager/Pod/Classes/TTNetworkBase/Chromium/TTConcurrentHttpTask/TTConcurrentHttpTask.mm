//
//  TTConcurrentHttpTask.mm
//  TTNetworkManager
//
//  Created by dongyangfan on 2020/10/25.
//

#import "TTConcurrentHttpTask.h"
#import "TTNetworkManagerChromium+TTConcurrentHttpTask.h"
#import "NSTimer+TTNetworkBlockTimer.h"
#import "TTNetworkManagerApiParameters.h"
#import "TTNetworkManagerChromium.h"
#import "TTNetworkUtil.h"
#import "TTNetworkManagerLog.h"

#include "components/cronet/ios/cronet_environment.h"

static const NSInteger kUnsetIntMatchRuleValue = -666666; //indicate that the integer value isn't set

#pragma mark - UrlMatchRule
@interface UrlMatchRule : NSObject
#pragma mark - TNC config value
@property (nonatomic, copy) NSArray<NSString *> *hostGroup;
@property (nonatomic, copy) NSArray<NSString *> *equalGroup;
@property (nonatomic, copy) NSArray<NSString *> *prefixGroup;
@property (nonatomic, copy) NSArray<NSString *> *patternGroup;
@property (nonatomic, copy) NSArray<NSString *> *concurrentHost;
@property (nonatomic, assign) NSInteger maxFailCount;
@property (nonatomic, assign) NSInteger forbiddenDurationSeconds;
@property (nonatomic, copy) NSSet<NSNumber *> *blockErrorCodeSet;
@property (nonatomic, assign) unsigned short connectIntervalMillis;
@property (nonatomic, assign) BOOL isRetryForNot2xxCode;
@property (nonatomic, copy) NSString* rsName;
@property (nonatomic, assign) BOOL isBypassRouteSelection;

#pragma mark - other logic
@property (atomic, assign) NSInteger continuousFailCount;
@property (atomic, strong) NSDate *firstForbiddenTime;
@end


@implementation UrlMatchRule

- (instancetype)initWithHostGroup:(NSArray<NSString *> *)hostGroup
                       equalGroup:(NSArray<NSString *> *)equalGroup
                      prefixGroup:(NSArray<NSString *> *)prefixGroup
                     patternGroup:(NSArray<NSString *> *)patternGroup
                   concurrentHost:(NSArray<NSString *> *)concurrentHost
                     maxFailCount:(NSInteger)maxFailCount
         forbiddenDurationSeconds:(NSInteger)forbiddenDurationSeconds
                blockErrorCodeSet:(NSSet<NSNumber *> *)blockErrorCodeSet
            connectIntervalMillis:(unsigned short)connectIntervalMillis
             isRetryForNot2xxCode:(BOOL)isRetryForNot2xxCode
     refineWithRouteSelectionName:(NSString*)rsName
           isBypassRouteSelection:(BOOL)isBypassRouteSelection {
    if (self = [super init]) {
        self.hostGroup = hostGroup;
        self.equalGroup = equalGroup;
        self.prefixGroup = prefixGroup;
        self.patternGroup = patternGroup;
        self.concurrentHost = concurrentHost;
        self.maxFailCount = maxFailCount;
        self.forbiddenDurationSeconds = forbiddenDurationSeconds;
        self.blockErrorCodeSet = blockErrorCodeSet;
        self.connectIntervalMillis = connectIntervalMillis;
        self.isRetryForNot2xxCode = isRetryForNot2xxCode;
        self.rsName = rsName;
        self.isBypassRouteSelection = isBypassRouteSelection;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[UrlMatchRule class]]) {
        return NO;
    }
    return [self isEqualToRule:(UrlMatchRule *)object];
}

- (BOOL)isEqualToRule:(UrlMatchRule *)object {
    if (!object) {
        return NO;
    }
    
    return ((!self.hostGroup && !object.hostGroup) || [self.hostGroup isEqualToArray:object.hostGroup]) &&
        ((!self.equalGroup && !object.equalGroup) || [self.equalGroup isEqualToArray:object.equalGroup]) &&
        ((!self.prefixGroup && !object.prefixGroup) || [self.prefixGroup isEqualToArray:object.prefixGroup]) &&
        ((!self.patternGroup && !object.patternGroup) || [self.patternGroup isEqualToArray:object.patternGroup]) &&
        ((!self.concurrentHost && !object.concurrentHost) || [self.concurrentHost isEqualToArray:object.concurrentHost]) &&
        (self.maxFailCount == object.maxFailCount) &&
        (self.forbiddenDurationSeconds == object.forbiddenDurationSeconds) &&
        ((!self.blockErrorCodeSet && !object.blockErrorCodeSet) || ([self.blockErrorCodeSet isEqualToSet:object.blockErrorCodeSet])) &&
        (self.connectIntervalMillis == object.connectIntervalMillis) &&
        (self.isRetryForNot2xxCode == object.isRetryForNot2xxCode) &&
        (self.rsName == object.rsName) &&
        (self.isBypassRouteSelection == object.isBypassRouteSelection);
}

- (NSUInteger)hash {
    NSUInteger hash1 = [self.hostGroup hash];
    NSUInteger hash2 = [self.equalGroup hash];
    NSUInteger hash3 = [self.prefixGroup hash];
    NSUInteger hash4 = [self.patternGroup hash];
    NSUInteger hash5 = [self.concurrentHost hash];
    NSUInteger hash6 = [self.blockErrorCodeSet hash];
    
    NSUInteger result = hash1 ^ hash2 ^ hash3 ^ hash4 ^ hash5 ^ hash6;
    
    return result;
}

@end

@interface DispatchInfoGroup : NSObject

@property(nonatomic, copy) NSString* originalHost;
@property(nonatomic, copy) NSString* dispatchHost;
@property(nonatomic, strong) NSNumber* dispatchTime;
@property(nonatomic, assign) BOOL sentAlready;

@end

@implementation DispatchInfoGroup

- (instancetype)init {
    if (self = [super init]) {
        _originalHost = @"";
        _dispatchHost = @"";
        _dispatchTime = [NSNumber numberWithInt:-1];
        _sentAlready = false;
    }
    return self;
}

- (void)setInfo2Task:(TTHttpTaskChromium*)task {
    if (!task) return;
    task.originalHost = self.originalHost;
    task.dispatchedHost = self.dispatchHost;
    task.dispatchTime = [self.dispatchTime doubleValue];
    task.sentAlready = self.sentAlready;
}

@end


//store failed concurrent task's macth rule
static NSMutableSet<UrlMatchRule *> *ruleSet = nil;//lazy init
//the lock to handle with ruleSet
static NSLock *ruleSetLock = nil;//lazy init

@interface TTConcurrentHttpTask()
//the struct used  to store parameters which was pass to TTNetworkmanager's old interface(eg: requestForJSONWithURL)
@property (nonatomic, strong) TTNetworkManagerApiParameters *outerApiParams;
//used for calling TTNetworkManager's requestForxxx interface to generate specific subtask
@property (nonatomic, assign) TTNetworkManagerApiType requestApiType;
//subtask connection interval in a concurrent task
@property (nonatomic, assign) NSTimeInterval connectTimeInterval;
//store unused host list
@property (atomic, strong) NSMutableArray<NSString *> *concurrentHost;
//used for removing TTConcurrentHttpTask's instance from TTNetworkManager's taskMap when concurrent task finished
@property (nonatomic, assign) UInt64 concurrentTaskId;
//every subtask would get a same transactionId header to indicate that it belongs to a concurrent task
@property (nonatomic, copy) NSString *transactionId;
//the time point which first subtask start,the gap with other subtask is used for setting timeout
@property (nonatomic, strong) NSDate *firstTaskStartTime;
//subtask's sequence number, which can be used for locating a specific subtask in subTaskSequenceDict
@property (nonatomic, assign) NSUInteger subTaskSeqNumber;
//key is subTaskSeqNumber, value is subtask
@property (atomic, strong) NSMutableDictionary<NSString *, TTHttpTaskChromium *> *subTaskSequenceDict;

@property (atomic, strong) TTHttpTaskChromium *winnerTask;

//started task count
@property (atomic, assign) NSUInteger resumedTaskCount;
//Set of sent hosts , record hosts to prevent duplicated request
@property (atomic, strong) NSMutableSet* sentHostSet;

//callbacked task count. If resumedTaskCount == callbackedTaskCount, concurrent task finish
@property (atomic, assign) NSUInteger callbackedTaskCount;

//used for callback the first failed task info to user when all subtasks failed
@property (nonatomic, strong) NSMutableDictionary *callbackInfoDict;
//shot every connectTimeInterval to start a subtask if the previous subtask not responsed
@property (atomic, strong) NSTimer *timer;
//the concurrent task state - cancel
@property (atomic, assign) BOOL isCancelled;
//the concurrent task state - complete
@property (atomic, assign) BOOL isCompleted;
//indicate whether the redirect block has been callbacked to user
@property (atomic, assign) BOOL isRedirectionCallbackedToUser;

//set throttleNetSpeed when winner detected
@property (atomic, assign) int64_t throttleSpeed;
//the concurrent task's priority
@property (atomic, assign) float taskPriority;
//the TNC config which matches with this task
@property (nonatomic, strong) UrlMatchRule *matchRule;
//distinguish marking winner between headerCallback and final callback
@property (nonatomic, assign) BOOL isMarkingWinnerWithBlockErrorCodeSet;

//tasks info in log
@property (nonatomic, strong) NSMutableArray<TaskDetailInfo *> *tasksInfo;
//the full concurrent task's start time, used for calculating the concurrent task's duration
@property (nonatomic, assign) NSTimeInterval startTime;
//the full concurrent task's end time, used for calculating the concurrent task's duration
@property (nonatomic, assign) NSTimeInterval endTime;

@end


@interface TTConcurrentHttpTask() {
    std::atomic<bool> isTaskResumed;
}
@end

@implementation TTConcurrentHttpTask

//can't access members in base class if not use synthesize
@synthesize state = _state;
@synthesize recvHeaderTimeout = _recvHeaderTimeout;
@synthesize readDataTimeout = _readDataTimeout;
@synthesize protectTimeout = _protectTimeout;
@synthesize timeoutInterval = _timeoutInterval;
@synthesize skipSSLCertificateError = _skipSSLCertificateError;
@synthesize isStreamingTask = _isStreamingTask;
@synthesize enableHttpCache = _enableHttpCache;

#ifdef FULL_API_CONCURRENT_REQUEST
#pragma mark - Model
- (instancetype)initWithRequestInterval:(NSTimeInterval)requestInterval
                         concurrentHost:(NSArray <NSString *> *)concurrentHost
                           requestModel:(TTRequestModel *)model
                      requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                         requestApiType:(TTNetworkManagerApiType)requestApiType
                       concurrentTaskId:(UInt64)concurrentTaskId
                          transactionId:(NSString *)transactionId
                modelResponseSerializer:(Class<TTResponseModelResponseSerializerProtocol>)modelResponseSerializer
                          modelCallback:(TTNetworkResponseModelFinishBlock)modelCallback
                   callbackWithResponse:(TTNetworkModelFinishBlockWithResponse)modelCallbackWithResponse
                         dispatch_queue:(dispatch_queue_t)dispatch_queue
                              matchRule:(UrlMatchRule *)matchRule {
    return [self initWithRequestInterval:requestInterval URLString:[model _requestURL].absoluteString concurrentHost:concurrentHost requestModel:model params:nil method:nil needCommonParams:NO headerField:nil enableHttpCache:YES verifyRequest:NO isCustomizedCookie:NO constructingBodyWithBlock:nil bodyField:nil filePath:nil offset:0 length:0 progress:nil requestSerializer:requestSerializer requestApiType:requestApiType concurrentTaskId:concurrentTaskId transactionId:transactionId modelResponseSerializer:modelResponseSerializer useJsonResponseSerializer:NO jsonResponseSerializer:nil binaryResponseSerializer:nil modelCallback:modelCallback modelCallbackWithResponse:modelCallbackWithResponse headerCallback:nil dataCallback:nil callback:nil callbackWithResponse:nil redirectCallback:nil dispatch_queue:dispatch_queue destination:nil isAppend:NO progressCallback:nil completionHandler:nil timeout:-1 redirectHeaderDataCallbackQueue:[(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] serial_callback_dispatch_queue] nsrequest:nil mainDocURL:nil matchRule:matchRule];
}

+ (TTConcurrentHttpTask *)buildModelConcurrentTask:(TTRequestModel *)model
                                 requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                responseSerializer:(Class<TTResponseModelResponseSerializerProtocol>)responseSerializer
                                        autoResume:(BOOL)autoResume
                                          callback:(TTNetworkResponseModelFinishBlock)callback
                              callbackWithResponse:(TTNetworkModelFinishBlockWithResponse)callbackWithResponse
                                    dispatch_queue:(dispatch_queue_t)dispatch_queue
                           concurrentRequestConfig:(NSDictionary *)concurrentRequestConfig {
    if ([self.class parseIfConcurrentRequestSwitchEnabled:concurrentRequestConfig switchName:kTTNetworkConcurrentRequestEnabled]) {
        NSString *urlString = [model _requestURL].absoluteString;
        if ([self.class isMatchingWithNoRetry:urlString]) {
            return nil;
        }
        
        NSArray *matchRules = [self.class parseConcurrentRequestMatchRules:concurrentRequestConfig];
        if (!matchRules) {
            return nil;
        }
        //parse if host and path match
        UrlMatchRule *matchRule = [self.class getConcurrentHostAccordingToRules:matchRules withUrl:urlString];
        if (![self.class forbidConcurrentTaskIfNeed:matchRule]) {
            UInt64 concurrentTaskId = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] nextTaskId];
            NSString *transactionId =[[NSUUID UUID] UUIDString];
            
            TTConcurrentHttpTask *concurrentTask = [[TTConcurrentHttpTask alloc] initWithRequestInterval:[self.class parseConcurrentRequestConnectInterval:concurrentRequestConfig preferMatchRule:matchRule]
                                                                                          concurrentHost:matchRule.concurrentHost
                                                                                            requestModel:model
                                                                                       requestSerializer:requestSerializer
                                                                                          requestApiType:TTNetworkManagerApiModel
                                                                                        concurrentTaskId:concurrentTaskId
                                                                                           transactionId:transactionId
                                                                                 modelResponseSerializer:responseSerializer
                                                                                           modelCallback:callback
                                                                                    callbackWithResponse:callbackWithResponse
                                                                                          dispatch_queue:dispatch_queue
                                                                                               matchRule:matchRule];
            
            if (autoResume) {
                [concurrentTask resume];
            }
            
            [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] addTaskWithId_:concurrentTaskId task:concurrentTask];
            return concurrentTask;
        }
    }
    return nil;
}

#pragma mark - Memmory upload
- (instancetype)initWithRequestInterval:(NSTimeInterval)requestInterval
                         concurrentHost:(NSArray <NSString *> *)concurrentHost
                              URLString:(NSString *)URLString
                             parameters:(id)parameters
                            headerField:(NSDictionary *)headerField
              constructingBodyWithBlock:(TTConstructingBodyBlock)bodyBlock
                               progress:(NSProgress * __autoreleasing *)progress
                       needcommonParams:(BOOL)needCommonParams
                      requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                         requestApiType:(TTNetworkManagerApiType)requestApiType
                       concurrentTaskId:(UInt64)concurrentTaskId
                          transactionId:(NSString *)transactionId
              useJsonResponseSerializer:(BOOL)useJsonResponseSerializer
                 jsonResponseSerializer:(Class<TTJSONResponseSerializerProtocol>)jsonResponseSerializer
               binaryResponseSerializer:(Class<TTBinaryResponseSerializerProtocol>)binaryResponseSerializer
                               callback:(TTNetworkJSONFinishBlock)callback
                   callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                                timeout:(NSTimeInterval)timeout
                              matchRule:(UrlMatchRule *)matchRule {
    return [self initWithRequestInterval:requestInterval URLString:URLString concurrentHost:concurrentHost requestModel:nil params:parameters method:nil needCommonParams:needCommonParams headerField:headerField enableHttpCache:YES verifyRequest:NO isCustomizedCookie:NO constructingBodyWithBlock:bodyBlock bodyField:nil filePath:nil offset:0 length:0 progress:progress requestSerializer:requestSerializer requestApiType:requestApiType concurrentTaskId:concurrentTaskId transactionId:transactionId modelResponseSerializer:nil useJsonResponseSerializer:useJsonResponseSerializer jsonResponseSerializer:jsonResponseSerializer binaryResponseSerializer:binaryResponseSerializer modelCallback:nil modelCallbackWithResponse:nil headerCallback:nil dataCallback:nil callback:callback callbackWithResponse:callbackWithResponse redirectCallback:nil dispatch_queue:nil destination:nil isAppend:NO progressCallback:nil completionHandler:nil timeout:timeout redirectHeaderDataCallbackQueue:[(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] serial_callback_dispatch_queue] nsrequest:nil mainDocURL:nil matchRule:matchRule];
}

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
                                  concurrentRequestConfig:(NSDictionary *)concurrentRequestConfig {
    if ([self.class parseIfConcurrentRequestSwitchEnabled:concurrentRequestConfig switchName:kTTNetworkConcurrentRequestEnabled]) {
        if ([self.class isMatchingWithNoRetry:URLString]) {
            return nil;
        }
        
        NSArray *matchRules = [self.class parseConcurrentRequestMatchRules:concurrentRequestConfig];
        if (!matchRules) {
            return nil;
        }
        //parse if host and path match
        UrlMatchRule *matchRule = [self.class getConcurrentHostAccordingToRules:matchRules withUrl:URLString];
        if (![self.class forbidConcurrentTaskIfNeed:matchRule]) {
            UInt64 concurrentTaskId = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] nextTaskId];
            NSString *transactionId =[[NSUUID UUID] UUIDString];
               
            TTConcurrentHttpTask *concurrentTask = [[TTConcurrentHttpTask alloc] initWithRequestInterval:[self.class parseConcurrentRequestConnectInterval:concurrentRequestConfig preferMatchRule:matchRule]
                                                                                             concurrentHost:matchRule.concurrentHost
                                                                                                  URLString:URLString
                                                                                                 parameters:parameters
                                                                                                headerField:headerField
                                                                                  constructingBodyWithBlock:bodyBlock
                                                                                                   progress:progress
                                                                                           needcommonParams:needCommonParams
                                                                                          requestSerializer:requestSerializer
                                                                                             requestApiType:TTNetworkManagerApiMemoryUpload
                                                                                           concurrentTaskId:concurrentTaskId
                                                                                              transactionId:transactionId
                                                                                  useJsonResponseSerializer:useJsonResponseSerializer
                                                                                     jsonResponseSerializer:jsonResponseSerializer
                                                                                   binaryResponseSerializer:binaryResponseSerializer
                                                                                                   callback:callback
                                                                                       callbackWithResponse:callbackWithResponse
                                                                                                    timeout:timeout
                                                                                               matchRule:matchRule];
               
               if (autoResume) {
                   [concurrentTask resume];
               }
               
               [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] addTaskWithId_:concurrentTaskId task:concurrentTask];
               return concurrentTask;
        }
    }
    return nil;
}

#pragma mark - File upload

- (instancetype)initWithRequestInterval:(NSTimeInterval)requestInterval
                         concurrentHost:(NSArray <NSString *> *)concurrentHost
                              URLString:(NSString *)URLString
                                 method:(NSString *)method
                            headerField:(NSDictionary *)headerField
                              bodyField:(NSData *)bodyField
                               filePath:(NSString *)filePath
                                 offset:(uint64_t)uploadFileOffset
                                 length:(uint64_t)uploadFileLength
                               progress:(NSProgress * __autoreleasing *)progress
                      requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                         requestApiType:(TTNetworkManagerApiType)requestApiType
                       concurrentTaskId:(UInt64)concurrentTaskId
                          transactionId:(NSString *)transactionId
                     responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                               callback:(TTNetworkObjectFinishBlockWithResponse)callback
                          callbackQueue:(dispatch_queue_t)callbackQueue
                                timeout:(NSTimeInterval)timeout
                              matchRule:(UrlMatchRule *)matchRule {
    return [self initWithRequestInterval:requestInterval URLString:URLString concurrentHost:concurrentHost requestModel:nil params:nil method:method needCommonParams:NO headerField:headerField enableHttpCache:YES verifyRequest:NO isCustomizedCookie:NO constructingBodyWithBlock:nil bodyField:bodyField filePath:filePath offset:uploadFileOffset length:uploadFileLength progress:progress requestSerializer:requestSerializer requestApiType:requestApiType concurrentTaskId:concurrentTaskId transactionId:transactionId modelResponseSerializer:nil useJsonResponseSerializer:NO jsonResponseSerializer:nil binaryResponseSerializer:responseSerializer modelCallback:nil modelCallbackWithResponse:nil headerCallback:nil dataCallback:nil callback:nil callbackWithResponse:callback redirectCallback:nil dispatch_queue:callbackQueue destination:nil isAppend:NO progressCallback:nil completionHandler:nil timeout:timeout redirectHeaderDataCallbackQueue:[(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] serial_callback_dispatch_queue] nsrequest:nil mainDocURL:nil matchRule:matchRule];
}

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
                                          callbackQueue:(dispatch_queue_t)callbackQueue {
    if ([self.class parseIfConcurrentRequestSwitchEnabled:concurrentRequestConfig switchName:kTTNetworkConcurrentRequestEnabled]) {
        if ([self.class isMatchingWithNoRetry:URLString]) {
            return nil;
        }
        
        NSArray *matchRules = [self.class parseConcurrentRequestMatchRules:concurrentRequestConfig];
        if (!matchRules) {
            return nil;
        }
        //parse if host and path match
        UrlMatchRule *matchRule = [self.class getConcurrentHostAccordingToRules:matchRules withUrl:URLString];
        if (![self.class forbidConcurrentTaskIfNeed:matchRule]) {
            UInt64 concurrentTaskId = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] nextTaskId];
            NSString *transactionId =[[NSUUID UUID] UUIDString];
            
            TTConcurrentHttpTask *concurrentTask = [[TTConcurrentHttpTask alloc] initWithRequestInterval:[self.class parseConcurrentRequestConnectInterval:concurrentRequestConfig preferMatchRule:matchRule]
                                                                                          concurrentHost:matchRule.concurrentHost
                                                                                               URLString:URLString
                                                                                                  method:method
                                                                                             headerField:headerField
                                                                                               bodyField:bodyField
                                                                                                filePath:filePath
                                                                                                  offset:uploadFileOffset
                                                                                                  length:uploadFileLength
                                                                                                progress:progress
                                                                                       requestSerializer:requestSerializer
                                                                                          requestApiType:TTNetworkManagerApiFileUpload
                                                                                        concurrentTaskId:concurrentTaskId
                                                                                           transactionId:transactionId
                                                                                      responseSerializer:responseSerializer
                                                                                                callback:callback
                                                                                           callbackQueue:callbackQueue
                                                                                                 timeout:timeout
                                                                                               matchRule:matchRule];
            
            if (autoResume) {
                [concurrentTask resume];
            }
            
            [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] addTaskWithId_:concurrentTaskId task:concurrentTask];
            return concurrentTask;
        }
    }
    return nil;
}

#pragma mark - Download
- (instancetype)initWithRequestInterval:(NSTimeInterval)requestInterval
                         concurrentHost:(NSArray <NSString *> *)concurrentHost
                              URLString:(NSString *)URLString
                             parameters:(id)parameters
                            headerField:(NSDictionary *)headerField
                       needCommonParams:(BOOL)needCommonParams
                      requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                         requestApiType:(TTNetworkManagerApiType)requestApiType
                       concurrentTaskId:(UInt64)concurrentTaskId
                          transactionId:(NSString *)transactionId
                               isAppend:(BOOL)isAppend
                       progressCallback:(void (^)(int64_t current, int64_t total))progressCallback
                               progress:(NSProgress * __autoreleasing *)progress
                            destination:(NSURL *)destination
                      completionHandler:(void (^)(TTHttpResponse *response, NSURL *filePath, NSError *error))completionHandler
                              matchRule:(UrlMatchRule *)matchRule {
    return [self initWithRequestInterval:requestInterval URLString:URLString concurrentHost:concurrentHost requestModel:nil params:parameters method:nil needCommonParams:needCommonParams headerField:headerField enableHttpCache:YES verifyRequest:NO isCustomizedCookie:NO constructingBodyWithBlock:nil bodyField:nil filePath:nil offset:0 length:0 progress:progress requestSerializer:requestSerializer requestApiType:requestApiType concurrentTaskId:concurrentTaskId transactionId:transactionId modelResponseSerializer:nil useJsonResponseSerializer:NO jsonResponseSerializer:nil binaryResponseSerializer:nil modelCallback:nil modelCallbackWithResponse:nil headerCallback:nil dataCallback:nil callback:nil callbackWithResponse:nil redirectCallback:nil dispatch_queue:nil destination:destination isAppend:isAppend progressCallback:progressCallback completionHandler:completionHandler timeout:-1 redirectHeaderDataCallbackQueue:[(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] serial_callback_dispatch_queue] nsrequest:nil mainDocURL:nil matchRule:matchRule];
}

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
                              concurrentRequestConfig:(NSDictionary *)concurrentRequestConfig {
    if ([self.class parseIfConcurrentRequestSwitchEnabled:concurrentRequestConfig switchName:kTTNetworkConcurrentRequestEnabled]) {
        if ([self.class isMatchingWithNoRetry:URLString]) {
            return nil;
        }
        
        NSArray *matchRules = [self.class parseConcurrentRequestMatchRules:concurrentRequestConfig];
        if (!matchRules) {
            return nil;
        }
        //parse if host and path match
        UrlMatchRule *matchRule = [self.class getConcurrentHostAccordingToRules:matchRules withUrl:URLString];
        if (![self.class forbidConcurrentTaskIfNeed:matchRule]) {
            UInt64 concurrentTaskId = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] nextTaskId];
            NSString *transactionId =[[NSUUID UUID] UUIDString];
            
            TTConcurrentHttpTask *concurrentTask = [[TTConcurrentHttpTask alloc] initWithRequestInterval:[self.class parseConcurrentRequestConnectInterval:concurrentRequestConfig preferMatchRule:matchRule]
                                                                                          concurrentHost:matchRule.concurrentHost
                                                                                               URLString:URLString
                                                                                              parameters:parameters
                                                                                             headerField:headerField
                                                                                        needCommonParams:needCommonParams
                                                                                       requestSerializer:requestSerializer
                                                                                          requestApiType:TTNetworkManagerApiDownload
                                                                                        concurrentTaskId:concurrentTaskId
                                                                                           transactionId:transactionId
                                                                                                isAppend:isAppend
                                                                                        progressCallback:progressCallback
                                                                                                progress:progress
                                                                                             destination:destination
                                                                                       completionHandler:completionHandler
                                                                                               matchRule:matchRule];
               
            if (autoResume) {
                [concurrentTask resume];
            }
               
            [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] addTaskWithId_:concurrentTaskId task:concurrentTask];
            return concurrentTask;
        }
    }
    return nil;
}

#endif /* FULL_API_CONCURRENT_REQUEST */



#pragma mark - JSON
- (instancetype)initWithRequestInterval:(NSTimeInterval)requestInterval
                         concurrentHost:(NSArray <NSString *> *)concurrentHost
                              URLString:(NSString *)URLString
                                 params:(id)params
                                 method:(NSString *)method
                       needCommonParams:(BOOL)needCommonParams
                            headerField:(NSDictionary *)headerField
                      requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                         requestApiType:(TTNetworkManagerApiType)requestApiType
                       concurrentTaskId:(UInt64)concurrentTaskId
                          transactionId:(NSString *)transactionId
                     responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                          verifyRequest:(BOOL)verifyRequest
                     isCustomizedCookie:(BOOL)isCustomizedCookie
                               callback:(TTNetworkJSONFinishBlock)callback
                   callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                         dispatch_queue:(dispatch_queue_t)dispatch_queue
                              matchRule:(UrlMatchRule *)matchRule {
    return [self initWithRequestInterval:requestInterval URLString:URLString concurrentHost:concurrentHost requestModel:nil params:params method:method needCommonParams:needCommonParams headerField:headerField enableHttpCache:YES verifyRequest:verifyRequest isCustomizedCookie:isCustomizedCookie constructingBodyWithBlock:nil bodyField:nil filePath:nil offset:0 length:0 progress:nil requestSerializer:requestSerializer requestApiType:requestApiType concurrentTaskId:concurrentTaskId transactionId:transactionId modelResponseSerializer:nil useJsonResponseSerializer:NO jsonResponseSerializer:responseSerializer binaryResponseSerializer:nil modelCallback:nil modelCallbackWithResponse:nil headerCallback:nil dataCallback:nil callback:callback callbackWithResponse:callbackWithResponse redirectCallback:nil dispatch_queue:dispatch_queue destination:nil isAppend:NO progressCallback:nil completionHandler:nil timeout:-1 redirectHeaderDataCallbackQueue:[(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] serial_callback_dispatch_queue] nsrequest:nil mainDocURL:nil matchRule:matchRule];
}

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
                          concurrentRequestConfig:(NSDictionary *)concurrentRequestConfig {
    if ([self.class parseIfConcurrentRequestSwitchEnabled:concurrentRequestConfig switchName:kTTNetworkConcurrentRequestEnabled]) {
        if ([self.class isMatchingWithNoRetry:URLString]) {
            return nil;
        }
        
        NSArray *matchRules = [self.class parseConcurrentRequestMatchRules:concurrentRequestConfig];
        if (!matchRules) {
            return nil;
        }
        //parse if host and path match
        UrlMatchRule *matchRule = [self.class getConcurrentHostAccordingToRules:matchRules withUrl:URLString];
        if (![self.class forbidConcurrentTaskIfNeed:matchRule]) {
            UInt64 concurrentTaskId = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] nextTaskId];
            NSString *transactionId =[[NSUUID UUID] UUIDString];
            
            TTConcurrentHttpTask *concurrentTask = [[TTConcurrentHttpTask alloc] initWithRequestInterval:[self.class parseConcurrentRequestConnectInterval:concurrentRequestConfig preferMatchRule:matchRule]
                                                                                          concurrentHost:matchRule.concurrentHost
                                                                                               URLString:URLString
                                                                                                  params:params
                                                                                                  method:method
                                                                                        needCommonParams:needCommonParams
                                                                                             headerField:headerField
                                                                                       requestSerializer:requestSerializer
                                                                                          requestApiType:TTNetworkManagerApiJSON
                                                                                        concurrentTaskId:concurrentTaskId
                                                                                           transactionId:transactionId
                                                                                      responseSerializer:responseSerializer
                                                                                           verifyRequest:verifyRequest
                                                                                      isCustomizedCookie:isCustomizedCookie
                                                                                                callback:callback
                                                                                    callbackWithResponse:callbackWithResponse
                                                                                          dispatch_queue:dispatch_queue
                                                                                               matchRule:matchRule];
            
            if (autoResume) {
                [concurrentTask resume];
            }
            
            [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] addTaskWithId_:concurrentTaskId task:concurrentTask];
            return concurrentTask;
        }
    }
    return nil;
}

#pragma mark - Binary
- (instancetype)initWithRequestInterval:(NSTimeInterval)requestInterval
                         concurrentHost:(NSArray <NSString *> *)concurrentHost
                              URLString:(NSString *)URLString
                                 params:(id)params
                                 method:(NSString *)method
                       needCommonParams:(BOOL)needCommonParams
                            headerField:(NSDictionary *)headerField
                        enableHttpCache:(BOOL)enableHttpCache
                      requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                         requestApiType:(TTNetworkManagerApiType)requestApiType
                       concurrentTaskId:(UInt64)concurrentTaskId
                          transactionId:(NSString *)transactionId
                     responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                     isCustomizedCookie:(BOOL)isCustomizedCookie
                         headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
                           dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
                               callback:(TTNetworkObjectFinishBlock)callback
                   callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                       redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback
                               progress:(NSProgress * __autoreleasing *)progress
                         dispatch_queue:(dispatch_queue_t)callback_queue
        redirectHeaderDataCallbackQueue:(dispatch_queue_t)chunk_dispatch_queue
                              matchRule:(UrlMatchRule *)matchRule {
    return [self initWithRequestInterval:requestInterval URLString:URLString concurrentHost:concurrentHost requestModel:nil params:params method:method needCommonParams:needCommonParams headerField:headerField enableHttpCache:enableHttpCache verifyRequest:NO isCustomizedCookie:isCustomizedCookie constructingBodyWithBlock:nil bodyField:nil filePath:nil offset:0 length:0 progress:progress requestSerializer:requestSerializer requestApiType:requestApiType concurrentTaskId:concurrentTaskId transactionId:transactionId modelResponseSerializer:nil useJsonResponseSerializer:NO jsonResponseSerializer:nil binaryResponseSerializer:responseSerializer modelCallback:nil modelCallbackWithResponse:nil headerCallback:headerCallback dataCallback:dataCallback callback:callback callbackWithResponse:callbackWithResponse redirectCallback:redirectCallback dispatch_queue:callback_queue destination:nil isAppend:NO progressCallback:nil completionHandler:nil timeout:-1 redirectHeaderDataCallbackQueue:chunk_dispatch_queue nsrequest:nil mainDocURL:nil matchRule:matchRule];
}

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
                            concurrentRequestConfig:(NSDictionary *)concurrentRequestConfig {
    if ([self.class parseIfConcurrentRequestSwitchEnabled:concurrentRequestConfig switchName:kTTNetworkConcurrentRequestEnabled]) {
        if ([self.class isMatchingWithNoRetry:URLString]) {
            return nil;
        }
        
        NSArray *matchRules = [self.class parseConcurrentRequestMatchRules:concurrentRequestConfig];
        if (!matchRules) {
            return nil;
        }
        //parse if host and path match
        UrlMatchRule *matchRule = [self.class getConcurrentHostAccordingToRules:matchRules withUrl:URLString];
        if (![self.class forbidConcurrentTaskIfNeed:matchRule]) {
            UInt64 concurrentTaskId = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] nextTaskId];
            NSString *transactionId =[[NSUUID UUID] UUIDString];
            
            TTConcurrentHttpTask *concurrentTask = [[TTConcurrentHttpTask alloc] initWithRequestInterval:[self.class parseConcurrentRequestConnectInterval:concurrentRequestConfig preferMatchRule:matchRule]
                                                                                          concurrentHost:matchRule.concurrentHost
                                                                                               URLString:URLString
                                                                                                  params:params
                                                                                                  method:method needCommonParams:needCommonParams
                                                                                             headerField:headerField
                                                                                         enableHttpCache:enableHttpCache
                                                                                       requestSerializer:requestSerializer
                                                                                          requestApiType:TTNetworkManagerApiBinary
                                                                                        concurrentTaskId:concurrentTaskId
                                                                                           transactionId:transactionId
                                                                                      responseSerializer:responseSerializer
                                                                                      isCustomizedCookie:isCustomizedCookie
                                                                                          headerCallback:headerCallback
                                                                                            dataCallback:dataCallback
                                                                                                callback:callback
                                                                                    callbackWithResponse:callbackWithResponse
                                                                                        redirectCallback:redirectCallback
                                                                                                progress:progress
                                                                                          dispatch_queue:callback_queue
                                                                         redirectHeaderDataCallbackQueue:chunk_dispatch_queue
                                                                                               matchRule:matchRule];
            
            if (autoResume) {
                [concurrentTask resume];
            }
            
            [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] addTaskWithId_:concurrentTaskId task:concurrentTask];
            return concurrentTask;
        }
    }
    return nil;
}

#pragma mark - webview
- (instancetype)initWithRequestInterval:(NSTimeInterval)requestInterval
                         concurrentHost:(NSArray <NSString *> *)concurrentHost
                         requestApiType:(TTNetworkManagerApiType)requestApiType
                       concurrentTaskId:(UInt64)concurrentTaskId
                          transactionId:(NSString *)transactionId
                              nsrequest:(NSURLRequest *)nsRequest
                             mainDocURL:(NSString *)mainDocURL
                        enableHttpCache:(BOOL)enableHttpCache
                       redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback
                         headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
                           dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
                   callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                              matchRule:(UrlMatchRule *)matchRule {
    return [self initWithRequestInterval:requestInterval URLString:nsRequest.URL.absoluteString concurrentHost:concurrentHost requestModel:nil params:nil method:nil needCommonParams:NO headerField:nil enableHttpCache:enableHttpCache verifyRequest:NO isCustomizedCookie:NO constructingBodyWithBlock:nil bodyField:nil filePath:nil offset:0 length:0 progress:nil requestSerializer:nil requestApiType:requestApiType concurrentTaskId:concurrentTaskId transactionId:transactionId modelResponseSerializer:nil useJsonResponseSerializer:NO jsonResponseSerializer:nil binaryResponseSerializer:nil modelCallback:nil modelCallbackWithResponse:nil headerCallback:headerCallback dataCallback:dataCallback callback:nil callbackWithResponse:callbackWithResponse redirectCallback:redirectCallback dispatch_queue:[(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] serial_callback_dispatch_queue] destination:nil isAppend:NO progressCallback:nil completionHandler:nil timeout:-1 redirectHeaderDataCallbackQueue:[(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] serial_callback_dispatch_queue] nsrequest:nsRequest mainDocURL:mainDocURL matchRule:matchRule];
}

+ (TTConcurrentHttpTask *)buildWebviewConcurrentTask:(NSURLRequest *)nsRequest
                                          mainDocURL:(NSString *)mainDocURL
                                          autoResume:(BOOL)autoResume
                                     enableHttpCache:(BOOL)enableHttpCache
                                    redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback
                                      headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
                                        dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
                                callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                             concurrentRequestConfig:(NSDictionary *)concurrentRequestConfig {
    if ([self.class parseIfConcurrentRequestSwitchEnabled:concurrentRequestConfig switchName:kTTNetworkConcurrentRequestEnabled]) {
        if ([self.class isMatchingWithNoRetry:nsRequest.URL.absoluteString]) {
            return nil;
        }
        
        NSArray *matchRules = [self.class parseConcurrentRequestMatchRules:concurrentRequestConfig];
        if (!matchRules) {
            return nil;
        }
        //parse if host and path match
        UrlMatchRule *matchRule = [self.class getConcurrentHostAccordingToRules:matchRules withUrl:nsRequest.URL.absoluteString];
        if (![self.class forbidConcurrentTaskIfNeed:matchRule]) {
            UInt64 concurrentTaskId = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] nextTaskId];
            NSString *transactionId =[[NSUUID UUID] UUIDString];
            
            TTConcurrentHttpTask *concurrentTask = [[TTConcurrentHttpTask alloc] initWithRequestInterval:[self.class parseConcurrentRequestConnectInterval:concurrentRequestConfig preferMatchRule:matchRule]
                                                                                          concurrentHost:matchRule.concurrentHost
                                                                                          requestApiType:TTNetworkManagerApiWebview
                                                                                        concurrentTaskId:concurrentTaskId
                                                                                           transactionId:transactionId
                                                                                               nsrequest:nsRequest
                                                                                              mainDocURL:mainDocURL
                                                                                         enableHttpCache:enableHttpCache
                                                                                        redirectCallback:redirectCallback
                                                                                          headerCallback:headerCallback
                                                                                            dataCallback:dataCallback
                                                                                    callbackWithResponse:callbackWithResponse
                                                                                               matchRule:matchRule];
            
            if (autoResume) {
                [concurrentTask resume];
            }
            
            [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] addTaskWithId_:concurrentTaskId task:concurrentTask];
            return concurrentTask;
        }
    }
    return nil;
}

- (instancetype)initWithRequestInterval:(NSTimeInterval)requestInterval
                              URLString:(NSString *)URLString
                         concurrentHost:(NSArray <NSString *> *)concurrentHost
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
                         requestApiType:(TTNetworkManagerApiType)requestApiType
                       concurrentTaskId:(UInt64)concurrentTaskId
                          transactionId:(NSString *)transactionId
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
                             mainDocURL:(NSString *)mainDocURL
                              matchRule:(UrlMatchRule *)matchRule {
    if (self = [super init]) {
        self.outerApiParams = [[TTNetworkManagerApiParameters alloc] initWithURLString:URLString
                                                                           requestModel:model
                                                                                 params:params
                                                                                 method:method
                                                                       needCommonParams:needCommonParams
                                                                            headerField:headerField
                                                                        enableHttpCache:enableHttpCache
                                                                          verifyRequest:verifyRequest
                                                                     isCustomizedCookie:isCustomizedCookie
                                                              constructingBodyWithBlock:bodyBlock
                                                                              bodyField:bodyField
                                                                               filePath:filePath
                                                                                 offset:uploadFileOffset
                                                                                 length:uploadFileLength
                                                                               progress:progress
                                                                      requestSerializer:requestSerializer
                                                                modelResponseSerializer:modelResponseSerializer
                                                             useJsonResponseSerializer:useJsonResponseSerializer
                                                                 jsonResponseSerializer:jsonResponseSerializer
                                                               binaryResponseSerializer:binaryResponseSerializer
                                                                          modelCallback:modelCallback
                                                             modelCallbackWithResponse:modelCallbackWithResponse
                                                                         headerCallback:headerCallback
                                                                           dataCallback:dataCallback
                                                                               callback:callback
                                                                   callbackWithResponse:callbackWithResponse
                                                                       redirectCallback:redirectCallback
                                                                         dispatch_queue:dispatch_queue
                                                                            destination:destination
                                                                               isAppend:isAppend
                                                                       progressCallback:progressCallback
                                                                      completionHandler:completionHandler
                                                                                timeout:timeout
                                                        redirectHeaderDataCallbackQueue:chunk_dispatch_queue
                                                                              nsrequest:nsRequest
                                                                             mainDocURL:mainDocURL];
        
        self.requestApiType = requestApiType;
        self.connectTimeInterval = requestInterval;
        self.concurrentHost = [NSMutableArray arrayWithArray:concurrentHost];
        self.concurrentTaskId = concurrentTaskId;
        self.transactionId = transactionId;
        self.subTaskSequenceDict = [NSMutableDictionary dictionary];
        self.callbackInfoDict = [NSMutableDictionary dictionary];
        
        self.timeoutInterval = g_request_timeout;
        self.enableHttpCache = enableHttpCache;
        self.matchRule = matchRule;
        self.tasksInfo = [[NSMutableArray alloc] init];
        self.loadFlags = 0;
        isTaskResumed = false;
        self.sentHostSet = [NSMutableSet set];
        isTaskResumed = false;
    }
    return self;
}


//override
- (void)cancel {
    @synchronized (self) {
        if ([self state] != TTHttpTaskStateCompleted) {
            [self asyncStopTimer];
            for (NSString *key in self.subTaskSequenceDict) {
                TTHttpTaskChromium *task = self.subTaskSequenceDict[key];
                [task cancel];
            }
        }
        self.isCancelled = YES;
    }
}

- (BOOL)isCancelledByUser {
    @synchronized (self) {
        return self.isCancelled;
    }
}

- (TTHttpTask *)getOneSubtask {
    TTHttpTask *task = nil;
    switch (self.requestApiType) {
        case TTNetworkManagerApiJSON:
            task = [self generateJSONTask];
            break;
            
        case TTNetworkManagerApiBinary:
            task = [self generateBinaryTask];
            break;
            
        case TTNetworkManagerApiWebview:
            task = [self generateWebviewTask];
            break;
#ifdef FULL_API_CONCURRENT_REQUEST
        case TTNetworkManagerApiModel:
            task = [self generateModelTask];
            break;
           
        case TTNetworkManagerApiMemoryUpload:
            task = [self generateMemoryUploadTask];
            break;
            
        case TTNetworkManagerApiFileUpload:
            task = [self generateFileUploadTask];
            break;
        
        case TTNetworkManagerApiDownload:
            task = [self generateDownloadTask];
            break;
#endif /* FULL_API_CONCURRENT_REQUEST */
            
        default:
            NSAssert(false, @"unsupport requestApiType");
            break;
    }
    if (task && self.matchRule.rsName && self.subTaskSeqNumber > 1) {
        [task.request setValue:@"1" forHTTPHeaderField:kRequestHeadersBypassRouteSelection];
    }
    return task;
}

//override
- (void)resume {
    // If the task has resumed, it returns directly.
    if (isTaskResumed) {
        LOGE(@"Currently reuse of previous concurrent task is not supported.");
        return;
    }
    
    // The first resume is expected to be the original state.
    bool expectValue = false;
    // If it is the first time to resume, it is set to resume.
    bool setValue = true;
    if (!isTaskResumed.compare_exchange_strong(expectValue, setValue)) {
        LOGE(@"Currently reuse of previous concurrent is not supported-Multi.");
        return;
    }
    
    TTHttpTask *firstSubTask = [self getOneSubtask];
    if (firstSubTask) {
        self.startTime = [[NSDate date] timeIntervalSince1970]; //concurrent request start time
        [self generateSubtaskStartInfo:firstSubTask startTimeInterval:self.startTime];
        LOGD(@"----concurrent subtask resume: %@", firstSubTask.request.URL.absoluteString);
        [firstSubTask resume];
    }
    
    [self asyncStartTimer];
}

- (void)generateSubtaskStartInfo:(TTHttpTask *)subtask startTimeInterval:(NSTimeInterval)startTimeInterval {
    TaskDetailInfo *subtaskInfo = [[TaskDetailInfo alloc] init];
    subtaskInfo.host = subtask.request.URL.host;
    subtaskInfo.start = startTimeInterval;
    if (self.matchRule.rsName) {
        subtaskInfo.host = subtask.originalHost;
        subtaskInfo.dispatchedHost = subtask.dispatchedHost;
        subtaskInfo.dispatchTime = subtask.dispatchTime;
        subtaskInfo.sentAlready = subtask.sentAlready;
    }
    [self.tasksInfo addObject:subtaskInfo];
}

- (void)runOnceInTimer {
    @synchronized (self) {
        TTHttpTask *subTask = [self getOneSubtask];
        if (subTask) {
            [self generateSubtaskStartInfo:subTask startTimeInterval:[[NSDate date] timeIntervalSince1970]];
            LOGD(@"----subtask in timer resume:%@", subTask.request.URL.absoluteString);
            [subTask resume];
        }
    }
}

- (void)startTimerInternalInMainThread {
    __weak typeof(self) weakSelf = self;
    NSTimeInterval timeout = self.connectTimeInterval;
    self.timer = [NSTimer ttnet_scheduledTimerWithTimeInterval:timeout block:^{
        [weakSelf runOnceInTimer];
    } repeats:YES];
}

- (void)asyncStartTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self startTimerInternalInMainThread];
    });
}

- (void)syncStartTimer {
    [self performSelectorOnMainThread:@selector(startTimerInternalInMainThread) withObject:nil waitUntilDone:YES];
}

- (void)stopTimerInternalInMainThread {
    if ([self.timer isValid]) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)asyncStopTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopTimerInternalInMainThread];
    });
}

- (void)syncStopTimer {
    [self performSelectorOnMainThread:@selector(stopTimerInternalInMainThread) withObject:nil waitUntilDone:YES];
}

- (void)restartTimer {
    [self asyncStopTimer];

    [self asyncStartTimer];
}

- (void)addWrapperHeaderCallbackForTask:(TTHttpTaskChromium *)task taskNumber:(NSUInteger)subtaskNumber {
    @synchronized (self) {
        [self.subTaskSequenceDict setValue:task forKey:[NSString stringWithFormat:@"%@", @(subtaskNumber)]];
    }

    if (task) {
        __weak typeof(self) weakSelf = self;
        __weak typeof(task) weakTask = task;
        //determine winner task in headerCallback
        //headerBlock execute on TTNetworkManager's serial dispatch queue
        task.headerBlock = ^(TTHttpResponseChromium *response) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            __strong typeof(weakTask) strongTask = weakTask;
            [strongSelf handleWrapperHeaderCallback:strongTask withResponse:response];
        };
         
        [task.request setValue:self.transactionId forHTTPHeaderField:kRequestHeadersTransactionId];
        [task.request setValue:[NSString stringWithFormat:@"%@", @(subtaskNumber)] forHTTPHeaderField:kRequestHeadersSequenceNumber];
        if (self.matchRule.isBypassRouteSelection && !self.matchRule.rsName) {
            [task.request setValue:@"1" forHTTPHeaderField:kRequestHeadersBypassRouteSelection];
        }
    }
}

//execute on TTNetworkManager's serial dispatch queue (self.dispatch_queue = dispatch_queue_create("ttnet_dispatch_queue", DISPATCH_QUEUE_SERIAL);)
- (void)handleWrapperHeaderCallback:(TTHttpTaskChromium *)task withResponse:(TTHttpResponseChromium *)response {
    bool isApiSource5xx = false;
    if ([response.allHeaderFields[kResponseHeaderApiSource5xx] isEqualToString:@"1"]) {
        isApiSource5xx = true;
    }
    NSInteger httpCode = response.statusCode;
    BOOL isHttpCodeBlocked = NO;
    if ([self.matchRule.blockErrorCodeSet containsObject:[NSNumber numberWithInteger:httpCode]]) {
        isHttpCodeBlocked = YES;
        LOGD(@"block retry due to http code");
    }
    if ((httpCode >= 200 && httpCode < 300) || [self isTreatingNon2xxResponseAsSuccess] || isApiSource5xx || isHttpCodeBlocked) {
        [self markWinnerAndCancelTasksInternal:task];
        [self callbackHeaderToUser:task withResponse:response];
    }
}

//execute on TTNetworkManager's serial dispatch queue or Chrome I/O thread(if have redirect block)
//do NOT need lock here since it is serial
- (void)markWinnerAndCancelTasksInternal:(TTHttpTaskChromium *)subtask {
    @synchronized (self) {
        if (!self.winnerTask) {
            self.winnerTask = subtask;
            LOGD(@"----winner task url:%@", subtask.request.urlString);
            [self asyncStopTimer];
            
            if (self.throttleSpeed > 0) {
                [self.winnerTask setThrottleNetSpeed:self.throttleSpeed];
            }
            
            int winnerTaskIndex = 0;
            for (NSString *key in self.subTaskSequenceDict) {
                TTHttpTaskChromium *task = self.subTaskSequenceDict[key];
                if ((task != subtask)) {
                    [task cancel];
                    //generate detail log info for non-winner subtask
                    //key is "1", "2", "3"...
                    NSInteger index = [key integerValue] -  1;
                    TaskDetailInfo *subtaskInfo = [self.tasksInfo objectAtIndex:index];
                    subtaskInfo.end = [[NSDate date] timeIntervalSince1970];
                    subtaskInfo.netError = -999; //indicate cancel
                    subtaskInfo.httpCode = -1; //same with default value in cronet
                } else {
                    winnerTaskIndex = [key intValue];
                }
            }
            
            // Use concurrent reqeust result to refine route selection result, when not-the-first domain name succeeded.
            if (winnerTaskIndex > 1) {
                cronet::CronetEnvironment* engine =
                    (cronet::CronetEnvironment*)[(TTNetworkManagerChromium*)[TTNetworkManager shareInstance] getEngine];
                if (engine && [self.matchRule.rsName length] > 0) {
                    engine->SetRouteSelectionBestHost([subtask.request.URL.host UTF8String], [self.matchRule.rsName UTF8String]);
                }
            }
        }
    }
}

//if one subtask's error code matches with blockErrorCodeSet, we won't try other subtasks
//execute on TTNetworkManager's serial dispatch queue
- (void)markWinnerAndCancelOtherTasks:(NSUInteger)currentTaskNumber accordingToError:(NSError *)error {
    if (error) {
        NSInteger errorCode = error.code;
        LOGD(@"----error code in response:%ld, url:%@", errorCode, [self.subTaskSequenceDict objectForKey:[NSString stringWithFormat:@"%@", @(currentTaskNumber)]].request.URL.absoluteString);
        if (!self.winnerTask && [self.matchRule.blockErrorCodeSet containsObject:[NSNumber numberWithInteger:errorCode]]) {
            LOGD(@"----errorCode: %ld matches blockErrorCodeSet, cancel other subtask", errorCode);
            self.isMarkingWinnerWithBlockErrorCodeSet = YES;
            TTHttpTaskChromium *task = [self.subTaskSequenceDict objectForKey:[NSString stringWithFormat:@"%@", @(currentTaskNumber)]];
            LOGD(@"----mark winner according to error:%ld", errorCode);
            [self markWinnerAndCancelTasksInternal:task];
        }
    }
}

//execute on TTNetworkManager's serial dispatch queue
- (void)callbackHeaderToUser:(TTHttpTaskChromium *)task withResponse:(TTHttpResponseChromium *)response {
    if (task == self.winnerTask) {
        TTNetworkChunkedDataHeaderBlock outerHeaderCallback = [[self outerApiParams] headerCallback];
        if (outerHeaderCallback) {
            dispatch_queue_t outerHeaderCallbackQueue = [self outerApiParams].chunk_dispatch_queue;
            if (!outerHeaderCallbackQueue) {
                outerHeaderCallbackQueue = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] serial_callback_dispatch_queue];
            }
            dispatch_async(outerHeaderCallbackQueue, ^{
                outerHeaderCallback(response);
            });
        }
    }
}

- (void)addWrapperRedirectCallbackForTask:(TTHttpTaskChromium *)task {
    //redirectedBlock execute on Chrome I/O thread only
    if (task) {
        __weak typeof(self) weakSelf = self;
        __weak typeof(task) weakTask = task;
        task.redirectedBlock = ^(NSString *new_location, TTHttpResponse *old_repsonse) {
            if (old_repsonse.isInternalRedirect) {
                return;
            }
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            __strong typeof(weakTask) strongTask = weakTask;
            if (!strongSelf || !strongTask) {
                LOGI(@"strongSelf or strongTask is nil");
                return;
            }
            //note that a url may redirect for more than one time
            if (!strongSelf.isRedirectionCallbackedToUser) {
                strongSelf.isRedirectionCallbackedToUser = YES;
                [strongSelf markWinnerAndCancelTasksInternal:strongTask];
            }
                
            if (strongTask == strongSelf.winnerTask) {
                TTNetworkURLRedirectBlock outerRedirectCallback = [[strongSelf outerApiParams] redirectCallback];
                if (outerRedirectCallback) {
                    dispatch_queue_t outerRedirectCallbackQueue = [strongSelf outerApiParams].chunk_dispatch_queue;
                    if (!outerRedirectCallbackQueue) {
                        outerRedirectCallbackQueue = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] serial_callback_dispatch_queue];
                    }
                    if (strongSelf.requestApiType == TTNetworkManagerApiWebview) {
                        //TTNetworkManager's requestForWebview interface callback redirectBlock in main thread
                        outerRedirectCallbackQueue = dispatch_get_main_queue();
                    }
                    dispatch_async(outerRedirectCallbackQueue, ^{
                        outerRedirectCallback(new_location, old_repsonse);
                    });
                }
            }
        };
    }
}

- (void)addWrapperDataCallbackForTask:(TTHttpTaskChromium *)task {
    //dataBlock execute on TTNetworkManager's serial dispatch queue
    if (task) {
    __weak typeof(self) weakSelf = self;
    __weak typeof(task) weakTask = task;
        task.dataBlock = ^(NSData *data) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            __strong typeof(weakTask) strongTask = weakTask;
            if (strongTask == strongSelf.winnerTask) {
                TTNetworkChunkedDataReadBlock outerDataCallback = [[strongSelf outerApiParams] dataCallback];
                if (outerDataCallback) {
                    dispatch_queue_t outerDataCallbackQueue = [strongSelf outerApiParams].chunk_dispatch_queue;
                    if (!outerDataCallbackQueue) {
                        outerDataCallbackQueue = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] serial_callback_dispatch_queue];
                    }
                    dispatch_async(outerDataCallbackQueue, ^{
                        outerDataCallback(data);
                    });
                }
            }
        };
    }
}

- (BOOL)isTreatingNon2xxResponseAsSuccess {
    return !self.matchRule.isRetryForNot2xxCode;
}

- (BOOL)isTTNetworkTimeout:(NSError *)responseError {
    if (responseError && (responseError.code == NSURLErrorTimedOut || responseError.code == net::ERR_TTNET_REQUEST_TIMED_OUT)) {
        return YES;
    }
    return NO;
}

- (BOOL)isProtectTimeoutReached:(NSError *)error {
    if (error && error.code == net::ERR_TTNET_REQUEST_TIMED_OUT) {
        //protectTimeout reached, finish the concurrent request
        return YES;
    }
    return NO;
}

- (BOOL)isAllResumedSubtaskCompleted {
    @synchronized (self) {
        return self.resumedTaskCount == self.callbackedTaskCount;
    }
}

- (NSString *)generateNewRequestURLAndAddTaskCount {
    @synchronized (self) {
        NSString *host = [self.concurrentHost firstObject];
        [self.concurrentHost removeObjectAtIndex:0];
        NSString *URL = [[self outerApiParams] URLString];
        NSURL *nsurl = [NSURL URLWithString:URL];
        NSString *oldHost = nsurl.host;
        NSString *query = nsurl.query;

        URL = [self addConcurrentAndIsRetryQueryIfNeed:URL originalQuery:query];
        
        //replace old host with concurrent host
        NSString *newURL = [TTNetworkUtil replaceFirstAppearString:URL target:oldHost toString:host];
        ++self.subTaskSeqNumber;
    
        return newURL;
    }
}

- (void)addTimeoutSettingForTaskIfNotTimeout:(TTHttpTaskChromium *)task {
    NSTimeInterval gap = 0;
    if (!self.firstTaskStartTime) {
        //the first task start time
        self.firstTaskStartTime = [NSDate date];
    } else {
        gap = [self.firstTaskStartTime timeIntervalSinceNow];
    }
    
    if (_timeoutInterval > 0) {
        task.timeoutInterval = _timeoutInterval + gap;
    }
    
    if (_protectTimeout > 0) {
        task.protectTimeout = _protectTimeout + gap;
    }
    
    if (_recvHeaderTimeout > 0) {
        task.recvHeaderTimeout = _recvHeaderTimeout + gap;
    }
    
    if (_readDataTimeout > 0) {
        task.readDataTimeout = _readDataTimeout + gap;
    }
}

- (void)addOtherSettingsForTask:(TTHttpTaskChromium *)task {
    task.skipSSLCertificateError = _skipSSLCertificateError;
    task.enableHttpCache = _enableHttpCache;
    task.taskPriority = self.taskPriority;
    task.loadFlags = self.loadFlags;
}

- (void)addHeaderCallbackAndTimeoutSettings:(TTHttpTaskChromium *)task subtaskNumber:(NSUInteger)subtaskNumber {
    if (task) {
        [self addTimeoutSettingForTaskIfNotTimeout:task];
        [self addOtherSettingsForTask:task];
    
        [self addWrapperHeaderCallbackForTask:task taskNumber:subtaskNumber];
    }
}

#ifdef FULL_API_CONCURRENT_REQUEST
- (void)callbackModelResultToUser:(NSError *)error withModelObject:(NSObject<TTResponseModelProtocol> *)responseModel modelResponse:(TTHttpResponse *)response {
    if ([self outerApiParams].modelCallback) {
        dispatch_async([[self outerApiParams] dispatch_queue], ^{
            [self outerApiParams].modelCallback(error, responseModel);
        });
    } else if ([self outerApiParams].modelCallbackWithResponse) {
        dispatch_async([[self outerApiParams] dispatch_queue], ^{
            [self outerApiParams].modelCallbackWithResponse(error, responseModel, response);
        });
    }
}

- (void)callbackDownloadResultToUser:(NSError *)error response:(TTHttpResponse *)response filePath:(NSURL *)filePath {
    if ([self outerApiParams].completionHandler) {
        [self outerApiParams].completionHandler(response, filePath, error);
    }
}
#endif /* FULL_API_CONCURRENT_REQUEST */

//execute on TTNetworkManager's serial dispatch queue
- (void)callbackCommonResultToUser:(NSError *)error obj:(id)obj response:(TTHttpResponse *)response {
    if ([self outerApiParams].callback) {
        dispatch_async([[self outerApiParams] dispatch_queue], ^{
            [self outerApiParams].callback(error, obj);
        });
    }
    
    if ([self outerApiParams].callbackWithResponse) {
        dispatch_async([[self outerApiParams] dispatch_queue], ^{
            [self outerApiParams].callbackWithResponse(error, obj, response);
        });
    }
}

#ifdef FULL_API_CONCURRENT_REQUEST
#pragma mark - Model request
- (TTHttpTask *)generateModelTask {
    TTHttpTaskChromium *modelTask = nil;
    @synchronized (self) {
        if ([self.concurrentHost count] > 0) {
            NSString *host = [self.concurrentHost firstObject];
            [self.concurrentHost removeObjectAtIndex:0];
        
            TTRequestModel *model = [[self outerApiParams] model];
            NSString *URL = [model _requestURL].absoluteString;
            NSURL *nsurl = [NSURL URLWithString:URL];
            NSString *oldHost = nsurl.host;
            NSString *query = nsurl.query;

            URL = [self addConcurrentAndIsRetryQueryIfNeed:URL originalQuery:query];
                    
            //replace old host with concurrent host
            NSString *newURL = [TTNetworkUtil replaceFirstAppearString:URL target:oldHost toString:host];
            model._fullNewURL = newURL;
        
            ++self.subTaskSeqNumber;
            NSUInteger subtaskNumber = self.subTaskSeqNumber;
            ++self.resumedTaskCount;
            
            dispatch_queue_t wrapperSerialDispatchQueue = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] dispatch_queue];
            __weak typeof(self) wself = self;
            
            TTNetworkModelFinishBlockWithResponse modelCallbackWithResponse = ^(NSError *error, NSObject<TTResponseModelProtocol> *responseModel, TTHttpResponse *response) {
                __strong typeof(wself) sself = wself;
                [sself handleModelCallbackWithError:error
                                        modelObject:responseModel
                                      modelResponse:response
                                      taskSeqNumber:subtaskNumber];
            };
            
            
            modelTask = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] buildModelHttpTask:model
                                                                                       requestSerializer:[[self outerApiParams] requestSerializer]
                                                                                      responseSerializer:[[self outerApiParams] modelResponseSerializer]
                                                                                              autoResume:NO
                                                                                                callback:nil
                                                                                    callbackWithResponse:modelCallbackWithResponse
                                                                                          dispatch_queue:wrapperSerialDispatchQueue];
            
            [self addHeaderCallbackAndTimeoutSettings:modelTask subtaskNumber:subtaskNumber];
        }
    }
    return modelTask;
}

//execute on TTNetworkManager's serial dispatch queue
- (void)handleModelCallbackWithError:(NSError *)error
                         modelObject:(NSObject<TTResponseModelProtocol> *)responseModel
                       modelResponse:(TTHttpResponse *)response
                       taskSeqNumber:(NSUInteger)taskSeqNumber {
    @synchronized (self) {
        [self markWinnerAndCancelOtherTasks:taskSeqNumber accordingToError:error];
        TTHttpTaskChromium *originalTask = [self.subTaskSequenceDict objectForKey:[NSString stringWithFormat:@"%@", @(taskSeqNumber)]];
        [self generateSubtaskEndInfo:error withResponse:response taskSeqNumber:taskSeqNumber];
        if (self.winnerTask) {
            if (self.winnerTask == originalTask) {
                self.endTime = [[NSDate date] timeIntervalSince1970]; //concurrent request end time
                response.concurrentRequestLogInfo = [self generateFinalConcurrentRequestLogInfo]; //add concurrent request log info to response
                [self callbackModelResultToUser:error withModelObject:responseModel modelResponse:response];
            } else {
                //shutdown failed subtask's log notification
                //only send winnerTask's log notification
                originalTask.request.shouldReportLog = NO;
            }
        } else {
            //shutdown failed subtask's log notification
            //only send winnerTask's log notification
            originalTask.request.shouldReportLog = NO;
            ModelCallbackInfo *modelCallback = [[ModelCallbackInfo alloc] initWithError:error reponseModel:responseModel];
            if (modelCallback) {
                [self.callbackInfoDict setValue:modelCallback forKey:[NSString stringWithFormat:@"%@", @(taskSeqNumber)]];
            }
            if (![self isTTNetworkTimeout:error] && ![self isCancelledByUser]) {
                //if not timeout nor cancelled, start next task immediately
                TTHttpTask *subTask = [self getOneSubtask];
                if (subTask) {
                    //reset timer
                    [self restartTimer];
                    [self generateSubtaskStartInfo:subTask startTimeInterval:[[NSDate date] timeIntervalSince1970]];
                    [subTask resume];
                }
            }
        }
    
        ++self.callbackedTaskCount;
    
        BOOL finished = [self isAllResumedSubtaskCompleted];
        if (finished) {
            //stop timer
            //callback user block
            //remove concurrent task
            [self asyncStopTimer];
            self.isCompleted = YES;
            
            if (self.winnerTask) {
                [self updateMatchRuleInfo];
            } else {
                //send log notification in last falied subtask
                originalTask.request.shouldReportLog = YES;;
                self.endTime = [[NSDate date] timeIntervalSince1970]; //concurrent request end time
                response.concurrentRequestLogInfo = [self generateFinalConcurrentRequestLogInfo]; //add concurrent request log info to response
                
                if ([self isCancelledByUser]) {
                    //concurrent request is canceled
                    NSDictionary *userInfo = @{kTTNetSubErrorCode : @(NSURLErrorCancelled),
                                               NSLocalizedDescriptionKey : @"the concurrent request was cancelled"};
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
                    [self callbackModelResultToUser:error withModelObject:nil modelResponse:response];
                } else if ([self isProtectTimeoutReached:error]) {
                    //concurrent request is protect timeout
                    NSDictionary *userInfo = @{kTTNetSubErrorCode : @(net::ERR_TTNET_REQUEST_TIMED_OUT),
                                               NSLocalizedDescriptionKey : @"the concurrent request was protect timeout"};
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:net::ERR_TTNET_REQUEST_TIMED_OUT userInfo:userInfo];
                    [self callbackModelResultToUser:error withModelObject:nil modelResponse:response];
                } else {
                    //all subtask failed, callback the first url request info in concurrentHost to user
                    ModelCallbackInfo *firstTaskCallback = [self.callbackInfoDict objectForKey:[NSString stringWithFormat:@"%d", 1]];
                    [self callbackModelResultToUser:firstTaskCallback.error withModelObject:firstTaskCallback.responseModel modelResponse:response];
                }
                
                if (![self isCancelledByUser]) {
                    //add failed concurrent task to ruleSet if small black house config exists
                    UrlMatchRule *targetRule = self.matchRule;
                    if ([self.class isConservativeStrategyEnabled:targetRule]) {
                        [ruleSetLock lock];
                        [self.class updateFailCountAndForbiddenTime:targetRule];
                        [ruleSetLock unlock];
                    }
                }
            }
        
            [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] removeTaskWithId_:self.concurrentTaskId];
        }
    }
}
#endif /* FULL_API_CONCURRENT_REQUEST */

#pragma mark - JSON request
- (TTHttpTask *)generateJSONTask {
    TTHttpTaskChromium *JSONTask = nil;
    @synchronized (self) {
        if ([self.concurrentHost count] > 0) {
            NSString *newURL = [self generateNewRequestURLAndAddTaskCount];
            
            DispatchInfoGroup* dispatchInfo = [[DispatchInfoGroup alloc] init];
            if (![self doDispatchWithUrl:&newURL andDispatchInfo:dispatchInfo]) {
                return nil;
            }
            
            NSUInteger subtaskNumber = self.subTaskSeqNumber;
            ++self.resumedTaskCount;

            dispatch_queue_t wrapperSerialDispatchQueue = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] dispatch_queue];
            __weak typeof(self) wself = self;
            JSONTask = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] buildJSONHttpTask:newURL
                                                                        params:[[self outerApiParams] params]
                                                                        method:[[self outerApiParams] method]
                                                                        needCommonParams:[[self outerApiParams] needCommonParams]
                                                                        headerField:[[self outerApiParams] headerField]
                                                                        requestSerializer:[[self outerApiParams] requestSerializer]
                                                                        responseSerializer:[[self outerApiParams] jsonResponseSerializer]
                                                                        autoResume:NO
                                                                        verifyRequest:[[self outerApiParams] verifyRequest]
                                                                        isCustomizedCookie:[[self outerApiParams] isCustomizedCookie]
                                                                        callback:nil
                                                                        callbackWithResponse:^(NSError *error, id jsonObj, TTHttpResponse *response) {
                __strong typeof(wself) sself = wself;
                [sself handleCallbackWithResponseError:error
                                            withObject:jsonObj
                                          withResponse:response
                                         taskSeqNumber:subtaskNumber];
            }
                                                                        dispatch_queue:wrapperSerialDispatchQueue];
        
            [self addHeaderCallbackAndTimeoutSettings:JSONTask subtaskNumber:subtaskNumber];
            
            if (self.matchRule.rsName) {
                [dispatchInfo setInfo2Task:JSONTask];
            }
        }
    }
    return JSONTask;
}

//execute on TTNetworkManager's serial dispatch queue
- (void)handleCallbackWithResponseError:(NSError *)error withObject:(id)obj withResponse:(TTHttpResponse *)response taskSeqNumber:(NSUInteger)taskSeqNumber {
    @synchronized (self) {
        [self markWinnerAndCancelOtherTasks:taskSeqNumber accordingToError:error];
        TTHttpTaskChromium *originalTask = [self.subTaskSequenceDict objectForKey:[NSString stringWithFormat:@"%@", @(taskSeqNumber)]];
        [self generateSubtaskEndInfo:error withResponse:response taskSeqNumber:taskSeqNumber];
        if (self.winnerTask) {
            if (self.winnerTask == originalTask) {
                self.endTime = [[NSDate date] timeIntervalSince1970]; //concurrent request end time
                response.concurrentRequestLogInfo = [self generateFinalConcurrentRequestLogInfo]; //add concurrent request log info to response
                [self callbackCommonResultToUser:error obj:obj response:response];
            } else {
                //shutdown failed subtask's log notification
                //only send winnerTask's log notification
                originalTask.request.shouldReportLog = NO;
            }
        } else {
            //shutdown failed subtask's log notification
            //only send winnerTask's log notification
            originalTask.request.shouldReportLog = NO;
            CallbackInfo *callback = [[CallbackInfo alloc] initWithError:error obj:obj response:response];
            if (callback) {
                [self.callbackInfoDict setValue:callback forKey:[NSString stringWithFormat:@"%@", @(taskSeqNumber)]];
            }
            
            if (![self isTTNetworkTimeout:error] && ![self isCancelledByUser]) {
                //if not timeout nor cancelled, start next task immediately
                TTHttpTask *subTask = [self getOneSubtask];
                if (subTask) {
                    //reset timer
                    [self restartTimer];
                    LOGD(@"----resume immediately for error code:%ld ,error: %@", error.code, subTask.request.URL.absoluteString);
                    [self generateSubtaskStartInfo:subTask startTimeInterval:[[NSDate date] timeIntervalSince1970]];
                    [subTask resume];
                }
            }
        }
        
        ++self.callbackedTaskCount;
        BOOL finished = [self isAllResumedSubtaskCompleted];
        if (finished) {
            //stop timer
            //callback user block
            //remove concurrent task
            [self asyncStopTimer];
            self.isCompleted = YES;
            
            if (self.winnerTask) {
                [self updateMatchRuleInfo];
            } else {
                //send log notification in last falied subtask
                originalTask.request.shouldReportLog = YES;
                self.endTime = [[NSDate date] timeIntervalSince1970]; //concurrent request end time
                response.concurrentRequestLogInfo = [self generateFinalConcurrentRequestLogInfo]; //add concurrent request log info to response
                
                if ([self isCancelledByUser]) {
                    //concurrent request is canceled
                    NSDictionary *userInfo = @{kTTNetSubErrorCode : @(NSURLErrorCancelled),
                                               NSLocalizedDescriptionKey : @"the concurrent request was cancelled"};
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
                    [self callbackCommonResultToUser:error obj:nil response:nil];
                } else if ([self isProtectTimeoutReached:error]) {
                    //concurrent request is protect timeout
                    NSDictionary *userInfo = @{kTTNetSubErrorCode : @(net::ERR_TTNET_REQUEST_TIMED_OUT),
                                               NSLocalizedDescriptionKey : @"the concurrent request was protect timeout"};
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:net::ERR_TTNET_REQUEST_TIMED_OUT userInfo:userInfo];
                    [self callbackCommonResultToUser:error obj:nil response:nil];
                } else {
                    //all subtask failed, callback the first url request info in concurrentHost to user
                    CallbackInfo *firstTaskCallback = [self.callbackInfoDict objectForKey:[NSString stringWithFormat:@"%d", 1]];
                    [self callbackCommonResultToUser:firstTaskCallback.error obj:firstTaskCallback.obj response:firstTaskCallback.response];
                }
                
                if (![self isCancelledByUser]) {
                    //add failed concurrent task to ruleSet if small black house config exists
                    UrlMatchRule *targetRule = self.matchRule;
                    if ([self.class isConservativeStrategyEnabled:targetRule]) {
                        [ruleSetLock lock];
                        [self.class updateFailCountAndForbiddenTime:targetRule];
                        [ruleSetLock unlock];
                    }
                }
            }
            [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] removeTaskWithId_:self.concurrentTaskId];
        }
    }
}

- (void)generateSubtaskEndInfo:(NSError *)error withResponse:(TTHttpResponse *)response taskSeqNumber:(NSUInteger)taskSeqNumber {
    TaskDetailInfo *subtaskInfo = [self.tasksInfo objectAtIndex:taskSeqNumber -  1];
    subtaskInfo.end = [[NSDate date] timeIntervalSince1970];
    if (error) {
        subtaskInfo.netError = [[error.userInfo objectForKey:kTTNetSubErrorCode] integerValue];
    }
    subtaskInfo.httpCode = response.statusCode;
}

- (NSMutableDictionary *)generateFinalConcurrentRequestLogInfo {
    NSMutableDictionary *concurrentInfo = [[NSMutableDictionary alloc] init];
    [concurrentInfo setValue:@(self.resumedTaskCount - 1) forKey:@"concurrent"];
    [concurrentInfo setValue:@((self.endTime - self.startTime) * 1000) forKey:@"duration"];
    
    NSMutableArray<NSDictionary*>* tasksInfoArray = [NSMutableArray array];
    for (TaskDetailInfo* taskInfo in self.tasksInfo) {
        NSMutableDictionary* taskInfoDict = [@{
            kTTNetworkConcurrentRequestTasksStart:[NSNumber numberWithDouble:(taskInfo.start * 1000)],
            kTTNetworkConcurrentRequestTasksEnd:[NSNumber numberWithDouble:(taskInfo.end * 1000)],
            kTTNetworkConcurrentRequestTasksHost:taskInfo.host,
            kTTNetworkConcurrentRequestTasksHttpCode:[NSNumber numberWithInteger:taskInfo.httpCode],
            kTTNetworkConcurrentRequestTasksNetError:[NSNumber numberWithInteger:taskInfo.netError]
        } mutableCopy];
        if (self.matchRule.rsName) {
            if (!taskInfo.dispatchedHost) {
                taskInfo.dispatchedHost = @"emptyHost";
            }
            [taskInfoDict setObject:taskInfo.dispatchedHost
                             forKey:kTTNetworkConcurrentRequestTasksDispatchHost];
            [taskInfoDict setObject:[NSNumber numberWithDouble:taskInfo.dispatchTime * 1000]
                             forKey:kTTNetworkConcurrentRequestTasksDispatchTime];
            if (taskInfo.sentAlready) {
                [taskInfoDict setObject:[NSNumber numberWithBool:taskInfo.sentAlready]
                                 forKey:kTTNetworkConcurrentRequestTasksAlreadySent];
            }
        }
        [tasksInfoArray addObject:taskInfoDict];
    }
    [concurrentInfo setValue:tasksInfoArray forKey:@"tasks"];
    return concurrentInfo;
}

- (BOOL)doDispatchWithUrl:(NSString**)inputUrl andDispatchInfo:(DispatchInfoGroup*)info {
    if (!self.matchRule.rsName) return YES;
    
    if (self.subTaskSeqNumber > 1) {
        *inputUrl = [TTNetworkUtil webviewURLString:*inputUrl appendCommonParams:@{@"bypass_rs" : @"1"}];
    }
    info.originalHost = [NSURL URLWithString:*inputUrl].host;
    NSTimeInterval dispatchStart = [[NSDate date] timeIntervalSince1970];
    LOGD(@"Concurrent before dispatch %@", info.originalHost);
    TTDispatchResult* res = [[TTNetworkManager shareInstance] ttUrlDispatchWithUrl:*inputUrl];
    if (!res || [res.finalUrl length] <= 0) return YES;
    
    info.dispatchHost = [NSURL URLWithString:res.finalUrl].host;
    if (!info.dispatchHost) return YES;
    
    LOGD(@"Concurrent after dispatch %@", info.dispatchHost);
    info.dispatchTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] - dispatchStart];
    
    if ([self.sentHostSet containsObject:info.dispatchHost]) {
        TaskDetailInfo *subtaskInfo = [[TaskDetailInfo alloc] init];
        subtaskInfo.host = info.originalHost;
        subtaskInfo.start = dispatchStart;
        subtaskInfo.dispatchedHost = info.dispatchHost;
        subtaskInfo.dispatchTime = [info.dispatchTime doubleValue];
        subtaskInfo.sentAlready = YES;
        [self.tasksInfo addObject:subtaskInfo];
        
        TTHttpTask *subTask = [self getOneSubtask];
        if (subTask) {
            [self restartTimer];
            [self generateSubtaskStartInfo:subTask startTimeInterval:[[NSDate date] timeIntervalSince1970]];
            [subTask resume];
        }
        return NO;
    } else {
        [self.sentHostSet addObject:[info.dispatchHost copy]];
    }
    
    return YES;
}

#pragma mark - Binary request
- (TTHttpTask *)generateBinaryTask {
    TTHttpTaskChromium *binaryTask = nil;
    @synchronized (self) {
        if ([self.concurrentHost count] > 0) {
            NSString *newURL = [self generateNewRequestURLAndAddTaskCount];
            
            DispatchInfoGroup* dispatchInfo = [[DispatchInfoGroup alloc] init];
            if (![self doDispatchWithUrl:&newURL andDispatchInfo:dispatchInfo]) {
                return nil;
            }
            
            NSUInteger subtaskNumber = self.subTaskSeqNumber;
            ++self.resumedTaskCount;

            dispatch_queue_t wrapperSerialDispatchQueue = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] dispatch_queue];
            __weak typeof(self) wself = self;
            NSProgress *progress = [[self outerApiParams] progress];
            TTNetworkChunkedDataHeaderBlock headerBlock = [[self outerApiParams] headerCallback];
            TTNetworkChunkedDataReadBlock dataCallback = [[self outerApiParams] dataCallback];
            TTNetworkURLRedirectBlock redirectCallback = [[self outerApiParams] redirectCallback];
            binaryTask = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] buildBinaryHttpTask:newURL
                                                                            params:[[self outerApiParams] params]
                                                                            method:[[self outerApiParams] method]
                                                                            needCommonParams:[[self outerApiParams] needCommonParams]
                                                                            headerField:[[self outerApiParams] headerField]
                                                                            enableHttpCache:[[self outerApiParams] enableHttpCache]
                                                                            requestSerializer:[[self outerApiParams] requestSerializer]
                                                                            responseSerializer:[[self outerApiParams] binaryResponseSerializer]
                                                                            autoResume:NO
                                                                            isCustomizedCookie:[[self outerApiParams] isCustomizedCookie]
                                                                            headerCallback:headerBlock
                                                                            dataCallback:dataCallback
                                                                            callback:nil
                                                                            callbackWithResponse:^(NSError *error, id obj, TTHttpResponse *response) {
                __strong typeof(wself) sself = wself;
                [sself handleCallbackWithResponseError:error
                                            withObject:obj
                                          withResponse:response
                                         taskSeqNumber:subtaskNumber];
            }
                                                                            redirectCallback:redirectCallback
                                                                            progress:&progress
                                                                            dispatch_queue:wrapperSerialDispatchQueue];
    
            [self addHeaderCallbackAndTimeoutSettings:binaryTask subtaskNumber:subtaskNumber];
            
            if (redirectCallback) {
                //some interface have redirectCallback, if so, determine winner task there, otherwise determine in headerBlock
                //note that a task may redirect many times
                [self addWrapperRedirectCallbackForTask:binaryTask];
            }
            
            if (dataCallback) {
                [self addWrapperDataCallbackForTask:binaryTask];
            }
            
            if (self.matchRule.rsName) {
                [dispatchInfo setInfo2Task:binaryTask];
            }
        }
    }
    return binaryTask;
}

#pragma mark - Webview request
- (TTHttpTask *)generateWebviewTask {
    TTHttpTaskChromium *webviewTask = nil;
    @synchronized (self) {
        if ([self.concurrentHost count] > 0) {
            NSString *newURL = [self generateNewRequestURLAndAddTaskCount];
            
            DispatchInfoGroup* dispatchInfo = [[DispatchInfoGroup alloc] init];
            if (![self doDispatchWithUrl:&newURL andDispatchInfo:dispatchInfo]) {
                return nil;
            }
            
            NSUInteger subtaskNumber = self.subTaskSeqNumber;
            ++self.resumedTaskCount;
            
            __weak typeof(self) wself = self;
            
            TTNetworkChunkedDataHeaderBlock headerBlock = [[self outerApiParams] headerCallback];
            TTNetworkChunkedDataReadBlock dataCallback = [[self outerApiParams] dataCallback];
            TTNetworkURLRedirectBlock redirectCallback = [[self outerApiParams] redirectCallback];
            
            NSURLRequest *originalRequest = self.outerApiParams.nsrequest;
            NSMutableURLRequest *mutableRequest = [originalRequest mutableCopy];
            mutableRequest.URL = [NSURL URLWithString:newURL];
            
            webviewTask = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] buildWebviewHttpTask:mutableRequest
                                                                                                  mainDocURL:[[self outerApiParams] mainDocURL]
                                                                                                  autoResume:NO
                                                                                             enableHttpCache:[[self outerApiParams] enableHttpCache]
                                                                                              headerCallback:headerBlock
                                                                                                dataCallback:dataCallback
                                                                                        callbackWithResponse:^(NSError *error, id obj, TTHttpResponse *response) {
                __strong typeof(wself) sself = wself;
                [sself handleCallbackWithResponseError:error
                                            withObject:obj
                                          withResponse:response
                                         taskSeqNumber:subtaskNumber];
            }
                                                                                            redirectCallback:redirectCallback];
            
            [self addHeaderCallbackAndTimeoutSettings:webviewTask subtaskNumber:subtaskNumber];
            
            if (redirectCallback) {
                //some interface have redirectCallback, if so, determine winner task there, otherwise determine in headerBlock
                //note that a task may redirect many times
                [self addWrapperRedirectCallbackForTask:webviewTask];
            }
            
            if (dataCallback) {
                [self addWrapperDataCallbackForTask:webviewTask];
            }
            
            if (self.matchRule.rsName) {
                [dispatchInfo setInfo2Task:webviewTask];
            }
        }
    }
    return webviewTask;
}

#ifdef FULL_API_CONCURRENT_REQUEST
#pragma mark - memory Upload request
- (TTHttpTask *)generateMemoryUploadTask {
    TTHttpTaskChromium *memoryUploadTask = nil;
    @synchronized (self) {
        if ([self.concurrentHost count] > 0) {
            NSString *newURL = [self generateNewRequestURLAndAddTaskCount];
            NSUInteger subtaskNumber = self.subTaskSeqNumber;
            ++self.resumedTaskCount;
        
            __weak typeof(self) wself = self;
            NSProgress *progress = [[self outerApiParams] progress];
            
            memoryUploadTask = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] buildMemoryUploadHttpTask:newURL
                                                                                    parameters:[[self outerApiParams] params]
                                                                                    headerField:[[self outerApiParams] headerField]
                                                                                    constructingBodyWithBlock:[[self outerApiParams] bodyBlock]
                                                                                    progress:&progress
                                                                                    needcommonParams:[[self outerApiParams] needCommonParams]
                                                                                    requestSerializer:[[self outerApiParams] requestSerializer]
                                                                                    useJsonResponseSerializer:[[self outerApiParams]  useJsonResponseSerializer]
                                                                                    jsonResponseSerializer:[[self outerApiParams] jsonResponseSerializer]
                                                                                    binaryResponseSerializer:[[self outerApiParams]  binaryResponseSerializer]
                                                                                    autoResume:NO
                                                                                    callback:nil
                                                                                    callbackWithResponse:^(NSError *error, id obj, TTHttpResponse *response) {
                __strong typeof(wself) sself = wself;
                [sself handleCallbackWithResponseError:error
                                            withObject:obj
                                          withResponse:response
                                         taskSeqNumber:subtaskNumber];
            }
                                                                                    timeout:[[self outerApiParams] timeout]];
        
            [self addHeaderCallbackAndTimeoutSettings:memoryUploadTask subtaskNumber:subtaskNumber];
        }
    }
    return memoryUploadTask;
}


#pragma mark - file Upload request
- (TTHttpTask *)generateFileUploadTask {
    TTHttpTaskChromium *fileUploadTask = nil;
    @synchronized (self) {
        if ([self.concurrentHost count] > 0) {
            NSString *newURL = [self generateNewRequestURLAndAddTaskCount];
            NSUInteger subtaskNumber = self.subTaskSeqNumber;
            ++self.resumedTaskCount;

            NSDate *startTime = [NSDate date];
            dispatch_queue_t wrapperSerialDispatchQueue = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] dispatch_queue];
            __weak typeof(self) wself = self;
            NSProgress *progress = [[self outerApiParams] progress];
        
            fileUploadTask = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] buildFileUploadHttpTask:newURL
                                                                                    method:[[self outerApiParams] method]
                                                                                    headerField:[[self outerApiParams] headerField]
                                                                                    bodyField:[[self outerApiParams] bodyField]
                                                                                    filePath:[[self outerApiParams] filePath]
                                                                                    offset:[[self outerApiParams] uploadFileOffset]
                                                                                    length:[[self outerApiParams] uploadFileLength]
                                                                                    progress:&progress
                                                                                    requestSerializer:[[self outerApiParams] requestSerializer]
                                                                                    responseSerializer:[[self outerApiParams] binaryResponseSerializer]
                                                                                    autoResume:NO
                                                                                    callback:^(NSError *error, id obj, TTHttpResponse *response){
                __strong typeof(wself) sself = wself;
                [sself handleCallbackWithResponseError:error
                                            withObject:obj
                                          withResponse:response
                                         taskSeqNumber:subtaskNumber];
            }
                                                                                    timeout:[[self outerApiParams] timeout]
                                                                                    callbackQueue:wrapperSerialDispatchQueue];
            
            [self addHeaderCallbackAndTimeoutSettings:fileUploadTask subtaskNumber:subtaskNumber];
        }
    }
    return fileUploadTask;
}


#pragma mark - downlaod request
- (TTHttpTask *)generateDownloadTask {
    TTHttpTaskChromium *downloadTask = nil;
    @synchronized (self) {
        if ([self.concurrentHost count] > 0) {
            NSString *newURL = [self generateNewRequestURLAndAddTaskCount];
            NSUInteger subtaskNumber = self.subTaskSeqNumber;
            ++self.resumedTaskCount;
        
            __weak typeof(self) wself = self;
            NSProgress *progress = [[self outerApiParams] progress];
        
            downloadTask = [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] buildDownloadHttpTask:newURL
                                                                            parameters:[[self outerApiParams] params]
                                                                            headerField:[[self outerApiParams] headerField]
                                                                            needCommonParams:[[self outerApiParams] needCommonParams]
                                                                            requestSerializer:[[self outerApiParams] requestSerializer]
                                                                            isAppend:[[self outerApiParams] isAppend]
                                                                            progressCallback:^(int64_t current, int64_t total) {
                __strong typeof(wself) sself = wself;
                if (sself.winnerTask) {
                    TTHttpTaskChromium *originalTask = [sself.subTaskSequenceDict objectForKey:[NSString stringWithFormat:@"%@", @(subtaskNumber)]];
                    if (originalTask == sself.winnerTask && [sself outerApiParams].progressCallback) {
                        [sself outerApiParams].progressCallback(current, total);
                    }
                }
            }
                                                                            progress:&progress
                                                                            destination:[[self outerApiParams] destination]
                                                                            autoResume:NO
                                                                            completionHandler:^(TTHttpResponse *response, NSURL *filePath, NSError *error){
                __strong typeof(wself) sself = wself;
                [sself handleDownloadCallback:error
                                     response:response
                                     filePath:filePath
                                taskSeqNumber:subtaskNumber];
            }];
        
            [self addHeaderCallbackAndTimeoutSettings:downloadTask subtaskNumber:subtaskNumber];
        }
    }
    return downloadTask;
}

- (void)handleDownloadCallback:(NSError *)error response:(TTHttpResponse *)response filePath:(NSURL *)filePath taskSeqNumber:(NSUInteger)taskSeqNumber {
    @synchronized (self) {
        [self markWinnerAndCancelOtherTasks:taskSeqNumber accordingToError:error];
        TTHttpTaskChromium *originalTask = [self.subTaskSequenceDict objectForKey:[NSString stringWithFormat:@"%@", @(taskSeqNumber)]];
        [self generateSubtaskEndInfo:error withResponse:response taskSeqNumber:taskSeqNumber];
        if (self.winnerTask) {
            if (self.winnerTask == originalTask) {
                self.endTime = [[NSDate date] timeIntervalSince1970]; //concurrent request end time
                response.concurrentRequestLogInfo = [self generateFinalConcurrentRequestLogInfo]; //add concurrent request log info to response
                [self callbackDownloadResultToUser:error response:response filePath:filePath];
            } else {
                //shutdown failed subtask's log notification
                //only send winnerTask's log notification
                originalTask.request.shouldReportLog = NO;
            }
        } else {
            //shutdown failed subtask's log notification
            //only send winnerTask's log notification
            originalTask.request.shouldReportLog = NO;
            DownloadCallbackInfo *downloadCallback = [[DownloadCallbackInfo alloc] initWithError:error filePath:filePath response:response];
            if (downloadCallback) {
                [self.callbackInfoDict setValue:downloadCallback forKey:[NSString stringWithFormat:@"%@", @(taskSeqNumber)]];
            }
            
            if (![self isTTNetworkTimeout:error] && ![self isCancelledByUser]) {
                //if not timeout nor cancelled, start next task immediately
                TTHttpTask *subTask = [self getOneSubtask];
                if (subTask) {
                    //reset timer
                    [self restartTimer];
                    [self generateSubtaskStartInfo:subTask startTimeInterval:[[NSDate date] timeIntervalSince1970]];
                    [subTask resume];
                }
            }
        }
        
        ++self.callbackedTaskCount;
        
        BOOL finished = [self isAllResumedSubtaskCompleted];
        if (finished) {
            //stop timer
            //callback user block
            //remove concurrent task
            [self asyncStopTimer];
            self.isCompleted = YES;
            
            if (self.winnerTask) {
                [self updateMatchRuleInfo];
            } else {
                //send log notification in last falied subtask
                originalTask.request.shouldReportLog = YES;
                self.endTime = [[NSDate date] timeIntervalSince1970]; //concurrent request end time
                response.concurrentRequestLogInfo = [self generateFinalConcurrentRequestLogInfo]; //add concurrent request log info to response
                
                if ([self isCancelledByUser]) {
                    //concurrent request is canceled
                    NSDictionary *userInfo = @{kTTNetSubErrorCode : @(NSURLErrorCancelled),
                                               NSLocalizedDescriptionKey : @"the concurrent request was cancelled"};
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
                    [self callbackDownloadResultToUser:error response:nil filePath:nil];
                } else if ([self isProtectTimeoutReached:error]) {
                    //concurrent request is protect timeout
                    NSDictionary *userInfo = @{kTTNetSubErrorCode : @(net::ERR_TTNET_REQUEST_TIMED_OUT),
                                               NSLocalizedDescriptionKey : @"the concurrent request was protect timeout"};
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:net::ERR_TTNET_REQUEST_TIMED_OUT userInfo:userInfo];
                    [self callbackDownloadResultToUser:error response:nil filePath:nil];
                } else {
                    //all subtask failed, callback the first url request info in concurrentHost to user
                    DownloadCallbackInfo *firstTaskCallback = [self.callbackInfoDict objectForKey:[NSString stringWithFormat:@"%d", 1]];
                    [self callbackDownloadResultToUser:firstTaskCallback.error response:firstTaskCallback.response filePath:firstTaskCallback.filePath];
                }
            }
            
            [(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] removeTaskWithId_:self.concurrentTaskId];
        }
    }
}
#endif /* FULL_API_CONCURRENT_REQUEST */

#pragma mark - requestForBinaryWithStreamTask NOT support concurrent

//override
- (TTHttpTaskState)state {
    TTHttpTaskState state = TTHttpTaskStateRunning;
    if (self.isCompleted) {
        state = TTHttpTaskStateCompleted;
    }
    return state;
}

//override
- (void)setRecvHeaderTimeout:(NSTimeInterval)recvHeaderTimeout {
    _recvHeaderTimeout = recvHeaderTimeout;
}

//override
- (void)setReadDataTimeout:(NSTimeInterval)readDataTimeout {
    _readDataTimeout = readDataTimeout;
}

//override
- (void)setProtectTimeout:(NSTimeInterval)protectTimeout {
    _protectTimeout = protectTimeout;
}

//override
- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    _timeoutInterval = timeoutInterval + g_concurrent_request_delta_timeout;
}

//override
- (void)setSkipSSLCertificateError:(BOOL)skipSSLCertificateError {
    _skipSSLCertificateError = skipSSLCertificateError;
}

//override
- (void)setEnableHttpCache:(BOOL)enableHttpCache {
    _enableHttpCache = enableHttpCache;
}

//override
- (void)setIsStreamingTask:(BOOL)isStreamingTask {
    //not support streaming task yet
    _isStreamingTask = NO;
}

//override
- (void)setThrottleNetSpeed:(int64_t)bytesPerSecond {
    self.throttleSpeed = bytesPerSecond;
}

//override
- (void)suspend DEPRECATED_ATTRIBUTE {
    LOGI(@"suspend is NOT implemented");
}

//override
- (void)setPriority:(float)priority {
    self.taskPriority = priority;
}

//override
- (void)readDataOfMinLength:(NSUInteger)minBytes
                  maxLength:(NSUInteger)maxBytes
                    timeout:(NSTimeInterval)timeout
          completionHandler:(void (^)(NSData *, BOOL, NSError *, TTHttpResponse *))completionHandler {
     LOGI(@"readDataOfMinLength is NOT implemented");
}

+ (void)clearMatchRules:(NSDictionary *)concurrentRequestConfig {
    if (![self.class parseIfConcurrentRequestSwitchEnabled:concurrentRequestConfig switchName:kTTNetworkConcurrentRequestEnabled] ||
        ![self.class parseConcurrentRequestMatchRules:concurrentRequestConfig]) {
        return;
    }
    
    [self.class lazyInitStaticRuleObj];
    
    [ruleSetLock lock];
    if ([ruleSet count] > 0) {
        [ruleSet removeAllObjects];
    }
    [ruleSetLock unlock];
}

+ (BOOL)forbidConcurrentTaskIfNeed:(UrlMatchRule *)matchRule {
    if (!matchRule || !matchRule.concurrentHost || matchRule.concurrentHost.count < 2) {
        LOGD(@"matchRule invalid");
        return YES;
    }
    
    //old or invalid TNC config(without SBH value)
    if (![self.class isConservativeStrategyEnabled:matchRule]) {
        return NO;
    }
    
    BOOL isForbidden = NO;
    [self.class lazyInitStaticRuleObj];
    [ruleSetLock lock];
    if ([ruleSet containsObject:matchRule]) {
        UrlMatchRule *ruleInSet = [ruleSet member:matchRule];
        NSDate *firstForbiddenTime = ruleInSet.firstForbiddenTime;
        NSTimeInterval gap = -[firstForbiddenTime timeIntervalSinceNow];
        NSInteger forbidSeconds = ruleInSet.forbiddenDurationSeconds;
        NSInteger maxFailCount = ruleInSet.maxFailCount;
        
        if (ruleInSet.continuousFailCount >= maxFailCount) {
            if (gap > forbidSeconds) {
                [ruleSet removeObject:ruleInSet];
            } else {
                isForbidden = YES;
                LOGD(@"forbid set matchRule");
            }
        }
    }
    [ruleSetLock unlock];
    
    return isForbidden;
}

- (void)updateMatchRuleInfo {
    UrlMatchRule *targetRule = self.matchRule;
    if (![self.class isConservativeStrategyEnabled:targetRule]) {
        //old TNC config without SBH
        return;
    }
    [ruleSetLock lock];
    if (self.isMarkingWinnerWithBlockErrorCodeSet) {
        //mark winner in final callback and match blockErrorCodeSet
        [self.class updateFailCountAndForbiddenTime:targetRule];
    } else {
        //mark winner in headerCallback
        if ([ruleSet containsObject:targetRule]) {
            [ruleSet removeObject:targetRule];
        }
    }
    [ruleSetLock unlock];
}

+ (void)updateFailCountAndForbiddenTime:(UrlMatchRule *)targetRule {
    if ([ruleSet containsObject:targetRule]) {
        UrlMatchRule *rule = [ruleSet member:targetRule];
        ++rule.continuousFailCount;
        if ((rule.continuousFailCount >= rule.maxFailCount) && (!rule.firstForbiddenTime)) {
            rule.firstForbiddenTime = [NSDate date];
        }
    } else {
        ++targetRule.continuousFailCount;
        if ((targetRule.continuousFailCount >= targetRule.maxFailCount) && (!targetRule.firstForbiddenTime)) {
            targetRule.firstForbiddenTime = [NSDate date];
        }
        [ruleSet addObject:targetRule];
    }
}

+ (BOOL)isMatchingWithNoRetry:(NSString *)urlString {
    //For the sake of simplicity, we don't take into account the case that no_retry=1 appears in fragment and other non-query place
    return [urlString containsString:[NSString stringWithFormat:@"%@=1", kTTNetworkConcurrentRequestNoRetry]];
}

- (NSString *)addConcurrentAndIsRetryQueryIfNeed:(NSString *)originalURL originalQuery:(NSString *)originalQuery {
    if (!originalURL) {
        return nil;
    }
    NSString *additionalQuery = nil;
    //add concurrent=${number} query, reserve fragment
    if (originalQuery) {
        BOOL doesQueryExist = [TTNetworkUtil doesQueryContainKey:originalQuery keyName:kTTNetworkConcurrentRequestIsRetry keyValue:@"1"];
        if (!doesQueryExist) {
            additionalQuery = [NSString stringWithFormat:@"&concurrent=%ld", self.subTaskSeqNumber];
            NSString *newQuery = [NSString stringWithFormat:@"%@%@", originalQuery, additionalQuery];
            if (self.subTaskSeqNumber >= 1) {
                //add is_retry=1 to retry task's query
                additionalQuery = [NSString stringWithFormat:@"&%@=1", kTTNetworkConcurrentRequestIsRetry];
                newQuery = [NSString stringWithFormat:@"%@%@", newQuery, additionalQuery];
            }
            originalURL = [TTNetworkUtil replaceFirstAppearString:originalURL target:originalQuery toString:newQuery];
        }
    } else {
        additionalQuery = [NSString stringWithFormat:@"?concurrent=%ld", self.subTaskSeqNumber];
        if (self.subTaskSeqNumber >= 1) {
            //add is_retry=1 to retry task's query
            additionalQuery = [NSString stringWithFormat:@"%@&%@=1", additionalQuery, kTTNetworkConcurrentRequestIsRetry];
        }
        NSString *path = [TTNetworkUtil getRealPath:[NSURL URLWithString:originalURL]];
        NSString *pathAndQuery = [NSString stringWithFormat:@"%@%@", path, additionalQuery];
        originalURL = [TTNetworkUtil replaceFirstAppearString:originalURL target:path toString:pathAndQuery];
    }
    
    return originalURL;
}


#pragma mark - parse TNC concurrent request config

+ (BOOL)parseIfConcurrentRequestSwitchEnabled:(NSDictionary *)concurrentRequestConfig  switchName:(NSString *)switchName {
    if (concurrentRequestConfig && [concurrentRequestConfig isKindOfClass:NSDictionary.class] ) {
        NSNumber *enabled = [concurrentRequestConfig objectForKey:switchName];
        if (enabled && [enabled integerValue] >= 1) {
            return YES;
        }
    }
    return NO;
}

+ (NSTimeInterval)parseConcurrentRequestConnectInterval:(NSDictionary *)concurrentRequestConfig preferMatchRule:(UrlMatchRule *)matchRule {
    //prefer "connect_interval_millis" in matchRule to "connect_interval" in concurrentRequestConfig
    unsigned short connectIntervalMillis = matchRule.connectIntervalMillis;
    if (connectIntervalMillis > 0) {
        return (NSTimeInterval)connectIntervalMillis / 1000;
    }
    
    //if "connect_interval_millis" donsen't exist in matchRule, use "connect_interval" in concurrentRequestConfig as default value
    if (concurrentRequestConfig && [concurrentRequestConfig isKindOfClass:NSDictionary.class] ) {
        NSNumber *connectInterval = [concurrentRequestConfig objectForKey:kTTNetworkConcurrentRequestConnectInterval];
        if (connectInterval && [connectInterval doubleValue] > 0) {
            return (NSTimeInterval)[connectInterval doubleValue];
        }
    }
    
    //both not exist, use global default value
    return (NSTimeInterval)g_concurrent_request_connect_interval;
}

+ (NSArray *)parseConcurrentRequestMatchRules:(NSDictionary *)concurrentRequestConfig {
    if (concurrentRequestConfig && [concurrentRequestConfig isKindOfClass:NSDictionary.class] ) {
        id matchRules = [concurrentRequestConfig objectForKey:kTTNetworkConcurrentRequestMatchRules];
        if (matchRules && [matchRules isKindOfClass:NSArray.class]) {
            return (NSArray *)matchRules;
        }
    }
    return nil;
}

+ (UrlMatchRule *)getConcurrentHostAccordingToRules:(NSArray *)matchRules withUrl:(NSString *)URL {
    if (!matchRules) {
        return nil;
    }
    
    NSURL *nsurl = [NSURL URLWithString:URL];
    if (!nsurl) {
        LOGE(@"URL is malformed in getConcurrentHostAccordingToRules!");
        return nil;
    }
    NSString *targetHost = nsurl.host;
    NSString *targetPath = [TTNetworkUtil.class getRealPath:nsurl];
    
    UrlMatchRule *rule = nil;
    for (id item in matchRules) {
        NSDictionary *dictMatchRulesItem = (NSDictionary *)item;
        NSArray *hostGroup = [dictMatchRulesItem objectForKey:kTNCHostGroup];
        if (!hostGroup) {
            continue;
        }
        
        NSArray *equalGroup = [dictMatchRulesItem objectForKey:kTNCEqualGroup];
        NSArray *prefixGroup = [dictMatchRulesItem objectForKey:kTNCPrefixGroup];
        NSArray *patternGroup = [dictMatchRulesItem objectForKey:kTNCPatternGroup];
        //at least one path pattern must exist
        if (!equalGroup && !prefixGroup && !patternGroup) {
            continue;
        }
        
        if ([TTNetworkUtil isMatching:targetHost pattern:kCommonMatch source:hostGroup]) {
            if ([TTNetworkUtil isMatching:targetPath pattern:kPathEqualMatch source:equalGroup]) {
                rule = [self.class constructRuleWithItem:dictMatchRulesItem hostGroup:hostGroup equalGroup:equalGroup prefixGroup:prefixGroup patternGroup:patternGroup];
                break;
            }
            if ([TTNetworkUtil isMatching:targetPath pattern:kPathPrefixMatch source:prefixGroup]) {
                rule = [self.class constructRuleWithItem:dictMatchRulesItem hostGroup:hostGroup equalGroup:equalGroup prefixGroup:prefixGroup patternGroup:patternGroup];
                break;
            }
            if ([TTNetworkUtil isMatching:targetPath pattern:kPathPatternMatch source:patternGroup]) {
                rule = [self.class constructRuleWithItem:dictMatchRulesItem hostGroup:hostGroup equalGroup:equalGroup prefixGroup:prefixGroup patternGroup:patternGroup];
                break;
            }
        } else {
            continue;
        }
    }
    
    return rule;
}

+ (UrlMatchRule *)constructRuleWithItem:(NSDictionary *)matchRulesItem
                              hostGroup:(NSArray<NSString *> *)hostGroup
                             equalGroup:(NSArray<NSString *> *)equalGroup
                                 prefixGroup:(NSArray<NSString *> *)prefixGroup
                                patternGroup:(NSArray<NSString *> *)patternGroup {
    UrlMatchRule *rule = nil;
    NSArray<NSString *> *concurrentHostList = nil;
    id obj = [matchRulesItem objectForKey:kTTNetworkConcurrentRequestConcurrentHosts];
    if ([obj isKindOfClass:NSArray.class]) {
        concurrentHostList = obj;
    }
    NSInteger maxFailCount = kUnsetIntMatchRuleValue;
    NSInteger forbidSeconds = kUnsetIntMatchRuleValue;
    obj = [matchRulesItem objectForKey:kTTNetworkConcurrentRequestMaxFailCount];
    if ([obj isKindOfClass:NSNumber.class] && [obj integerValue] > 0) {
        maxFailCount = [obj integerValue];
    }
    obj = [matchRulesItem objectForKey:kTTNetworkConcurrentRequestForbidSeconds];
    if ([obj isKindOfClass:NSNumber.class] && [obj integerValue] > 0) {
        forbidSeconds = [obj integerValue];
    }
    
    NSSet *blockCodeList = nil;
    obj = [matchRulesItem objectForKey:kTTNetworkConcurrentRequestBlockCodeList];
    if ([obj isKindOfClass:NSArray.class]) {
        blockCodeList = [NSSet setWithArray:(NSArray *)obj];
    }
    
    unsigned short connectIntervalMillis = 0;
    obj = [matchRulesItem objectForKey:kTTNetworkSubRequestConnectInterval];
    if ([obj isKindOfClass:NSNumber.class] && [obj integerValue] > 0) {
        connectIntervalMillis = [obj unsignedShortValue];
    }
    
    BOOL isRetryForNot2xxCode = NO;
    obj = [matchRulesItem objectForKey:kTTNetworkConcurrentRequestRetryForNot2xxCode];
    if ([obj isKindOfClass:NSNumber.class] && [obj integerValue] >= 0) {
        isRetryForNot2xxCode = [obj integerValue] > 0;
    }
    
    BOOL isBypassRouteSelection = YES; //concurrent request bypass RS as default
    obj = [matchRulesItem objectForKey:kTTNetworkSubRequestBypassRouteSelection];
    if ([obj isKindOfClass:NSNumber.class] && [obj integerValue] >= 0) {
        isBypassRouteSelection = [obj integerValue] > 0;
    }
    
    NSString* refineRouteSelectionName = nil;
    obj = [matchRulesItem objectForKey:kTTNetworkConcurrentRequestRsName];
    if ([obj isKindOfClass:NSString.class]) {
        refineRouteSelectionName = [obj copy];
    }
    
    rule = [[UrlMatchRule alloc] initWithHostGroup:hostGroup
                                        equalGroup:equalGroup
                                       prefixGroup:prefixGroup
                                      patternGroup:patternGroup
                                    concurrentHost:concurrentHostList
                                      maxFailCount:maxFailCount
                          forbiddenDurationSeconds:forbidSeconds
                                 blockErrorCodeSet:blockCodeList
                             connectIntervalMillis:connectIntervalMillis
                              isRetryForNot2xxCode:isRetryForNot2xxCode
                      refineWithRouteSelectionName:refineRouteSelectionName
                            isBypassRouteSelection:isBypassRouteSelection];
    return rule;
}

//SBH: small black house
+ (BOOL)isConservativeStrategyEnabled:(UrlMatchRule *)matchRule {
    NSInteger forbidSeconds = matchRule.forbiddenDurationSeconds;
    NSInteger maxFailCount = matchRule.maxFailCount;
    
    BOOL isValueUnset = (maxFailCount == kUnsetIntMatchRuleValue) || (forbidSeconds == kUnsetIntMatchRuleValue);
    if (isValueUnset) {
        //compatible with old strategy
        LOGD(@"old TNC config");
        return NO;
    }
    
    BOOL isValueInvalid = (maxFailCount <= 0) || (forbidSeconds <= 0);
    if (isValueInvalid) {
        //TNC config wants to close SBH strategy
        LOGD(@"TNC config close SBH");
        return NO;
    }
    return YES;
}

+ (void)lazyInitStaticRuleObj {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ruleSetLock = [[NSLock alloc] init];
        ruleSet = [[NSMutableSet alloc] init];
    });
}

@end
