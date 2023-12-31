//
//  TTHttpTask.h
//  Pods
//
//  Created by gaohaidong on 9/22/16.
//
//

#import <Foundation/Foundation.h>

#import "TTHttpResponse.h"
#import "TTHttpRequest.h"
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, TTHttpTaskState) {
    TTHttpTaskStateRunning   = 0,
    TTHttpTaskStateSuspended = 1,
    TTHttpTaskStateCanceling = 2,
    TTHttpTaskStateCompleted = 3,
};

typedef NS_ENUM(uint32_t, TTNetRequestType) {
    TTNetRequestTypeNormal = 0,
    TTNetRequestTypeWebViewRequest = 1 << 0,
    //placeholder, only available on android
    //TTNetRequestTypeDoNotSendCookie = 1 << 1,
    TTNetRequestTypeEnableEarlyData = 1 << 2,
    TTNetRequestTypeDownloadRequest = 1 << 3,
};

typedef void (^OnHttpTaskHeaderCallbackBlock)(TTHttpResponse * _Nonnull response);
typedef void (^OnHttpTaskProgressCallbackBlock)(int64_t current, int64_t total);

@interface TTHttpTask : NSObject

/*
 * The current state of the task.
 */
@property (readonly) TTHttpTaskState state;

/*
 * Set the timeout for detailed phases of a request.
 * They are effective only when corresponding callback is used
 * to initiate a request. This currently only supported in Chromium
 * implementation.
 */
@property (nonatomic, assign) NSTimeInterval recvHeaderTimeout;
@property (nonatomic, assign) NSTimeInterval readDataTimeout;

/*
 * Set the request protect timeout for per task request.
 * TTNet will cancel the request when duration of request has reached
 * the protectTimeout. unit: seconds.
 * ONLY effective in Chromium implementation.
 */
@property (nonatomic, assign) NSTimeInterval protectTimeout;

/*
 * Set the timeout for per task request.
 * NOTE: this value overwrite the request's timeoutInteval if both exist.
 * ONLY effective in Chromium implementation.
 */
@property (assign) NSTimeInterval timeoutInterval;

/*
 * YES to skip the ssl certificate error.
 * ONLY effective in Chromium implementation.
 */
@property (assign) BOOL skipSSLCertificateError;

/*
 * YES means task working in stream mode. Call readDataOfMinLength to
 * retreive data.
 * ONLY effective in Chromium implementation.
 */
@property (assign) BOOL isStreamingTask;

/**
 * Set cronet http cache.
 * YES : open the current task cronet Http Cache.
 * NO : close the current task cronet Http Cache.
 */
@property (nonatomic, assign) BOOL enableHttpCache;

/**
 *Set customized cookie, autoResume MUST set to NO when generate task
 *YES: send cookie with customized Cookie header, bypass NSHTTPCookieStorage
 *NO: send NSHTTPCookieStorage
 */
@property (nonatomic, assign) BOOL enableCustomizedCookie;

/**
 *User can set load flag for each request
 */
@property (assign) NSInteger loadFlags;

/**
 * flags to indicat the request type.
 */
@property (assign) TTNetRequestType requestTypeFlags;

/**
 @brief  ConcurrentRequest may use dispatch interface.
 */
@property (nonatomic, copy) NSString* originalHost;
@property (nonatomic, copy) NSString* dispatchedHost;
@property (nonatomic, assign) NSTimeInterval dispatchTime;
@property (nonatomic, assign) BOOL sentAlready;

/**
  @brief cancel returns immediately and invoke callback with NSURLErrorCancelled error.
 */
- (void)cancel;

/**
  @brief not supported
 */
- (void)suspend;
- (void)resume;

- (void)setThrottleNetSpeed:(int64_t)bytesPerSecond;

- (void)setHeaderCallback:(OnHttpTaskHeaderCallbackBlock)headerCallback;

- (void)setUploadProgressCallback:(OnHttpTaskProgressCallbackBlock)uploadProgressCallback;

- (void)setDownloadProgressCallback:(OnHttpTaskProgressCallbackBlock)downloadProgressCallback;

/*
 * Sets a scaling factor for the priority of the task. The scaling factor is a
 * value between 0.0 and 1.0 (inclusive), where 0.0 is considered the lowest
 * priority and 1.0 is considered the highest.
 *
 * The priority is a hint and not a hard requirement of task performance. The
 * priority of a task may be changed using this API at any time, but not all
 * protocols support this; in these cases, the last priority that took effect
 * will be used.
 *
 * If no priority is specified, the task will operate with the default priority
 * as defined by the constant NSURLSessionTaskPriorityDefault. Two additional
 * priority levels are provided: NSURLSessionTaskPriorityLow and
 * NSURLSessionTaskPriorityHigh, but use is not restricted to these.
 */
- (void)setPriority:(float)priority;

/**
 *  （Actively）Read response from a task.
 *  Only supported by stream mode task in Chromium kernel, otherwise exception will be thrown.
 *  Use requestForBinaryWithStreamTaskTask will set the task mode into stream mode automatically.
 *
 *  @param minBytes                Least bytes of response in callback(>)
 *  @param maxBytes                Max bytes of response in callback(<=)，note that maxBytes will influence the buffer in iOS layer
 *  @param timeout                 Timeout of the callback
 *  @param completionHandler       Callback when data is read.
 */
- (void)readDataOfMinLength:(NSUInteger)minBytes
                  maxLength:(NSUInteger)maxBytes
                    timeout:(NSTimeInterval)timeout
          completionHandler:(void (^)(NSData *data, BOOL atEOF, NSError *error, TTHttpResponse *response))completionHandler;

/**
 *get request in task
 *so that user can task action on this request, such as set customized headers
 *autoResume must set to NO when get task, and call [task resume] to start network task after this
 */
- (TTHttpRequest *)request;

@end
NS_ASSUME_NONNULL_END
