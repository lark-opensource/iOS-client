//
//  BDPAppDownloadTaskDelegate.h
//  Timor
//
//  Created by 傅翔 on 2019/1/28.
//

#import <Foundation/Foundation.h>
@class BDPPkgDownloadTask;

NS_ASSUME_NONNULL_BEGIN

/// 代码包下载任务代理
@protocol BDPAppDownloadTaskDelegate <NSObject>

/// 开始下载前，上次已下载的文件数据offset
- (int64_t)httpRangeOffsetForAppDownloadTask:(BDPPkgDownloadTask *)task;

- (void)ttpkgDownloadTaskWillBegin:(BDPPkgDownloadTask *)task;

- (void)appDownloadTask:(BDPPkgDownloadTask *)task
           receivedData:(NSData *)data
          receivedBytes:(int64_t)receivedBytes
             totalBytes:(int64_t)totalBytes
             httpStatus:(NSUInteger)httpStatus
                  error:(nullable NSError *)error;

- (void)appDownloadTask:(BDPPkgDownloadTask *)task didFinishWithError:(nullable NSError *)error;

- (void)appDownloadTask:(BDPPkgDownloadTask *)task didCancelWithError:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
