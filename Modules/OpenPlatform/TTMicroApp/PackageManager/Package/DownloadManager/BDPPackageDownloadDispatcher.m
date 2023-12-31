//
//  BDPPackageDownloadDispatcher.m
//  Timor
//
//  Created by houjihu on 2020/5/22.
//

#import "BDPPackageDownloadDispatcher.h"
#import "BDPPkgDownloadManager.h"
#import "BDPPkgDownloadTask.h"
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPUtils.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "BDPPackageLocalManager.h"
#import "BDPPackageManagerStrategy.h"
#import <OPFoundation/BDPCommonMonitorHelper.h>
#import <OPFoundation/NSError+BDPExtension.h>
#import "BDPPackageDownloadResponseHandler.h"
#import "BDPPackageDownloadContext.h"
#import "BDPPackageDownloadMergedTask.h"
#import "BDPPackageDownloadTaskQueue.h"
#import <ECOInfra/OPError.h>
#import <OPFoundation/BDPTracingManager.h>
#import "BDPSubPackageManager.h"
#import <OPFoundation/EEFeatureGating.h>
#import "PKMApplePieManager.h"
#import <OPSDK/OPSDK-Swift.h>
#import <ECOInfra/OPError.h>
#import "BDPPackageInfoManager.h"


@interface BDPPackageDownloadDispatcher ()

/// 下载器
@property (nonatomic, strong) BDPPkgDownloadManager *downloadManager;
/// 下载任务队列
@property (nonatomic, strong) BDPPackageDownloadTaskQueue *taskQueue;
/// 下载任务同步信号量
@property (nonatomic) dispatch_semaphore_t downloadTaskSemphore;

@end

@implementation BDPPackageDownloadDispatcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.taskQueue = [[BDPPackageDownloadTaskQueue alloc] init];
        self.downloadManager = [[BDPPkgDownloadManager alloc] init];
        self.downloadTaskSemphore = dispatch_semaphore_create(1);
    }
    return self;
}

#pragma mark - start/stop package download task

/// 下载安装包
- (void)downloadPackageWithContext:(BDPPackageContext * _Nonnull)context
                          priority:(float)priority
                             begun:(nullable BDPPackageDownloaderBegunBlock)begunBlock
                          progress:(nullable BDPPackageDownloaderProgressBlock)progressBlock
                         completed:(nullable BDPPackageDownloaderCompletedBlock)completedBlock {
    //下包入口，这里要做一个拦截，判断是不是需要走 ODR
    if( [OPSDKFeatureGating isEnableApplePie] &&
       //确保 uniqueID 在内置 json 中，才走ODR逻辑
       [OPSDKFeatureGating shouldKeepDataWith:context.uniqueID]) {
        [[PKMApplePieManager sharedManager] makePieImmediately:context.uniqueID
                                                withCompletion:^(NSError * _Nonnull error, OPAppUniqueID * _Nonnull pie) {
            OPError * _Nonnull opError = error ? OPErrorWithError(CommonMonitorCodePackage.pkg_download_failed, error) : nil;
            //没有Error，应该是 ODR 下载成功了
            if(opError == nil) {
                //检查是不是在对应bundle目录下已经 ODR 文件了
                NSString * pathForPie = [[PKMApplePieManager sharedManager] specificPathForPie:context.uniqueID];
                //需要进行安装操作
                if([[NSFileManager defaultManager] fileExistsAtPath:pathForPie]){
                    NSString * pkgDirPath = [[BDPPackageLocalManager localPackagePathForContext:context] stringByDeletingLastPathComponent];
                    NSError * installError = nil;
                    BOOL installed = [BDPPackageManagerStrategy installPackageWithContext:context
                                                                              packagePath:pathForPie
                                                                              installPath:pkgDirPath
                                                                               isApplePie:YES
                                                                                    error:&installError];
                    //安装成功，可以直接返回了
                    if (installed && !installError) {
                        //修改本地package 数据库状态
                        BDPPackageInfoManager * packageInfoManager = [[BDPPackageInfoManager alloc] initWithAppType:context.uniqueID.appType];
                        [packageInfoManager replaceInToPkgInfoWithStatus:BDPPkgFileLoadStatusDownloaded
                                                            withUniqueID:context.uniqueID
                                                                 pkgName:context.packageName
                                                                readType:BDPPkgFileReadTypeNormal];
                        //手动创建已下载的句柄，直接返回
                        id<BDPPkgFileManagerHandleProtocol> packageReader = [BDPPackageManagerStrategy packageReaderAfterDownloadedForPackageContext:context];
                        BLOCK_EXEC(begunBlock, packageReader);
                        BLOCK_EXEC(completedBlock, nil, NO, packageReader)
                    } else {
                        OPError * _Nonnull opError = error ? OPErrorWithError(CommonMonitorCodePackage.pkg_install_failed , error) : OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_failed, @"installed failure");
                        BLOCK_EXEC(completedBlock, opError, NO, nil)
                    }
                } else {
                    opError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_download_failed, @"beginAccessingResources with out error, but file doesn't exist");
                    BLOCK_EXEC(completedBlock, opError, NO, nil)
                }
            } else {
                BLOCK_EXEC(completedBlock, opError, NO, nil)
            }
        }];
        return;
    }
    dispatch_semaphore_wait(self.downloadTaskSemphore, DISPATCH_TIME_FOREVER);
    BDPLogInfo(@"downloadPackageWithContext: id(%@), packageName(%@), priority(%@)", context.uniqueID.identifier, context.packageName, @(priority));
    if (!context) {
        NSString *errorMessage = @"context is empty";
        OPError *error = OPErrorWithMsg(CommonMonitorCodePackage.pkg_download_invalid_params, errorMessage);
        if (completedBlock) {
            completedBlock(error, NO, nil);
        }
        dispatch_semaphore_signal(self.downloadTaskSemphore);
        return;
    }
    //box off ture，所有下载停止
    if([OPSDKFeatureGating isBoxOff]) {
        NSString *errorMessage = @"is boxoff is ture";
        OPError *error = OPErrorWithMsg(CommonMonitorCodePackage.pkg_download_failed, errorMessage);
        if (completedBlock) {
            completedBlock(error, NO, nil);
        }
        dispatch_semaphore_signal(self.downloadTaskSemphore);
        return;
    }
    // 生成下载任务ID
    OPError *taskIDError;
    // TODO: yinyuan 确认 identifier 当做 appID 使用
    NSString *taskID = [BDPPackageDownloadContext taskIDWithUniqueID:context.uniqueID packageName:context.packageName error:&taskIDError];
    // 检查创建的下载任务的ID
    if (taskIDError) {
        if (completedBlock) {
            completedBlock(taskIDError, NO, nil);
        }
        dispatch_semaphore_signal(self.downloadTaskSemphore);
        return;
    }

    // 重复任务合并
    BDPPackageDownloadResponseHandler *responseHandler = [[BDPPackageDownloadResponseHandler alloc]
                                                          initWithID:taskID
                                                          begunBlock:begunBlock
                                                          progressBlock:progressBlock
                                                          completedBlock:completedBlock
                                                          ];
    if ([OPSDKFeatureGating fixPackageDownloadTaskMergeIncorrect]) {
        BDPPackageDownloadMergedTask *mergeTask = [self mergeDownloadTaskV2WithTaskID:taskID context:context priority:priority responseHandler:responseHandler];
        if (mergeTask) {
            BDPLogTagInfo(BDPTag.packageManager, @"package download task merged V2 for id(%@) & url(%@)", mergeTask.downloadContext.packageContext.uniqueID, mergeTask.task.requestURL.absoluteString);
            dispatch_semaphore_signal(self.downloadTaskSemphore);
            return;
        }
    } else {
        BDPPkgDownloadTask *task = [self mergeDownloadTaskWithTaskID:taskID context:context priority:priority responseHandler:responseHandler];
        if (task) {
            BDPLogTagInfo(BDPTag.packageManager, @"package download task merged for id(%@) & url(%@)", task.uniqueId, task.requestURL.absoluteString);
            dispatch_semaphore_signal(self.downloadTaskSemphore);
            return;
        }
    }

    // 根据上下文，创建下载任务
    BDPPackageDownloadContext *downloadContext = [[BDPPackageDownloadContext alloc] init];
    downloadContext.taskID = taskID;
    downloadContext.packageContext = context;
    [downloadContext addResponseHandler:responseHandler];
    BDPPackageDownloadMergedTask *mergedTask = [[BDPPackageDownloadMergedTask alloc] initWithDownloadContext:downloadContext taskID:taskID];
    if ([OPSDKFeatureGating fixPackageDownloadTaskMergeIncorrect]) {
        // 设置mergeTask的优先级,重复任务合并时会根据优先级重排任务顺序
        mergedTask.priority = priority;
    }

    OPError *aError;
    // 创建fileHandle，以供持续写入下载数据
    downloadContext.fileHandle = [BDPPackageLocalManager createFileHandleForContext:context error:&aError];
    if (aError) {
        if (completedBlock) {
            completedBlock(aError, NO, nil);
        }
        dispatch_semaphore_signal(self.downloadTaskSemphore);
        return;
    }
    [downloadContext.fileHandle seekToEndOfFile];
    downloadContext.lastFileOffset = downloadContext.fileHandle.offsetInFile;
    downloadContext.originalFileOffset = downloadContext.lastFileOffset;
    // 如果之前下载过，则状态设置为downloading，支持断点续传
    if (downloadContext.originalFileOffset > 0) {
        downloadContext.loadStatus = BDPPkgFileLoadStatusDownloading;
    }

    // 刚开始下载时，检查匹配的本地包是否下载过/不存在，更改loadStatus
    // 此处不会存在文件下载完成的情况，因为数据库内保存了文件的下载状态，调用这里之前会先检查
    // 针对流式包的原逻辑：1）检查文件头是否下载完成，如果没下载完则重置文件来设置noFileInfo，如果已下载完看整个文件是否下载完来判断downloading/downloaded
    OPError *resetError;
    BOOL shouldResetFile = [mergedTask shouldResetAppFileDataBeforeDownloadingWithLastFileOffset:downloadContext.lastFileOffset resetError:&resetError];
    if (shouldResetFile && resetError) {
        if (completedBlock) {
            completedBlock(resetError, NO, nil);
        }
        dispatch_semaphore_signal(self.downloadTaskSemphore);
        return;
    }
    downloadContext.createLoadStatus = downloadContext.loadStatus;
    // isDownloadRange需要在重置文件操作后再执行。如果重置文件后，originalFileOffset会发生变化
    downloadContext.isDownloadRange = (downloadContext.originalFileOffset > 0);

    [self setupCompletionsForMergedTask:mergedTask priority:priority];

    [self.taskQueue startOrEnqueueMergedTask:mergedTask];
    dispatch_semaphore_signal(self.downloadTaskSemphore);
}

/// 配置下载任务的回调
- (void)setupCompletionsForMergedTask:(BDPPackageDownloadMergedTask *)mergedTask priority:(float)priority {
    __weak typeof(self) weakSelf = self;
    __weak typeof(mergedTask) weakMergedTask = mergedTask;
    NSString *taskID = mergedTask.downloadContext.taskID;

    BDPPackageContext *context = mergedTask.downloadContext.packageContext;
    CommonMonitorWithNameIdentifierType(kEventName_op_common_package_download_start, context.uniqueID)
    .addTag(BDPTag.packageManager)
    .bdpTracing(context.trace)
    .kv(kEventKey_load_type, BDPPkgFileReadTypeInfo(context.readType))
    .kv(kEventKey_app_version, context.version)
    .kv(kEventKey_package_name, context.packageName)
    .flush();
    OPMonitorEvent *monitorResult = CommonMonitorWithNameIdentifierType(kEventName_op_common_package_download_result, context.uniqueID)
    .addTag(BDPTag.packageManager)
    .bdpTracing(context.trace)
    .kv(kEventKey_load_type, BDPPkgFileReadTypeInfo(context.readType))
    .kv(kEventKey_app_version, context.version)
    .kv(kEventKey_package_name, context.packageName);
    BDPTracing *requestTrace = [BDPTracingManager.sharedInstance generateTracingWithParent:context.trace];
    mergedTask.startDownloadTaskCompletion = ^{
        __strong typeof(weakSelf) self = weakSelf;
        __strong typeof(weakMergedTask) mergedTask = weakMergedTask;
        BDPPackageContext *context = mergedTask.downloadContext.packageContext;
        BDPUniqueID *uniqueID = context.uniqueID;
        BDPPkgDownloadTask *downloadTask = [self.downloadManager startDownloadWithTaskID:taskID requestURLs:context.urls priority:priority uniqueId:uniqueID addGzip:NO canDownloadBr:NO taskDelegate:mergedTask trace:requestTrace];
        if (!downloadTask) {
            NSString *errorMessage = [NSString stringWithFormat:@"task is empty for url(%@) of identifier(%@), uniqueID(%@)", context.urls, context.uniqueID.identifier, uniqueID];
            OPError *error = OPErrorWithMsg(CommonMonitorCodePackage.pkg_download_invalid_params, errorMessage);
            NSArray * responseHandlersCopied = mergedTask.downloadContext.responseHandlers.copy;
            for (BDPPackageDownloadResponseHandler *responseHandler in responseHandlersCopied) {
                BDPPackageDownloaderCompletedBlock completedBlock = responseHandler.completedBlock;
                if (completedBlock) {
                    completedBlock(error, NO, nil);
                }
            }
            return;
        }
        // 保存下载上下文
        mergedTask.task = downloadTask;

        // 首次使用、pkg访问类型获取，记录状态
        [mergedTask updateBasicInfo];
        BDPLogTagInfo(BDPTag.packageManager, @"package download task started for id(%@) & url(%@)", downloadTask.uniqueId, downloadTask.requestURL.absoluteString);

        NSArray * responseHandlersCopied = mergedTask.downloadContext.responseHandlers.copy;
        // start download
        for (BDPPackageDownloadResponseHandler *responseHandler in responseHandlersCopied) {
            BDPPackageDownloaderBegunBlock begunBlock = responseHandler.begunBlock;
            if (begunBlock) {
                begunBlock(mergedTask.packageReader);
            }
        }

        monitorResult.timing();
    };
    mergedTask.stopDownloadTaskCompletion = ^{
        __strong typeof(weakSelf) self = weakSelf;
        __strong typeof(weakMergedTask) mergedTask = weakMergedTask;
        [self stopDownloadTaskWithContext:mergedTask.downloadContext.packageContext error:nil];
    };
    mergedTask.retryDownloadTaskCompletion = ^{
        __strong typeof(weakSelf) self = weakSelf;
        __strong typeof(weakMergedTask) mergedTask = weakMergedTask;
        BDPPkgDownloadTask *task = mergedTask.task;
        [self.downloadManager startDownloadWithTask:task];
    };
    mergedTask.clearDownloadTaskCompletion = ^{
        __strong typeof(weakSelf) self = weakSelf;
        __strong typeof(weakMergedTask) mergedTask = weakMergedTask;
        [self stopDownloadTaskWithContext:mergedTask.downloadContext.packageContext error:nil];
    };
    mergedTask.downloadTaskFinishedCompletion = ^(NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        __strong typeof(weakMergedTask) mergedTask = weakMergedTask;
        // 停止下载任务后，task.delegate会置为nil，不再触发回调
        [self.downloadManager stopDownloadForTaskID:taskID];

        // 通知任务队列清除task
        [self.taskQueue finishMergedTaskWithTaskID:taskID];
        monitorResult.timing();
        if (error) {
            monitorResult
            .setError(error)
            .setResultTypeFail();
        } else {
            monitorResult
            .setResultTypeSuccess();
        }
        monitorResult
        .kv(kEventKey_pkg_url, mergedTask.task.requestURL.absoluteString)
        .flush();
    };
}

/// 合并重复任务
/// 判断当前是否已经存在相同的BDPPackageDownloadMergedTask对象
/// 存在相同task的话则将handler添加到task的handler数组中并根据优先级重排
- (BDPPackageDownloadMergedTask *)mergeDownloadTaskV2WithTaskID:(NSString *)downloadTaskID context:(BDPPackageContext *)context priority:(float)priority responseHandler:(BDPPackageDownloadResponseHandler *)responseHandler {
    BDPPackageDownloadMergedTask *mergedTask = [self.taskQueue mergedTaskWithTaskID:downloadTaskID];
    if (!mergedTask) {
        // 找不到重复任务时，直接返回
        return nil;
    }
    BDPPackageDownloadContext *downloadContext = mergedTask.downloadContext;
    // 合并handler
    [downloadContext addResponseHandler:responseHandler];
    // 使用较高优先级
    if (mergedTask.priority < priority) {
        mergedTask.priority = priority;
        [self.taskQueue notifyToRaisePriorityForMergedTask:mergedTask];
    }
    //如果是重用的merge任务，会丢掉begun callback（mergedTask在之前已经触发了beguncallback），之后触发completeCallback
    //需要在这里补一次回调
    //尚不明确每次begunCallback有什么问题，谨慎起见只在分包场景下会有这次回调
    // update: 2022.8.24 非分包场景，包下载任务重场景下打开小程序必现加载失败 https://lark-oncall.bytedance.net/tickets/ticket_16611561322000411?activeTab=message
    bool fixMergeTask = [EEFeatureGating boolValueForKey: EEFeatureGatingKeyFixMergePackageDownloadTask];
    if ((fixMergeTask || context.isSubpackageEnable) &&
        responseHandler.begunBlock) {
        responseHandler.begunBlock(mergedTask.packageReader);
    }
    
    // 判断是否复用了预下载任务，用于埋点
    if (downloadContext.packageContext.readType == BDPPkgFileReadTypePreload && context.readType != BDPPkgFileReadTypePreload) {
        downloadContext.isReusePreload = YES;
    }
    return mergedTask;
}

/// 重复任务合并
- (BDPPkgDownloadTask *)mergeDownloadTaskWithTaskID:(NSString *)downloadTaskID context:(BDPPackageContext *)context priority:(float)priority responseHandler:(BDPPackageDownloadResponseHandler *)responseHandler {
    BDPPackageDownloadMergedTask *mergedTask = [self.taskQueue mergedTaskWithTaskID:downloadTaskID];
    BDPPkgDownloadTask *task = mergedTask.task;
    if (!task) {
        // 找不到重复任务时，直接返回
        return nil;
    }
    BDPPackageDownloadContext *downloadContext = mergedTask.downloadContext;
    // 合并handler
    [downloadContext addResponseHandler:responseHandler];
    // 使用较高优先级
    if (task.priority < priority) {
        task.priority = priority;
        [self.taskQueue notifyToRaisePriorityForMergedTask:mergedTask];
    }
    //如果是重用的merge任务，会丢掉begun callback（mergedTask在之前已经触发了beguncallback），之后触发completeCallback
    //需要在这里补一次回调
    //尚不明确每次begunCallback有什么问题，谨慎起见只在分包场景下会有这次回调
    // update: 2022.8.24 非分包场景，包下载任务重场景下打开小程序必现加载失败 https://lark-oncall.bytedance.net/tickets/ticket_16611561322000411?activeTab=message
    bool fixMergeTask = [EEFeatureGating boolValueForKey: EEFeatureGatingKeyFixMergePackageDownloadTask];
    if ((fixMergeTask || context.isSubpackageEnable) &&
        responseHandler.begunBlock) {
        responseHandler.begunBlock(mergedTask.packageReader);
    }
    
    // 判断是否复用了预下载任务，用于埋点
    if (downloadContext.packageContext.readType == BDPPkgFileReadTypePreload && context.readType != BDPPkgFileReadTypePreload) {
        downloadContext.isReusePreload = YES;
    }
    return task;
}

/// 停止下载任务
- (BOOL)stopDownloadTaskWithContext:(BDPPackageContext *)context error:(OPError **)error {
    if (!context) {
        NSString *errorMessage = @"context is empty";
        OPError *contextError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_download_invalid_params, errorMessage);
        if (error) {
            *error = contextError;
        }
        return NO;
    }
    return [self stopDownloadTaskWithUniqueID:context.uniqueID packageName:context.packageName error:error];
}
- (BOOL)stopDownloadTaskWithUniqueID:(OPAppUniqueID *)uniqueID packageName:(NSString*)packageName error:(OPError **)error {
    OPError *taskIDError;
    // TODO: yinyuan 确认 identifier 当做 appID 使用
    NSString *taskID = [BDPPackageDownloadContext taskIDWithUniqueID:uniqueID packageName:packageName error:&taskIDError];
    if (taskIDError) {
        if (error) {
            *error = taskIDError;
        }
        return NO;
    }

    BDPPackageDownloadMergedTask *mergedTask = [self.taskQueue finishMergedTaskWithTaskID:taskID];
    BDPPkgDownloadTask *task = mergedTask.task;
    [mergedTask trackDownloadResultForTask:task error:nil];
    [mergedTask handleDownloadFinishedTask:task cancelled:YES withError:nil];

    BDPLogTagInfo(BDPTag.packageManager, @"package download task stopped for id(%@)", task.uniqueId);
    return YES;
}

#pragma mark - utils
- (BOOL)packageIsDownloadingForUniqueID:(BDPUniqueID *)uniqueID {
    // TODO: yinyuan 这里发现一个 ID 混用的 bug，请想办法修复
    return [self.taskQueue isMergedTaskExecutingForTaskID:uniqueID.identifier];
}

/// 清除下载队列
- (void)clearAllDownloadTasks {
    [self.taskQueue finishAllMergedTasks];
}

@end
