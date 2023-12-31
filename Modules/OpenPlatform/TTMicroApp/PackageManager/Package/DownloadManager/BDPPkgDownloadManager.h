//
//  BDPPkgDownloadManager.h
//  Timor
//
//  Created by 傅翔 on 2019/1/22.
//

#import <Foundation/Foundation.h>
#import "BDPAppDownloadTaskDelegate.h"
#import <OPFoundation/BDPTracing.h>
#import <OPFoundation/BDPUniqueID.h>

NS_ASSUME_NONNULL_BEGIN

/**
 应用代码包下载管理器.
 
 负责下载任务及对应delegate管理. 同时通过Notification将特定事件丢出。方便其他业务使用(比如埋点)
 */
@interface BDPPkgDownloadManager : NSObject

/// 判断是否正在下载
- (BOOL)hasDowloadForTaskID:(NSString *)taskID;

/// 创建下载任务，并开始下载
- (BDPPkgDownloadTask *)startDownloadWithTaskID:(NSString *)taskID
                                        requestURLs:(NSArray<NSURL *> *)requestURLs
                                           priority:(float)priority
                                           uniqueId:(BDPUniqueID *)uniqueId
                                            addGzip:(BOOL)addGzip
                                      canDownloadBr:(BOOL)useBr
                                       taskDelegate:(id<BDPAppDownloadTaskDelegate>)taskDelegate
                                              trace:(BDPTracing *)trace;
/// 使用已有下载任务，开始下载
- (void)startDownloadWithTask:(BDPPkgDownloadTask *)task;

/// 取消下载任务。task.delegate会置为nil，不再触发回调
- (void)stopDownloadForTaskID:(NSString *)taskID;
/// 取消包含指定前缀的所有下载任务
- (void)stopDownloadWithPrefix:(NSString *)prefix;
/// 移除任务
- (void)removeTaskWithTaskID:(NSString *)taskID;

/// 调整下载任务的优先级
- (void)setPriority:(float)priority withTaskID:(NSString *)taskID;

@end

NS_ASSUME_NONNULL_END
