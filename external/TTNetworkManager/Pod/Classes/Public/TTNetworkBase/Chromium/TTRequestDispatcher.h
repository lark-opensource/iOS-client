//
//  TTRequestDispatcher.h
//  Pods
//
//  Created by changxing on 2020/10/10.
//

#import <Foundation/Foundation.h>

@class TTHttpTask;

@interface TTRequestDispatcher : NSObject

+ (instancetype)shareInstance;

/**
 *  MaxApiConcurrentCount for request dispatcher, default 8.
 */
@property (nonatomic, assign) int maxApiConcurrentCount;

/**
 *  MaxDownloadConcurrentCount for request dispatcher, default 8.
 */
@property (nonatomic, assign) int maxDownloadConcurrentCount;

/**
 *  The target request url.
 *  Uri Format: https://host/path
 */
@property (nonatomic, copy) NSString* targetUri;

/**
 *  The dependency request url，non thread safe，modification is not allowed.
 *  Uri Format: https://host/path
 */
@property (nonatomic, copy) NSArray<NSString *> *dependencyUri;

/**
 *  Delay timeout of dependent request, default 10 seconds.
 *  If the target request is not executed, the delay request in the delay queue will be executed.
 */
@property (nonatomic, assign) int dependencyTimeoutToStart;

/**
 *  Delay execution timing of dependent request.
 *  The default target request is executed after execution. If the setting value is 100,
 *  it indicates that the delay request is executed 100 ms after the target  request starts to execute.
 */
@property (nonatomic, assign) int dependencyExecuteTime;

/**
 *  Start request dispatcher.
 *  Limit the number of concurrent requests running at the same time.
 */
- (void)startRequestDispatcher;

/**
 *  Stop request dispatcher
 */
- (void)stopRequestDispatcher;

/**
 *  Start request dependency policy.
 */
- (void)startRequestDependency;

/**
 *  Stop request dependency policy.
 */
- (void)stopRequestDependency;

- (BOOL)isRequestDispatcherWorking;

/**
 *  Get the number of delayed requests, which is obtained after the target
 *  request is completed.
 *
 *  @return Number of delayed requests.
 */
- (NSUInteger)getDelayRequestCount;

- (BOOL)onHttpTaskResume:(TTHttpTask *)httpTask;

- (BOOL)onHttpTaskCancel:(TTHttpTask *)httpTask;

- (void)onHttpTaskFinish:(TTHttpTask *)httpTask;

@end
