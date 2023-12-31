//
//  TTMicroAppNetwork.m
//  Timor
//
//  Created by muhuai on 2017/11/29.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import "TMAPluginNetwork.h"
#import "BDPAPIInterruptionManager.h"
#import <OPFoundation/BDPCommonManager.h>
#import <ECOInfra/BDPFileSystemHelper.h>
#import <ECOInfra/BDPLogHelper.h>
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPNetworking.h>
#import <OPFoundation/BDPRequestMetrics.h>
#import <OPFoundation/BDPRouteMediator.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import "BDPTaskManager.h"
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPTracingManager.h>
#import <OPFoundation/BDPTracker.h>
#import "BDPURLProtocolManager.h"
#import <OPFoundation/BDPUserAgent.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPVersionManager.h>
#import <OPFoundation/EEFeatureGating.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <ECOInfra/ECONetworkGlobalConst.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <ECOInfra/NSURLSession+TMA.h>
#import <OPFoundation/TMACustomHelper.h>
#import "OPAPIDefine.h"
#import <KVOController/KVOController.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <ECOInfra/NSURLSessionTask+Tracing.h>
#import "TMAPluginNetworkTools.h"
#import <OPFoundation/BDPCommonMonitorHelper.h>
#import <ECOInfra/ECOCookieStorage.h>
#import <ECOInfra/ECOCookieService.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/OPTrace+RequestID.h>
#import "OPAppUniqueId+GadgetCookieIdentifier.h"
#import "BDPAppPagePrefetchManager.h"
#import "BDPAppPagePrefetcher.h"
#import <OPFoundation/OPFoundation-Swift.h>
#import "TMAPluginNetworkDefines.h"

#define BDPRequestTypeStringNormal @"default"

#define BACKGROUND_GUARD \
    if ([[BDPAPIInterruptionManager sharedManager] shouldInterruptionV2ForAppUniqueID:engine.uniqueID]) {   \
        response.errMsg = @"app in background"; \
        [response callback:OPGeneralAPICodeBackground];  \
        return; \
    }

#define BACKGROUND_GUARD_WITH_ENGINE \
    if ([[BDPAPIInterruptionManager sharedManager] shouldInterruptionV2ForEngine:context.engine]) {   \
        response.errMsg = @"app in background"; \
        [response callback:OPGeneralAPICodeBackground];  \
        return; \
    }

typedef NS_ENUM(NSUInteger, BDPTTRequestType) {
    BDPTTRequestTypeDefault = 0,           // 默认请求，nsurlsession
    //  下面两个无用
    BDPTTRequestTypeTTNet,                 // ttnet请求，仅内部请求使用
    BDPTTRequestTypeHttpDNS                // httpDNS优化请求
};

@interface BDPNetworkTask : NSObject

@property (nonatomic, strong) id<BDPNetworkTaskProtocol> realTask;
@property (nonatomic, copy) NSDictionary *param;
@property (nonatomic, strong) BDPRequestMetrics *metrics;
@property (nonatomic) BDPNetworkRequestType requestType;
@property (nonatomic) BDPTracing *tracing;

@end

@implementation BDPNetworkTask

@end

@interface TMAPluginNetwork() <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, assign) NSInteger lastestTaskID;
@property (nonatomic, strong) NSMutableDictionary<NSString *, BDPNetworkTask *> *taskIdMapTask;
@property (nonatomic, strong) NSRecursiveLock* taskLock;
@property (nonatomic, weak)  id<BDPEngineProtocol> engine;
@property (nonatomic, assign) BOOL isInterruption;
@property (nonatomic, copy) NSArray<NSString *> *validMethods;

@end

@implementation TMAPluginNetwork

#pragma mark - Initialize
/*-----------------------------------------------*/
//             Initialize - 初始化相关
/*-----------------------------------------------*/

+ (BDPJSBridgePluginMode)pluginMode
{
    return BDPJSBridgePluginModeLifeCycle;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.taskLock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

#pragma mark - Function Implementation
/*-----------------------------------------------*/
//       Function Implementation - 功能实现
/*-----------------------------------------------*/
- (void)createRequestTaskWithParam:(NSDictionary *)param
                          callback:(BDPJSBridgeCallback)callback
                            engine:(BDPJSBridgeEngine)engine
                        controller:(UIViewController *)controller {
    OP_API_RESPONSE(OPAPIResponse)
    if (![NetworkLarkFeatureGatingDependcy v1SupportInBackground]) {
        BACKGROUND_GUARD
    }
    [self requestWithParam:param
                  response:response
                    engine:engine
                controller:controller
    onStateChangeEventName:@"onRequestTaskStateChange"
             needCheckAuth:engine.uniqueID.appType != BDPTypeBlock];
}

- (void)createUploadTaskWithParam:(NSDictionary *)param
                         callback:(BDPJSBridgeCallback)callback
                           engine:(BDPJSBridgeEngine)engine
                       controller:(UIViewController *)controller {
    OP_API_RESPONSE(OPAPIResponse)
    if (![NetworkLarkFeatureGatingDependcy v1SupportInBackground]) {
        BACKGROUND_GUARD
    }
    BDPTracing *tracing = [TMAPluginNetwork generateRequestTracing:engine.uniqueID];
    // 参数类型合法性检测，失败则在方法内进行失败回调
    BOOL isParamValid = [response checkParamValidAndCallbackIfNeeded:param paramArr:@[@"url", @"filePath", @"name"]];
    if (!isParamValid) {
        return;
    }
    
    // Get URL
    self.engine = engine;
    NSString *url = [param bdp_stringValueForKey:@"url"];
    url = [TMACustomHelper urlCustomEncodeWithUrl:url];
    
    // Check URL
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:engine.uniqueID];
    
    BOOL canVisitURL = [common.auth checkAuthorizationURL:url authType:BDPAuthorizationURLDomainTypeUpload];
    OP_INVOKE_GUARD_NEW(!canVisitURL, [response callback:UploadFileAPICodeInvalidDomain], ([NSString stringWithFormat:@"url is not valid domain, url == %@", url]))
    
    NSURL *URL = [NSURL URLWithString:url] ?: [TMACustomHelper URLWithString:url relativeToURL:nil];
    OP_INVOKE_GUARD_NEW(!URL, [response callback:UploadFileAPICodeInvalidUrl], ([NSString stringWithFormat:@"url is not valid domain, url == %@", url]))

    // Check FileURLPath
    NSString *filePath = [param bdp_stringValueForKey:@"filePath"];
    /// 标准化文件操作
    /// 创建 file object
    OPFileObject *file = [[OPFileObject alloc] initWithRawValue:filePath];
    OP_INVOKE_GUARD_NEW(!file, [response callback:UploadFileAPICodeInvalidFilePath], @"filePath is illegal");

    tracing.info(@"has uniqueId %@", @(common.model.uniqueID != nil));
    OP_INVOKE_GUARD_NEW(!common.model.uniqueID, [response callback:OPGeneralAPICodeUnkonwError], @"unknown error");

    /// 创建上下文信息
    OPFileSystemContext *fsContext = [[OPFileSystemContext alloc] initWithUniqueId:common.model.uniqueID
                                                                             trace:tracing
                                                                               tag:@"createUploadTask"];

    /// package 路径需要异步读取，防止在弱网等待下包情况下卡死。
    /// 这里针对 package path 使用异步读取，ttfile path 使用同步读取，是为了与以前保持一致。
    /// 但是！！！
    /// createUploadTask 的 isSynchronize 设置为了 YES，意味着异步读取其实是无响应的。
    /// 因此，这里先和老逻辑保持一致，哪怕是 bug 也先保持一样的表现，迁移结束后再考虑各业务统一处理。
    if (file.isValidPackageFile) {   // package path
        WeakSelf;
        WeakObject(engine);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            /// 读取文件数据
            NSError *error = nil;
            NSData *data = [OPFileSystem readFile:file context:fsContext error:&error];

            dispatch_async(dispatch_get_main_queue(), ^{
                StrongSelfIfNilReturn
                StrongObjectIfNilReturn(engine)

                /// 原逻辑未做 error 判断, 先统一返回 unknown error, 实际上读取文件时需要:
                /// 1. 判断文件权限
                /// 2. 判断文件存在性
                /// 3. 判断是否是文件
                if (error) {
                    fsContext.trace.error(@"call readFile failed, hasData: %@, error: %@", @(data != nil), error.description);
                    /// 文件不存在, 不是文件 (与原逻辑保持一致，提示 file is empty)
                    if ([OPFileSystemError matchFileSystemError:@[@(FileSystemErrorCodeFileNotExists), @(FileSystemErrorCodeIsNotFile)] error:error]) {
                        OP_CALLBACK_WITH_ERRMSG([response callback:UploadFileAPICodeFileEmpty], @"file is empty")
                    } else {
                        OP_CALLBACK_WITH_ERRMSG([response callback:OPGeneralAPICodeUnkonwError], @"unknown error");
                    }
                    return;
                }

                /// 上传文件
                [self uploadFileWithData:data param:param toUrl:URL engine:engine tracing:tracing response:response];
            });
        });
    } else {    // ttfile path
        /// 读取文件数据
        NSError *error = nil;
        NSData *data = [OPFileSystem readFile:file context:fsContext error:&error];

        /// 原逻辑未做 error 判断, 先统一返回 unknown error, 实际上读取文件时需要:
        /// 1. 判断文件权限
        /// 2. 判断文件存在性
        /// 3. 判断是否是文件
        if (error) {
            fsContext.trace.error(@"call readFile failed, hasData: %@, error: %@", @(data != nil), error.description);
            /// 文件不存在, 不是文件 (与原逻辑保持一致，提示 file is empty)
            if ([OPFileSystemError matchFileSystemError:@[@(FileSystemErrorCodeFileNotExists), @(FileSystemErrorCodeIsNotFile)] error:error]) {
                OP_CALLBACK_WITH_ERRMSG([response callback:UploadFileAPICodeFileEmpty], @"file is empty")
            } else {
                OP_CALLBACK_WITH_ERRMSG([response callback:OPGeneralAPICodeUnkonwError], @"unknown error");
            }
            return;
        }

        /// 上传文件
        [self uploadFileWithData:data param:param toUrl:URL engine:engine tracing:tracing response:response];
    }
}

- (void)createDownloadTaskWithParam:(NSDictionary *)param
                           callback:(BDPJSBridgeCallback)callback
                            context:(BDPPluginContext)context {
    OP_API_RESPONSE(OPAPIResponse)
    if (![NetworkLarkFeatureGatingDependcy v1SupportInBackground]) {
        BACKGROUND_GUARD_WITH_ENGINE
    }
    BDPTracing *tracing = [TMAPluginNetwork generateRequestTracing:context.engine.uniqueID];
    BDPMonitorEvent *event = BDPMonitorWithNameAndEngine(kEventName_mp_request_download_start, context.engine);
    // 参数类型合法性检测，失败则在方法内进行失败回调
    BOOL isParamValid = [response checkParamValidAndCallbackIfNeeded:param paramArr:@[@"url"]];
    if (!isParamValid) {
        return;
    }
    
    // Get URL
    self.engine = context.engine;
    NSString *url = [param bdp_stringValueForKey:@"url"];
    NSString *filePath = [param bdp_stringValueForKey:@"filePath"];
    url = [TMACustomHelper urlCustomEncodeWithUrl:url];
    
    // Check URL
    BDPAuthorization *auth = context.engine.authorization;
    BOOL canVisitURL = [auth checkAuthorizationURL:url authType:BDPAuthorizationURLDomainTypeDownload];
    OP_INVOKE_GUARD_NEW(!canVisitURL, [response callback:DownloadFileAPICodeInvalidDomain], ([NSString stringWithFormat:@"url is not valid domain, url == %@", url]))
    
    NSURL *URL = [NSURL URLWithString:url] ?: [TMACustomHelper URLWithString:url relativeToURL:nil];
    OP_INVOKE_GUARD_NEW(!URL, [response callback:DownloadFileAPICodeInvalidUrl], ([NSString stringWithFormat:@"url is not valid domain, url == %@", url]))

    /// 判断 filePath 非空
    if (!BDPIsEmptyString(filePath)) {
        /// 准备前置数据
        OPFileSystemContext *fsContext = [[OPFileSystemContext alloc] initWithUniqueId:context.engine.uniqueID
                                                                                 trace:nil
                                                                                   tag:@"createDownloadTask"];
        OPFileObject *fileObj = [[OPFileObject alloc] initWithRawValue:filePath];
        OP_INVOKE_GUARD_NEW(!fileObj, [response callback:DownloadFileAPICodeFileNotExist], ([NSString stringWithFormat:@"no such file or directory \"%@\"", filePath]))

        /// 判断是否可写（注意 download 还需要能写入到 temp 目录，你要问我为什么？这是前人的传承）
        BOOL isInTempDir = fileObj.isInTempDir;
        NSError *error = nil;
        NSNumber *canWrite = [OPFileSystem canWrite:fileObj isRemove:false context:fsContext error:&error];
        BOOL callCanWriteFailed = !canWrite || error;
        if (callCanWriteFailed) {
            fsContext.trace.error(@"call canWrite failed, hasResult: %@, error: %@", @(canWrite != nil), error.description);
        }
        BOOL hasWriteAccess = canWrite.boolValue || isInTempDir;
        OP_INVOKE_GUARD_NEW(callCanWriteFailed || !hasWriteAccess, [response callback:OPGeneralAPICodeSystemAuthDeny], ([NSString stringWithFormat:@"permission denied, open \"%@\"",filePath]));

        /// 判断父文件目录是否存在
        error = nil;
        OPFileObject *destFolder = fileObj.deletingLastPathComponent;
        NSNumber *fileExist = [OPFileSystem fileExist:destFolder context:fsContext error:&error];
        BOOL callFileExistFailed = !fileExist || error;
        if (callFileExistFailed) {
            fsContext.trace.error(@"call fileExists failed, hasResult: %@, error: %@", @(fileExist != nil), error.description);
        }
        OP_INVOKE_GUARD_NEW(callFileExistFailed || !fileExist.boolValue, [response callback:DownloadFileAPICodeFileNotExist], ([NSString stringWithFormat:@"no such file or directory \"%@\"", filePath]));
    }
    
    //默认使用GET
    NSString *method = [self parseHttpMethod:param];
    OP_INVOKE_GUARD_NEW((![self isValidMethod:method]), [response callback:DownloadFileAPICodeInvalidDomain], @"method is invalid");

    BDPTask* appTask = nil;
    if ([context.engine conformsToProtocol:@protocol(BDPJSBridgeEngineProtocol)]) {
        id<BDPJSBridgeEngineProtocol> engine = context.engine;
        appTask = [[BDPTaskManager sharedManager] getTaskWithUniqueID:engine.uniqueID];
    }
    NSInteger taskID = [self generateTaskID:param];
    NSString *patchCookiesMonitorValue = nil;
    
    NSDictionary *header = [param bdp_dictionaryValueForKey:@"header"];
    if(header) {
        header = [TMAPluginNetwork compatibleHeader:header];
        OP_INVOKE_GUARD_NEW(header == nil, [response callback:OPGeneralAPICodeParam], @"header is invalid")
    }
    header = [TMAPluginNetwork processHeader:header
                                   URLString:url
                                        type:BDPNetworkRequestTypeDownload
                                     tracing:tracing
                                    uniqueID:context.engine.uniqueID
                    patchCookiesMonitorValue:&patchCookiesMonitorValue
              ];
    if (patchCookiesMonitorValue) {
        event.kv(kTMAPluginNetworkMonitorPatchSystemCookies, patchCookiesMonitorValue);
    }

    id<BDPNetworkTaskProtocol> downloadTask = nil;
    NSURLSessionConfiguration *sessionConfig = [TMAPluginNetwork urlSessionConfiguration];
    sessionConfig.networkServiceType = NSURLNetworkServiceTypeDefault;
    sessionConfig.timeoutIntervalForRequest = 60;
    sessionConfig.allowsCellularAccess = YES;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                          delegate:self
                                                     delegateQueue:nil];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    request.timeoutInterval = appTask? appTask.config.networkTimeout.downloadFileTime.doubleValue / 1000: 60.f;
    request.allHTTPHeaderFields = header;
    request.HTTPMethod = method;
    
    id data = param[@"data"];
    if (![method isEqualToString:@"GET"]) {
        if ([data isKindOfClass:[NSData class]]) {
            request.HTTPBody = data;
        } else if ([data isKindOfClass:[NSString class]]) {
            request.HTTPBody = [data dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
    
    event
    .bdpTracing(tracing)
    .kv(kTMAPluginNetworkMonitorRequestVersion, @"v1")
    .kv(kTMAPluginNetworkMonitorMethod, request.HTTPMethod)
    .kv(kTMAPluginNetworkMonitorDomain, URL.host)
    .kv(kTMAPluginNetworkMonitorPath, URL.path)
    .kv(kTMAPluginNetworkMonitorRequestID, [tracing getRequestID]);

    // request header 根据配置脱敏上报
    NSString *reqMonitorHeader = [TMAPluginNetworkTools monitorValueForUniqueID:context.engine.uniqueID requestHeader:header];
    event.kv(kTMAPluginNetworkMonitorRequestHeader, reqMonitorHeader);

    event.flush();
    [tracing clientDurationTagStart:kEventName_mp_request_download_start];

    BDPLogInfo(@"start download task, url=%@, taskId=%@, requestTracing=%@, path=%@", [BDPLogHelper safeURL:URL], @(taskID), tracing.traceId, filePath);
    downloadTask = (id<BDPNetworkTaskProtocol>)[session downloadTaskWithRequest:request eventName:@"wx.downloadFile" requestTracing:tracing];
    [downloadTask resume];
    
    BDPNetworkTask *task = [BDPNetworkTask new];
    task.realTask = downloadTask;
    task.param = param;
    task.requestType = BDPNetworkRequestTypeDownload;
    task.tracing = tracing;
    [self.taskLock lock];
    [self.taskIdMapTask setValue:task forKey:[NSString stringWithFormat:@"%ld", (long)taskID]];
    [self.taskLock unlock];
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    result[@"downloadTaskId"] = @(taskID);
    result[@"trace"] = [tracing getRequestID];
    OP_CALLBACK_WITH_DATA([response callback:OPGeneralAPICodeOk], [result copy]);
}

- (void)operateRequestTaskWithParam:(NSDictionary *)param
                           callback:(BDPJSBridgeCallback)callback
                            context:(BDPPluginContext)context
{
    OP_API_RESPONSE(OPAPIResponse)
    [self abortWithParam:param response:response abortBlock:^(){[response callback:RequestAPICodeAbort];}];
}

- (void)operateUploadTaskWithParam:(NSDictionary *)param
                          callback:(BDPJSBridgeCallback)callback
                           context:(BDPPluginContext)context
{
    OP_API_RESPONSE(OPAPIResponse)
    [self abortWithParam:param response:response abortBlock:^(){[response callback:RequestAPICodeAbort];}];
}

- (void)operateDownloadTaskWithParam:(NSDictionary *)param
                            callback:(BDPJSBridgeCallback)callback
                             context:(BDPPluginContext)context
{
    OP_API_RESPONSE(OPAPIResponse)
    [self abortWithParam:param response:response abortBlock:^(){[response callback:RequestAPICodeAbort];}];
}

#pragma mark - NSURLSessionDelegate
/*-----------------------------------------------*/
//     NSURLSessionDelegate - 网络进度回调代理
/*-----------------------------------------------*/
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
                     willPerformHTTPRedirection:(NSHTTPURLResponse *)response
                                     newRequest:(NSURLRequest *)request
                              completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    [TMAPluginNetwork handleCookieWithResponse: response uniqueId: self.engine.uniqueID];
    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    if (![task isKindOfClass:[NSURLSessionUploadTask class]]) {
        return;
    }
    
    // Get TaskID By Task
    __block NSString *taskId = nil;
    NSDictionary *taskIdMapTaskCopy = nil;
    [self.taskLock lock];
    taskIdMapTaskCopy = [self.taskIdMapTask copy];
    [self.taskLock unlock];
    [taskIdMapTaskCopy enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, BDPNetworkTask * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.realTask == (id<BDPNetworkTaskProtocol>)task) {
            taskId = key;
            *stop = YES;
        }
    }];
    
    if (!BDPIsEmptyString(taskId)) {
        NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
        [data setValue:@"progressUpdate" forKey:@"state"];
        [data setValue:taskId forKey:@"uploadTaskId"];
        [data setValue:@(totalBytesSent * 100.0 / totalBytesExpectedToSend) forKey:@"progress"];
        [data setValue:@(totalBytesSent) forKey:@"totalBytesSent"];
        [data setValue:@(totalBytesExpectedToSend) forKey:@"totalBytesExpectedToSend"];
        [self.engine bdp_fireEvent:@"onUploadTaskStateChange" sourceID:NSNotFound data:data];
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    
    // Get TaskID By Task
    __block NSString *taskId = nil;
    __block BDPNetworkTask *networkTask = nil;
    NSDictionary *taskIdMapTaskCopy = nil;
    [self.taskLock lock];
    taskIdMapTaskCopy = [self.taskIdMapTask copy];
    [self.taskLock unlock];
    [taskIdMapTaskCopy enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, BDPNetworkTask * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.realTask == (id<BDPNetworkTaskProtocol>)downloadTask) {
            taskId = key;
            networkTask = obj;
            *stop = YES;
        }
    }];
    
    if (!BDPIsEmptyString(taskId)) {
        NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
        [data setValue:@"progressUpdate" forKey:@"state"];
        [data setValue:taskId forKey:@"downloadTaskId"];
        [data setValue:@(totalBytesWritten * 100.0 / totalBytesExpectedToWrite) forKey:@"progress"];
        [data setValue:@(totalBytesWritten) forKey:@"totalBytesWritten"];
        [data setValue:@(totalBytesExpectedToWrite) forKey:@"totalBytesExpectedToWrite"];
        [self.engine bdp_fireEvent:@"onDownloadTaskStateChange" sourceID:NSNotFound data:data];
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    NSURLResponse *response = downloadTask.response;
    NSString *url = response.URL.absoluteString;
    [BDPLogHelper logRequestEndWithEventName:@"wx.downloadFile" URLString:url URLResponse:response];
    // Get TaskID By Task
    __block NSString *taskId = nil;
    __block BDPNetworkTask *networkTask = nil;
    NSDictionary *taskIdMapTaskCopy = nil;
    [self.taskLock lock];
    taskIdMapTaskCopy = [self.taskIdMapTask copy];
    [self.taskLock unlock];
    [taskIdMapTaskCopy enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, BDPNetworkTask *  _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.realTask == (id<BDPNetworkTaskProtocol>)downloadTask) {
            taskId = key;
            networkTask = obj;
            *stop = YES;
        }
    }];
    
    if (BDPIsEmptyString(taskId)) {
        BDPLogWarn(@"taskId is empty, taskId=%@, url=%@", taskId, [BDPLogHelper safeURLString:url]);
        return;
    }
    // 移除taskID
    [self.taskLock lock];
    [self.taskIdMapTask removeObjectForKey:taskId];
    [self.taskLock unlock];
    [session finishTasksAndInvalidate];

    NSHTTPURLResponse *httpResponse = [downloadTask.response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)downloadTask.response: nil;
    if (networkTask && httpResponse) {
        [TMAPluginNetwork handleCookieWithResponse: httpResponse
                                          uniqueId: self.engine.uniqueID];
    }
    NSString *state = downloadTask.error ? @"fail" : @"success";
    NSString *downloadTaskID = taskId;
    NSString *errMsg = downloadTask.error.localizedDescription;
    NSString *statusCode = [NSString stringWithFormat:@"%ld", (long)httpResponse.statusCode];
    NSString *tempFilePath = @"";
    
    // 如果jscontext已经被销毁，这里就不再返回任何值。
    if (!self.engine) {
        BDPLogInfo(@"downlaod finish, engine is nil, return, state=%@, url=%@, taskId=%@, error=%@", state, [BDPLogHelper safeURLString:url], taskId, downloadTask.error);
        return;
    }
    BDPLogInfo(@"download finish success, taskId=%@, state=%@", taskId, state);
    // 下载成功，获取到路径
    BOOL vaildFilePath = NO;
    long long fileSize = 0;
    NSString *targetPath = [networkTask.param bdp_stringValueForKey:@"filePath"];

    if (!BDPIsEmptyString(location.path)) {
        /// 文件操作标准化改造
            /// 数据准备
            OPFileObject *destFileObj = nil;
            OPFileSystemContext *fsContext = [[OPFileSystemContext alloc] initWithUniqueId:self.engine.uniqueID
                                                                                     trace:networkTask.tracing
                                                                                       tag:@"createDownloadTask"];

            /// 如果传入了 targetPath，则使用 targetPath
            if (!BDPIsEmptyString(targetPath)) {
                destFileObj = [[OPFileObject alloc] initWithRawValue:targetPath];
                vaildFilePath = destFileObj != nil;
            }

            /// 如果没传 targetPath，则生成目标路径
            if (!destFileObj) {
                if (httpResponse.suggestedFilename) {   // 有建议名称则生成建议名称
                    destFileObj = [OPFileObject generateSpecificTTFile:BDPFolderPathTypeTemp
                                                        pathComponment:httpResponse.suggestedFilename];
                } else {                                // 无建议名称则生成随机路径
                    destFileObj = [OPFileObject generateRandomTTFile:BDPFolderPathTypeTemp fileExtension:nil];
                }
            }

            /// 判断目标文件是否存在
            NSError *error = nil;
            NSNumber *fileExist = [OPFileSystem fileExist:destFileObj context:fsContext error:&error];
            BOOL callFileExistFailed = !fileExist || error;
            if (callFileExistFailed) {
                fsContext.trace.error(@"call fileExist failed, hasResult: %@, error: %@", @(fileExist != nil), error.description);
            }
            /// 目标文件存在，先删除
            if (fileExist.boolValue) {
                error = nil;
                [OPFileSystem removeFile:destFileObj context:fsContext error:&error];
                if (error) {
                    fsContext.trace.error(@"call removeFile failed, error: %@", error.description);
                }
            }

            /// move 系统文件到沙箱
            error = nil;
            [OPFileSystemCompatible moveSystemFile:location.path to:destFileObj context:fsContext error:&error];
            if (error) {
                fsContext.trace.error(@"call moveSystemFile failed, error: %@", error.description);
                /// 无写权限
                if ([OPFileSystemError matchFileSystemError:@[@(FileSystemErrorCodeWritePermissionDenied)] error:error]) {
                    state = @"fail";
                    errMsg = [NSString stringWithFormat:@"permission denied, %@", destFileObj.rawValue];
                /// user 目录写入大小限制
                } else if ([OPFileSystemError matchFileSystemError:@[@(FileSystemErrorCodeWriteSizeLimit)] error:error]) {
                    state = @"fail";
                    errMsg = @"savefile: fail the maximum size of the file storage limit is exceeded";
                /// 系统 或 内部业务错误
                } else if ([OPFileSystemError matchSystemError:error] || [OPFileSystemError matchAllBizError:error]) {
                    state = @"faile";
                    errMsg = @"internal error";
                /// 文件系统 error
                } else if ([OPFileSystemError matchAllFileSystemError:error]) {
                    state = @"fail";
                    errMsg = BDPIsEmptyString(error.localizedDescription) ? error.localizedDescription : @"unknown error";
                /// 未知错误
                } else if ([OPFileSystemError matchUnknownError:error]) {
                    state = @"fail";
                    errMsg = @"unknown error";
                } else {
                    state = @"fail";
                    errMsg = @"unknown error";
                }
            } else {    /// 写入成功
                tempFilePath = destFileObj.rawValue;
            }
        // 下载失败，回调错误原因
    } else {
        state = @"fail";
        errMsg = @"Location Path is NULL.";
    }
    
    NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] initWithCapacity:5];
    [dataDict setValue:state forKey:@"state"];
    [dataDict setValue:downloadTaskID forKey:@"downloadTaskId"];
    [dataDict setValue:errMsg forKey:@"errMsg"];
    [dataDict setValue:statusCode forKey:@"statusCode"];
    [dataDict setValue:tempFilePath forKey:@"tempFilePath"];
    [dataDict setValue:vaildFilePath ? targetPath : nil forKey:@"filePath"];
    [dataDict setValue:[networkTask.tracing getRequestID] forKey:@"trace"];
    if ([state isEqualToString:@"success"]) {
        BDPLogInfo(@"download file success, taskId=%@, tempFilePath=%@", taskId, tempFilePath);
    } else {
        BDPLogWarn(@"download file fail! state=%@, taskId=%@, url=%@, errMsg=%@, tempFilePath=%@", state, downloadTaskID, [BDPLogHelper safeURLString:url], errMsg, tempFilePath);
    }
    OPMonitorEvent *event = BDPMonitorWithNameAndEngine(kEventName_mp_request_download_result, self.engine)
    .kv(kTMAPluginNetworkMonitorRequestVersion, @"v1")
    .kv(kTMAPluginNetworkMonitorDomain, response.URL.host)
    .kv(kTMAPluginNetworkMonitorPath, response.URL.path)
    .setResultType(dataDict[@"state"])
    .setError(downloadTask.error)
    .kv(kTMAPluginNetworkMonitorFileSize, @(fileSize))
    .setPlatform(OPMonitorReportPlatformTea|OPMonitorReportPlatformSlardar);

    // request header 根据配置脱敏上报
    NSString *reqMonitorHeader = [TMAPluginNetworkTools monitorValueForUniqueID:self.engine.uniqueID requestHeader:downloadTask.currentRequest.allHTTPHeaderFields];
    event.kv(kTMAPluginNetworkMonitorRequestHeader, reqMonitorHeader);

    if (httpResponse) {
        event.kv(@"http_code", @(httpResponse.statusCode));

        // response header 根据配置脱敏上报
        NSString *resMonitorHeader = [TMAPluginNetworkTools monitorValueForUniqueID:self.engine.uniqueID responseHeader:httpResponse.allHeaderFields];
        event.kv(kTMAPluginNetworkMonitorResponseHeader, resMonitorHeader);
    }
    if (networkTask.tracing) {
        event.bdpTracing(networkTask.tracing)
        .kv(kTMAPluginNetworkMonitorDuration, @([networkTask.tracing clientDurationTagEnd:kEventName_mp_request_download_start]))
        .kv(kTMAPluginNetworkMonitorRequestID, [networkTask.tracing getRequestID]);
    }
    event.flush();
    [self.engine bdp_fireEvent:@"onDownloadTaskStateChange" sourceID:NSNotFound data:[dataDict copy]];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics  API_AVAILABLE(ios(10.0))
{
    __block BDPNetworkTask *networkTask = nil;
    NSDictionary *taskIdMapTaskCopy = nil;
    [self.taskLock lock];
    taskIdMapTaskCopy = [self.taskIdMapTask copy];
    [self.taskLock unlock];
    [taskIdMapTaskCopy enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, BDPNetworkTask * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.realTask == (id<BDPNetworkTaskProtocol>)task) {
            networkTask = obj;
            *stop = YES;
        }
    }];
    //只有普通的请求需要计算时间，上传下载暂时不需要计算
    if (networkTask.requestType == BDPNetworkRequestTypeRequest) {
        networkTask.metrics = [BDPRequestMetrics metricsFromTransactionMetrics:metrics.transactionMetrics.firstObject];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    // Get TaskID By Task
    __block NSString *taskId = nil;
    __block BDPNetworkTask *networkTask = nil;
    NSDictionary *taskIdMapTaskCopy = nil;
    [self.taskLock lock];
    taskIdMapTaskCopy = [self.taskIdMapTask copy];
    [self.taskLock unlock];
    [taskIdMapTaskCopy enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, BDPNetworkTask * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.realTask == (id<BDPNetworkTaskProtocol>)task) {
            taskId = key;
            networkTask = obj;
            *stop = YES;
        }
    }];
    
    if (!BDPIsEmptyString(taskId)) {
        // 移除taskID
        [self.taskLock lock];
        [self.taskIdMapTask removeObjectForKey:taskId];
        [self.taskLock unlock];
        [session finishTasksAndInvalidate];

        if ([task isKindOfClass:[NSURLSessionDownloadTask class]]) {
            NSHTTPURLResponse *httpResponse = [task.response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)task.response: nil;
            NSString *state = error ? @"fail" : @"success";
            NSString *downloadTaskID = taskId;
            NSString *errMsg = error.localizedDescription;
            NSString *statusCode = [NSString stringWithFormat:@"%ld", (long)httpResponse.statusCode];
            NSString *tempFilePath = @"";
            if (error.code == NSURLErrorCancelled) {
                errMsg = @"abort";
            }
            
            NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] initWithCapacity:5];
            [dataDict setValue:state forKey:@"state"];
            [dataDict setValue:downloadTaskID forKey:@"downloadTaskId"];
            [dataDict setValue:errMsg forKey:@"errMsg"];
            [dataDict setValue:statusCode forKey:@"statusCode"];
            [dataDict setValue:tempFilePath forKey:@"tempFilePath"];
            OPMonitorEvent *event = BDPMonitorWithNameAndEngine(kEventName_mp_request_download_result, self.engine)
            .kv(kTMAPluginNetworkMonitorDomain, httpResponse.URL.host)
            .kv(kTMAPluginNetworkMonitorPath, httpResponse.URL.path)
            .setResultType(dataDict[@"state"])
            .setError(error)
            .setPlatform(OPMonitorReportPlatformTea|OPMonitorReportPlatformSlardar);
            if (httpResponse) {
                event.kv(@"http_code", @(httpResponse.statusCode));
            }
            if (networkTask.tracing) {
                event.bdpTracing(networkTask.tracing)
                .kv(kTMAPluginNetworkMonitorDuration, @([networkTask.tracing clientDurationTagEnd:kEventName_mp_request_download_start]))
                .kv(kTMAPluginNetworkMonitorRequestID, [networkTask.tracing getRequestID]);
            }
            event.flush();
            [self.engine bdp_fireEvent:@"onDownloadTaskStateChange" sourceID:NSNotFound data:[dataDict copy]];
        }
    }
}

#pragma mark - Utils
/*-----------------------------------------------*/
//                  Utils - 工具
/*-----------------------------------------------*/
- (void)uploadFileWithData:(NSData *)data
                     param:(NSDictionary *)param
                     toUrl:(NSURL *)URL
                    engine:(BDPJSBridgeEngine)engine
                   tracing:(BDPTracing *)tracing
                  response:(OPAPIResponse *)response {
    if (!data) {
        OP_CALLBACK_WITH_ERRMSG([response callback:UploadFileAPICodeFileEmpty], @"file is empty")
        return;
    }

    OPMonitorEvent * event = BDPMonitorWithName(kEventName_mp_request_upload_result, engine.uniqueID);
    NSInteger taskID = [self generateTaskID:param];
    NSString *filePath = [param bdp_stringValueForKey:@"filePath"];
    NSString *name = [param bdp_stringValueForKey:@"name"];
    NSDictionary *otherformData = [param bdp_dictionaryValueForKey:@"formData"];
    NSData *body = [TMAPluginNetworkTools multipartBodyWithName:name
                                                       boundary:kTMAPluginNetworkMultipartBoundary
                                                       fileName:filePath
                                                       fileData:data
                                                  otherFormData:otherformData];
    BDPNetworkRequestType requestType = BDPNetworkRequestTypeUpload;
    NSString *patchCookiesMonitorValue = nil;
    NSDictionary *header = [TMAPluginNetwork processHeader:[param bdp_dictionaryValueForKey:@"header"]
                                                 URLString:URL.absoluteString
                                                      type:requestType
                                                   tracing:tracing
                                                  uniqueID:engine.uniqueID
                                  patchCookiesMonitorValue:&patchCookiesMonitorValue];
    if (patchCookiesMonitorValue) {
        event.kv(kTMAPluginNetworkMonitorPatchSystemCookies, patchCookiesMonitorValue);
    }
    
    BDPTask *appTask = [[BDPTaskManager sharedManager] getTaskWithUniqueID:engine.uniqueID];
    
    id<BDPNetworkTaskProtocol> uploadTask = nil;
    WeakObject(engine);
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    request.timeoutInterval = appTask? appTask.config.networkTimeout.uploadFileTime.doubleValue / 1000: 10.f;
    request.HTTPMethod = @"POST";
    request.allHTTPHeaderFields = header;
    request.HTTPShouldHandleCookies = [BDPNetworking HTTPShouldHandleCookies];

    BDPMonitorWithName(kEventName_mp_request_upload_start, engine.uniqueID)
    .bdpTracing(tracing)
    .kv(kTMAPluginNetworkMonitorRequestVersion, @"v1")
    .kv(kTMAPluginNetworkMonitorMethod, request.HTTPMethod)
    .kv(kTMAPluginNetworkMonitorDomain, URL.host)
    .kv(kTMAPluginNetworkMonitorPath, URL.path)
    .kv(kTMAPluginNetworkMonitorRequestID, [tracing getRequestID])
    .flush();
    [tracing clientDurationTagStart:kEventName_mp_request_upload_start];
    
    // bugfix: 上传进度丢失的问题
    // - 原因：Heimdaller使用URLProtocol技术进行拦截Request来做到网络监控。
    // 但NSURLProtocol有bug，会导致URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend: 方法不会被调用
    // 导致了上传进度无法通知到前端
    // - 解决方案：不让Heimdallr拦截小程序的数据上传请求
    Class HMDURLProtocol = NSClassFromString(@"HMDURLProtocol");
    if ([HMDURLProtocol isSubclassOfClass:NSURLProtocol.class]) {
        [HMDURLProtocol setProperty:@YES forKey:@"HMDHTTPHandledIdentifier" inRequest:request];
    }
    BDPLogInfo(@"start upload task, url=%@, taskID=%@, file=%@, requestTracing=%@", [BDPLogHelper safeURL:URL], @(taskID), filePath, tracing.traceId);
    NSURLSessionConfiguration *sessionConfig = [TMAPluginNetwork urlSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                          delegate:self
                                                     delegateQueue:nil];
    WeakSelf;
    uploadTask = (id<BDPNetworkTaskProtocol>)[session uploadTaskWithRequest:[request copy] fromData:body completionHandler:^(NSData * _Nullable responseData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        StrongSelfIfNilReturn;
        [self.taskLock lock];
        [self.taskIdMapTask removeObjectForKey:[NSString stringWithFormat:@"%ld",(long)taskID]];
        [self.taskLock unlock];

        StrongObjectIfNilReturn(engine)

        NSHTTPURLResponse *httpResponse = [response isKindOfClass:[NSHTTPURLResponse class]]? (NSHTTPURLResponse *)response: nil;
        if (httpResponse) {
            [TMAPluginNetwork handleCookieWithResponse: httpResponse
                                              uniqueId: engine.uniqueID];
        }
        NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] init];
        [dataDict setValue:error? @"fail": @"success" forKey:@"state"];
        [dataDict setValue:@(taskID) forKey:@"uploadTaskId"];
        [dataDict setValue:error.localizedDescription forKey:@"errMsg"];
        [dataDict setValue:@(httpResponse.statusCode) forKey:@"statusCode"];
        [dataDict setValue:[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] forKey:@"data"];
        [dataDict setValue:[tracing getRequestID] forKey:@"trace"];
        if (error) {
            BDPLogWarn(@"finish upload task fail, url=%@, taskID=%@, file=%@, requestTracing=%@, code=%@, error=%@", [BDPLogHelper safeURL:URL], @(taskID), filePath, tracing.traceId, @(httpResponse.statusCode), error);
        } else {
            BDPLogInfo(@"finish upload task success, url=%@, taskID=%@, file=%@, requestTracing=%@, code=%@", [BDPLogHelper safeURL:URL], @(taskID), filePath, tracing.traceId, @(httpResponse.statusCode));
        }
        event
        .bdpTracing(tracing)
        .kv(kTMAPluginNetworkMonitorRequestVersion, @"v1")
        .kv(kTMAPluginNetworkMonitorMethod, request.HTTPMethod)
        .kv(kTMAPluginNetworkMonitorDomain, URL.host)
        .kv(kTMAPluginNetworkMonitorPath, URL.path)
        .kv(kTMAPluginNetworkMonitorRequestID, [tracing getRequestID])
        .setResultType(dataDict[@"state"])
        .setError(error)
        .kv(kTMAPluginNetworkMonitorDuration, @([tracing clientDurationTagEnd:kEventName_mp_request_upload_start]))
        .kv(kTMAPluginNetworkMonitorFileSize, @(data.length))
        .setPlatform(OPMonitorReportPlatformTea|OPMonitorReportPlatformSlardar);

        // request header 根据配置脱敏上报
        NSString *reqMonitorHeader = [TMAPluginNetworkTools monitorValueForUniqueID:engine.uniqueID requestHeader:header];
        event.kv(kTMAPluginNetworkMonitorRequestHeader, reqMonitorHeader);
        if (httpResponse) {
            event.kv(@"http_code", @(httpResponse.statusCode));
            // response header 根据配置脱敏上报
            NSString *resMonitorHeader = [TMAPluginNetworkTools monitorValueForUniqueID:engine.uniqueID responseHeader:httpResponse.allHeaderFields];
            event.kv(kTMAPluginNetworkMonitorResponseHeader, resMonitorHeader);
        }
        event.flush();
        
        [engine bdp_fireEvent:@"onUploadTaskStateChange" sourceID:NSNotFound data:[dataDict copy]];
        [session finishTasksAndInvalidate];
    } eventName:@"wx.uploadFile" requestTracing:tracing];
    [uploadTask resume];
    
    BDPNetworkTask *task = [BDPNetworkTask new];
    task.realTask = uploadTask;
    task.param = param;
    task.requestType = BDPNetworkRequestTypeUpload;
    task.tracing = tracing;
    [self.taskLock lock];
    [self.taskIdMapTask setValue:task forKey:[NSString stringWithFormat:@"%ld",(long)taskID]];
    [self.taskLock unlock];

    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    result[@"uploadTaskId"] = @(taskID);
    result[@"trace"] = [tracing getRequestID];
    OP_CALLBACK_WITH_DATA([response callback:OPGeneralAPICodeOk], [result copy]);
}

- (void)abortWithParam:(NSDictionary *)param
              response:(OPAPIResponse *)response
            abortBlock:(void (^)(void))abortBlock {
    NSString *operationType = [param bdp_stringValueForKey:@"operationType"];
    NSInteger taskId = 0;
    if (param[@"requestTaskId"]) {
        taskId = [param bdp_integerValueForKey:@"requestTaskId"];
    } else if (param[@"downloadTaskId"]) {
        taskId = [param bdp_integerValueForKey:@"downloadTaskId"];
    } else if (param[@"uploadTaskId"]) {
        taskId = [param bdp_integerValueForKey:@"uploadTaskId"];
    }
    BDPLogInfo(@"%@ request, taskId=%@", operationType, @(taskId));
    if (!BDPIsEmptyString(operationType) && [operationType isEqualToString:@"abort"]) {
        BDPNetworkTask *task = nil;
        [self.taskLock lock];
        task = [self.taskIdMapTask objectForKey:[NSString stringWithFormat:@"%ld", (long)taskId]];
        [self.taskLock unlock];
        
        if ([task.realTask respondsToSelector:@selector(cancel)]) {
            [task.realTask cancel];
        }
        if(abortBlock) abortBlock();
    }else{
        [response callback:OPGeneralAPICodeOk];
    }
        
}

- (void)requestWithParam:(NSDictionary *)param
                response:(OPAPIResponse *)response
                  engine:(BDPJSBridgeEngine)engine
              controller:(UIViewController *)controller
  onStateChangeEventName:(NSString*)onStateChangeEventName
           needCheckAuth:(BOOL)needCheckAuth {
    BDPTracing *tracing = [TMAPluginNetwork generateRequestTracing:engine.uniqueID];
    OPMonitorEvent *resultEvent = BDPMonitorWithName(kEventName_mp_request_result, engine.uniqueID);

    // 参数类型合法性检测，失败则在方法内进行失败回调
    BOOL isParamValid = [response checkParamValidAndCallbackIfNeeded:param paramArr:@[@"url"]];
    if (!isParamValid) {
        BDPLogWarn(@"param not valid, app=%@", engine.uniqueID);
        return;
    }
    
    // Get URL
    self.engine = engine;
    NSString *url = [param bdp_stringValueForKey:@"url"];
    url = [TMACustomHelper urlCustomEncodeWithUrl:url];
    
    // Check URL
    if (needCheckAuth) {
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:engine.uniqueID];
        OP_INVOKE_GUARD_NEW(![common.auth checkAuthorizationURL:url authType:BDPAuthorizationURLDomainTypeRequest], [response callback:RequestAPICodeInvalidDomain], ([NSString stringWithFormat:@"url is not valid domain, url == %@", url]))
    }

    NSURL *URL = [NSURL URLWithString:url] ?: [TMACustomHelper URLWithString:url relativeToURL:nil];
    OP_INVOKE_GUARD_NEW(!URL, [response callback:RequestAPICodeInvalidUrl], ([NSString stringWithFormat:@"url is not valid domain, url == %@", url]))
    
    // Get Params
    NSInteger taskID = [self generateTaskID:param];
    NSString *responseType = [param bdp_stringValueForKey:@"responseType"];
    BDPNetworkRequestType requestType = BDPNetworkRequestTypeRequest;
    NSString *patchCookiesMonitorValue = nil;
    NSDictionary *header = [TMAPluginNetwork processHeader:[param bdp_dictionaryValueForKey:@"header"]
                                                 URLString:url
                                                      type:requestType
                                                   tracing:tracing
                                                  uniqueID:engine.uniqueID
                                  patchCookiesMonitorValue:&patchCookiesMonitorValue];
    if (patchCookiesMonitorValue) {
        resultEvent.kv(kTMAPluginNetworkMonitorPatchSystemCookies, patchCookiesMonitorValue);
    }
    NSString *method = [self parseHttpMethod:param];
    OP_INVOKE_GUARD_NEW((![self isValidMethod:method]), [response callback:RequestAPICodeInvalidMethod], @"method is invalid");
    BOOL usePrefetchCache = [param bdp_boolValueForKey:@"usePrefetchCache"];
    WeakSelf;
    WeakObject(engine);
    void (^requestCompletion) (id data, id<BDPNetworkResponseProtocol>response, NSInteger prefetchDetail, NSError * __nullable error, NSDictionary *metrics)  =  ^(id data, id<BDPNetworkResponseProtocol>response, NSInteger prefetchDetail, NSError * __nullable error, NSDictionary *metrics) {
        StrongSelfIfNilReturn;
        StrongObjectIfNilReturn(engine);

        NSHTTPURLResponse *httpResponse = [response isKindOfClass:[NSHTTPURLResponse class]]? (NSHTTPURLResponse *)response: nil;
        if (httpResponse) {
            [TMAPluginNetwork handleCookieWithResponse: httpResponse
                                              uniqueId: engine.uniqueID];
        }
        NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] init];
        [dataDict setValue:@(taskID) forKey:@"requestTaskId"];
        [dataDict setValue:[tracing getRequestID] forKey:@"trace"];
        if (httpResponse) {
            [dataDict setValue:@"success" forKey:@"state"];
            [dataDict setValue:@(httpResponse.statusCode) forKey:@"statusCode"];
            [dataDict setValue:httpResponse.allHeaderFields forKey:@"header"];
            if (!BDPIsEmptyString(responseType) && [responseType isEqualToString:@"arraybuffer"]) {
                [dataDict setValue:data forKey:@"data"];
            } else {
                [dataDict setValue:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] forKey:@"data"];
            }
        } else {
            [dataDict setValue:@"fail" forKey:@"state"];
            [dataDict setValue:error.localizedDescription forKey:@"errMsg"];
        }
        [dataDict setValue:httpResponse.allHeaderFields forKey:@"header"];
        //prefetchDetail在发起请求时候，prefetchDetail 是 -1。表示没有走预取逻辑
        BOOL isPrefetch = usePrefetchCache && (prefetchDetail>=BDPPrefetchDetailFetchAndUseSuccess);
        if (usePrefetchCache) {
            //数据返回对齐
            //https://bytedance.feishu.cn/docs/doccnWyBevHJKJSX38jp0ONVDdb
            dataDict[@"isPrefetch"] = @(isPrefetch);
        }

        resultEvent
        .tracing(tracing)
        .kv(kTMAPluginNetworkMonitorRequestVersion, @"v1")
        .kv(kTMAPluginNetworkMonitorIsPrefetch, isPrefetch)
        .kv(kTMAPluginNetworkMonitorPrefetchResultDetail, prefetchDetail)
        .kv(kTMAPluginNetworkMonitorMethod, method)
        .kv(kTMAPluginNetworkMonitorDomain, URL.host)
        .kv(kTMAPluginNetworkMonitorPath, URL.path)
        .kv(kTMAPluginNetworkMonitorRequestID, [tracing getRequestID])
        .setResultType(dataDict[@"state"])
        .setError(error)
        .kv(kTMAPluginNetworkMonitorDuration, @([tracing clientDurationTagEnd:kEventName_mp_request_start]))
        .kv(@"channel", [BDPNetworking isNetworkTransmitOverRustChannel] ? @"rust" : @"native")
        .addMap(metrics)
        .setPlatform(OPMonitorReportPlatformTea|OPMonitorReportPlatformSlardar);

        // request header 根据配置脱敏上报
        NSString *monitorReqHeader = [TMAPluginNetworkTools monitorValueForUniqueID:engine.uniqueID requestHeader:header];
        resultEvent.kv(kTMAPluginNetworkMonitorRequestHeader, monitorReqHeader);

        if (httpResponse) {
            // http_code 没有时则不传这个key，不要取默认值
            resultEvent.kv(@"http_code", @(httpResponse.statusCode));

            // response header 根据配置脱敏上报
            NSString *monitorResHeader = [TMAPluginNetworkTools monitorValueForUniqueID:engine.uniqueID responseHeader:httpResponse.allHeaderFields];
            resultEvent.kv(kTMAPluginNetworkMonitorResponseHeader, monitorResHeader);
        }
        if ([data isKindOfClass:[NSData class]]) {
            resultEvent.kv(kTMAPluginNetworkMonitorResponseBodyLength, [(NSData*)data length]);
        }
        resultEvent.kv(kTMAPluginNetworkMonitorNetStatus, OPNetStatusHelperBridge.opNetStatus);
        resultEvent.kv(kTMAPluginNetworkMonitorRustStatus, OPNetStatusHelperBridge.rustNetStatus);
        resultEvent.kv(kTMAPluginNetworkMonitorNQEStatus, [TTNetworkManager shareInstance].getEffectiveConnectionType);
        resultEvent.kv(kTMAPluginNetworkMonitorNQEHttpRtt, [TTNetworkManager shareInstance].getNetworkQuality.httpRttMs);
        resultEvent.kv(kTMAPluginNetworkMonitorNQETransportRtt, [TTNetworkManager shareInstance].getNetworkQuality.transportRttMs);
        resultEvent.kv(kTMAPluginNetworkMonitorNQEDownstreamThroughput, [TTNetworkManager shareInstance].getNetworkQuality.downstreamThroughputKbps);
        resultEvent.kv(kTMAPluginNetworkMonitorIsBackground, [[BDPAPIInterruptionManager sharedManager] shouldInterruptionV2ForAppUniqueID:engine.uniqueID]);
        resultEvent.flush();
        if ([param[kBDPArrayBufferParam] boolValue]) {
            [engine bdp_fireEventV2:onStateChangeEventName data:[dataDict copy]];
        } else {
            [engine bdp_fireEvent:onStateChangeEventName sourceID:NSNotFound data:[dataDict copy]];
        }
    };
    BDPMonitorWithName(kEventName_mp_request_start, engine.uniqueID)
    .tracing(tracing)
    .kv(kTMAPluginNetworkMonitorRequestVersion, @"v1")
    .kv(kTMAPluginNetworkMonitorMethod, method)
    .kv(kTMAPluginNetworkMonitorDomain, URL.host)
    .kv(kTMAPluginNetworkMonitorPath, URL.path)
    .kv(kTMAPluginNetworkMonitorRequestID, [tracing getRequestID])
    .kv(kTMAPluginNetworkMonitorUsePrefetch, usePrefetchCache)
    .flush();
    [tracing clientDurationTagStart:kEventName_mp_request_start];
    
    OPPrefetchErrnoWrapper *prefetchMatchError; // 预取命中细节
    if (usePrefetchCache) {
        if ([PrefetchLarkFeatureGatingDependcy prefetchRequestV2WithUniqueID:engine.uniqueID]) {
            BDPMonitorWithName(@"mp_request_v1_prefetch_version_error_dev", engine.uniqueID)
            .kv(kTMAPluginNetworkMonitorRequestVersion, @"v1")
            .kv(kTMAPluginNetworkMonitorMethod, method)
            .kv(kTMAPluginNetworkMonitorDomain, URL.host)
            .kv(kTMAPluginNetworkMonitorPath, URL.path)
            .kv(kTMAPluginNetworkMonitorRequestID, [tracing getRequestID])
            .setPlatform(OPMonitorReportPlatformTea|OPMonitorReportPlatformSlardar)
            .flush();
        }

        BOOL useCache = [[BDPAppPagePrefetchManager sharedManager] shouldUsePrefetchCacheWithParam:param uniqueID: engine.uniqueID requestCompletion:^(id  _Nonnull data, id<BDPNetworkResponseProtocol>  _Nonnull response, NSInteger prefetchDetail, NSError * _Nullable error) {
            requestCompletion(data, response, prefetchDetail, error, nil);
        }  error:&prefetchMatchError];
        if(prefetchMatchError) {
            NSError *prefetchError = [NSError errorWithDomain:@"BDPAppPagePrefetcherErrorDomin" code:prefetchMatchError.errnoValue userInfo:nil];
            BDPLogInfo(@"usePrefetchCache, with error:%@", prefetchError);
        }
        if (useCache) {
            NSMutableDictionary *result = [NSMutableDictionary dictionary];
            result[@"requestTaskId"] = @(taskID);
            result[@"trace"] = [tracing getRequestID];
            // 预取成功 or 复用预取结果
            OP_CALLBACK_WITH_DATA([response callback:OPGeneralAPICodeOk], [result copy]);
            return;
        }
    }
    
    BDPTask* appTask = [[BDPTaskManager sharedManager] getTaskWithUniqueID:engine.uniqueID];
    BDPNetworkTask *task = [BDPNetworkTask new];
    id<BDPNetworkTaskProtocol> dataTask = nil;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    request.timeoutInterval = appTask? appTask.config.networkTimeout.requestTime.doubleValue / 1000: 10.f;
    request.HTTPMethod = method;
    request.allHTTPHeaderFields = header;
    request.HTTPShouldHandleCookies = [BDPNetworking HTTPShouldHandleCookies];

    id data = param[@"data"];
    if (![method isEqualToString:@"GET"]) {
        if ([data isKindOfClass:[NSData class]]) {
            request.HTTPBody = data;
        } else if ([data isKindOfClass:[NSString class]]) {
            request.HTTPBody = [data dataUsingEncoding:NSUTF8StringEncoding];
        }
    }

    NSString *typeStr = BDPRequestTypeStringNormal;
    NSURLSessionConfiguration *sessionConfig = [TMAPluginNetwork urlSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                          delegate:self
                                                     delegateQueue:nil];
    resultEvent.kv(kTMAPluginNetworkMonitorRequestBodyLength, request.HTTPBody ? request.HTTPBody.length : 0);
    dataTask = (id<BDPNetworkTaskProtocol>)[session dataTaskWithRequest:[request copy] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        StrongSelfIfNilReturn;
        [self.taskLock lock];
        [self.taskIdMapTask removeObjectForKey:[NSString stringWithFormat:@"%ld",(long)taskID]];
        [self.taskLock unlock];
        
        NSMutableDictionary *metrics = [NSMutableDictionary dictionary];
        BOOL useRustHttpProtocol = [BDPNetworking isNetworkTransmitOverRustChannel];
        if (useRustHttpProtocol) {
            NSDictionary *rustMetrics = [BDPNetworking rustMetricsForTask:task.realTask];
            if (!BDPIsEmptyDictionary(rustMetrics)) {
                [metrics addEntriesFromDictionary:rustMetrics];
            }
        } else {
            metrics[@"dns"] = @(task.metrics.dns);
            metrics[@"connection"] = @(task.metrics.tcp);;
            metrics[@"ssl"] = @(task.metrics.ssl);;
            metrics[@"ttfb"] = @(task.metrics.wait);
        }
        //prefetchDetail为-1，表示该结果是来自实际网络请求，没走预拉取
        requestCompletion(data, response, -1, error, metrics);
        [session finishTasksAndInvalidate];
    } eventName:@"wx.request" requestTracing:tracing];
    [dataTask resume];

    task.realTask = dataTask;
    task.param = param;
    task.requestType = BDPNetworkRequestTypeRequest;
    task.tracing = tracing;
    [self.taskLock lock];
    [self.taskIdMapTask setValue:task forKey:[NSString stringWithFormat:@"%ld", (long)taskID]];
    [self.taskLock unlock];
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    result[@"requestTaskId"] = @(taskID);
    result[@"trace"] = [tracing getRequestID];
    OP_CALLBACK_WITH_DATA([response callback:OPGeneralAPICodeOk], [result copy]);
}

+ (NSString *)appendCookiesAtURLString:(NSString *)url
                                cookie:(NSString *)cookie
                              uniqueId:(OPAppUniqueID *)uniqueId
              patchCookiesMonitorValue:(NSString **)patchCookiesMonitorValue {
    // Check URL IsValid
    NSURL *URL = [NSURL URLWithString:[[url componentsSeparatedByString:@"?"] firstObject]];
    if (!URL) {
        return cookie ?: @"";
    }


    NSMutableSet<NSString *> *uniqueCookieNames = [NSMutableSet setWithCapacity:20];
    // firstparty login cookie
    NSArray<NSHTTPCookie *> *firstPartyCookies = [[FirstPartyMicroAppLoginOpt shared] cookiesForURL:URL uniqueID:uniqueId];
    // gadget cookie
    id<ECOCookieStorage> storage = [[ECOCookie resolveService] gadgetCookieStorageWithGadgetId: uniqueId];
    NSArray<NSHTTPCookie *> *urlCookies = [storage cookiesForURL:URL] ?: @[];
    if (firstPartyCookies.count > 0) {
        NSMutableArray<NSHTTPCookie *> *newURLCookies = [NSMutableArray<NSHTTPCookie *> array];
        for (NSHTTPCookie *cookie in firstPartyCookies) {
            if (!BDPIsEmptyString(cookie.name) && ![uniqueCookieNames containsObject:cookie.name]) {
                [uniqueCookieNames addObject: cookie.name];
                [newURLCookies addObject:cookie];
            }
        }
        for (NSHTTPCookie *cookie in urlCookies) {
            if (!BDPIsEmptyString(cookie.name) && ![uniqueCookieNames containsObject:cookie.name]) {
                [uniqueCookieNames addObject: cookie.name];
                [newURLCookies addObject:cookie];
            }
        }
        urlCookies = [newURLCookies copy];
    }

    if (urlCookies.count > 0 && !BDPIsEmptyString(cookie)) {
        NSMutableArray<NSString *> *userCookieKeys = [NSMutableArray<NSString *> array];
        NSMutableArray<NSHTTPCookie *> *newURLCookies = [NSMutableArray<NSHTTPCookie *> array];
        NSArray<NSString *> *userCookieKVs = [cookie componentsSeparatedByString:@";"];
        for (NSString *userCookieKV in userCookieKVs) {
            NSString *userCookieKey = [userCookieKV componentsSeparatedByString:@"="].firstObject;
            userCookieKey = [userCookieKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (!BDPIsEmptyString(userCookieKey)) {
                [uniqueCookieNames addObject:userCookieKey];
            }
            [userCookieKeys addObject:userCookieKey];
        }
        for (NSHTTPCookie *httpCookie in urlCookies) {
            NSString *httpCookieKey = httpCookie.name;
            if (![userCookieKeys containsObject:httpCookieKey]) {
                [newURLCookies addObject:httpCookie];
            }
        }
        urlCookies = newURLCookies;
    }
    
    if (urlCookies.count) {
        NSMutableString *cookiesValue = [[NSMutableString alloc] init];
        NSMutableArray<NSString *> *patchCookieNames = [NSMutableArray array];
        for (NSHTTPCookie *cookie in urlCookies) {
            [cookiesValue appendFormat:@"%@=%@;", cookie.name, cookie.value];
            [patchCookieNames addObject:[cookie.name reuseCacheMask]];
        }
        if (!BDPIsEmptyString(cookiesValue)) {
            NSString *URLCookie = [cookiesValue substringToIndex:MAX(0, cookiesValue.length - 1)];
            if (BDPIsEmptyString(cookie)) {
                cookie = URLCookie;
            } else {
                cookie = [cookie stringByAppendingFormat:@";%@", URLCookie];
            }
            if (patchCookiesMonitorValue) {
                /// 所有引擎侧补充的 cookie name
                *patchCookiesMonitorValue = [patchCookieNames componentsJoinedByString:@","];
            }
        }
    }

    return cookie ?: @"";
}

- (NSInteger)generateTaskID:(NSDictionary *)param {
    /// 如果jssdk提供了taskId，直接使用jssdk提供的
    NSInteger taskID = [param integerValueForKey:@"taskId" defaultValue:NSNotFound];
    if (taskID != NSNotFound) {
        return taskID;
    }
    return _lastestTaskID++;
}

- (NSString *)parseHttpMethod:(NSDictionary *)param {
    NSString *method = [param stringValueForKey:@"method" defaultValue:@"GET"].uppercaseString;
    if (BDPIsEmptyString(method)) {
        method = @"POST"; // 如果用户没有写method, 默认是GET， 如果用户写成了’‘  默认是POST， 不要问我为什么，跟微信对齐。
    }
    return method;
}

- (NSMutableDictionary *)taskIdMapTask
{
    if (!_taskIdMapTask) {
        _taskIdMapTask = [[NSMutableDictionary alloc] init];
    }
    return _taskIdMapTask;
}

- (BOOL)isValidMethod:(NSString *)method
{
    return [self.validMethods containsObject:method];
}

- (NSArray<NSString *> *)validMethods
{
    if (!_validMethods) {
        _validMethods = @[@"GET", @"HEAD", @"POST", @"PUT", @"DELETE", @"CONNECT", @"OPTIONS", @"TRACE", @"PATCH"];
    }
    
    return [_validMethods copy];
}

// 对 Header 做可兼容的校验, 尝试将 Header 中 key 和 value 转为 string 类型, 失败的情况下返回 NO
// 用于 5.0 临时兜底 JSSDK 没有处理 Header 类型的情况. 5.1 重构后,这部分逻辑由 JSSDK 实现. @majiaxin
+ (NSDictionary<NSString *, NSString *> *)compatibleHeader:(NSDictionary <id, id>*)header{
    NSMutableDictionary *newHeader = [NSMutableDictionary dictionary];
    NSMutableArray *invalidKeys = [NSMutableArray array];
    __block BOOL isValid = YES;
    [header enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *newKey = [self stringValue:key];
        NSString *newValue = [self stringValue:obj];
        if(!newKey || !newValue) {
            isValid = NO;
            [invalidKeys addObject:key];
        } else {
            newHeader[newKey] = newValue;
        }
    }];
    BDPLogError(@"request with invalid Header Keys = %@", invalidKeys);
    return isValid ? newHeader : nil;
}

+ (NSString *)stringValue:(id)value {
    if (value && [value isKindOfClass:[NSString class]]) {
        return value;
    } else if (value && [value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    } else {
        return nil;
    }
}


+ (NSString *)referWithUniqueID:(OPAppUniqueID *) uniqueID
{
    BDPPlugin(networkPlugin, BDPNetworkPluginDelegate);
    NSString *referString;
    if ([networkPlugin respondsToSelector:@selector(bdp_customReferWithUniqueID:)]) {
        referString = [networkPlugin bdp_customReferWithUniqueID:uniqueID];
    } else {
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
        referString = [BDPURLProtocolManager serviceReferer:common.uniqueID version:common.model.version];
    }
    return referString;
}

+ (void)logRequestResultWithDuration:(NSUInteger)duration Error:(NSError*)error Reponse:(id<BDPNetworkResponseProtocol>) response UniqueID:(BDPUniqueID *)uniqueID RequestType:(NSString*)type
{
    NSMutableDictionary *metric = [NSMutableDictionary dictionary];
    NSMutableDictionary *category = [NSMutableDictionary dictionary];
    NSMutableDictionary *extra = [NSMutableDictionary dictionary];
    
    [metric setValue:@(duration) forKey:@"duration"];
    
    if (error) {
        [category setValue:@(9100) forKey:@"status"];
        //错误信息
        [extra setValue:error.localizedDescription forKey:@"error_msg"];
        //网络类型
        NSString *netType = nil;

        switch ([BDPNetworking networkType]) {
            case BDPNetworkTypeWifi:
                netType = @"Wifi";
                break;
            case BDPNetworkType4G:
                netType = @"4G";
                break;
            case BDPNetworkType3G:
                netType = @"3G";
                break;
            case BDPNetworkType2G:
                netType = @"2G";
                break;
            case BDPNetworkTypeMobile:
                netType = @"Mobile";
                break;
            default:
                break;
        }
    
        [extra setValue:netType forKey:@"net_type"];
        //网络是否正常 true有网络，false 无网络
        [extra setValue:[BDPNetworking isNetworkConnected]?@"true":@"false" forKey:@"net_available"];
    }else
    {
        [category setValue:@(0) forKey:@"status"];
    }
    
    [extra setValue:type forKey:@"request_type"];
    [extra setValue:[NSString stringWithFormat:@"%@://%@%@",response.URL.scheme,response.URL.host,response.URL.path] forKey:@"url_path"];
    [BDPTracker monitorService:@"mp_ttrequest_result" metric:metric category:category extra:extra uniqueID:uniqueID];
}

@end

@implementation TMAPluginNetwork(Utils)

+ (BDPTracing *)generateRequestTracing:(BDPUniqueID *)uniqueID {
    BDPTracing *parentTracing = [BDPTracingManager.sharedInstance getTracingByUniqueID:uniqueID];
    BDPTracing *tracing = [BDPTracingManager.sharedInstance generateTracingWithParent:parentTracing];
    // TODO: 确认这里选用 appID 改为使用 uniqueID.fullString 是否更好
    [tracing genRequestID:uniqueID.appID];
    return tracing;
}

/// tt.request 相关 URLSession 配置，隔离状态下禁用原生 cookie 设置
+ (NSURLSessionConfiguration *)urlSessionConfiguration {
    NSURLSessionConfiguration *config = [[BDPNetworking sharedSession].configuration copy];
    config.HTTPCookieStorage = nil;
    config.HTTPShouldSetCookies = false;
    config.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
    config.protocolClasses = @[SwiftToOCBridge._EMARustHttpURLProtocol];
    return config;
}

/// 处理 tt.request 的 response cookie
/// @param response tt.request 请求的 HTTPURLResponse
/// @param uniqueId UniqueID
+ (void)handleCookieWithResponse: (NSHTTPURLResponse *)response
                        uniqueId: (OPAppUniqueID *)uniqueId {
    id<ECOCookieStorage> storage =
        [[ECOCookie resolveService] gadgetCookieStorageWithGadgetId: uniqueId];
    [storage saveCookieWithResponse: response];
}

+ (NSDictionary *)processHeader:(NSDictionary *)header
                      URLString:(NSString *)url
                           type:(BDPNetworkRequestType)type
                        tracing:(BDPTracing *)tracing
                       uniqueID:(BDPUniqueID *)uniqueID
       patchCookiesMonitorValue:(NSString *__autoreleasing *)patchCookiesMonitorValue {
    NSMutableDictionary *mutableHeader = [[header bdp_dictionaryWithLowercaseKeys] mutableCopy];
    if (mutableHeader == nil) {
        mutableHeader = [[NSMutableDictionary alloc] init];
    }
    
    NSString *cookie = [mutableHeader bdp_stringValueForKey:@"cookie"];
    NSString *userAgent = [mutableHeader bdp_stringValueForKey:@"user-agent"];
    NSString *contentType = [mutableHeader bdp_stringValueForKey:@"content-type"];
    NSString *referer = [TMAPluginNetwork referWithUniqueID:uniqueID];
    
    cookie = [TMAPluginNetwork appendCookiesAtURLString:url
                                                 cookie:cookie
                                               uniqueId:uniqueID
                               patchCookiesMonitorValue:patchCookiesMonitorValue];
    userAgent = [BDPUserAgent getUserAgentString]; // 经过与微信测试对齐，User-Agent不允许开发者自行设置，全部使用默认UA
    
    if (type == BDPNetworkRequestTypeRequest) {
        // 微信 API - tt.request 在 Header 中 Content-Type 为空时会默认处理为 @"application/json"，经与前端确认，暂不对齐。
        // contentType = contentType ?: @"application/json";
    } else if (type == BDPNetworkRequestTypeDownload) {
        // None Process
    } else if (type == BDPNetworkRequestTypeUpload) {
        contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", kTMAPluginNetworkMultipartBoundary];
    }
    
    [mutableHeader setValue:referer forKey:@"referer"];
    [mutableHeader setValue:cookie forKey:@"cookie"];
    [mutableHeader setValue:contentType forKey:@"content-type"];
    [mutableHeader setValue:userAgent forKey:@"user-agent"];
    // rust存在动态超时逻辑: 1. 5s 如果没有数据返回，则认为出现网络问题。 2. 如果等待超过20s且没有数据返回，会认为超时
    [mutableHeader setValue:@"1" forKey:@"x-rust-disable-dynamic-timeout"];
    [mutableHeader setValue:[tracing getRequestID] forKey:OP_REQUEST_ID_HEADER];
    [mutableHeader setValue:[tracing getRequestID] forKey:OP_REQUEST_LOGID_HEADER];
    return [mutableHeader copy];
}

@end
