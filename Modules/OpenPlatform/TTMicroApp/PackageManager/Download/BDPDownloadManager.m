//
//  BDPDownloadManager.m
//  Timor
//
//  Created by 傅翔 on 2019/1/22.
//

#import "BDPDownloadManager.h"
#import <OPFoundation/BDPMacroUtils.h>
#import "BDPHttpDownloadTask.h"
#import <ECOInfra/NSURLSession+TMA.h>
#import <ECOInfra/BDPLog.h>

#define LOCK_BLK(...) dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);\
__VA_ARGS__;\
dispatch_semaphore_signal(self.lock)

@interface BDPDownloadTaskDelegate : NSObject

@property (nonatomic, copy) BDPDownloadReceivedDataBlk receivedDataBlk;
@property (nonatomic, copy) BDPDownloadCompletedBlk completedBlk;
@property (nonatomic, strong) BDPRequestMetrics *metrics;

@end

@implementation BDPDownloadTaskDelegate
@end


@interface BDPDownloadManager () <NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMapTable<id, BDPDownloadTaskDelegate *> *delegates;
@property (nonatomic, strong) dispatch_semaphore_t lock;

@end

@implementation BDPDownloadManager

#pragma mark -
+ (instancetype)managerWithSessionConfiguration:(NSURLSessionConfiguration *)config
                               andDelegateQueue:(NSOperationQueue *)queue {
    BDPDownloadManager *manager = [[self alloc] init];
    manager.lock = dispatch_semaphore_create(1);
    manager.session = [NSURLSession sessionWithConfiguration:config ?: [NSURLSessionConfiguration defaultSessionConfiguration]
                                                    delegate:manager
                                               delegateQueue:queue];
    return manager;
}

#pragma mark - Public
- (BDPHttpDownloadTask *)taskWithRequest:(NSURLRequest *)request
                          receivedDataBlk:(BDPDownloadReceivedDataBlk)recvDataBlk
                             completedBlk:(BDPDownloadCompletedBlk)completedBlk
                                   trace:(BDPTracing *)trace {
    if (!request) {
        return nil;
    }

    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request eventName:@"pkg_download" requestTracing:trace];
    BDPDownloadTaskDelegate *taskDelegate = [[BDPDownloadTaskDelegate alloc] init];
    taskDelegate.receivedDataBlk = recvDataBlk;
    taskDelegate.completedBlk = completedBlk;
    
    BDPHttpDownloadTask *bdpTask = [[BDPHttpDownloadTask alloc] init];
    bdpTask.nsTask = task;
    
    [self addTask:task andDelegate:taskDelegate];
    
    return bdpTask;
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    BDPDownloadTaskDelegate *delegate = [self delegateForTask:dataTask];
    if (!delegate.receivedDataBlk) {
        return;
    }
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)dataTask.response;
    BLOCK_EXEC(delegate.receivedDataBlk,
               data,
               dataTask.countOfBytesReceived,
               dataTask.countOfBytesExpectedToReceive,
               response.statusCode);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    BDPDownloadTaskDelegate *delegate = [self delegateForTask:task];
    BDPLogInfo(@"BDPDownloadManager didCompleteWithError, URL: %@, delegate: %@, error: %@", task.originalRequest.URL.absoluteString, delegate, error);
    BLOCK_EXEC(delegate.completedBlk, error, delegate.metrics);
    [self removeDelegateForTask:task];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics  API_AVAILABLE(ios(10.0)) {
    BDPDownloadTaskDelegate *delegate = [self delegateForTask:task];
    delegate.metrics = [BDPRequestMetrics metricsFromTransactionMetrics:metrics.transactionMetrics.firstObject];
}

#pragma mark - Task Manage
- (BDPDownloadTaskDelegate *)delegateForTask:(id)task {
    __block BDPDownloadTaskDelegate *delegate = nil;
    LOCK_BLK({
        delegate = [self.delegates objectForKey:task];
    });
    return delegate;
}

- (void)addTask:(id)task andDelegate:(BDPDownloadTaskDelegate *)delegate {
    LOCK_BLK({
        if (!self.delegates) {
            self.delegates = [NSMapTable strongToStrongObjectsMapTable];
        }
        [self.delegates setObject:delegate forKey:task];
    });
}

- (void)removeDelegateForTask:(id)task {
    LOCK_BLK({
        [self.delegates removeObjectForKey:task];
    });
}

#pragma mark - Accessor
- (NSArray<NSURLSessionDownloadTask *> *)tasks {
    __block NSArray *tasks = nil;
    dispatch_semaphore_t lock = dispatch_semaphore_create(0);
    [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        tasks = dataTasks;
        dispatch_semaphore_signal(lock);
    }];
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    return tasks;
}

@end



