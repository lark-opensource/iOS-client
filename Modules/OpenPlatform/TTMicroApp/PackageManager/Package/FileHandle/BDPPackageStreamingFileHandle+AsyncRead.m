//
//  BDPPackageStreamingFileHandle+AsyncRead.m
//  Timor
//
//  Created by houjihu on 2020/7/16.
//

#import "BDPPackageStreamingFileHandle+AsyncRead.h"
#import "BDPPackageStreamingFileHandle+Private.h"
#import "BDPPackageStreamingFileHandle+SyncRead.h"
#import "BDPPackageStreamingFileHandle+WriteHandle.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/NSError+BDPExtension.h>
#import <ECOInfra/OPError.h>
#import <OPFoundation/EEFeatureGating.h>

@implementation BDPPackageStreamingFileHandle (AsyncRead)

#pragma mark - BDPPkgFileAsyncReadHandleProtocol

/** 文件是否存在包内 */
- (void)checkExistedFileInPkg:(NSString *)filePath withCompletion:(void (^)(BOOL existed))completion {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"empty filePath");
        return;
    }
    if (!completion) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath(%@) with empty completion", filePath);
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        [self handleCheckFileInfoBlk:^{
            completion([self __fileExistsInPkgAtPath:filePath withFileInfo:self.fileInfo]);
        }];
    });
}

/** 获取文件大小, 若不存在则会返回负数 */
- (void)getFileSizeInPkg:(NSString *)filePath withCompletion:(void (^)(int64_t size))completion {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"empty filePath");
        return;
    }
    if (!completion) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath(%@) with empty completion", filePath);
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        [self handleCheckFileInfoBlk:^{
            completion([self indexInfoForFilePath:filePath].size);
        }];
    });
}

/** 获取目录下的所有文件名 */
- (void)getContentsOfDirAtPath:(NSString *)dirPath withCompletion:(void (^)(NSArray<NSString *> *_Nullable filenames))completion {
    if (BDPIsEmptyString(dirPath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"empty filePath");
        return;
    }
    if (!completion) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"dirPath(%@) with empty completion", dirPath);
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        [self handleCheckFileInfoBlk:^{
            NSMutableArray *filenames = nil;
            for (BDPPkgFileIndexInfo *index in self.fileInfo.fileIndexes) {
                if ([index.filePath hasPrefix:dirPath]) {
                    if (!filenames) {
                        filenames = [NSMutableArray array];
                    }
                    [filenames addObject:index.filePath];
                }
            }
            completion([filenames copy]);
        }];
    });
}

/// 读取数据内容
- (void)readDataInOrder:(BOOL)inOrder
           withFilePath:(NSString *)filePath
          dispatchQueue:(dispatch_queue_t)dispatchQueue
             completion:(BDPPkgFileReadDataBlock)completion {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"empty filePath");
        return;
    }
    if (!completion) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath(%@) with empty completion", filePath);
        return;
    }
    BDPPackageStreamingFileReadTask *task = [[BDPPackageStreamingFileReadTask alloc] init];
    task.inOrder = inOrder;
    task.filePath = filePath;
    task.queue = dispatchQueue;
    task.dataCompletedBlk = completion;
    [self addOrExecuteReadDataTask:task];
}

/// 读取音频资源URL
- (void)readDataURLInOrder:(BOOL)inOrder
              withFilePath:(NSString *)filePath
             dispatchQueue:(dispatch_queue_t)dispatchQueue
                completion:(BDPPkgFileReadURLBlock)completion {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"empty filePath");
        return;
    }
    if (!completion) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath(%@) with empty completion", filePath);
        return;
    }
    BDPPackageStreamingFileReadTask *task = [[BDPPackageStreamingFileReadTask alloc] init];
    task.inOrder = inOrder;
    task.filePath = filePath;
    task.queue = dispatchQueue;
    task.urlCompletedBlk = completion;
    [self addOrExecuteReadDataTask:task];
}

/// 异步读取文件内容
- (void)readDataWithFilePath:(NSString *)filePath
            syncIfDownloaded:(BOOL)syncIfDownloaded
               dispatchQueue:(dispatch_queue_t)dispatchQueue
                  completion:(BDPPkgFileReadDataBlock)completion {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"empty filePath");
        return;
    }
    if (!completion) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath(%@) with empty completion", filePath);
        return;
    }
    BDPPackageStreamingFileReadTask *task = [[BDPPackageStreamingFileReadTask alloc] init];
    task.filePath = filePath;
    task.queue = dispatchQueue;
    task.dataCompletedBlk = completion;
    task.syncIfDownloaded = syncIfDownloaded;
    [self addOrExecuteReadDataTask:task];
}

#pragma mark - Helper

- (void)handleWhenHeaderReady:(dispatch_block_t)blk {
        //直接当前线程返回，避免到子线程后出现onPackageReaderReady 和 onPackageLoadComplete 时序问题，导致 package_cache埋点出错
    if (self.loadStatus > BDPPkgFileLoadStatusNoFileInfo) {
        blk();
        return ;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        [self handleCheckFileInfoBlk:blk];
    });
}

- (void)handleCheckFileInfoBlk:(dispatch_block_t)blk {
    if (self.loadStatus > BDPPkgFileLoadStatusNoFileInfo) {
        blk();
    } else {
        __weak typeof(self) weakSelf = self;
        [self executeSync:NO inSelfQueueOfBlk:^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) { return; }
            if (self.loadStatus > BDPPkgFileLoadStatusNoFileInfo) {
                blk();
            } else {
                if (!self.checkFileInfoBlkQueue) {
                    self.checkFileInfoBlkQueue = [[BDPQueue alloc] init];
                }
                [self.checkFileInfoBlkQueue enqueueObject:^{
                    blk();
                }];
            }
        }];
    }
}

- (void)addOrExecuteReadDataTask:(BDPPackageStreamingFileReadTask *)task {
    BOOL didDownload = NO;
    [self.readDataTasksLock lock];
    if (!(didDownload = self.loadStatus == BDPPkgFileLoadStatusDownloaded)) {
        if (task.isInOrder) {
            if (!self.readDataTasksQueue) {
                self.readDataTasksQueue = [[BDPQueue alloc] init];
            }
            [self.readDataTasksQueue enqueueObject:task];
        } else {
            if (!self.readDataTasksSet) {
                self.readDataTasksSet = [NSMutableSet set];
            }
            [self.readDataTasksSet addObject:task];
        }
    }
    [self.readDataTasksLock unlock];
    if (didDownload) {
        task.execSync = task.syncIfDownloaded;
        [self handleReadDataTaskWithTask:task];
    } else {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.serialQueue, ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) { return; }
            if (self.loadStatus > BDPPkgFileLoadStatusNoFileInfo) {
                [self tryHandleReadDataTasks];
            }
        });
    }
    [self recordRequestOfFile:task.filePath];
}

- (void)handleReadDataTaskWithTask:(BDPPackageStreamingFileReadTask *)task {
    __weak typeof(self) weakSelf = self;
    dispatch_block_t executeBlk = ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        [self tryMatchIndexForTask:task]; // 有可能刚下载完无序任务直接丢过来了
        NSData *data = nil;
        NSURL *fileURL = nil;
        dispatch_queue_t queue = task.queue ?: dispatch_get_main_queue();
        if (!task.error) {
            BOOL shouldReadData = NO;
            if (task.dataCompletedBlk) {
                shouldReadData = YES;
            } else { // 辅助文件若已写出, 不读取data
                NSString *auxPath = [self auxiliaryPathFrom:task.indexInfo.filePath appType:self.packageContext.uniqueID.appType];
                if ([self syncCheckFileExists:auxPath]) {
                    fileURL = [NSURL fileURLWithPath:auxPath];
                } else {
                    shouldReadData = YES;
                }
            }
            if (shouldReadData) {
                NSError *error = nil;
                data = [self getDataOfIndexModel:task.indexInfo error:&error];
                task.error = error;
            }
        }
        if (task.dataCompletedBlk) {
            if (task.execSync) {
                BLOCK_EXEC(task.dataCompletedBlk, task.error, self.packageContext.packageName, data);
            } else {
                dispatch_async(queue, ^{
                    BLOCK_EXEC(task.dataCompletedBlk, task.error, self.packageContext.packageName, data);
                });
            }
        } else {
            if (!fileURL && !task.error) {
                __block NSURL *bURL = nil;
                dispatch_sync(BDPPackageStreamingFileHandleSerialQueue, ^{
                    bURL = [self writeAuxiliaryFileWithData:data
//                                                      appId:self.packageContext.uniqueID.identifier
                            // TODO: yinyuan 这里把 identifier 传给 appId 的接口的操作需要确认
                                       uniqueID:self.packageContext.uniqueID
                                                    pkgName:self.packageContext.packageName
                                                    appType:self.packageContext.uniqueID.appType
                                                   filePath:task.indexInfo.filePath];
                });
                fileURL = bURL;
            }
            dispatch_async(queue, ^{
                task.urlCompletedBlk(task.error, self.packageContext.packageName, fileURL);
            });
        }
    };
    if (task.isInOrder || task.execSync) { // inOrder原地触发执行
        executeBlk();
    } else {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), executeBlk);
    }
}

- (BOOL)tryAddReadTask:(BDPPackageStreamingFileReadTask *)task inDataTasks:(NSMutableArray **)dataTasks {
    if (!task || !dataTasks) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"task(%@) or dataTasks(%@) is empty", task, dataTasks);
        return NO;
    }
    [self tryMatchIndexForTask:task];
    if (task.error || task.indexInfo.endOffset <= self.lastFileOffset) { // 没命中 或 在可加载区域内的
        if (*dataTasks == nil) {
            *dataTasks = [NSMutableArray array];
        }
        [*dataTasks addObject:task];
        return YES;
    }
    return NO;
}

- (void)tryMatchIndexForTask:(BDPPackageStreamingFileReadTask *)task {
    if (!task) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"task is empty");
        return;
    }
    // 之前已匹配过，不需要再匹配了
    if (task.didMatchIndex) {
        return;
    }
    task.indexInfo = [self indexInfoForFilePath:task.filePath];
    task.didMatchIndex = YES;
    if (!task.indexInfo) {
        task.error = OPErrorWithMsg(CommonMonitorCodePackage.pkg_file_not_found, @"%@(%@): File Not Found(%@)", self.packageContext.uniqueID.identifier, self.packageContext.packageName, task.filePath);
    }
}

@end
