//
//  BDPPkgDownloadManager.m
//  Timor
//
//  Created by 傅翔 on 2019/1/22.
//

#import "BDPPkgDownloadManager.h"
#import "BDPPkgDownloadTask.h"
#import "BDPAppLoadDefineHeader.h"
#import "BDPDownloadManager.h"

#import <OPFoundation/BDPSettingsManager.h>
#import <OPFoundation/BDPTracker.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import <OPFoundation/BDPNetworking.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPCommonMonitorHelper.h>
#import <OPFoundation/NSError+BDPExtension.h>
#import <OPSDK/OPSDK-Swift.h>

#define PRECONNECT_TIMEOUT 3
#define REQUEST_TIMEOUT 20

@interface BDPPkgDownloadManager ()

@property (nonatomic, strong) BDPDownloadManager *manager;
@property (nonatomic, strong) NSMutableDictionary<NSString *, BDPPkgDownloadTask *> *tasksDic;

@property (nonatomic, copy) NSSet<NSString *> *hostsAddGzipSet;

@end

@implementation BDPPkgDownloadManager

#pragma mark -
- (BOOL)hasDowloadForTaskID:(NSString *)taskID {
    if (BDPIsEmptyString(taskID)) {
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_download_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(@"taskID is empty")
        .flush();
        return NO;
    }
    return self.tasksDic[taskID] != nil;
}

- (BDPPkgDownloadTask *)startDownloadWithTaskID:(NSString *)taskID
                                        requestURLs:(NSArray<NSURL *> *)requestURLs
                                           priority:(float)priority
                                           uniqueId:(BDPUniqueID *)uniqueId
                                            addGzip:(BOOL)addGzip
                                      canDownloadBr:(BOOL)canDownloadBr
                                   taskDelegate:(id<BDPAppDownloadTaskDelegate>)taskDelegate
                                          trace:(BDPTracing *)trace {
    if (BDPIsEmptyString(taskID) || !requestURLs.count) {
        NSString *errorMessage = [NSString stringWithFormat:@"taskID(%@) or requestURLs(%@) is empty", taskID, requestURLs];
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_download_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(errorMessage)
        .flush();
        return nil;
    }
    if ([self hasDowloadForTaskID:taskID]) {
        NSString *errorMessage = [NSString stringWithFormat:@"downloader for taskID(%@) is exsit", taskID];
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_download_failed)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(errorMessage)
        .flush();
        return nil;
    }
    
    BDPPkgDownloadTask *task = [[BDPPkgDownloadTask alloc] init];
    task.taskID = taskID;
    task.delegate = taskDelegate;
    task.priority = priority;
    task.uniqueId = uniqueId;
    task.addGzip = addGzip;
    task.trace = trace;
    
    if (task.isDownloadBr) {
        task.isDownloadBr = ![BDPSettingsManager.sharedManager s_boolValueForKey:kBDPSTTPkgCompressDowngrade];
    }

    task.requestURLs = requestURLs;
    
    [self addTask:task];
    [self downloadTask:task];
    return task;
}

- (void)startDownloadWithTask:(BDPPkgDownloadTask *)task {
    if (!task.taskID) {
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_download_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(@"taskID is empty")
        .flush();
        return;
    }
    self.tasksDic[task.taskID] = task;
    [self downloadTask:task];
}

- (void)downloadTask:(BDPPkgDownloadTask *)task {
    [self innerDownloadWithTask:task];
}

- (void)handleReceivedData:(NSData *)data
                   forTask:(BDPPkgDownloadTask *)task
            withStatusCode:(NSUInteger)statusCode
             receivedBytes:(int64_t)receivedBytes
                totalBytes:(int64_t)totalBytes {
    id<BDPAppDownloadTaskDelegate> strongDelegate = task.delegate;
    if ([strongDelegate respondsToSelector:@selector(appDownloadTask:receivedData:receivedBytes:totalBytes:httpStatus:error:)]) {
        NSError *error = nil;
        if (statusCode / 200 != 1) {
            error = BDP_APP_LOAD_ERROR_TYPE_N(GDMonitorCodeAppLoad.url_request_error, @"response staus not 2xx", BDP_APP_LOAD_TYPE_PKG, @(statusCode));
        }
        data = [task decodeData:data];
        if (!data && task.isDownloadBr) {
            error = BDP_APP_LOAD_ERROR_TYPE_N(GDMonitorCodeAppLoad.pkg_br_decode_failed, @"br decode failed", BDP_APP_LOAD_TYPE_PKG, @(statusCode));
        }
        [strongDelegate appDownloadTask:task
                           receivedData:data
                          receivedBytes:receivedBytes
                             totalBytes:totalBytes
                             httpStatus:statusCode
                                  error:error];
    } else {
        [task stopTask];
    }
}

- (void)handleCompletionForTask:(BDPPkgDownloadTask *)task
                      withError:(NSError *)error
                        metrics:(BDPRequestMetrics *)metrics {
    [task recordEndTime];
    
    NSDate *beginDate = task.beginDate;
    NSDate *endDate = task.endDate;
    id<BDPAppDownloadTaskDelegate> strongDelegate = task.delegate;
    if (!error) {
        [self notifyDownloadTask:task didFinishedWithError:nil];
    } else {
        if (error.code == NSURLErrorCancelled) {
            if ([strongDelegate respondsToSelector:@selector(appDownloadTask:didCancelWithError:)]) {
                [strongDelegate appDownloadTask:task didCancelWithError:error];
            }
        } else {
            OPError *opError = [NSError configOPError:error
                                          monitorCode:GDMonitorCodeAppLoad.url_request_error
                                 useCustomDescription:YES
                                             userInfo:@{
                BDP_APP_LOAD_TYPE_KEY: BDP_APP_LOAD_TYPE_PKG,
                BDP_APP_HTTP_STATUS_KEY: @(task.downloadTask.statusCode)
            }];
            [self notifyDownloadTask:task didFinishedWithError:opError];
        }
    }
    if (metrics) {
        NSInteger duration = ([endDate timeIntervalSince1970] - [beginDate timeIntervalSince1970]) * 1000.0;
        [BDPTracker monitorService:@"mp_ttpkg_request_cost"
                            metric:@{
                                     @"duration": @(duration),
                                     @"dns": @(metrics.dns),
                                     @"tcp": @(metrics.tcp),
                                     @"ssl": @(metrics.ssl),
                                     @"send": @(metrics.send),
                                     @"wait": @(metrics.wait),
                                     @"recv": @(metrics.receive)
                                     }
                          category:@{
                                     @"reuseType": [NSNumber numberWithInt:metrics.reuseConnect],
                                     @"resultType": @(error ? 0 : 1),
                                     @"host": task.downloadTask.host ?: @"",
                                     @"httpStatus": @(task.downloadTask.statusCode),
                                     @"requestType": @(0)
                                     }
                             extra:@{
                                     @"errorCode": @(error.code),
                                     @"errorMsg": error.description ?: @""
                                     }
              uniqueID:task.uniqueId];
    }
}

- (void)innerDownloadWithTask:(BDPPkgDownloadTask *)task {
    int64_t rangeOffset = 0;
    id<BDPAppDownloadTaskDelegate> strongDelegate = task.delegate;
    if ([strongDelegate respondsToSelector:@selector(httpRangeOffsetForAppDownloadTask:)]) {
        rangeOffset = [strongDelegate httpRangeOffsetForAppDownloadTask:task];
    }
    if (rangeOffset > 0) {
        task.isDownloadBr = NO; // TODO: br不支持断点续传
    }
    BOOL addGzip = task.addGzip;
    if (task.isDownloadBr) {
        addGzip = NO;
    } else if (!addGzip) {
        if (!self.hostsAddGzipSet) { // 读取settings决定使用添加gzip
            NSDictionary<NSString *, NSNumber *> *hostsGzipDict = [BDPSettingsManager.sharedManager s_dictionaryValueForKey:kBDPCDNHostsAddGzip];
            if (hostsGzipDict.count) {
                NSMutableSet *mSet = [NSMutableSet setWithCapacity:hostsGzipDict.count];
                for (NSString *host in hostsGzipDict.allKeys) {
                    if ([hostsGzipDict[host] boolValue]) {
                        [mSet addObject:host];
                    }
                }
                self.hostsAddGzipSet = mSet;
            }
        }
        addGzip = [self.hostsAddGzipSet containsObject:task.requestURL.host];
    }
    
    NSUInteger checkIndex = task.urlIndex;
    NSURLRequest *request = [self reqeustWithURL:task.requestURL rangeOffset:rangeOffset addGzip:addGzip];
    
    if ([strongDelegate respondsToSelector:@selector(ttpkgDownloadTaskWillBegin:)]) {
        [strongDelegate ttpkgDownloadTaskWillBegin:task];
    }
    __weak typeof(self) weakSelf = self;
    __weak typeof(task) weakTask = task;
    
    BDPDownloadReceivedDataBlk dataBlk = ^(NSData * _Nonnull data, int64_t receivedBytes, int64_t totalBytes, NSUInteger statusCode)
    {
        typeof(weakSelf) self = weakSelf;
        typeof(weakTask) task = weakTask;
        if (!task || checkIndex != task.urlIndex) { return; }
        [self handleReceivedData:data forTask:task withStatusCode:statusCode receivedBytes:receivedBytes totalBytes:totalBytes];
    };
    BDPDownloadCompletedBlk compBlk = ^(NSError * _Nullable error, BDPRequestMetrics * _Nullable metrics) {
        typeof(weakSelf) self = weakSelf;
        typeof(weakTask) task = weakTask;
        if (!task || checkIndex != task.urlIndex) { return; }
        [self handleCompletionForTask:task withError:error metrics:metrics];
        task.downloadTask = nil;
    };
    
    task.downloadTask = [self.manager taskWithRequest:request receivedDataBlk:dataBlk completedBlk:compBlk trace:task.trace];
    task.downloadTask.priority = task.priority;
    [task startTask];
}

- (void)notifyDownloadTask:(BDPPkgDownloadTask *)task didFinishedWithError:(NSError *)error {
    id<BDPAppDownloadTaskDelegate> strongDelegate = task.delegate;
    if ([strongDelegate respondsToSelector:@selector(appDownloadTask:didFinishWithError:)]) {
        [strongDelegate appDownloadTask:task didFinishWithError:error];
    }
}

- (NSURLRequest *)reqeustWithURL:(NSURL *)url rangeOffset:(int64_t)rangeOffset addGzip:(BOOL)addGzip {
    if (!url) {
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_download_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(@"url is empty")
        .flush();
        return nil;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:REQUEST_TIMEOUT];
    [request setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    if (addGzip) {
        [request setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
    } else {
        [request setValue:@"identity" forHTTPHeaderField:@"Accept-Encoding"];
    }
    [request setValue:@"application/javascript; charset=utf-8;" forHTTPHeaderField:@"Content-Type"];
    if (rangeOffset > 0) {
        [request setValue:[NSString stringWithFormat:@"bytes=%@-", @(rangeOffset)] forHTTPHeaderField:@"Range"];
    }
    request.HTTPShouldUsePipelining = YES;
    
    return [request copy];
}

- (void)stopDownloadForTaskID:(NSString *)taskID {
    if (BDPIsEmptyString(taskID)) {
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_download_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(@"taskID is empty")
        .flush();
        return;
    }
    BDPPkgDownloadTask *task = self.tasksDic[taskID];
    // 清理delegate, 主动取消的只抛出Notification, 但不给error回调
    task.delegate = nil;
    [task stopTask];
    self.tasksDic[taskID] = nil;
}

- (void)stopDownloadWithPrefix:(NSString *)prefix {
    if (!prefix) {
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_download_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(@"prefix is empty")
        .flush();
        return;
    }
    NSDictionary *copyDict = [self.tasksDic copy];
    for (NSString *taskID in copyDict.allKeys) {
        if ([taskID hasPrefix:prefix]) {
            [self stopDownloadForTaskID:taskID];
        }
    }
}

- (void)setPriority:(float)priority withTaskID:(NSString *)taskID  {
    if (BDPIsEmptyString(taskID)) {
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_download_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(@"taskID is empty")
        .flush();
        return;
    }
    BDPPkgDownloadTask *task = nil;
    task = self.tasksDic[taskID];
    task.priority = priority;
}

#pragma mark - Task Manage
- (void)addTask:(BDPPkgDownloadTask *)task {
    if (!task.taskID) {
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_download_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(@"taskID is empty")
        .flush();
        return;
    }
    if (!self.tasksDic) {
        self.tasksDic = [NSMutableDictionary dictionary];
    }
    self.tasksDic[task.taskID] = task;
}

- (void)removeTaskWithTaskID:(NSString *)taskID {
    if (BDPIsEmptyString(taskID)) {
        CommonMonitorWithCode(CommonMonitorCodePackage.pkg_download_invalid_params)
        .addTag(BDPTag.packageManager)
        .setErrorMessage(@"taskID is empty")
        .flush();
        return;
    }
    self.tasksDic[taskID] = nil;
}

#pragma mark - LazyLoading

- (BDPDownloadManager *)manager {
    @synchronized (self) {
        if (!_manager) {
            NSURLSessionConfiguration *config = BDPNetworking.sharedSession.configuration.copy;
            config.HTTPShouldUsePipelining = YES;
            _manager = [BDPDownloadManager managerWithSessionConfiguration:config andDelegateQueue:nil];
        }
    }
    return _manager;
}
@end
