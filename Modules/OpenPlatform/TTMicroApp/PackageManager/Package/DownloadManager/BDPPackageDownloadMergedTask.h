//
//  BDPPackageDownloadMergedTask.h
//  Timor
//
//  Created by houjihu on 2020/7/6.
//

#import <Foundation/Foundation.h>
#import "BDPAppDownloadTaskDelegate.h"
#import "BDPPkgFileWriteHandleProtocol.h"
#import <OPFoundation/BDPPkgFileReadHandleProtocol.h>

@class BDPPkgDownloadTask, BDPPackageDownloadContext, OPError;

NS_ASSUME_NONNULL_BEGIN

/// 应用代码包下载器，管理单个下载任务的代理方法
@interface BDPPackageDownloadMergedTask : NSObject <BDPAppDownloadTaskDelegate>

/// 下载标识
@property (nonatomic, copy, readonly) NSString *taskID;
/// 下载优先级
@property (nonatomic, assign) float priority;
/// 下载任务
@property (nonatomic, strong) BDPPkgDownloadTask *task;
/// 下载上下文
@property (nonatomic, strong, readonly) BDPPackageDownloadContext *downloadContext;

/// 开始下载任务回调
@property (nonatomic, copy) void (^startDownloadTaskCompletion)();
/// 结束下载任务的回调，但不对外部回调结果，后续仍可恢复下载
@property (nonatomic, copy) void (^stopDownloadTaskCompletion)();
/// 重试下载任务回调
@property (nonatomic, copy) void (^retryDownloadTaskCompletion)();
/// 清理下载任务的回调，对外部回调结果，后续不再下载
@property (nonatomic, copy) void (^clearDownloadTaskCompletion)();
/// 下载任务完成回调
@property (nonatomic, copy) void (^downloadTaskFinishedCompletion)(NSError *error);

/// 指定appID和pkgName的文件读取器。在下载过程中返回
/// 需要保证下载的过程中，reader存在。
/// reader的生命周期大于等于downloadTask，启动场景下外部需要持有，以保证后续可以访问代码包内的文件。
@property (nonatomic, strong, readonly) id<BDPPkgFileManagerHandleProtocol> packageReader;

/// 初始化
- (instancetype)initWithDownloadContext:(BDPPackageDownloadContext *)downloadContext taskID:(NSString *)taskID;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

#pragma mark - Task management
/// 开始执行下载任务
- (void)startTask;

/// 中止任务，后续仍可恢复下载
- (void)stopTask;

/// 清理任务，后续不再下载
- (void)clearTask;

#pragma mark - Update Info

/// 更新包信息记录
- (void)updateBasicInfo;

/// 下载结果埋点
- (void)trackDownloadResultForTask:(BDPPkgDownloadTask *)task error:(NSError *)error;

/// 回调下载结果
- (void)handleDownloadFinishedTask:(BDPPkgDownloadTask *)task cancelled:(BOOL)cancelled withError:(OPError *)error;

/// 删除下载产物
- (void)resetFileHandleAndCacheWithError:(NSError **)error;

/// 开始下载前，检查文件是否需要重置
- (BOOL)shouldResetAppFileDataBeforeDownloadingWithLastFileOffset:(uint64_t)lastFileOffset resetError:(OPError **)resetError;

@end

NS_ASSUME_NONNULL_END
