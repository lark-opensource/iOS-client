//
//  BDPPackageStreamingFileHandle+WriteHandle.m
//  Timor
//
//  Created by houjihu on 2020/7/17.
//

#import "BDPPackageStreamingFileHandle+WriteHandle.h"
#import "BDPPackageStreamingFileHandle+Private.h"
#import "BDPPackageStreamingFileHandle+SyncRead.h"
#import "BDPPackageStreamingFileHandle+AsyncRead.h"
#import "BDPAppLoadDefineHeader.h"
#import <OPFoundation/TMAMD5.h>
#import "BDPPackageModuleProtocol.h"
#import <OPFoundation/BDPCommonMonitorHelper.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPSDK/OPSDK-Swift.h>

@implementation BDPPackageStreamingFileHandle (WriteHandle)

#pragma mark - BDPPkgFileWriteHandleProtocol

/// 开始下载前，判断是否需要重置文件
- (BOOL)shouldResetAppFileDataBeforeDownloadingWithLastFileOffset:(uint64_t)lastFileOffset {
    BOOL shouldResetFile = NO;
    BDPPkgHeaderInfo *headerInfo = [self readHeaderInfoWithLastFileOffset:lastFileOffset];
    if (!headerInfo) {
        shouldResetFile = YES;
    }
    return shouldResetFile;
}

/// 流式下载写入方式与普通zip文件下载方式不同。
/// 在解析文件头后会从NoFileInfo切换到Downloading状态。
/// 在文件头下载完成之前，下载过程中的中间数据还没持久化到磁盘。
/// 期间如果出错，需要向外抛出解析过程中的错误。
/// 需要保持双向同步的状态：loadStatus，
/// 需要保持单向传回的状态：parseError, availableData
- (NSData *)writeAppFileData:(NSData *)data withTotalBytes:(int64_t)bytes parseError:(OPError **)parseError {
    // 解析文件描述信息
    if (self.loadStatus <= BDPPkgFileLoadStatusNoFileInfo) {
        [self createParserIfNeededWithParseError:parseError];
        [self.parser appendData:data];
    }

    NSData *chunk;
    if (self.loadStatus > BDPPkgFileLoadStatusNoFileInfo) { // 文件头解析完毕
        chunk = self.parser.availableData ?: data;
    } else {
        chunk = nil;
    }
    return chunk;
}

/// 追加数据给writer"写入"(内存+IO缓存)成功的事件通知
- (void)notifyToWriteAppFileDataSuccess {
    if (self.loadStatus > BDPPkgFileLoadStatusNoFileInfo) { // 文件头解析完毕
        self.parser = nil;
        [self tryHandleTasks];
    }
}

/// 重置文件后的loadStatus
- (BDPPkgFileLoadStatus)loadStatusForResetFileHandleAndCache {
    self.fileInfo = nil;
    if ([OPSDKFeatureGating fixLoadScriptFailWhenRetryDownloadPackage]) {
        self.loadStatus = BDPPkgFileLoadStatusNoFileInfo;
    }
    return BDPPkgFileLoadStatusNoFileInfo;
}

#pragma mark - Helper

/// 读取文件头，用于开始下载前以及已下载需要返回可用的reader时
- (BDPPkgHeaderInfo *)readHeaderInfoWithLastFileOffset:(uint64_t)lastFileOffset {
    NSDate *parseHeaderBegin = [NSDate date];
    /// 判断文件头是否存在
    BDPPkgHeaderInfo *headerInfo = [self headerInfoFromLocalPkgWithLastFileOffset:lastFileOffset];
    NSDate *parseHeaderEnd = [NSDate date];
    if (headerInfo) {
        self.fileInfo = headerInfo;
        self.loadStatus = headerInfo.totalSize == lastFileOffset ? BDPPkgFileLoadStatusDownloaded : BDPPkgFileLoadStatusDownloading;
    }
    return headerInfo;
}

- (BDPPkgHeaderInfo *)headerInfoFromLocalPkgWithLastFileOffset:(uint64_t)lastFileOffset {
    if (lastFileOffset <= 0) {
        return nil;
    }
    __block BDPPkgHeaderInfo *bHeaderInfo = nil;
    __block BOOL stopParse = NO;
    BDPPkgHeaderParser *parser = [[BDPPkgHeaderParser alloc] initWithProtection:OPSDKFeatureGating.enableHeaderParserProtection];
    parser.completionBlk = ^(BDPPkgHeaderInfo * _Nullable fileInfo, NSError * _Nullable error) {
        bHeaderInfo = fileInfo;
        stopParse = YES;
    };
    uint64_t offset = 0;
    const uint64_t kMaxParseOffset = MIN(lastFileOffset, 1024 * 1024);
    const uint64_t kChunkSize = 4 * 1024;
    NSFileHandle *fileHandle = self.downloadContext.fileHandle;
    while (!stopParse && offset < kMaxParseOffset) {
        @try {
            [fileHandle seekToFileOffset:offset];
            offset += kChunkSize;
            [parser appendData:[fileHandle readDataOfLength:kChunkSize]];
        } @catch (NSException *exception) {
            NSString *errorMessage = [NSString stringWithFormat:@"parse header failed: %@", exception.reason];
            CommonMonitorWithCodeIdentifierType(CommonMonitorCodePackage.pkg_read_data_failed, self.packageContext.uniqueID)
            .addTag(BDPTag.packageManager)
            .kv(kEventKey_app_version, self.packageContext.version)
            .kv(kEventKey_package_name, self.packageContext.packageName)
            .setErrorMessage(errorMessage)
            .flush();
            stopParse = YES;
        }
    }
    [fileHandle seekToEndOfFile];
    BDPLogTagInfo(BDPTag.packageManager, @"fileHandle seekToEndOfFile with offset(%@)", @(fileHandle.offsetInFile));
    return bHeaderInfo;
}

- (void)createParserIfNeededWithParseError:(OPError **)parseError {
    if (self.parser) {
        return;
    }
    self.parser = [[BDPPkgHeaderParser alloc] initWithProtection:OPSDKFeatureGating.enableHeaderParserProtection];
    __weak typeof(self) weakSelf = self;
    // completionBlk回调是在appendData方法中同步触发的
    self.parser.completionBlk = ^(BDPPkgHeaderInfo * _Nonnull fileInfo,
                                  NSError * _Nonnull error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        BDPUniqueID *uniqueID = self.packageContext.uniqueID;
        NSString *pkgName = self.packageContext.packageName;
        BDPPkgFileReadType readType = self.packageContext.readType;

        if (error) {
            if (parseError) {
                *parseError = OPErrorWithError(CommonMonitorCodePackage.pkg_write_file_failed, error);
            }
            [self.parser emptyData]; // 清空数据
            NSString *errorMessage = [NSString stringWithFormat:@"%@(%@): parse file info failed: %@", uniqueID.identifier, pkgName, error.localizedDescription];
            CommonMonitorWithCodeIdentifierType(CommonMonitorCodePackage.pkg_read_data_failed, self.packageContext.uniqueID)
            .addTag(BDPTag.packageManager)
            .kv(kEventKey_app_version, self.packageContext.version)
            .kv(kEventKey_package_name, self.packageContext.packageName)
            .setErrorMessage(errorMessage)
            .flush();
        } else {
            NSDate *parseEnd = [NSDate date];
            self.fileInfo = fileInfo;
            self.loadStatus = BDPPkgFileLoadStatusDownloading;
            id<BDPPackageInfoManagerProtocol> packageInfoManager = BDPGetResolvedModule(BDPPackageModuleProtocol, uniqueID.appType).packageInfoManager;
            // TODO: yinyuan 待确认 identifier 当做 appID 使用
            [packageInfoManager replaceInToPkgInfoWithStatus:BDPPkgFileLoadStatusDownloading withUniqueID:uniqueID pkgName:pkgName readType:readType];
        }
    };
}

- (void)tryHandleTasks {
    [self tryHandleReadDataTasks];
    [self tryHandleCheckFileInfoBlks];
}

- (void)tryHandleReadDataTasks {
    BOOL shouldBreak = NO;
    NSMutableArray<BDPPackageStreamingFileReadTask *> *dataTasks = nil;
    [self.readDataTasksLock lock];
    while (self.readDataTasksQueue.count && !shouldBreak) {
        BDPPackageStreamingFileReadTask *task = self.readDataTasksQueue.firstObject;
        if ([self tryAddReadTask:task inDataTasks:&dataTasks]) {
            [self.readDataTasksQueue dequeueObject];
        } else {
            shouldBreak = YES;
        }
    }
    if (self.loadStatus == BDPPkgFileLoadStatusDownloaded) { // 如果是已经下载完了, 所有无序任务可以一次性丢其他线程处理
        if (self.readDataTasksSet.count) {
            if (!dataTasks) {
                dataTasks = [self.readDataTasksSet.allObjects mutableCopy];
            } else {
                [dataTasks addObjectsFromArray:self.readDataTasksSet.allObjects];
            }
            [self.readDataTasksSet removeAllObjects];
        }
    } else {
        for (BDPPackageStreamingFileReadTask *task in [self.readDataTasksSet copy]) {
            if ([self tryAddReadTask:task inDataTasks:&dataTasks]) {
                [self.readDataTasksSet removeObject:task];
            }
        }
    }
    [self.readDataTasksLock unlock];
    for (BDPPackageStreamingFileReadTask *task in dataTasks) {
        [self handleReadDataTaskWithTask:task];
    }
}

/// 文件头解析完成后，触发检查fileInfo的回调
- (void)tryHandleCheckFileInfoBlks {
    // 都是blk内部实现都是在异步操作, 此处触发下就好. 不耗时
    if (self.checkFileInfoBlkQueue.count) {
        dispatch_block_t blk = nil;
        while ((blk = [self.checkFileInfoBlkQueue dequeueObject])) {
            blk();
        }
    }
}

@end
