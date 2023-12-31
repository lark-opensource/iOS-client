//
//  TTHttpTaskChromium.m
//  Pods
//
//  Created by gaohaidong on 11/16/16.
//
//

#import "TTHttpTaskChromium.h"

#import <Godzippa/NSData+Godzippa.h>
#import "TTNetworkUtil.h"
#import "TTNetworkManagerChromium.h"
#import "TTNetworkManagerChromium+TTConcurrentHttpTask.h"
#import "TTFetcherDelegateForCommonTask.h"
#import "TTFetcherDelegateForStreamTask.h"
#import "TTNetworkManagerLog.h"
#import "TTNetworkManagerMonitorNotifier.h"
#import "TTRedirectTask.h"
#import "TTRequestDispatcher.h"
#import "TTReqFilterManager.h"
#import "TTRegionManager.h"
#import "QueryFilterEngine.h"
#import "TTNetworkDefine.h"

#include "base/bind.h"
#include "base/threading/sequenced_task_runner_handle.h"
#include "base/strings/sys_string_conversions.h"
#include "base/timer/timer.h"
#include "components/cronet/ios/cronet_environment.h"
#include "net/base/net_errors.h"
#include "net/base/load_flags.h"
#include "net/http/http_request_headers.h"
#include "net/http/http_response_headers.h"
#include "net/tt_net/config/tt_config_manager.h"
#include "base/strings/string_split.h"
#include "base/strings/string_util.h"
#include "url/gurl.h"
#include "net/tt_net/config/tt_init_config.h"
#include "net/tt_net/compress/tt_compress_native.h"
#include "net/tt_net/util/tt_http_utils.h"
#include "net/url_request/redirect_info.h"
#ifndef OC_DISABLE_STORE_IDC
#include "net/tt_net/tt_region/store_idc_manager.h"
#include "net/tt_net/config/tt_config_manager.h"
#endif
#include "net/tt_net/route_selection/tt_net_common_tools.h"
#include "TTURLDispatch.h"

// Define pure request by control header, will bypass request filter and query filter
NSString* const kPureRequestControlHeaderKey = @"x-metasec-bypass-ttnet-features";// valid if value equals "1"

static const int kMinBodySize = 100;

@interface TTHttpResponseChromium ()

- (instancetype)initWithURLFetcher:(const net::URLFetcher *)fetcher;
- (instancetype)initWithRequestLog:(NSString *)requestLog;
- (void)appendRequestLogWithCompressLog:(NSString *)compressLog;

@end

TTFetcherDelegate::TTFetcherDelegate(__weak TTHttpTaskChromium *task, cronet::CronetEnvironment *engine)
        : task_(task),
          taskId_(task.taskId),
          engine_(engine),
          is_complete_(false),
          timeout_timer_(new base::OneShotTimer) {
}

TTFetcherDelegate::~TTFetcherDelegate() {
}
    
void TTFetcherDelegate::OnTransactionAboutToStart(const net::URLFetcher* source, const std::string& url, net::HttpRequestHeaders* headers) {
    GURL origin_url(url);
    std::vector<std::string> request_headers;
    std::string url_string = url;
    net::ttutils::HandleHpackOptimization(origin_url, headers, url_string,
                                          request_headers);
    
    
    NSMutableDictionary *requestHeadersDict = [[NSMutableDictionary alloc] init];
    size_t request_headers_size = request_headers.size();
    for (size_t i = 0; i < request_headers_size; i += 2) {
        if (i < request_headers_size - 1) {
            NSString *key = base::SysUTF8ToNSString(request_headers.at(i));
            NSString *value = base::SysUTF8ToNSString(request_headers.at(i + 1));
            [requestHeadersDict setValue:value forKey:[key lowercaseString]];
        }
    }
    task_.request.allHTTPHeaderFields = requestHeadersDict;
    
    if ([TTNetworkManager shareInstance].addSecurityFactorBlock) {
        NSURL* requestURL = [NSURL URLWithString:base::SysUTF8ToNSString(url_string)];
 
        // Monitor timing consumed by |addSecurityFactorBlock|.    
        source->SetSecurityCallbackStart(base::TimeTicks::Now());
        NSDictionary* addRequestHeaders = [TTNetworkManager shareInstance].addSecurityFactorBlock(requestURL, requestHeadersDict);
        source->SetSecurityCallbackEnd(base::TimeTicks::Now());
        if (!addRequestHeaders) {
            return;
        }
            
        for (NSString* addKey in [addRequestHeaders allKeys]) {
            NSString* addValue = [addRequestHeaders objectForKey:addKey];
            headers->SetHeader(base::SysNSStringToUTF8(addKey), base::SysNSStringToUTF8(addValue));
        }
    }
}
    
    
bool TTFetcherDelegate::SkipSSLCertificateError(net::URLRequest* request, const net::SSLInfo& ssl_info, bool fatal) {
    // fatal has been checked in fetcher
    return task_.skipSSLCertificateError;
}
    
void TTFetcherDelegate::CreateURLFetcher() {
    if (!engine_) {
        NSDictionary *userInfo = @{kTTNetSubErrorCode : @(TTNetworkErrorCodeIllegalClientState),
                                   NSLocalizedDescriptionKey : @"check engine failed",
                                   NSURLErrorFailingURLStringErrorKey : task_.request.urlString ?  task_.request.urlString  : @"Nil"};
        NSError *resultError =  [NSError errorWithDomain:kTTNetworkErrorDomain code:TTNetworkErrorCodeIllegalClientState userInfo:userInfo];
        task_.isCompleted = YES;
        [[TTRequestDispatcher shareInstance] onHttpTaskFinish:task_];
        task_.callbackBlock(nil, nil, resultError);
        return;
    }
    
    if (task_.delayTimeMills > 0) {
        engine_->GetURLRequestContextGetter()->GetNetworkTaskRunner()->PostDelayedTask(FROM_HERE, base::Bind(&TTFetcherDelegate::CreateURLFetcherOnNetThread, this), base::TimeDelta::FromMilliseconds(task_.delayTimeMills));
        return;
    }
    engine_->GetURLRequestContextGetter()->GetNetworkTaskRunner()->PostTask(FROM_HERE, base::Bind(&TTFetcherDelegate::CreateURLFetcherOnNetThread, this));
}
    
void TTFetcherDelegate::Cancel() {
    engine_->GetURLRequestContextGetter()->GetNetworkTaskRunner()->PostTask(FROM_HERE, base::Bind(&TTFetcherDelegate::CancelOnNetThread, this));
}

void TTFetcherDelegate::StartRedirect() {
    engine_->GetURLRequestContextGetter()->GetNetworkTaskRunner()->PostTask(FROM_HERE, base::Bind(&TTFetcherDelegate::StartRedirectOnNetThread, this));
}

void TTFetcherDelegate::SetThrottleNetSpeed(int64_t bytesPerSecond) {
    if (fetcher_) {
        engine_->GetURLRequestContextGetter()->GetNetworkTaskRunner()->PostTask(FROM_HERE, base::Bind(&TTFetcherDelegate::SetThrottleNetSpeedOnNetThread, this, bytesPerSecond));
    }
}

void TTFetcherDelegate::SetThrottleNetSpeedOnNetThread(int64_t bytesPerSecond) {
    if (fetcher_) {
        fetcher_->SetThrottleNetSpeed(bytesPerSecond);
    }
}

void TTFetcherDelegate::GetResponseAsFilePathFromFetcher() {
    if (task_.fileDestinationURL) {
        base::FilePath download_file_path;
        if (!fetcher_ || !fetcher_->GetResponseAsFilePath(true, &download_file_path)) {
            LOGE(@"get response file failed!!!");
        }
    }
}

void TTFetcherDelegate::FreeFetcher() {
    // URLFetcher must be freed in the thread where it creates, in our case, it is network thread.
    // Before the ownership of |this| is posted to other thread, use this function to free fetcher
    // after it is used. Otherwise there may be a race when |this| is released on other thread, and
    // network thread called reset() in OnURLFetchComplete();
    fetcher_.reset();
}

void TTFetcherDelegate::ReadDataWithLength(int minLength, int maxLength, double timeoutInSeconds, OnStreamReadCompleteBlock completionHandler) {
}

void TTFetcherDelegate::OnTimeout() {
    if (!is_complete_) {
        is_complete_ = true;
            
        int error = net::OK;
        int status = -1;
        NSString *details = @"";
        NSString *requestLog = @"";
        if (fetcher_) {
            fetcher_->Cancel(net::ERR_TTNET_APP_TIMED_OUT);
            status = error = fetcher_->GetError();
            details = @(fetcher_->GetRequestDetails().c_str());
            requestLog = @(fetcher_->GetRequestLog().c_str());
        }
        timeout_timer_.reset();
        if (task_.isFileAppend) {
            GetResponseAsFilePathFromFetcher();
        }
        fetcher_.reset();
            
        [task_ onTimeout:status error:error details:details requestLog:requestLog];
    }
}

void TTFetcherDelegate::StartRedirectOnNetThread() {
    if (is_complete_ || !task_ || !fetcher_) {
        return;
    }

    // compose remove_headers list
    base::Optional<std::vector<std::string>> remove_headers = base::nullopt;
    NSArray<NSString *> *current_remove = task_.redirectTask.currentRemovedHeaders;
    if (current_remove.count) {
        std::vector<std::string> remove;
        for (NSString *header in current_remove) {
            remove.push_back([header UTF8String]);
        }
        if (!remove.empty()) {
            remove_headers = std::move(remove);
        }
    }

    // compose modify_headers map
    base::Optional<std::map<std::string, std::string>> modify_headers = base::nullopt;
    NSDictionary<NSString*, NSString*> *current_modify = task_.redirectTask.currentModifiedHeaders;
    if (current_modify.count) {
        std::map<std::string, std::string> modify;
        for (NSString *key in current_modify) {
            modify[[key UTF8String]] = [[current_modify valueForKey:key] UTF8String];
        }
        if (!modify.empty()) {
            modify_headers = std::move(modify);
        }
    }

    std::string redirect_url = base::SysNSStringToUTF8(task_.redirectTask.redirectUrl.absoluteString);

    fetcher_->FollowDeferredRedirect(remove_headers, modify_headers, redirect_url);
}

std::string TTFetcherDelegate::CompressBodyOnNetThread(NSData *body) {
    if (!body) {
        return "";
    }
    net::CompressNativeWrapper* compressManager = engine_->GetURLRequestContextGetter()->GetURLRequestContext()->compress_native_wrapper();
    int compressType = compressManager->GetCompressConfig().type;
    NSTimeInterval compressStart = [[NSDate date] timeIntervalSince1970];
    unsigned long beforeSize = (unsigned long)[body length];
    std::string bodyString = "";
    
    switch (compressType) {
        case net::CompressType::COMPRESS_ZLIB: {
            NSData *compressedData = nil;
            NSError *compressionError = nil;
            compressedData = [body dataByGZipCompressingWithError:&compressionError];
            if (compressedData && !compressionError) {
                bodyString = std::string((char*)compressedData.bytes, compressedData.length);
                fetcher_->AddExtraRequestHeader(base::SysNSStringToUTF8(@"x-bd-content-encoding: gzip"));
            } else {
                bodyString = std::string((char*)body.bytes, body.length);
            }
            break;
        }
        case net::CompressType::COMPRESS_BROTLI: {
            std::string originalString = std::string((char*)body.bytes, body.length);
            int compressState = compressManager->CompressUsingBrotli(originalString, bodyString);
            if (compressState != 0) {
                bodyString = std::string((char*)body.bytes, body.length);
            } else {
                fetcher_->AddExtraRequestHeader(base::SysNSStringToUTF8(@"x-bd-content-encoding: br"));
            }
            break;
        }
        default:
            break;
    }
    unsigned int compressDuration = ([[NSDate date] timeIntervalSince1970] -  compressStart) * 1000 * 1000;
    NSString *compressLog = [NSString stringWithFormat:@"\"compress\" : {\"type\" : %@, \"duration\" : %@, \"beforeSize\" : %@, \"afterSize\" : %@},", [NSString stringWithFormat:@"%d",compressType], [NSString stringWithFormat:@"%u",compressDuration], [NSString stringWithFormat:@"%lu",beforeSize], [NSString stringWithFormat:@"%lu",(unsigned long)bodyString.size()]];
    
    task_.compressLog = compressLog;

    return bodyString;
}

void TTFetcherDelegate::CreateURLFetcherOnNetThread() {
    if (is_complete_ || !task_) {
        LOGI(@"is_complete_ is true or the task is gone, do nothing but return...");
        return;
    }
    
    __strong TTHttpRequestChromium *request = task_.request;
    if (!request) {
        LOGE(@"TTHttpRequestChromium is nil! ");
        return;
    }
    
    const std::string &native_url = base::SysNSStringToUTF8(request.urlString);
    GURL url(native_url);
    if (!url.is_valid()) {
        LOGE(@"!!! Threading issue: url is invalid !!!");
        return;
    }
    
    net::URLFetcher::RequestType requestType = net::URLFetcher::GET;
    if ([request.HTTPMethod.uppercaseString isEqualToString:@"POST"]) {
        requestType = net::URLFetcher::POST;
    } else if ([request.HTTPMethod.uppercaseString isEqualToString:@"PUT"]) {
        requestType = net::URLFetcher::PUT;
    } else if ([request.HTTPMethod.uppercaseString isEqualToString:@"DELETE"]) {
        requestType = net::URLFetcher::DELETE_REQUEST;
    } else if ([request.HTTPMethod.uppercaseString isEqualToString:@"HEAD"]) {
        requestType = net::URLFetcher::HEAD;
    } else if ([request.HTTPMethod.uppercaseString isEqualToString:@"PATCH"]) {
        requestType = net::URLFetcher::PATCH;
    } else if ([request.HTTPMethod.uppercaseString isEqualToString:@"OPTIONS"]) {
        requestType = net::URLFetcher::OPTIONS;
    }
    
    fetcher_ = net::URLFetcher::Create(url, requestType, this);
    fetcher_->SetRequestContext(engine_->GetURLRequestContextGetter());
    if (task_.protectTimeout > 0.0) {
      fetcher_->SetRequestTimeout(task_.protectTimeout * 1000);
    }
    
    // Record delay time in request log.
    if (task_.delayTimeMills > 0) {
        fetcher_->SetDelayTime(task_.delayTimeMills);
    }
    
    //set headers
    NSDictionary<NSString *, NSString *> *headers = request.allHTTPHeaderFields;
    for (NSString *field in [headers allKeys]) {
//        LOGE(@"test header, head: %@, value: %@", field, [headers valueForKey:field]);
        NSString *header = [NSString stringWithFormat:@"%@: %@", field, [headers valueForKey:field]];
        
        fetcher_->AddExtraRequestHeader(base::SysNSStringToUTF8(header));
    }
    
    //handle POST and PUT request
    if (requestType == net::URLFetcher::POST
        || requestType == net::URLFetcher::PUT
        || requestType == net::URLFetcher::DELETE_REQUEST
        || requestType == net::URLFetcher::PATCH) {
        NSString *contentType = [headers objectForKey:@"Content-Type"];
        if (request.uploadFilePath) {
            // File upload
            fetcher_->SetUploadFilePath(base::SysNSStringToUTF8(contentType),
                                        base::FilePath::FromUTF8Unsafe(base::SysNSStringToUTF8(request.uploadFilePath)),
                                        task_.uploadFileOffset, task_.uploadFileLength, engine_->GetFileThreadRunnerForTesting());
        } else {
            // Memory data upload
            NSData *body = request.HTTPBody;
            std::string bodyString = "";
            if (request.form) {
                body = [request.form finalFormDataWithHttpRequest:request];
                contentType = [request.form getContentType];
            }
            net::CompressNativeWrapper* compressManager = engine_->GetURLRequestContextGetter()->GetURLRequestContext()->compress_native_wrapper();
            fetcher_->AddExtraRequestHeader(base::SysNSStringToUTF8([NSString stringWithFormat:@"X-SS-STUB: %@", [TTNetworkUtil md5Hex:body]]));
            std::string path = CPPSTR([TTNetworkUtil.class getRealPath:task_.request.URL]);
            std::string host = CPPSTR([task_.request.URL host]);
            if (compressManager && compressManager->GetCompressConfig().enabled && [body length] > kMinBodySize && [body length] < compressManager->GetCompressConfig().max_body_size && compressManager->IsUrlMatchedConfig(host, path)) {
                bodyString = CompressBodyOnNetThread(body);
            } else {
                bodyString = std::string((char*)body.bytes, body.length);
            }
            fetcher_->SetUploadData(base::SysNSStringToUTF8(contentType), bodyString);
        }
    }
    
    int loadFlags = static_cast<int>(task_.loadFlags);
    if (![TTNetworkManager shareInstance].enableHttpCache
        || !task_.enableHttpCache
        || requestType == net::URLFetcher::OPTIONS) {
        loadFlags |= net::LOAD_DISABLE_CACHE;
    }
    
    if (task_.enableCustomizedCookie) {
        fetcher_->SetAllowCredentials(false);
        loadFlags |= net::LOAD_FORCE_PRIVACY_MODE_DISABLED;
    }

    if (request.bypassProxy) {
        loadFlags |= net::LOAD_BYPASS_PROXY;
    }

    if (loadFlags > 0) {
        fetcher_->SetLoadFlags(fetcher_->GetLoadFlags() | loadFlags);
    }
    
    fetcher_->SetAutomaticallyRetryOn5xx(false);
    // Cannot automatically retry if there are multiple callbacks.
    if (task_.headerBlock || task_.dataBlock) {
        fetcher_->SetAutomaticallyRetryOnNetworkChanges(0);
    } else {
        fetcher_->SetAutomaticallyRetryOnNetworkChanges(g_request_count_network_changed);
    }
    bool follow_redirect = request.followRedirect;
    fetcher_->SetStopOnRedirect(!follow_redirect);
    
    [task_ setFetcherPriority_:fetcher_.get()];
    
    task_runner_ = base::SequencedTaskRunnerHandle::Get();
    //fix missing Referer when cross origin in webview
    NSString *referer = [task_.request.allHTTPHeaderFields valueForKey:@"Referer"];
    if (!referer) {
        referer = [task_.request.allHTTPHeaderFields valueForKey:@"referer"];
    }
    if (referer) {
        fetcher_->SetReferrer(base::SysNSStringToUTF8(referer));
    }
    if (task_.throttleNetBytesPerSecond > 0) {
        fetcher_->SetThrottleNetSpeed(task_.throttleNetBytesPerSecond);
    }
    if (task_.requestTypeFlags > 0) {
        fetcher_->SetRequestTypeFlags(task_.requestTypeFlags);
    }
    if (request.authCredentials && request.authCredentials.username && request.authCredentials.password) {
        fetcher_->SetAuthCredentials(
                base::SysNSStringToUTF8(request.authCredentials.username),
                base::SysNSStringToUTF8(request.authCredentials.password));
    }
}

//#define LEAK_DEBUG
#ifdef LEAK_DEBUG

static NSMutableDictionary *leakMap = [[NSMutableDictionary alloc] init];
static NSLock *leakLock = [[NSLock alloc] init];

static void addToLeakMap(TTHttpTaskChromium *task) {
    uintptr_t pointer_as_integer = (uintptr_t)task;
    [leakLock lock];
    leakMap[@(pointer_as_integer)] = task.request.URL;
    [leakLock unlock];
}

static void removeFromLeakMap(TTHttpTaskChromium *task) {
    uintptr_t pointer_as_integer = (uintptr_t)task;
    [leakLock lock];
    [leakMap removeObjectForKey:@(pointer_as_integer)];
    [leakLock unlock];
}
#endif

@interface TTHttpTaskChromium()
@property (nonatomic, strong) dispatch_queue_t downloadProgressCallbackQueue;
@end

@implementation TTHttpTaskChromium

- (instancetype)initWithRequest:(TTHttpRequestChromium *)request
                         engine:(cronet::CronetEnvironment *)env
                  dispatchQueue:(dispatch_queue_t)queue
                         taskId:(UInt64)taskId
              completedCallback:(OnHttpTaskCompletedCallbackBlock)block {
    return [self initWithRequest:request engine:env dispatchQueue:queue taskId:taskId enableHttpCache:YES completedCallback:block uploadProgressCallback:nil downloadProgressCallback:nil];
}

- (instancetype)initWithRequest:(TTHttpRequestChromium *)request
                         engine:(cronet::CronetEnvironment *)env
                  dispatchQueue:(dispatch_queue_t)queue
                         taskId:(UInt64)taskId
              completedCallback:(OnHttpTaskCompletedCallbackBlock)block
         uploadProgressCallback:(OnHttpTaskProgressCallbackBlock)uploadProgressBlock
       downloadProgressCallback:(OnHttpTaskProgressCallbackBlock)downloadProgressBlock {
    return [self initWithRequest:request engine:env dispatchQueue:queue taskId:taskId enableHttpCache:YES completedCallback:block uploadProgressCallback:uploadProgressBlock downloadProgressCallback:downloadProgressBlock];
}

- (instancetype)initWithRequest:(TTHttpRequestChromium *)request
                         engine:(cronet::CronetEnvironment *)env
                  dispatchQueue:(dispatch_queue_t)queue
                         taskId:(UInt64)taskId
                enableHttpCache:(BOOL)enableHttpCache
              completedCallback:(OnHttpTaskCompletedCallbackBlock)block
         uploadProgressCallback:(OnHttpTaskProgressCallbackBlock)uploadProgressBlock
       downloadProgressCallback:(OnHttpTaskProgressCallbackBlock)downloadProgressBlock {
    if (self = [super init]) {
        LOGD(@"%s %p", __FUNCTION__, self);
        self.engine = env;
        self.request = request;
        self.dispatch_queue = queue;
        self.taskId = taskId;
        self.callbackBlock = block;
        NSAssert(block != nil, @"callback shoud not be null");
        self.uploadProgressBlock = uploadProgressBlock;
        self.downloadProgressBlock = downloadProgressBlock;

        self.enableHttpCache = enableHttpCache;
        self.enableCustomizedCookie = NO;
        self.acceptableStatusCodes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];

        self.taskType = TTNET_TASK_TYPE_DEFAULT;
        self.forceRun = NO;
        self.uploadFileOffset = 0;
        self.uploadFileLength = UINT64_MAX;
        self.delayTimeMills = -1;
        is_task_resumed = false;
        
        self.originalHost = @"";
        self.dispatchedHost = @"";
        self.dispatchTime = -1;
        
        if (self.downloadProgressBlock) {
            self.downloadProgressCallbackQueue = dispatch_queue_create("download progress callback queue", DISPATCH_QUEUE_SERIAL);
        }
        
        self.isWebviewRequest = NO;
        self.loadFlags = 0;
#ifdef LEAK_DEBUG
        addToLeakMap(self);
#endif
    }
    return self;
}

- (void)dealloc {
    LOGD(@"+*+*+*%s %p", __FUNCTION__, self);
#ifdef LEAK_DEBUG
    removeFromLeakMap(self);
#endif
}

- (void)cancel {
    LOGD(@"%s %p", __FUNCTION__, self);
    if (![[TTRequestDispatcher shareInstance] onHttpTaskCancel:self]) {
        return;
    }
    self.isCancelled = YES;

    if (fetcher_delegate) {
        fetcher_delegate->Cancel();
    }
}

- (void)startRedirect {
    if (self.isCancelled == YES || !self.redirectTask) {
        return;
    }

    if (fetcher_delegate) {
        fetcher_delegate->StartRedirect();
    }
}

- (void)suspend {
    //not supported
    //LOGI(@"%s is not supported in chromium implementation.", __FUNCTION__);
}

- (int32_t)getDelayTimeWithUrl:(NSString*)originalUrl requestTag:(NSString*)requestTag {
    TTNetworkManagerChromium *networkManager = (TTNetworkManagerChromium *)[TTNetworkManager shareInstance];
    if (![networkManager ensureEngineStarted]) {
        TTURLDispatch *dispatch = [[TTURLDispatch alloc] initWithUrl:originalUrl requestTag:requestTag];
        [dispatch doDelay];
        [dispatch delayAwait];
        
        return [dispatch delayTimeMils];
    }
    
    return -1;
}

- (void)resume {
    // NOTICE: TTRequestDispatcher onHttpTaskResume MUST be called first.
    if (![[TTRequestDispatcher shareInstance] onHttpTaskResume:self]) {
        return;
    }

    // If the task has resumed, it returns directly.
    if (is_task_resumed) {
        LOGE(@"Currently reuse of previous task is not supported.");
        return;
    }

    // The first resume is expected to be the original state.
    bool expect_value = false;
    // If it is the first time to resume, it is set to resume.
    bool set_value = true;
    if (!is_task_resumed.compare_exchange_strong(expect_value, set_value)) {
        LOGE(@"Currently reuse of previous task is not supported-Multi.");
        return;
    }

    self.request.pureRequest = [self.request.allHTTPHeaderFields[kPureRequestControlHeaderKey] isEqual: @"1"];
    NSDictionary* pureHeaders = nil;
    if (self.request.pureRequest) {
        pureHeaders = [[self.request allHTTPHeaderFields] copy];
    }
    
    // Request Filter
    if ([TTNetworkManager shareInstance].requestFilterBlock) {
        [TTNetworkManager shareInstance].requestFilterBlock(self.request);
    }
    
    [[TTReqFilterManager shareInstance] runRequestFilter:self.request];
    
    if (self.request.pureRequest) {
        [self.request setAllHTTPHeaderFields:pureHeaders];
    }
    
    // Monitor request
    [[TTNetworkManagerMonitorNotifier defaultNotifier] notifyForMonitorStartRequest:self.request hasTriedTimes:0];
    
    self.isCancelled = NO;

    GURL url(base::SysNSStringToUTF8(self.request.urlString));
    if (!url.is_valid()) {
        LOGE(@"the url string is malformed: %@", self.request.urlString);
        NSDictionary *userInfo = @{kTTNetSubErrorCode : @(NSURLErrorBadURL),
                                   NSLocalizedDescriptionKey : @"the url is malformed",
                                   NSURLErrorFailingURLStringErrorKey : self.request.urlString ?  self.request.urlString  : @"Nil"};

        NSError *error = [NSError errorWithDomain:kTTNetworkErrorDomain code:NSURLErrorBadURL userInfo:userInfo];
        self.isCompleted = YES;
        [[TTRequestDispatcher shareInstance] onHttpTaskFinish:self];
        self.callbackBlock(nil, nil, error);
        return;
    }
    
    NSString *needDrop = [self.request.allHTTPHeaderFields valueForKey:kTTNetNeedDropClientRequest];
    if (needDrop && [needDrop isEqualToString:@"1"]) {
        LOGE(@"Client request is dropped by user added header [cli_need_drop_request: 1]");
        NSDictionary *userInfo = @{kTTNetSubErrorCode : @(TTNetworkErrorCodeDropClientRequest),
                                   NSLocalizedDescriptionKey : @"Client request is dropped by user added header [cli_need_drop_request: 1]",
                                   NSURLErrorFailingURLStringErrorKey : self.request.urlString ?  self.request.urlString  : @"Nil"};
        
        NSError *error = [NSError errorWithDomain:kTTNetworkErrorDomain code:TTNetworkErrorCodeDropClientRequest userInfo:userInfo];
        self.isCompleted = YES;
        [[TTRequestDispatcher shareInstance] onHttpTaskFinish:self];
        self.callbackBlock(nil, nil, error);
        return;
    }
    

    if ([[TTNetworkManager shareInstance] isKindOfClass:[TTNetworkManagerChromium class]]) {
        TTNetworkManagerChromium *ttnetworkManager = (TTNetworkManagerChromium *)[TTNetworkManager shareInstance];
        if ([ttnetworkManager ensureEngineStarted]) {
            LOGE(@"ensureEngineStarted failed 1");
            NSDictionary *userInfo = @{kTTNetSubErrorCode : @(TTNetworkErrorCodeIllegalClientState),
                                       NSLocalizedDescriptionKey : @"ensureEngineStarted failed 1",
                                       NSURLErrorFailingURLStringErrorKey : self.request.urlString ?  self.request.urlString  : @"Nil"};
            NSError *resultError =  [NSError errorWithDomain:kTTNetworkErrorDomain code:TTNetworkErrorCodeIllegalClientState userInfo:userInfo];
            self.isCompleted = YES;
            [[TTRequestDispatcher shareInstance] onHttpTaskFinish:self];
            self.callbackBlock(nil, nil, resultError);
            return;
        }

      if (!self.engine) {
        self.engine = (cronet::CronetEnvironment *)ttnetworkManager.getEngine;
      }

      if (!self.engine || !self.engine->GetURLRequestContextGetter() || !self.engine->GetURLRequestContextGetter()->GetNetworkTaskRunner()) {
        LOGE(@"ensureEngineStarted failed 2");
        NSDictionary *userInfo = @{kTTNetSubErrorCode : @(TTNetworkErrorCodeIllegalClientState),
                                   NSLocalizedDescriptionKey : @"ensureEngineStarted failed 2",
                                   NSURLErrorFailingURLStringErrorKey : self.request.urlString ?  self.request.urlString  : @"Nil"};
        NSError *resultError =  [NSError errorWithDomain:kTTNetworkErrorDomain code:TTNetworkErrorCodeIllegalClientState userInfo:userInfo];
        self.isCompleted = YES;
        [[TTRequestDispatcher shareInstance] onHttpTaskFinish:self];
        self.callbackBlock(nil, nil, resultError);
        return;
      }
    }

    //query filter engine
    //after all requestFilter, before start
    LOGD(@"the url string before query filter engine: %@", self.request.urlString);
    TICK;
    if (!self.isWebviewRequest) {
        NSDate *startTime = [NSDate date];
        self.request.urlString = [[QueryFilterEngine shareInstance] filterQuery:self.request];
        NSNumber *elapsedTime = [NSNumber numberWithDouble:(-[startTime timeIntervalSinceNow]) * 1000];
        [self.request.filterObjectsTimeInfo setValue:elapsedTime forKey:kTTNetQueryFilterTimingInfoKey];
    }
    TOCK;
    LOGD(@"the url string after query filter engine: %@", self.request.urlString);
    
    // Get delay time for current http task.
    if (net::ConfigManager::GetInstance()->IsRequestDelayEnabled()) {
        NSString *requestTag = [self.request.allHTTPHeaderFields valueForKey:kTTNetRequestTagHeaderName];
        self.delayTimeMills = [self getDelayTimeWithUrl:self.request.urlString requestTag:requestTag];
    }
    
    if (self.isStreamingTask) {
        fetcher_delegate = new TTFetcherDelegateForStreamTask(self, self.engine);
        fetcher_delegate->CreateURLFetcher();
    } else {
        fetcher_delegate = new TTFetcherDelegateForCommonTask(self, self.engine, (self.dataBlock != nil));
        fetcher_delegate->CreateURLFetcher();
    }
    if (self.throttleNetBytesPerSecond > 0) {
        fetcher_delegate->SetThrottleNetSpeed(self.throttleNetBytesPerSecond);
    }
}

- (void)setThrottleNetSpeed:(int64_t)bytesPerSecond {
    self.throttleNetBytesPerSecond = bytesPerSecond;
    if (fetcher_delegate) {
        fetcher_delegate->SetThrottleNetSpeed(bytesPerSecond);
    }
}

- (void)setPriority:(float)priority {
    self.taskPriority = priority;
}

- (void)setHeaderCallback:(OnHttpTaskHeaderCallbackBlock)headerCallback {
    self.headerBlock = headerCallback;
}

- (TTHttpTaskState)state {
    //NSLog(@"%s TTHttpTaskStateSuspended is not supported in chromium implementation.", __FUNCTION__);
    TTHttpTaskState state = TTHttpTaskStateRunning;
    if (self.isCancelled) {
        state = TTHttpTaskStateCanceling;
    } else if (self.isCompleted) {
        state = TTHttpTaskStateCompleted;
    }

    return state;
}

#pragma mark - TTFetcherProtocol implementation

- (void)onURLFetchComplete:(const net::URLFetcher*)source {
    TTHttpResponseChromium *response = [[TTHttpResponseChromium alloc] initWithURLFetcher:source];
    if (self.compressLog) {
        [response appendRequestLogWithCompressLog:self.compressLog];
    }
    LOGD(@"%p done http request: %@", self, self.request.urlString);

    NSError *responseError = nil; // check this error
    NSData *responseData = nil;
    int error_num = source->GetError();
    if (error_num == net::ERR_ABORTED || error_num == net::ERR_IO_PENDING) {
        NSAssert(error_num != net::ERR_IO_PENDING, @"should not be IO_PENDING state!");

        LOGE(@"URLRequestStatus is in bad state.");
        NSString *request_log = @(source->GetRequestLog().c_str());
        NSDictionary *userInfo = @{kTTNetSubErrorCode : @(error_num),
                                   NSLocalizedDescriptionKey : [NSString stringWithFormat:@"the request was cancelled programatically, status: %d, error: %d, requestLog: %@",error_num,error_num,request_log],
                                   NSURLErrorFailingURLErrorKey : [response URL] ? [[response URL] absoluteString] : @"nil response URL"};

        responseError = [NSError errorWithDomain:kTTNetworkErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
    } else if (error_num != net::OK) {
        const auto &error_string = net::ErrorToShortString(error_num);

        NSDictionary *userInfo = @{kTTNetSubErrorCode : @(error_num),
                                   NSLocalizedDescriptionKey : @(error_string.c_str()),
                                   NSURLErrorFailingURLErrorKey : [response URL] ? [[response URL] absoluteString] : @"nil response URL"};

        responseError = [NSError errorWithDomain:kTTNetworkErrorDomain code:error_num userInfo:userInfo];
    } else { // status.status() == net::URLRequestStatus::SUCCESS
        // For chunked way response read, all data have been passed to client via the |dataBlock| callback.
        if (!self.dataBlock) {
            std::string responseStr;
            if (!source->GetResponseAsString(&responseStr)) {
                LOGW(@"Get response as string failed!");
            }
            const char *data = responseStr.c_str();
            responseData = [NSData dataWithBytes:data length:responseStr.length()];
            // Update store region from passport and device server response.
#ifndef OC_DISABLE_STORE_IDC
            [TTRegionManager updateStoreRegionConfigFromResponse:source responseBody:responseData url:self.request.URL];
#endif
        }

        // Check for the http response code correctness.
        if (self.acceptableStatusCodes && ![self.acceptableStatusCodes containsIndex:(NSUInteger)response.statusCode] && [response URL]) {
            LOGE(@"server response code is wrong, response code = %ld, url = %@", (long)response.statusCode, [response URL]);
            NSMutableDictionary *mutableUserInfo = [@{kTTNetSubErrorCode : @(response.statusCode),
                                                      NSLocalizedDescriptionKey : [NSString stringWithFormat:@"server response code (%ld) is not 2xx.", (long)response.statusCode],
                                                      NSURLErrorFailingURLErrorKey :[[response URL] absoluteString],
                                                      @"com.alamofire.serialization.response.error.response" : response,
                                                      } mutableCopy];
            if (responseData) {
                mutableUserInfo[@"responseData"] = responseData;
            }

            responseError = [NSError errorWithDomain:kTTNetworkErrorDomain code:NSURLErrorBadServerResponse userInfo:mutableUserInfo];
        } else {
            if (self.fileDestinationURL) {
                fetcher_delegate->GetResponseAsFilePathFromFetcher();
            }
        }
    }

    // Free fetcher here in case of fetcher delegate destruction is executed on |dispatch_queue|.
    // If we free fetcher after this function in OnURLFetchComplete(), there could be a race.
    fetcher_delegate->FreeFetcher();

    dispatch_queue_t callbackBlockDispatchQueue = self.dispatch_queue;
    if (response.statusCode == 200 && [[response allHeaderFields] objectForKey:kTTNetBDTuringVerify]) {
        if (!((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).concurrent_dispatch_queue) {
            ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).concurrent_dispatch_queue = dispatch_queue_create("ttnet_response_queue", DISPATCH_QUEUE_CONCURRENT);
        }
        callbackBlockDispatchQueue = ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).concurrent_dispatch_queue;
    }
    __weak typeof(self) wself = self;
    dispatch_async(callbackBlockDispatchQueue, ^(void) {
        __strong typeof(wself) sself = wself;
        if (sself) {
            sself.isCompleted = YES;
            [[TTRequestDispatcher shareInstance] onHttpTaskFinish:sself];
            sself.callbackBlock(response, responseData, responseError);
        }
    });
}

- (void)onURLFetchDownloadProgress:(const net::URLFetcher*)fetcher
                           current:(int64_t)current
                             total:(int64_t)total
             current_network_bytes:(int64_t)current_network_bytes {
   // LOGD(@"OnURLFetchDownloadProgress, current = %lld, total = %lld, current_netwrok_bytes = %lld", current, total , current_network_bytes);
    if (!self.downloadProgressBlock) {
        return;
    }
    if (!self.downloadProgressCallbackQueue) {
        self.downloadProgressCallbackQueue = dispatch_get_main_queue();
    }
    __weak typeof(self) wself = self;
    dispatch_async(self.downloadProgressCallbackQueue, ^(void) {
        __strong typeof(wself) sself = wself;
        if (sself && sself.downloadProgressBlock) {
            sself.downloadProgressBlock(current, total);
        }
    });
}

- (void)onURLFetchUploadProgress:(const net::URLFetcher*)fetcher
                         current:(int64_t)current
                           total:(int64_t)total {
    // LOGD(@"OnURLFetchUploadProgress, current = %lld, total = %lld", current, total);
    if (!self.uploadProgressBlock) {
        return;
    }
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        __strong typeof(wself) sself = wself;
        if (sself && sself.uploadProgressBlock) {
            sself.uploadProgressBlock(current, total);
        }
    });
}

- (void)onURLRedirectReceived:(const net::URLFetcher*)source
                redirect_info:(const net::RedirectInfo&)redirect_info
                response_info:(const net::HttpResponseInfo&) response_info {
    //LOGD(@"onURLRedirectReceived, new_location = %@", new_location);
    if (!self.redirectedBlock && !redirect_info.is_defer_redirect) {
        return;
    }

    NSString *new_location = base::SysUTF8ToNSString(redirect_info.new_url.spec());
    NSString *original_url = base::SysUTF8ToNSString(source->GetOriginalURL().spec());

    if (self.redirectedBlock) {
        int status_code = redirect_info.status_code;

        TTCaseInsenstiveDictionary *response_headers = [[TTCaseInsenstiveDictionary alloc] init];
        const net::HttpResponseHeaders* headers = response_info.headers.get();
        // Returns an empty map if |headers| is nullptr.
        if (!headers) {
            size_t iter = 0;
            std::string header_name;
            std::string header_value;
            while (headers->EnumerateHeaderLines(&iter, &header_name, &header_value)) {
                response_headers[base::SysUTF8ToNSString(header_name)] = base::SysUTF8ToNSString(header_value);
            }
        }

        TTHttpResponseChromium *response = [[TTHttpResponseChromium alloc] initWithRedirectedInfo:original_url
                                                                                     new_location:new_location
                                                                                      status_code:status_code
                                                                                 response_headers:response_headers
                                                                             is_internal_redirect:redirect_info.is_internal_redirect];

        self.redirectedBlock(new_location, response);
    }

    if (redirect_info.is_defer_redirect) {
        NSString *extra_header = base::SysUTF8ToNSString(redirect_info.request_header_str);
        self.redirectTask = [[TTRedirectTask alloc] initWithHttpTask:self
                                                         httpHeaders:extra_header
                                                         originalUrl:original_url
                                                         redirectUrl:new_location];

        __weak typeof(self) wself = self;
        dispatch_async(self.dispatch_queue, ^(void) {
            __strong typeof(wself) sself = wself;
            if (sself) {
                [[TTReqFilterManager shareInstance] runRedirectFilter:self.redirectTask request:self.request];
                [sself startRedirect];
            }
        });
    }
}

- (void)onTimeout:(int)status error:(int)error details:(NSString *)details requestLog:(NSString *)requestLog {
    TTHttpResponseChromium *response = [[TTHttpResponseChromium alloc] initWithRequestLog:requestLog];
    if (self.compressLog) {
        [response appendRequestLogWithCompressLog:self.compressLog];
    }

    __weak typeof(self) wself = self;
    dispatch_async(self.dispatch_queue, ^(void) {
        __strong typeof(wself) sself = wself;

        if (sself) {
            sself.isCompleted = YES;
            NSDictionary *userInfo = @{kTTNetSubErrorCode : @(NSURLErrorTimedOut),
                                       NSLocalizedDescriptionKey : [NSString stringWithFormat:@"the request was timeout, status: %d, error: %d, requestLog: %@", status, error, requestLog],
                                       NSURLErrorFailingURLErrorKey : [response URL] ? [[response URL] absoluteString] : @"nil response URL"};
            
            NSError *error = [NSError errorWithDomain:kTTNetworkErrorDomain code:NSURLErrorTimedOut userInfo:userInfo];
            [[TTRequestDispatcher shareInstance] onHttpTaskFinish:sself];
            sself.callbackBlock(response, nil, error);
        }
    });
}

- (void)onCancel:(NSString *)requestLog {
    TTHttpResponseChromium *response = [[TTHttpResponseChromium alloc] initWithRequestLog:requestLog];
    if (self.compressLog) {
        [response appendRequestLogWithCompressLog:self.compressLog];
    }

    __weak typeof(self) wself = self;
    dispatch_async(self.dispatch_queue, ^(void) {
        __strong typeof(wself) sself = wself;
        
        if (sself) {
            NSDictionary *userInfo = @{kTTNetSubErrorCode : @(NSURLErrorCancelled),
                                       NSLocalizedDescriptionKey : @"the request was cancelled",
                                       NSURLErrorFailingURLErrorKey : [response URL] ? [[response URL] absoluteString] : @"nil response URL"};
            NSError *error = [NSError errorWithDomain:kTTNetworkErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
            [[TTRequestDispatcher shareInstance] onHttpTaskFinish:sself];
            sself.callbackBlock(response, nil, error);
        }
    });
}

- (void)onResponseStarted:(const net::URLFetcher *)fetcher {
    TTHttpResponseChromium *response = [[TTHttpResponseChromium alloc] initWithURLFetcher:fetcher];
    __weak typeof(self) wself = self;
    dispatch_async(self.dispatch_queue, ^(void) {
        __strong typeof(wself) sself = wself;
        if (sself) {
            sself.headerBlock(response);
        }
    });
}

- (void)onReadResponseData:(NSData*)data {
    __weak typeof(self) wself = self;
    dispatch_async(self.dispatch_queue, ^(void) {
        __strong typeof(wself) sself = wself;
        if (sself) {
            sself.dataBlock(data);
        }
    });
}

// the function must be called before the resume()
- (void)setFetcherPriority_:(net::URLFetcher*)fetcher {
    if (self.taskPriority > 0) {
        LOGD(@"%s set the task priorty = %f", __FUNCTION__, self.taskPriority);
        net::RequestPriority priorty = net::DEFAULT_PRIORITY;
        if (self.taskPriority <= 0.15) {
            priorty = net::LOWEST;
        } else if (self.taskPriority <= 0.25) {
            priorty = net::DEFAULT_PRIORITY; // same as net::LOWEST
        } else if (self.taskPriority <= 0.5) {
            priorty = net::LOW;
        } else if (self.taskPriority <= 0.75) {
            priorty = net::MEDIUM;
        } else {
            priorty = net::HIGHEST;
        }

        fetcher->SetPriority(priorty);
    }
}

- (void)readDataOfMinLength:(NSUInteger)minBytes
                  maxLength:(NSUInteger)maxBytes
                    timeout:(NSTimeInterval)timeout
          completionHandler:(OnStreamReadCompleteBlock)completionHandler {
    if (!self.isStreamingTask) {
        @throw [NSException exceptionWithName:@"OperationNotSupportedExcecption"
                                       reason:@"Current task in not working in stream mode."
                                     userInfo:nil];
    }
    
    if (!fetcher_delegate) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Task is not resumed."
                                     userInfo:nil];
    }
    
    self.streamReadCompleteBlock = completionHandler;
    
    OnStreamReadCompleteBlock appLevelCompletionCallback = ^(NSData *data, BOOL isEOF, NSError *error, TTHttpResponse *response) {
        __weak typeof(self) wself = self;
        dispatch_async(self.dispatch_queue, ^(void) {
            __strong typeof(wself) sself = wself;
            if (sself) {
                sself.streamReadCompleteBlock(data, isEOF, error, response);
            }
        });
    };
    
    int minReadLimit = minBytes > INT_MAX ? INT_MAX : static_cast<int>(minBytes);
    int maxReadLimit = maxBytes > INT_MAX ? INT_MAX : static_cast<int>(maxBytes);
    fetcher_delegate->ReadDataWithLength(minReadLimit, maxReadLimit, timeout, appLevelCompletionCallback);
}

- (void)setUploadProgressCallback:(OnHttpTaskProgressCallbackBlock)uploadProgressCallback {
    self.uploadProgressBlock = uploadProgressCallback;
}

- (void)setDownloadProgressCallback:(OnHttpTaskProgressCallbackBlock)downloadProgressCallback {
    self.downloadProgressBlock = downloadProgressCallback;
}

@end
