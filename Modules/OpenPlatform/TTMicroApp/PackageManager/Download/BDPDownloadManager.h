//
//  BDPDownloadManager.h
//  Timor
//
//  Created by 傅翔 on 2019/1/22.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPRequestMetrics.h>
#import "BDPHttpDownloadTask.h"
#import <OPFoundation/BDPTracing.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^BDPDownloadReceivedDataBlk)(NSData *data,
                                           int64_t receivedBytes, // 所有已接收的总字节数
                                           int64_t totalBytes,  // 应下载的总字节数
                                           NSUInteger statusCode);
typedef void (^BDPDownloadCompletedBlk)(NSError *_Nullable error, // error为nil则成功完成
                                        BDPRequestMetrics *_Nullable metrics); // iOS10及以上才有metrics

/**
 通用下载管理器
 */
@interface BDPDownloadManager : NSObject

/** 当前正在进行的下载任务 */
@property (nonatomic, readonly) NSArray<NSURLSessionDataTask *> *tasks;

+ (instancetype)managerWithSessionConfiguration:(nullable NSURLSessionConfiguration *)config
                               andDelegateQueue:(nullable NSOperationQueue *)queue;

- (instancetype)init __attribute__((unavailable("请使用managerWithSessionConfiguration:andDelegateQueue:")));

/**
 创建下载任务
 
 @param request NSURLRequest
 @param recvDataBlk 数据段接收回调
 @param completedBlk 完成回调
 @param trace Request Tracing
 @return NSURLSessionDataTask
 */
- (BDPHttpDownloadTask *)taskWithRequest:(NSURLRequest *)request
                         receivedDataBlk:(nullable BDPDownloadReceivedDataBlk)recvDataBlk
                            completedBlk:(BDPDownloadCompletedBlk)completedBlk
                                   trace:(BDPTracing *)trace;

@end

NS_ASSUME_NONNULL_END
