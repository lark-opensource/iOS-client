//
//  BDPPackageDownloadMergedTask.m
//  Timor
//
//  Created by houjihu on 2020/7/6.
//

#import "BDPPackageDownloadMergedTask.h"
#import "BDPPkgDownloadTask.h"
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPUtils.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "BDPPackageLocalManager.h"
#import "BDPPackageManagerStrategy.h"
#import <OPFoundation/BDPCommonMonitorHelper.h>
#import <OPFoundation/NSError+BDPExtension.h>
#import "BDPPackageModuleProtocol.h"
#import "BDPPackageContext.h"
#import "BDPPackageDownloadResponseHandler.h"
#import "BDPPackageDownloadContext.h"
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import <ECOInfra/OPError.h>
#import <OPSDK/OPSDK-Swift.h>
#import <BDPPackageStreamingFileHandle+Private.h>

@interface BDPPackageDownloadMergedTask ()

/// 下载标识
@property (nonatomic, copy, readwrite) NSString *taskID;
/// 下载上下文
@property (nonatomic, strong, readwrite) BDPPackageDownloadContext *downloadContext;
/// 下载队列
@property (nonatomic, strong) dispatch_queue_t serialQueue;
/// 记录写入文件过程中出现的错误，用于结束/取消任务回调方法内判断下载过程是否有异常
@property (nonatomic, strong) OPError *parseError;

/// 指定appID和pkgName的文件读取器。在下载过程中返回
/// 需要保证下载的过程中，reader存在。
/// reader的生命周期大于等于downloadTask，启动场景下外部需要持有，以保证后续可以访问代码包内的文件。
@property (nonatomic, strong, readwrite) id<BDPPkgFileManagerHandleProtocol> packageReader;

/// 写入代码包文件时的代理
@property (nonatomic, weak) id<BDPPkgFileWriteHandleProtocol> writeHandleDelegate;

@end

@implementation BDPPackageDownloadMergedTask

- (instancetype)initWithDownloadContext:(BDPPackageDownloadContext *)downloadContext taskID:(NSString *)taskID {
    if (self = [super init]) {
        self.taskID = taskID;
        self.downloadContext = downloadContext;
        self.packageReader = [BDPPackageManagerStrategy packageReaderForDownloadContext:self.downloadContext];
        self.writeHandleDelegate = [self.packageReader conformsToProtocol:@protocol(BDPPkgFileWriteHandleProtocol)] ? self.packageReader : nil;
        self.serialQueue = dispatch_queue_create("com.bytedance.timor.packageDownloadDispatcher.serialQueue", NULL);
        dispatch_queue_set_specific(_serialQueue, (__bridge void *)self, (__bridge void *)_serialQueue, NULL);
    }
    return self;
}

#pragma mark - BDPAppDownloadTaskDelegate
- (int64_t)httpRangeOffsetForAppDownloadTask:(BDPPkgDownloadTask *)task {
    __block int64_t bOffset = 0;
    //检查是否禁止断点续传，默认不禁止
    NSArray<NSString *> *disableList = [BDPSettingsManager.sharedManager s_arrayValueForKey:kBDPRangeDownloadDisableList];
    //如果uniqueID合法，且配置列表里包含appID，则判断禁止断点续传
    if (task.uniqueId.isValid &&
        disableList &&
        [disableList containsObject:task.uniqueId.appID]) {
        return bOffset;
    }
    [self executeSync:YES inSelfQueueOfBlk:^{
        BDPPackageDownloadContext *downloadContext = self.downloadContext;
        bOffset = downloadContext.lastFileOffset;
    }];
    return bOffset;
}

- (void)ttpkgDownloadTaskWillBegin:(BDPPkgDownloadTask *)task {
    BDPLogTagInfo(BDPTag.packageManager, @"package download task will begin: id(%@), url(%@), lastFileOffset(%@)", task.uniqueId, task.requestURL.absoluteString, @(self.downloadContext.lastFileOffset));
}

- (void)appDownloadTask:(BDPPkgDownloadTask *)task receivedData:(NSData *)data receivedBytes:(int64_t)receivedBytes totalBytes:(int64_t)totalBytes httpStatus:(NSUInteger)httpStatus error:(nullable NSError *)error {
    if (error) {
        error = OPErrorWithError(CommonMonitorCodePackage.pkg_download_failed, error);
    }
    [self executeSync:NO inSelfQueueOfBlk:^{
        // 回调下载进度
        BDPLogTagInfo(BDPTag.packageManager, @"package download task receivedData(length: %@): receivedBytes(%@), totalBytes(%@), httpStatus(%@), error(%@): id(%@), url(%@)", @(data.length), @(receivedBytes), @(totalBytes), @(httpStatus), error, task.uniqueId, task.requestURL.absoluteString);
        BDPPackageDownloadContext *downloadContext = self.downloadContext;
        NSArray * responseHandlersCopied = downloadContext.responseHandlers.copy;
        for (BDPPackageDownloadResponseHandler *responseHander in responseHandlersCopied) {
            if (responseHander.progressBlock) {
                // 考虑断点续传时，计算进度需加上下载之前本地已有的数据大小（URLSession返回的totalBytes可能为-1, see: https://developer.apple.com/documentation/foundation/nsurlsessiontask/1410663-countofbytesexpectedtoreceive?language=objc）
                responseHander.progressBlock(MAX(receivedBytes + self.downloadContext.originalFileOffset, 0),
                                             MAX(totalBytes + self.downloadContext.originalFileOffset, 0),
                                             task.requestURL);
            }
        }

        OPMonitorEvent *monitorResult = CommonMonitorWithCodeIdentifierType(CommonMonitorCodePackage.pkg_download_failed, downloadContext.packageContext.uniqueID)
        .addTag(BDPTag.packageManager)
        .bdpTracing(downloadContext.packageContext.trace)
        .kv(kEventKey_load_type, BDPPkgFileReadTypeInfo(downloadContext.packageContext.readType))
        .kv(kEventKey_app_version, downloadContext.packageContext.version)
        .kv(kEventKey_package_name, downloadContext.packageContext.packageName)
        .kv(kEventKey_pkg_url, task.requestURL.absoluteString);

        if (error) {
            // TODO: 此处强转类型需要适配确认
            self.parseError = (OPError *)error;
            monitorResult.setError(error).flush();
        } else {
            // 断点续传时的状态码为206(Partial Content)
            // 非断点续传, 但有缓存数据, 清理一下, 不然下载完了md5又校验不过
            if (downloadContext.originalFileOffset > 0 && httpStatus != 206) {
                OPError *resetError;
                [self resetFileHandleAndCacheWithError:&resetError];
                if (resetError) {
                    self.parseError = resetError;
                    monitorResult.setError(resetError).flush();
                }
            }
            // 写入文件
            // 当发生文件写入错误时，调用方会结束本次下载，不需要再处理
            if (!self.parseError) {
                [self writeAppFileData:data withTotalBytes:totalBytes fileHandle:downloadContext.fileHandle task:task];
            }
        }

        // 文件解析错误, 主动触发stopTask. 接着会走到didCancel里边
        if (self.parseError) {
            [task stopTask];
        }
    }];
}

- (void)appDownloadTask:(BDPPkgDownloadTask *)task didFinishWithError:(NSError *)error {
    error = error ? [NSError configOPError:error
                               monitorCode:CommonMonitorCodePackage.pkg_download_failed
                            appendUserInfo:YES
                                  userInfo:error.userInfo] : self.parseError;
    self.parseError = nil;
    [self trackDownloadResultForTask:task error:error];
    [self executeSync:NO inSelfQueueOfBlk: ^{
        BDPLogTagInfo(BDPTag.packageManager, @"package download task finished: id(%@), url(%@), error(%@)", task.uniqueId, task.requestURL.absoluteString, error);
        NSError *fError = error;
        /// 如果下载成功且保存成功，则返回结果
        /// 如果下载成功且保存失败，则重试
        /// 如果下载失败，则重试
        if (!fError) {
            [self appFileHasNoMoreDataToWriteForTask:task error:&fError];
        }
        // 如果上述过程出错，则重试下载
        // 在重试时无可用备份下载地址，则返回结果
        if ([self retryDownloadIfNeededForTask:task error:fError]) {
            BDPLogTagInfo(BDPTag.packageManager, @"retry download for id(%@) & url(%@) with error(%@)", task.uniqueId, task.requestURL.absoluteString, fError);
            return;
        }
        // TODO: 此处强转类型需要适配确认
        [self handleDownloadFinishedTask:task cancelled:NO withError:(OPError *)fError];
    }];
}

- (void)appDownloadTask:(BDPPkgDownloadTask *)task didCancelWithError:(NSError *)error {
    error = error ? [NSError configOPError:error
                               monitorCode:CommonMonitorCodePackage.pkg_download_failed
                            appendUserInfo:YES
                                  userInfo:error.userInfo] : self.parseError;
    self.parseError = nil;
    [self trackDownloadResultForTask:task error:error];
    [self executeSync:NO inSelfQueueOfBlk: ^{
        if ([self retryDownloadIfNeededForTask:task error:error]) {
            BDPLogTagInfo(BDPTag.packageManager, @"retry download for id(%@) & url(%@) with error(%@)", task.uniqueId, task.requestURL.absoluteString, error);
            return;
        }
        // TODO: 此处强转类型需要适配确认
        [self handleDownloadFinishedTask:task cancelled:YES withError:(OPError *)error];
    }];
}

#pragma mark Handle Task

- (void)startTask {
    if (self.startDownloadTaskCompletion) {
        self.startDownloadTaskCompletion();
    }
}

- (void)stopTask {
    if (self.stopDownloadTaskCompletion) {
        self.stopDownloadTaskCompletion();
    }
}

- (void)clearTask {
    if (self.clearDownloadTaskCompletion) {
        self.clearDownloadTaskCompletion();
    }
}

/// 在发生错误且有可用备份下载地址时，执行重试操作
- (BOOL)retryDownloadIfNeededForTask:(BDPPkgDownloadTask *)task error:(NSError *)error {
    NSError *fError = error;
    if (fError && task) {
        NSInteger errorCode = fError.code;
        // 外部传入的error如果是OPError类型的话, 需要取原来的error.code来判断逻辑
        if ([OPSDKFeatureGating fixLoadScriptFailWhenRetryDownloadPackage]) {
            self.parseError = nil;
            if ([fError isKindOfClass: [OPError class]]) {
                OPError *opError = (OPError *)fError;
                NSError *originNSError = opError.originError;
                // 这边递归查询一下挂载的NSError
                while (originNSError && [originNSError isKindOfClass:[OPError class]]) {
                    OPError *tmpError = (OPError *)originNSError;
                    originNSError = tmpError.originError;
                }
                errorCode = originNSError ? originNSError.code : errorCode;
                BDPLogInfo(@"start retry download for %@ with error: %@ code: %zd", task.requestURL.absoluteString, fError, errorCode);
            }
        }
        
        // 如果因网络问题出错，则可继续下载，支持断点续传
        // 如果非网络问题，则先重置文件内容
        if (![@[@(NSURLErrorNotConnectedToInternet), @(NSURLErrorTimedOut), @(NSURLErrorNetworkConnectionLost)] containsObject:@(errorCode)]) {
            NSError *resetError;
            [self resetFileHandleAndCacheWithError:&resetError];
            if (resetError) {
                BDPPackageDownloadContext *downloadContext = self.downloadContext;
                CommonMonitorWithCodeIdentifierType(CommonMonitorCodePackage.pkg_download_failed, downloadContext.packageContext.uniqueID)
                .addTag(BDPTag.packageManager)
                .bdpTracing(downloadContext.packageContext.trace)
                .kv(kEventKey_load_type, BDPPkgFileReadTypeInfo(downloadContext.packageContext.readType))
                .kv(kEventKey_app_version, downloadContext.packageContext.version)
                .kv(kEventKey_package_name, downloadContext.packageContext.packageName)
                .kv(kEventKey_pkg_url, task.requestURL.absoluteString)
                .setError(resetError)
                .flush();
            }
        }
        // 如果有可用备份下载地址，则重试下载
        if (!task.isLastRequestURL) {
            [task tryNextUrl];
            // 重试下载
            if (self.retryDownloadTaskCompletion) {
                self.retryDownloadTaskCompletion();
            }
            BDPLogTagInfo(BDPTag.packageManager, @"retry download for id(%@) & url(%@) with error(%@)", task.uniqueId, task.requestURL.absoluteString, fError);
            return YES;
        }
    }
    return NO;
}

/// 回调下载结果
- (void)handleDownloadFinishedTask:(BDPPkgDownloadTask *)task cancelled:(BOOL)cancelled withError:(OPError *)error {
    BDPPackageDownloadContext *downloadContext = self.downloadContext;

    // 关闭文件handle
    OPError *closeFileError;
    [self closeFileAfterDownloadFinishedWithDownloadContext:downloadContext task:task error:&closeFileError];

    OPError *finalError = error ?: closeFileError;
    BDPPackageContext *packageContext = downloadContext.packageContext;

    // 用户取消下载时，返回错误
    if (cancelled && !finalError) {
        finalError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_download_canceled, @"%@(%@): User cancel for pkg url(%@)", packageContext.uniqueID.identifier, packageContext.packageName, task.requestURL.absoluteString);
    }
    NSArray * responseHandlersCopied = downloadContext.responseHandlers.copy;
    for (BDPPackageDownloadResponseHandler *responseHander in responseHandlersCopied) {
        if (responseHander.completedBlock) {
            // 针对非流式包，下载完成后才创建packageReader
            self.packageReader = self.packageReader ?: [BDPPackageManagerStrategy packageReaderAfterDownloadedForPackageContext:packageContext createLoadStatus:self.downloadContext.createLoadStatus];
            responseHander.completedBlock(finalError, cancelled, !finalError ? self.packageReader : nil);
        }
    }

    if (self.downloadTaskFinishedCompletion) {
        self.downloadTaskFinishedCompletion(finalError);
    }
}

/// 保证文件读写操作串行
- (void)executeSync:(BOOL)sync inSelfQueueOfBlk:(dispatch_block_t)blk {
    if (!blk) {
        return;
    }
    // 加入tracing。拿当前线程 thread local的tracing传到block内部，在block执行的时候，替换执行现成的tracing
    dispatch_block_t tracingBlock = [BDPTracingManager convertTracingBlock:blk];
    if (dispatch_get_specific((__bridge void *)self)) {
        tracingBlock();
    } else {
        if (sync) {
            dispatch_sync(self.serialQueue, tracingBlock);
        } else {
            dispatch_async(self.serialQueue, tracingBlock);
        }
    }
}

/// 下载结果埋点
- (void)trackDownloadResultForTask:(BDPPkgDownloadTask *)task error:(NSError *)error {
    NSURL *url = task.requestURL;
    NSDate *beginDate = task.beginDate;
    NSDate *endDate = task.endDate;
    // https://bytedance.feishu.cn/space/doc/doccnj4w6w5uL6zXOd8FvtfKiRd
    int pkg_compress_type = 0;
    if (task.isDownloadBr) {
        pkg_compress_type = 2;
    } else if (task.addGzip) {
        pkg_compress_type = 1;
    }
    NSTimeInterval duration = ([endDate timeIntervalSince1970] - [beginDate timeIntervalSince1970]);
    BDPPackageDownloadContext *downloadContext = self.downloadContext;
    BDPPackageContext *context = downloadContext.packageContext;
    OPMonitorEvent *monitorResult =
    CommonMonitorWithNameIdentifierType(nil, context.uniqueID)
    .addTag(BDPTag.packageManager)
    .bdpTracing(context.trace)
    .kv(kEventKey_load_type, BDPPkgFileReadTypeInfo(context.readType))
    .kv(kEventKey_app_version, context.version)
    .kv(kEventKey_package_name, context.packageName)
    .kv(kEventKey_pkg_url, url.absoluteString)
    .kv(@"pkg_compress_type", @(pkg_compress_type));
    if (error.code == NSURLErrorCancelled) {
        monitorResult
        .setMonitorCode(CommonMonitorCodePackage.pkg_download_canceled)
        .setResultTypeCancel();
    } else if (error) {
        monitorResult
        .setMonitorCode(CommonMonitorCodePackage.pkg_download_failed)
        .setResultTypeFail()
        .setError(error);
    } else {
        monitorResult
        .setMonitorCode(CommonMonitorCodePackage.pkg_download_success)
        .setResultTypeSuccess()
        .setDuration(duration);
    }
    monitorResult.flush();
}

#pragma mark - Write Download File

/// 将包下载的中间数据写入文件
- (void)writeAppFileData:(NSData *)data withTotalBytes:(int64_t)bytes fileHandle:(NSFileHandle *)fileHandle task:(BDPPkgDownloadTask *)task {
    BDPPackageDownloadContext *downloadContext = self.downloadContext;

    /// 允许代理来更改数据
    if (self.writeHandleDelegate) {
        OPError *writeHandleDelegateParseError;
        data = [self.writeHandleDelegate writeAppFileData:data withTotalBytes:bytes parseError:&writeHandleDelegateParseError];
        if (writeHandleDelegateParseError) {
            self.parseError = writeHandleDelegateParseError;
        }
    }

    // 当data为nil时，说明文件头还没读完，不需要写入文件
    if (!data) {
        BDPLogTagInfo(BDPTag.packageManager, @"write file head info not finished");
        return;
    }
    //文件头已经读取完成了，这里就可以清空 parser。headerInfo 也已经挂在到了fileHandle上。不需要等到整个文件读取结束
    if([self.packageReader isKindOfClass:[BDPPackageStreamingFileHandle class]] &&
       [OPSDKFeatureGating enableHeaderParserProtection]) {
        BDPPkgHeaderParser * headerParser = ((BDPPackageStreamingFileHandle *)self.packageReader).parser;
        [headerParser emptyData];
        ((BDPPackageStreamingFileHandle *)self.packageReader).parser = nil;
    }
    @try { // 预防磁盘空间不足crash
        // 写入文件
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
        [fileHandle synchronizeFile];
        downloadContext.lastFileOffset = downloadContext.fileHandle.offsetInFile;
        BDPLogTagInfo(BDPTag.packageManager, @"write file with lastFileOffset(%@), data(%@)", @(downloadContext.lastFileOffset), @(data.length));
    } @catch (NSException *exception) {
        // 如果出错, 则直接重置并回调失败. 不再尝试
        NSError *resetError;
        [self resetFileHandleAndCacheWithError:&resetError];
        if (resetError) {
            CommonMonitorWithCodeIdentifierType(CommonMonitorCodePackage.pkg_write_file_failed, downloadContext.packageContext.uniqueID)
            .addTag(BDPTag.packageManager)
            .bdpTracing(downloadContext.packageContext.trace)
            .kv(kEventKey_load_type, BDPPkgFileReadTypeInfo(downloadContext.packageContext.readType))
            .kv(kEventKey_app_version, downloadContext.packageContext.version)
            .kv(kEventKey_package_name, downloadContext.packageContext.packageName)
            .kv(kEventKey_pkg_url, task.requestURL.absoluteString)
            .setError(resetError)
            .flush();
        }

        NSString *errorMessage = [NSString stringWithFormat:@"fileHandle write data failed(%@) with lastFileOffset(%@), data(%@)", exception.reason, @(downloadContext.lastFileOffset), @(data.length)];
        BDPLogTagError(BDPTag.packageManager, errorMessage);
        self.parseError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_write_file_failed, errorMessage);
        [self handleDownloadFinishedTask:task cancelled:NO withError:self.parseError];
        return;
    }

    // 更新记录的下载状态
    if (downloadContext.loadStatus != BDPPkgFileLoadStatusDownloading) {
        downloadContext.loadStatus = BDPPkgFileLoadStatusDownloading;
        BDPPackageContext *packageContext = downloadContext.packageContext;
        BDPType appType = packageContext.uniqueID.appType;
        id<BDPPackageInfoManagerProtocol> packageInfoManager = BDPGetResolvedModule(BDPPackageModuleProtocol, appType).packageInfoManager;
        // TODO: yinyuan 确认 identifier 当做 appID 使用
        [packageInfoManager replaceInToPkgInfoWithStatus:downloadContext.loadStatus withUniqueID:packageContext.uniqueID pkgName:packageContext.packageName readType:packageContext.readType];
    }

    [self.writeHandleDelegate notifyToWriteAppFileDataSuccess];
}

/// 包下载完成后开始验证、安装
- (void)appFileHasNoMoreDataToWriteForTask:(BDPPkgDownloadTask * _Nonnull)task error:(NSError **)error {
    BDPPackageDownloadContext *downloadContext = self.downloadContext;
    BDPPackageContext *packageContext = downloadContext.packageContext;

    // 校验代码包
    NSError *closeFileError;
    [self closeFileAfterDownloadFinishedWithDownloadContext:downloadContext task:task error:&closeFileError];
    if (closeFileError) {
        if (error) {
            *error = closeFileError;
        }
        BDPLogTagError(BDPTag.packageManager, @"closeFileError: %@", closeFileError);
        return;
    }
    NSString *packagePath = [BDPPackageLocalManager localPackagePathForContext:packageContext];
    NSError *verifyError;
    if (![BDPPackageManagerStrategy verifyPackageWithContext:packageContext packagePath:packagePath error:&verifyError]) {
        // 校验失败后，需要重试下载
        if (error) {
            *error = verifyError;
        }
        BDPLogTagError(BDPTag.packageManager, @"verifyError: %@", verifyError);
        return;
    }

    // 安装代码包
    NSString *packageDirPath = [BDPPackageLocalManager localPackageDirectoryPathForContext:packageContext];
    NSError *installError;
    BOOL installed = [BDPPackageManagerStrategy installPackageWithContext:packageContext packagePath:packagePath installPath:packageDirPath error:&installError];
    if (!installed) {
        if (error) {
            *error = installError;
        }
        BDPLogTagError(BDPTag.packageManager, @"installError: %@", installError);
        return;
    }

    // 安装代码包成功后，记录状态
    downloadContext.loadStatus = BDPPkgFileLoadStatusDownloaded;

    // 更新load状态
    BDPType appType = packageContext.uniqueID.appType;
    id<BDPPackageInfoManagerProtocol> packageInfoManager = BDPGetResolvedModule(BDPPackageModuleProtocol, appType).packageInfoManager;
    // TODO: yinyuan 确认 identifier 当做 appID 使用
    [packageInfoManager updatePkgInfoStatus:downloadContext.loadStatus withUniqueID:packageContext.uniqueID pkgName:packageContext.packageName readType:packageContext.readType];

    // 这边记录包的预安装信息(涉及到db读写,用FG控制一下)
    if ([OPSDKFeatureGating packageExtReadWriteEnable]) {
        BDPLogInfo(@"[Prehandle] %@ prehandle scene name: %@ preUpdatePullType: %zd", packageContext.uniqueID.identifier, packageContext.prehandleSceneName, packageContext.preUpdatePullType);
        [packageInfoManager updatePackage:packageContext.uniqueID
                                  pkgName:packageContext.packageName
                       prehandleSceneName:packageContext.prehandleSceneName
                        preUpdatePullType:packageContext.preUpdatePullType];
    }
}

// FIXME: houzhiyou OPError 类型与声明 NSError 不匹配
/// 删除下载产物
- (void)resetFileHandleAndCacheWithError:(OPError **)error {
    BDPPackageDownloadContext *downloadContext = self.downloadContext;
    BDPPkgFileLoadStatus loadStatus = BDPPkgFileLoadStatusDownloading;
    if (self.writeHandleDelegate) {
        loadStatus = [self.writeHandleDelegate loadStatusForResetFileHandleAndCache];
    }

    // 删除记录的包信息
    BDPPackageContext *packageContext = downloadContext.packageContext;
    BDPType appType = packageContext.uniqueID.appType;
    id<BDPPackageInfoManagerProtocol> packageInfoManager = BDPGetResolvedModule(BDPPackageModuleProtocol, appType).packageInfoManager;
    // TODO: yinyuan 确认 identifier 当做 appID 使用
    [packageInfoManager deletePkgInfoOfUniqueID:packageContext.uniqueID pkgName:packageContext.packageName];

    if (!downloadContext.fileHandle) {
        // 1. 如果包文件已删除，则需要重新创建
        // 2. 如果之前包文件仍存在，但downloadContext.fileHandle已清空，也需要重新创建downloadContext.fileHandle
        OPError *createError;
        downloadContext.fileHandle = [BDPPackageLocalManager createFileHandleForContext:packageContext error:&createError];
        if (createError) {
            if (error) {
                *error = createError;
            }
            return;
        }
    }
    // 重置包文件中的数据
    NSFileHandle *fileHandle = downloadContext.fileHandle;
    @try {
        [fileHandle seekToFileOffset:0];
        [fileHandle truncateFileAtOffset:0];
        [fileHandle synchronizeFile];
        downloadContext.originalFileOffset = 0;
        downloadContext.lastFileOffset = 0;
    } @catch (NSException *exception) {
        NSString *errorMessage = [NSString stringWithFormat:@"resetFileHelperWithFlag failed: %@", exception.reason];
        OPError *restFileHandleError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_write_file_failed, errorMessage);
        if (error) {
            *error = restFileHandleError;
        }
    }
}

/// close file handle
- (void)closeFileAfterDownloadFinishedWithDownloadContext:(BDPPackageDownloadContext *)downloadContext task:(BDPPkgDownloadTask *)task error:(OPError **)error {
    NSFileHandle *fileHandle = downloadContext.fileHandle;
    // 如果fileHandle为空，说明前面已经置空了，不需要再处理
    if (!fileHandle) {
        return;
    }
    // 关闭文件
    @try {
        [fileHandle closeFile];
        downloadContext.fileHandle = nil;
    } @catch (NSException *exception) {
        NSString *errorMessage = [NSString stringWithFormat:@"close package file failed: id(%@), url(%@), error(%@)", task.uniqueId, task.requestURL.absoluteString, exception.reason];
        OPError *closeFileError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_write_file_failed, errorMessage);
        if (error) {
            *error = closeFileError;
        }
    }
}

/// 开始下载前，检查文件是否需要重置
- (BOOL)shouldResetAppFileDataBeforeDownloadingWithLastFileOffset:(uint64_t)lastFileOffset resetError:(OPError **)resetError {
    BOOL shouldResetFile = NO;
    if (self.writeHandleDelegate) {
        shouldResetFile = [self.writeHandleDelegate shouldResetAppFileDataBeforeDownloadingWithLastFileOffset:lastFileOffset];
    }
    if (shouldResetFile) {
        // TODO: houzhiyou 此处类型问题适配需要确认
        [self resetFileHandleAndCacheWithError:resetError];
    }
    return shouldResetFile;
}

#pragma mark - Update Pkg Info

/// 更新包信息记录
- (void)updateBasicInfo {
    BDPPackageDownloadContext *downloadContext = self.downloadContext;
    BDPPackageContext *packageContext = downloadContext.packageContext;
    BDPType appType = packageContext.uniqueID.appType;
    id<BDPPackageInfoManagerProtocol> packageInfoManager = BDPGetResolvedModule(BDPPackageModuleProtocol, appType).packageInfoManager;
    WeakSelf;
    [self executeSync:NO inSelfQueueOfBlk:^{
        StrongSelfIfNilReturn;
        // 更新访问时间, 如果还没记录就等下载首包回来后再说
        // TODO: yinyuan 确认 identifier 当做 appID 使用
        [packageInfoManager updatePkgInfoAcessTimeWithStatus:downloadContext.loadStatus ofUniqueID:packageContext.uniqueID pkgName:packageContext.packageName readType:packageContext.readType];
    }];
}

- (float)priority {
    if ([OPSDKFeatureGating fixPackageDownloadTaskMergeIncorrect]) {
        return _priority;
    }
    return self.task.priority;
}

@end
