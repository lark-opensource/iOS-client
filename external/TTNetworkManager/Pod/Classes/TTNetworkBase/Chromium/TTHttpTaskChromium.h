//
//  TTHttpTaskChromium.h
//  Pods
//
//  Created by gaohaidong on 11/16/16.
//
//

#import <Foundation/Foundation.h>
#import "TTHttpTask.h"
#import "TTHttpRequestChromium.h"
#import "TTHttpResponseChromium.h"

#include <memory>

#include "net/url_request/url_fetcher.h"
#include "net/url_request/url_fetcher_delegate.h"
#include "base/timer/timer.h"

@protocol TTFetcherProtocol <NSObject>

- (void)onURLFetchComplete:(const net::URLFetcher*)fetcher;
- (void)onURLFetchDownloadProgress:(const net::URLFetcher*)fetcher
                           current:(int64_t)current
                             total:(int64_t)total
             current_network_bytes:(int64_t)current_network_bytes;
- (void)onURLFetchUploadProgress:(const net::URLFetcher*)fetcher
                         current:(int64_t)current
                           total:(int64_t)total;

- (void)onResponseStarted:(const net::URLFetcher*)fetcher;

- (void)onURLRedirectReceived:(const net::URLFetcher*)source
                redirect_info:(const net::RedirectInfo&)redirect_info
                response_info:(const net::HttpResponseInfo&) response_info;

- (void)onReadResponseData:(NSData*) data;

- (void)onTimeout:(int)status error:(int)error details:(NSString *)details requestLog:(NSString *)requestLog;
- (void)onCancel:(NSString *)requestLog;

@end

typedef void (^OnHttpTaskCompletedCallbackBlock)(TTHttpResponseChromium *response, id data, NSError *responseError);

typedef void (^OnHttpTaskHeaderReadCompletedCallbackBlock)(TTHttpResponseChromium *response);
typedef void (^OnHttpTaskDataReadCompletedCallbackBlock)(NSData* data);

typedef void (^OnHttpTaskURLRedirectedCallbackBlock)(NSString *new_location, TTHttpResponse *old_repsonse);

typedef void (^OnStreamReadCompleteBlock)(NSData *, BOOL, NSError *, TTHttpResponse *);

namespace cronet {
    class CronetEnvironment;
}
class TTFetcherDelegate;

#define TTNET_TASK_TYPE_DEFAULT 0
#define TTNET_TASK_TYPE_API 1
#define TTNET_TASK_TYPE_DOWNLOAD 2

@class TTRedirectTask;

@interface TTHttpTaskChromium : TTHttpTask<TTFetcherProtocol> {
    scoped_refptr<TTFetcherDelegate> fetcher_delegate;
    std::atomic<bool> is_task_resumed;
}

@property (nonatomic, strong) TTRedirectTask *redirectTask;

@property (nonatomic, strong) NSURL *fileDestinationURL;
@property (nonatomic, assign) BOOL isFileAppend;
@property (nonatomic, assign) uint64_t uploadFileOffset;
@property (nonatomic, assign) uint64_t uploadFileLength;
@property (nonatomic, assign) cronet::CronetEnvironment *engine;
@property (nonatomic, strong) TTHttpRequestChromium *request;

@property (nonatomic, assign) UInt64 taskId;

@property (nonatomic, copy) OnHttpTaskCompletedCallbackBlock callbackBlock;
@property (nonatomic, copy) OnHttpTaskProgressCallbackBlock uploadProgressBlock;
@property (nonatomic, copy) OnHttpTaskProgressCallbackBlock downloadProgressBlock;

@property (nonatomic, assign) float taskPriority;
@property (nonatomic, assign) BOOL isCancelled;
@property (nonatomic, assign) BOOL isCompleted;
@property (atomic, assign) int64_t throttleNetBytesPerSecond;

@property (nonatomic, assign) int taskType;
@property (nonatomic, assign) BOOL forceRun;

#ifndef DISABLE_REQ_LEVEL_CTRL
/*!
 @Brief Request Level which get from TTNetRequestLevelController.
        If level == 0, request can pass controller.
        If level == 1, request may wait p0 requests done.
        If level == 2, request will be canceled by controller.
 */
@property (nonatomic, assign) int level;
#endif

@property (nonatomic, strong) NSMutableIndexSet *acceptableStatusCodes;

@property (nonatomic, strong) dispatch_queue_t dispatch_queue;

@property (nonatomic, copy) OnStreamReadCompleteBlock streamReadCompleteBlock;

@property (nonatomic, strong) NSProgress *uploadProgress;
@property (nonatomic, strong) NSProgress *downloadProgress;

@property (nonatomic, copy) OnHttpTaskHeaderReadCompletedCallbackBlock headerBlock;
@property (nonatomic, copy) OnHttpTaskDataReadCompletedCallbackBlock dataBlock;
@property (nonatomic, copy) OnHttpTaskURLRedirectedCallbackBlock redirectedBlock;
@property (nonatomic, assign) BOOL isWebviewRequest;
@property (nonatomic, assign) int32_t delayTimeMills;
@property (nonatomic, copy) NSString *compressLog;

- (void)startRedirect;

- (instancetype)initWithRequest:(TTHttpRequestChromium *)request
                         engine:(cronet::CronetEnvironment *)env
                  dispatchQueue:(dispatch_queue_t)queue
                         taskId:(UInt64)taskId
              completedCallback:(OnHttpTaskCompletedCallbackBlock)block;

- (instancetype)initWithRequest:(TTHttpRequestChromium *)request
                         engine:(cronet::CronetEnvironment *)env
                  dispatchQueue:(dispatch_queue_t)queue
                         taskId:(UInt64)taskId
              completedCallback:(OnHttpTaskCompletedCallbackBlock)block
         uploadProgressCallback:(OnHttpTaskProgressCallbackBlock)uploadProgressBlock
       downloadProgressCallback:(OnHttpTaskProgressCallbackBlock)downloadProgressBlock;

- (instancetype)initWithRequest:(TTHttpRequestChromium *)request
                         engine:(cronet::CronetEnvironment *)env
                  dispatchQueue:(dispatch_queue_t)queue
                         taskId:(UInt64)taskId
                enableHttpCache:(BOOL)enableHttpCache
              completedCallback:(OnHttpTaskCompletedCallbackBlock)block
         uploadProgressCallback:(OnHttpTaskProgressCallbackBlock)uploadProgressBlock
       downloadProgressCallback:(OnHttpTaskProgressCallbackBlock)downloadProgressBlock;

- (void)setFetcherPriority_:(net::URLFetcher*)fetcher;

- (void)setThrottleNetSpeed:(int64_t)bytesPerSecond;

- (int32_t)getDelayTimeWithUrl:(NSString*)originalUrl requestTag:(NSString*)requestTag;

@end

class TTFetcherDelegate : public net::URLFetcherDelegate,
                          public base::RefCountedThreadSafe<TTFetcherDelegate> {
 public:
    TTFetcherDelegate(__weak TTHttpTaskChromium *task, cronet::CronetEnvironment *engine);
    
    // Default implement for delegate methods:
    void OnTransactionAboutToStart(const net::URLFetcher* source,
                                   const std::string& url,
                                   net::HttpRequestHeaders* headers) override;
    bool SkipSSLCertificateError(net::URLRequest* request,
                                 const net::SSLInfo& ssl_info,
                                 bool fatal) override;
    
    void CreateURLFetcher();
    
    void Cancel();
    
    void SetThrottleNetSpeed(int64_t bytesPerSecond);

    void SetThrottleNetSpeedOnNetThread(int64_t bytesPerSecond);

    void GetResponseAsFilePathFromFetcher();
                              
    void FreeFetcher();
                              
    void StartRedirect();

    virtual void ReadDataWithLength(int minLength, int maxLength, double timeoutInSeconds, OnStreamReadCompleteBlock completionHandler);
                              
    virtual void OnTimeout();
                              
 protected:
    friend class base::RefCountedThreadSafe<TTFetcherDelegate>;
    ~TTFetcherDelegate() override;
    
    virtual void CreateURLFetcherOnNetThread();
                              
    virtual void CancelOnNetThread() = 0;

    virtual void StartRedirectOnNetThread();

    __weak TTHttpTaskChromium *task_;

    UInt64 taskId_;

    cronet::CronetEnvironment *engine_;
    
    std::unique_ptr<net::URLFetcher> fetcher_;
    
    bool is_complete_;
    
    std::unique_ptr<base::OneShotTimer> timeout_timer_;
    
    // This should be same with the |URLFetcher::delegate_task_runner_|, so
    // create this writer and URLFetcher instance in the same thread.
    scoped_refptr<base::SequencedTaskRunner> task_runner_;
    
    scoped_refptr<base::SequencedTaskRunner> file_task_runner_;
private:
    std::string CompressBodyOnNetThread(NSData *body);

    DISALLOW_COPY_AND_ASSIGN(TTFetcherDelegate);

};
