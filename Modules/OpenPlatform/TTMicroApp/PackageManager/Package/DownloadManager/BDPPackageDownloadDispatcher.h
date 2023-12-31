//
//  BDPPackageDownloadDispatcher.h
//  Timor
//
//  Created by houjihu on 2020/5/22.
//

#import <Foundation/Foundation.h>
#import "BDPPackageModuleProtocol.h"
#import "BDPPackageContext.h"

NS_ASSUME_NONNULL_BEGIN

/// 代码包下载任务管理派发
@interface BDPPackageDownloadDispatcher : NSObject

/// 下载安装包
/// @param context 包管理所需上下文
/// @param priority 下载优先级
/// @param begunBlock 开始下载回调。针对流式包，会返回packageReader
/// @param progressBlock 下载进度回调，取值范围[0，1]，含义同NSURLSessionTaskPriorityDefault等定义
/// @param completedBlock 下载结果回调
- (void)downloadPackageWithContext:(BDPPackageContext *)context
                          priority:(float)priority
                             begun:(nullable BDPPackageDownloaderBegunBlock)begunBlock
                          progress:(nullable BDPPackageDownloaderProgressBlock)progressBlock
                         completed:(nullable BDPPackageDownloaderCompletedBlock)completedBlock;

/// 取消包下载任务
/// @param context 包管理所需上下文
/// @param error 错误信息
- (BOOL)stopDownloadTaskWithContext:(BDPPackageContext *)context error:(OPError **)error;
//根据包名和uniqueID，取消下载任务
- (BOOL)stopDownloadTaskWithUniqueID:(OPAppUniqueID *)uniqueID packageName:(NSString*)packageName error:(OPError **)error;

/// 判断是否正在下载指定的小程序包
/// @param uniqueID 包管理所需应用唯一标识
- (BOOL)packageIsDownloadingForUniqueID:(nonnull BDPUniqueID *)uniqueID;

/// 清除下载队列
- (void)clearAllDownloadTasks;
@end

NS_ASSUME_NONNULL_END
