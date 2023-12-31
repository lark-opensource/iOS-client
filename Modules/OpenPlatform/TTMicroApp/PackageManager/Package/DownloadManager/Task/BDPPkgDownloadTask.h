//
//  BDPPkgDownloadTask.h
//  Timor
//
//  Created by 傅翔 on 2019/1/22.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPTracing.h>
#import <OPFoundation/BDPUniqueID.h>

@class BDPRequestMetrics;
@class BDPHttpDownloadTask;

@protocol BDPAppDownloadTaskDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 文件下载任务对象
 
 记录下载Task, delegate等
 */
@interface BDPPkgDownloadTask : NSObject

/** BDPHttpDownloadTask的创建没有持有该对象，需当前实例来强持有.  停止后会释放 */
@property (nonatomic, strong, nullable) BDPHttpDownloadTask *downloadTask;

/// 下载任务标识
@property (nonatomic, copy) NSString *taskID;

/// unique id
@property (nonatomic, strong) BDPUniqueID *uniqueId;

/// 下载代理
@property (nonatomic, weak) id<BDPAppDownloadTaskDelegate> delegate;

/// 下载地址数组，下载过程中会逐个重试直到遍历完成或下载成功
@property (nonatomic, copy) NSArray<NSURL *> *requestURLs;
@property (nonatomic, assign, readonly) NSUInteger urlIndex;
/// 当前下载地址
@property (nonatomic, readonly) NSURL *requestURL;
/// 是否正在请求最后一个下载地址
@property (nonatomic, readonly) BOOL isLastRequestURL;
/// 上一个下载地址
@property (nonatomic, readonly) NSURL *prevRequestURL;

/// 优先级
@property (nonatomic, assign) float priority;

/** 下载开始时间 */
@property (nonatomic, readonly, strong) NSDate *beginDate;
/// 下载结束时间
@property (nonatomic, readonly, strong) NSDate *endDate;

/** 请求头添加gzip, deflate */
@property (nonatomic, assign) BOOL addGzip;

/// 下载Br压缩的文件
@property (nonatomic, assign) BOOL isDownloadBr;

/// 用于标记 PackageContext 的Trace
@property (nonatomic, strong) BDPTracing *trace;

/// 开始下载
- (void)startTask;
/// 暂停下载
- (void)suspendTask;
/// 取消下载
- (void)stopTask;

/// 记录当前结束时间
- (void)recordEndTime;
/// 尝试下一个下载链接
- (void)tryNextUrl;

/// 如果是br格式，则解压后返回；否则原样返回
- (NSData *)decodeData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
