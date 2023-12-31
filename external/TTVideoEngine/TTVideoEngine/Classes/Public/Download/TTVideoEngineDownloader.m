//
//  TTVideoEngineDownloader.m
//  TTVideoEngine
//
//  Created by 黄清 on 2020/3/12.
//

#import "TTVideoEngineDownloader+Private.h"
#import "TTVideoEngineKVStorage.h"

NSErrorDomain const TTVideoEngineDownloadTaskErrorDomain = @"TTVideoEngineDownloadTaskErrorDomain";
NSErrorUserInfoKey const TTVideoEngineDownloadUserCancelErrorKey = @"TTVideoEngineDownloadUserCancelErrorKey";
static NSString *const s_c_index_key = @"TTVideoEngineDownloader.index.v0";
static const int64_t MIN_FREE_SIZE = 1024 * 1024 *1024;

/// Task item @implementation
#import "TTVideoEngineDownloadTask+Private.h"


@implementation TTVideoEngineDownloader {
    dispatch_queue_t  _diskOperationQueue;
}

+ (instancetype)shareLoader {
    static TTVideoEngineDownloader *s_loader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_loader = [[[self class] alloc] init];
    });
    return s_loader;
}

- (instancetype)init {
    if (self = [super init]) {
        _maxTaskId = -1;
        _allTasks = [NSMutableArray array];
        _runningTasks = [NSMutableSet set];
        _indexArray = [NSMutableArray array];
        _waitingTasks = [NSMutableArray array];
        _maxDownloadOperationCount = 1;
        _limitFreeDiskSize = MIN_FREE_SIZE;
        _diskOperationQueue = dispatch_queue_create("vcloud.downloader.disk", DISPATCH_QUEUE_SERIAL);
        NSString *downloadDir = [TTVideoEngine ls_localServerConfigure].downloadDirectory;
        NSAssert(s_string_valid(downloadDir), @"downloadDir is null");
        NSString *cachePath = [downloadDir stringByAppendingPathComponent: TTVideoEngineBuildMD5(@"ttvideoengine-downloader-task-diskcache.v0")];
        _storage = [[TTVideoEngineKVStorage alloc] initWithPath:cachePath];
        if (!_storage) {
            TTVideoEngineLog(@"[downloader] open db fail");
        }
        NSString *indexDir = [downloadDir stringByAppendingPathComponent:TTVideoEngineBuildMD5(s_c_index_key)];
        if (![[NSFileManager defaultManager] fileExistsAtPath:indexDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:indexDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        _tasksIndexPath = [indexDir stringByAppendingPathComponent:@".index"];
        _storage.errorLogsEnabled = YES;
        _storage.disableLRU = YES;
        _storage.walSizeLimit = 10 * 1024 *1024;
        _readAllTask = NO;
        _loadingData = NO;
    }
    return self;
}

- (void)getAllTasksWithCompletionHandler:(void (^)(NSArray<__kindof TTVideoEngineDownloadTask *> * _Nonnull))completionHandler {
    NSAssert([NSThread isMainThread], @"should be in main thread");
    NSAssert([TTVideoEngine ls_isStarted], @"should start mdl");
    [[TTVideoEngineNetWorkReachability shareInstance] startNotifier];
    
    if (self.readAllTask) {
        !completionHandler ?: completionHandler(_allTasks.copy);
    }
    else {
        if (self.loadingData && !self.readAllTask) {
            dispatch_async(_diskOperationQueue, ^{
                TTVideoRunOnMainQueue(^{
                    if (self.readAllTask) {
                        !completionHandler ?: completionHandler(_allTasks.copy);
                    }
                    else {
                        NSAssert(NO, @"thread switch problem");
                        TTVideoEngineLog(@"[downloader] dispatch async");
                    }
                }, NO);
            });
            return;
        }
        self.loadingData = YES;
        __block NSArray *temArray = nil;
        dispatch_async(_diskOperationQueue, ^{
            temArray = [self _readTasksFromDisk];
            [_storage tryTrimWAL];
            
            TTVideoRunOnMainQueue(^{
                if (temArray) {
                    TTVideoEngineDownloadTask *task = temArray.lastObject;
                    if (task) {
                        self.maxTaskId = task.taskIdentifier;
                    }
                    for (TTVideoEngineDownloadTask *task in temArray) {
                        if (![self.indexArray containsObject:@(task.taskIdentifier)]) {
                            [self.indexArray addObject:@(task.taskIdentifier)];
                        }
                    }
                    [self.allTasks addObjectsFromArray:temArray];
                    self.readAllTask = YES;
                    self.loadingData = NO;
                    NSAssert(self.indexArray.count == self.allTasks.count, @"load data breakdown");
                    TTVideoEngineLog(@"[downloader] load all task, \n[\n%@\n]\n ",temArray);
                    !completionHandler ?: completionHandler(temArray.copy);
                }
            }, NO);
        });
    }
}

- (nullable TTVideoEngineDownloadURLTask *)existUrlTask:(NSString *)key {
    NSAssert(self.readAllTask, @"need load all tasks at first");
    NSAssert([NSThread isMainThread], @"should be in main thread");
    if (self.readAllTask) {
        NSArray *urls = @[@"http://temporary"];
        TTVideoEngineDownloadURLTask *urlTask = [TTVideoEngineDownloadURLTask urlTaskWithKey:key urls:urls vid:nil];
        if (urlTask) {
            NSInteger index = [self.allTasks indexOfObject:urlTask];
            if (index >= 0 && index < self.allTasks.count) {
                return [self.allTasks objectAtIndex:index];
            }
        }
    }
    return nil;
}

- (nullable TTVideoEngineDownloadURLTask *)urlTask:(NSArray *)urls key:(NSString *)key videoId:(nullable NSString *)videoId {
    NSAssert([NSThread isMainThread], @"should be in main thread");
    TTVideoEngineDownloadURLTask *urlTask = [TTVideoEngineDownloadURLTask urlTaskWithKey:key urls:urls vid:videoId];
    if (urlTask){
        urlTask = (TTVideoEngineDownloadURLTask *)[self _addTask:urlTask];
    }
    
    [urlTask updateUrls:urls];
    
    return urlTask;
}

- (TTVideoEngineDownloadVidTask *)existVidTask:(NSString *)videoId
                                    resolution:(TTVideoEngineResolutionType)resolution
                                       bytevc1:(BOOL)bytevc1Enable
                                      baseDash:(BOOL)baseDashEnable
                                         https:(BOOL)httpsEnable {
    return [self existVidTask:videoId resolution:resolution codec:bytevc1Enable?TTVideoEngineByteVC1:TTVideoEngineH264 baseDash:baseDashEnable https:httpsEnable];
}

- (TTVideoEngineDownloadVidTask *)existVidTask:(NSString *)videoId
                                    resolution:(TTVideoEngineResolutionType)resolution
                                         codec:(TTVideoEngineEncodeType)codecType
                                      baseDash:(BOOL)baseDashEnable
                                         https:(BOOL)httpsEnable {
    NSAssert(self.readAllTask, @"need load all tasks at first");
    NSAssert([NSThread isMainThread], @"should be in main thread");
    if (self.readAllTask) {
        TTVideoEngineDownloadVidTask *vidTask = [TTVideoEngineDownloadVidTask vidTaskWithVid:videoId
                                                                                  resolution:resolution
                                                                                       codec:codecType
                                                                                    baseDash:baseDashEnable
                                                                                       https:httpsEnable];
        if (vidTask) {
            NSInteger index = [self.allTasks indexOfObject:vidTask];
            if (index >= 0 && index < self.allTasks.count) {
                return [self.allTasks objectAtIndex:index];
            }
        }
    }
    return nil;
}

- (nullable TTVideoEngineDownloadVidTask *)vidTask:(NSString *)videoId
                                        resolution:(TTVideoEngineResolutionType)resolution
                                           bytevc1:(BOOL)bytevc1Enable
                                          baseDash:(BOOL)baseDashEnable
                                             https:(BOOL)httpsEnable {
    return [self vidTask:videoId resolution:resolution codec:bytevc1Enable?TTVideoEngineByteVC1:TTVideoEngineH264 baseDash:baseDashEnable https:httpsEnable];
}

- (nullable TTVideoEngineDownloadVidTask *)vidTask:(NSString *)videoId
                                        resolution:(TTVideoEngineResolutionType)resolution
                                             codec:(TTVideoEngineEncodeType)codecType
                                          baseDash:(BOOL)baseDashEnable
                                             https:(BOOL)httpsEnable {
    NSAssert([NSThread isMainThread], @"should be in main thread");
    TTVideoEngineDownloadVidTask *vidTask = [TTVideoEngineDownloadVidTask vidTaskWithVid:videoId
                                                                              resolution:resolution
                                                                                   codec:codecType
                                                                                baseDash:baseDashEnable
                                                                                   https:httpsEnable];
    if (vidTask){
        vidTask = (TTVideoEngineDownloadVidTask *)[self _addTask:vidTask];
    }
    return vidTask;
}

- (nullable TTVideoEngineDownloadVidTask *)existVidTaskWithVideoModel:(TTVideoEngineModel *)videoModel
                                                           resolution:(TTVideoEngineResolutionType)resolution {
    NSAssert(self.readAllTask, @"need load all tasks at first");
    NSAssert([NSThread isMainThread], @"should be in main thread");
    if (self.readAllTask) {
        TTVideoEngineDownloadVidTask *vidTask = [TTVideoEngineDownloadVidTask vidTaskWithVideoModel:videoModel
                                                                                         resolution:resolution];
        if (vidTask) {
            NSInteger index = [self.allTasks indexOfObject:vidTask];
            if (index >= 0 && index < self.allTasks.count) {
                TTVideoEngineDownloadVidTask *temTask = [self.allTasks objectAtIndex:index];
                temTask.videoModel = videoModel;
                return temTask;
            }
        }
    }
    return nil;
}

- (nullable TTVideoEngineDownloadVidTask *)vidTaskWithVideoModel:(TTVideoEngineModel *)videoModel
                                                      resolution:(TTVideoEngineResolutionType)resolution {
    NSAssert([NSThread isMainThread], @"should be in main thread");
    TTVideoEngineDownloadVidTask *vidTask = [TTVideoEngineDownloadVidTask vidTaskWithVideoModel:videoModel
                                                                                     resolution:resolution];
    if (vidTask){
        vidTask = (TTVideoEngineDownloadVidTask *)[self _addTask:vidTask];
    }
    
    vidTask.videoModel = videoModel;
    
    return vidTask;
}

- (BOOL)shouldResume:(TTVideoEngineDownloadTask *)task {
    NSAssert([NSThread isMainThread], @"should be in main thread");
    
    if (self.runningTasks.count < self.maxDownloadOperationCount ||
        ([self.runningTasks containsObject:task] && (task.state == TTVideoEngineDownloadStateSuspended || task.state == TTVideoEngineDownloadStateCompleted))) {
        int64_t freeSize = TTVideoEngineGetFreeSpace();
        TTVideoEngineLog(@"[downloader] get free size, size = %lld",freeSize);
        if (freeSize <= self.limitFreeDiskSize) {
            TTVideoEngineLog(@"[downloader] resume fail, size = %lld",freeSize);
            [task receiveError:s_dict_error(@{@"domain":TTVideoEngineDownloadTaskErrorDomain,
                                              @"code":@(TTVideoEngineErrorNotEnoughDiskSpace),
                                              @"info":@{@"task_id":@(task.taskIdentifier)}})];
            return NO;
        }
        
        return YES;
    }
    else {
        task.state = TTVideoEngineDownloadStateWaiting;
        if (![self.waitingTasks containsObject:task]) {
            [self.waitingTasks addObject:task];
        }
        TTVideoEngineLog(@"[downloader] task is waiting, task info: %@",task.jsonDict);
        return NO;
    }
}

- (BOOL)suspended:(TTVideoEngineDownloadTask *)task {
    NSAssert([NSThread isMainThread], @"should be in main thread");
    if ([self.waitingTasks containsObject:task]) {
        [self.waitingTasks removeObject:task];
        TTVideoEngineLog(@"[downloader] task is waiting, task info = %@",task);
        task.state = TTVideoEngineDownloadStateSuspended;
    }
    
    return YES;
}

- (void)resume:(TTVideoEngineDownloadTask *)task {
    NSAssert([NSThread isMainThread], @"should be in main thread");
    if (![self.runningTasks containsObject:task]) {
        [self.runningTasks addObject:task];
    }
    
    if ([self.waitingTasks containsObject:task]) {
        TTVideoEngineLog(@"[downloader] resume task, is waiting, task = %@",task);
        [self.waitingTasks removeObject:task];
    }
    
    if (task.countOfBytesReceived < 1 || task.countOfBytesExpectedToReceive < 1) {
        return;
    }
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(VideoEngineDownloader:downloadTask:didResumeAtOffset:expectedTotalBytes:)]) {
        [self.delegate VideoEngineDownloader:self
                                downloadTask:task
                           didResumeAtOffset:task.countOfBytesReceived
                          expectedTotalBytes:task.countOfBytesExpectedToReceive];
    }
}

- (void)task:(TTVideoEngineDownloadTask *)task completeError:(NSError *_Nullable)error {
    if (task.finished && !task.canceled) {
        TTVideoEngineLog(@"[downloader] task did finished.  %@  error: %@",task.jsonDict,error);
        return;
    }
    task.finished = YES;
    [self _saveTaskInfo:task];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(VideoEngineDownloader:downloadTask:didCompleteWithError:)]) {
        [self.delegate VideoEngineDownloader:self
                                downloadTask:task
                        didCompleteWithError:error];
    }
    
    TTVideoEngineLog(@"[downloader] task complete.  %@ error = %@",task.jsonDict,error);
    [self tryNextWaitingTask:task];
}

- (void)cancelTask:(TTVideoEngineDownloadTask *)task {
    NSAssert([NSThread isMainThread], @"should be in main thread");
    [_allTasks removeObject:task];
    [_waitingTasks removeObject:task];
    [_indexArray removeObject:@(task.taskIdentifier)];
    
    NSError *error = s_dict_error(@{@"domain":TTVideoEngineDownloadTaskErrorDomain,
                                    @"code":@(TTVideoEngineErrorUserCancel),
                                    @"info":@{@"task_id":@(task.taskIdentifier),
                                              TTVideoEngineDownloadUserCancelErrorKey:@(true)
                                    }
    });
    [task receiveError:error];
}

- (void)progress:(NSString *)key info:(NSDictionary *)info {
    TTVideoRunOnMainQueue(^{
        int64_t mediaSize = [info[@"mediaSize"] longLongValue];
        if (mediaSize < 0) {
            return;
        }
        
        TTVideoEngineDownloadTask *temTask = nil;
        temTask = [self _taskForKey:key];
        if (!temTask) {
            TTVideoEngineLog(@"[downloader] exect fail. key = %@, task is null",key);
            [TTVideoEngine _ls_cancelDownloadByKey:key];
            return;
        }
        if (temTask){
            if (temTask.state == TTVideoEngineDownloadStateSuspended || temTask.state == TTVideoEngineDownloadStateCompleted) {
                TTVideoEngineLog(@"[downloader] task should suspend, key = %@, state = %zd",key,temTask.state);
                [TTVideoEngine _ls_cancelDownloadByKey:key];
                [self tryNextWaitingTask:temTask];
                return;
            }
            
            temTask.bytesReceivedMap[key] = info[@"cacheSize"];
            temTask.bytesExpectedToReceiveMap[key] = info[@"mediaSize"];
            NSInteger countOfBytesReceived = 0;
            NSInteger countOfBytesExpectedToReceive = 0;
            bool allStreamsCome = true;
            for (NSString *temKey in temTask.mediaKeys) {
                if ([temTask.bytesReceivedMap objectForKey:temKey] == nil) {
                    allStreamsCome = false;
                } else {
                    countOfBytesReceived += [temTask.bytesReceivedMap[temKey] longLongValue];
                    countOfBytesExpectedToReceive += [temTask.bytesExpectedToReceiveMap[temKey] longLongValue];
                }
            }
            temTask.countOfBytesReceived = countOfBytesReceived;
            temTask.countOfBytesExpectedToReceive = countOfBytesExpectedToReceive;
            
            if (allStreamsCome && temTask.countOfBytesReceived > 0 && temTask.countOfBytesReceived == temTask.countOfBytesExpectedToReceive) {
                temTask.availableLocalFilePath = info[@"path"];
                [temTask downloadEnd];
                return;
            }
            
            NSTimeInterval currentTs = CACurrentMediaTime();
            NSTimeInterval interval = currentTs - temTask.updateTs;
            if (interval > 1.0f) {
                int64_t freeSize = TTVideoEngineGetFreeSpace();
                if (freeSize <= self.limitFreeDiskSize) {
                    TTVideoEngineLog(@"[downloader] dowmload fail, free size = %lld",freeSize);
                    [temTask receiveError:s_dict_error(@{@"domain":TTVideoEngineDownloadTaskErrorDomain,
                                                      @"code":@(TTVideoEngineErrorNotEnoughDiskSpace),
                                                      @"info":@{@"task_id":@(temTask.taskIdentifier)}})];
                    
                    if (temTask.mediaKeys) {
                        for (NSString *tem in temTask.mediaKeys) {
                            [TTVideoEngine _ls_cancelDownloadByKey:tem];
                        }
                    }
                    return;
                }
            }
            
            if (temTask.updateTs < 1 || (temTask.updateTs > 0 && interval > 1.0f)) {
                if (self.delegate && temTask.state != TTVideoEngineDownloadStateSuspended &&
                    [self.delegate respondsToSelector:@selector(VideoEngineDownloader:downloadTask:writeData:timeInterval:)]) {
                    [self.delegate VideoEngineDownloader:self
                                            downloadTask:temTask
                                               writeData:(temTask.countOfBytesReceived - temTask.updateBytesReceived)
                                            timeInterval:interval * 1000];
                }
                
                temTask.updateTs = currentTs;
                temTask.updateBytesReceived = temTask.countOfBytesReceived;
            }
        }
    }, NO);
}

- (void)downloadFail:(NSString *)key error:(NSError *)error {
    TTVideoRunOnMainQueue(^{
        TTVideoEngineDownloadTask *temTask = nil;
        temTask = [self _taskForKey:key];
        
        if (temTask) {
            
            NSInteger errorCode = error.code;
            if (errorCode == -5000) {
                errorCode = TTVideoEngineErrorWriteFile;
            }
            else if (errorCode == -3000) {
                if ([[TTVideoEngineNetWorkReachability shareInstance] currentReachabilityStatus] == TTVideoEngineNetWorkStatusNotReachable) {
                    errorCode = TTVideoEngineErrorNetworkNotAvailable;
                }
                else {
                    errorCode = TTVideoEngineErrorURLUnavailable;
                }
            }
            else if (errorCode == -4000) {
                errorCode = TTVideoEngineErrorServiceInaccessible;
            }
            NSError *newError = [NSError errorWithDomain:error.domain code:errorCode userInfo:error.userInfo];
            
            if (![temTask _shouldRetry:newError]) {
                temTask.state = TTVideoEngineDownloadStateCompleted;
            }
            [temTask receiveError:newError];
            
            if (temTask.mediaKeys) {
                for (NSString *tem in temTask.mediaKeys) {
                    [TTVideoEngine _ls_cancelDownloadByKey:tem];
                }
            }
        }
    }, NO);
}

- (void)downloadDidSuspend:(NSString *)key {
    TTVideoRunOnMainQueue(^{
        TTVideoEngineDownloadTask *temTask = nil;
        temTask = [self _taskForKey:key];
        if (temTask) {
            if (temTask.state != TTVideoEngineDownloadStateSuspended) {
                temTask.state = TTVideoEngineDownloadStateSuspended;
            }
            TTVideoEngineLog(@"[downloader] task did suspended, %@",temTask);
            [self tryNextWaitingTask:temTask];
        }
    }, NO);
}

- (void)tryNextWaitingTask:(TTVideoEngineDownloadTask *)nowTask {
    NSAssert([NSThread isMainThread], @"should be in main thread");
    [self.runningTasks removeObject:nowTask];
    
    if (self.runningTasks.count == self.maxDownloadOperationCount) {
        TTVideoEngineLog(@"[downloader] running task count is %zd, max count is %zd",self.runningTasks.count,self.maxDownloadOperationCount);
        return;
    }
    
    if (self.waitingTasks.count < 1) {
        TTVideoEngineLog(@"[downloader] waiting task is empty");
        return;
    }
    
    TTVideoEngineDownloadTask *task = [self.waitingTasks firstObject];
    [self.waitingTasks removeObject:task];
    [task resume];
    TTVideoEngineLog(@"[downloader] auto resume waiting task: %@",task.jsonDict);
}

///Private Method.

- (TTVideoEngineDownloadTask *)_addTask:(TTVideoEngineDownloadTask *)task {
    task.downloader = self;
    
    if (self.readAllTask) {
        if ([self.allTasks containsObject:task]) {
            NSInteger index = [self.allTasks indexOfObject:task];
            task = [self.allTasks objectAtIndex:index];
            task.downloader = self;
        } else {
            self.maxTaskId = self.maxTaskId + 1;
            task.taskIdentifier = self.maxTaskId;
            if ([self.indexArray containsObject:@(self.maxTaskId)]) {
                TTVideoEngineLog(@"[downloader] fail. the same task identifier");
                NSAssert(NO, @"the same task identifier");
                task = nil;
            } else {
                [self.indexArray addObject:@(task.taskIdentifier)];
                [self.allTasks addObject:task];
            }
            
            [self _saveTaskInfo:task];
        }
        return task;
    } else {
        TTVideoEngineLog(@"[downloader] need fetch all task first.");
        NSAssert(NO, @"need fetch all task first.");
        return nil;
    }
}

- (TTVideoEngineDownloadTask *)_taskForKey:(NSString *)key {
    NSArray *temArray = self.allTasks.copy;
    TTVideoEngineDownloadTask *temTask = nil;
    for (TTVideoEngineDownloadTask *task in temArray) {
        if (task.mediaKeys && task.mediaKeys.count > 0) {
            for (NSString *temKey in task.mediaKeys) {
                if ([key isEqualToString:temKey]) {
                    temTask = task;
                    break;
                }
            }
        }
        if (temTask) {
            break;
        }
    }
    return temTask;
}

- (NSArray *)_readTasksFromDisk {
    NSArray *temIndexs = [NSArray arrayWithContentsOfFile:_tasksIndexPath];
    NSArray *temIndexsV2 = [[NSUserDefaults standardUserDefaults] arrayForKey:s_c_index_key];
    if (!temIndexsV2 && !temIndexs) {
        TTVideoEngineLog(@"[downloader] index is null.");
        return @[];
    }
    
    if ((!temIndexs || !temIndexsV2) || ![temIndexs isEqualToArray:temIndexsV2]) {
        TTVideoEngineLog(@"[downloader] index maybe save fail.");
        if (temIndexsV2 && !temIndexs) {
            temIndexs = temIndexsV2;
        } else if (!temIndexsV2 && temIndexs) {
            temIndexs = temIndexs;
        } else {
            temIndexs = temIndexs.count > temIndexsV2.count ? temIndexs : temIndexsV2;
        }
    }
    
    NSMutableArray *temArray = [NSMutableArray array];
    NSData *temData = nil;
    NSDictionary *temDict = nil;
    NSString *temKey = nil;
    TTVideoEngineDownloadTask *task = nil;
    int64_t contentSize = 0;
    int64_t cacheSize = 0;
    TTVideoEngineLocalServerCacheInfo *cacheInfo = nil;
    for (NSNumber *index in temIndexs) {
        task = nil;
        temKey = [index stringValue];
        temData = [_storage getItemValueForKey:temKey];
        temDict = [NSKeyedUnarchiver unarchiveObjectWithData:temData];
        
        if (temDict[@"base_dict"]) {
            NSString *taskType = temDict[@"base_dict"][@"task_type"];
            if ([taskType isEqualToString:@"url_task"]) {
                task = [TTVideoEngineDownloadURLTask taskItem];
            } else if ([taskType isEqualToString:@"vid_task"]) {
                task = [TTVideoEngineDownloadVidTask taskItem];
            }
        }
        [task assignWithDict:temDict];
        if (!task) {
            //NSAssert(NO, @"read task info is null");
            TTVideoEngineLog(@"[downloader] read task info is null, dict: %@",temDict);
            continue;
        }
        [temArray addObject:task];
        
        contentSize = 0;
        cacheSize = 0;
        cacheInfo = nil;
        for (NSString *key in task.mediaKeys) {
            cacheInfo = [TTVideoEngine ls_getCacheFileInfoByKey:key];
            contentSize += MAX(0,cacheInfo.mediaSize);
            cacheSize += MAX(0,cacheInfo.cacheSizeFromZero);
        }
        
        task.countOfBytesReceived = cacheSize;
        task.countOfBytesExpectedToReceive = contentSize;
        
        if (task.state == TTVideoEngineDownloadStateCompleted) {
            if (task.countOfBytesReceived > 0 || task.countOfBytesExpectedToReceive > 0) {
                if (task.countOfBytesReceived == task.countOfBytesExpectedToReceive) {
                    task.state = TTVideoEngineDownloadStateCompleted;
                } else {
                    task.state = TTVideoEngineDownloadStateSuspended;
                }
            } else {
                task.state = TTVideoEngineDownloadStateInit;
            }
        }
        if (task.canceled && task.error) {
            task.state = TTVideoEngineDownloadStateCompleted;
        }
        if (task.state == TTVideoEngineDownloadStateRunning) {
            task.state = TTVideoEngineDownloadStateSuspended;
        }
        if (task.state == TTVideoEngineDownloadStateWaiting) {
            if (task.countOfBytesReceived > 0) {
                task.state = TTVideoEngineDownloadStateSuspended;
            } else {
                task.state = TTVideoEngineDownloadStateInit;
            }
        }
        task.downloader = self;
    }
    
    return temArray;
}

- (void)_writeIndexToDisk:(NSArray *)allTasks  {
    NSArray *temArray = allTasks.copy;
    NSMutableArray *indexArray = [NSMutableArray array];
    for (TTVideoEngineDownloadTask *task in temArray) {
        if (![indexArray containsObject:@(task.taskIdentifier)]) {
            [indexArray addObject:@(task.taskIdentifier)];
        }
    }
    NSArray *imArray = indexArray.copy;
    imArray = [imArray sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        return [obj1 compare:obj2];
    }];
    TTVideoEngineLog(@"[downloader] index info: %@",imArray);
    [[NSFileManager defaultManager] removeItemAtPath:_tasksIndexPath error:nil];
    [imArray writeToFile:_tasksIndexPath atomically:YES];
    [[NSUserDefaults standardUserDefaults] setObject:imArray forKey:s_c_index_key];
}

/// Call on the main thread.
- (void)_saveTaskInfo:(TTVideoEngineDownloadTask *)task {
    NSArray *temArray = self.allTasks.copy;
    dispatch_async(_diskOperationQueue, ^{
        [self _writeTaskToDisk:task allTasks:temArray];
    });
}

- (void)_writeTaskToDisk:(TTVideoEngineDownloadTask *)task allTasks:(NSArray *)allTasks {
    [self _writeIndexToDisk:allTasks];
    
    NSString *temKey = [NSString stringWithFormat:@"%@",@(task.taskIdentifier)];
    NSDictionary *temDict = task.jsonDict;
    if (![allTasks containsObject:task]) {
        BOOL result = [_storage removeItemForKey:temKey];
        if (!result) {
                   TTVideoEngineLog(@"[downloader] remove task fail. videoId is %@, identifier is %@",task.videoId,@(task.taskIdentifier));
                   [task receiveError:s_dict_error(@{@"domain":TTVideoEngineDownloadTaskErrorDomain,
                                                     @"code":@(TTVideoEngineErrorSaveTaskItem),
                                                     @"info":@{@"task_id":@(task.taskIdentifier)}
                   })];
               }
    } else {
        NSData *temData = [NSKeyedArchiver archivedDataWithRootObject:temDict];
        BOOL result = [_storage saveItemWithKey:temKey value:temData];
        if (!result) {
            TTVideoEngineLog(@"[downloader] save task fail. videoId is %@, identifier is %@",task.videoId,@(task.taskIdentifier));
            [task receiveError:s_dict_error(@{@"domain":TTVideoEngineDownloadTaskErrorDomain,
                                              @"code":@(TTVideoEngineErrorSaveTaskItem),
                                              @"info":@{@"task_id":@(task.taskIdentifier)}
            })];
        }
    }
    
    [_storage tryTrimWAL];
}


@end
