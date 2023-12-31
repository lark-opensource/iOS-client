//
//  BDDownloadManager.h
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/28.
//

#import <Foundation/Foundation.h>
#import "BDDownloadTask.h"
#import "BDWebImageDownloader.h"

/**
 如果任务超过并行上限则会进入等待队列，BDDownloadStackMode指定了等待队列的模式
 */

typedef NS_ENUM(NSUInteger, BDDownloadStackMode)
{
    BDDownloadStackModeFIFO = 0,//先进先出
    BDDownloadStackModeLIFO = 1,//后进先出
    BDDownloadStackModeDefault = BDDownloadStackModeFIFO,
};

@class BDDownloadManager;

@protocol BDDownloadManagerTaskDelegate

/**
 任务下载失败
 @param downloader 当前的下载器
 @param task 当前下载的任务
 @param error 错误码
 */
- (void)downloader:(BDDownloadManager *)downloader
              task:(BDDownloadTask *)task
   failedWithError:(NSError *)error;

/**
 任务下载成功
 @param downloader 当前的下载器
 @param task 当前下载的任务
 @param data 下载的数据
 @param savePath 数据保存的位置
 */
- (void)downloader:(BDDownloadManager *)downloader
              task:(BDDownloadTask *)task
  finishedWithData:(NSData *)data
          savePath:(NSString *)savePath;

@optional
- (void)downloader:(BDDownloadManager *)downloader
               task:(BDDownloadTask *)task
      receivedSize:(NSInteger)receivedSize
      expectedSize:(NSInteger)expectedSize;

- (void)downloader:(BDDownloadManager *)downloader
              task:(BDDownloadTask *)task
    didReceiveData:(NSData *)data
          finished:(BOOL)finished;

// heic 缩略图解码repack功能相关
/**
 是否是需要剥离缩略图的heic图
 */
- (BOOL)isRepackNeeded:(NSData *)data;

/**
 剥离heic缩略图
 */
- (NSMutableData *)heicRepackData:(NSData *)data;

@end

@interface BDDownloadManager : NSObject <BDWebImageDownloaderInfo, BDWebImageDownloaderDownloading, BDWebImageDownloaderManagement>

@property (nonatomic, weak) id<BDDownloadManagerTaskDelegate> delegate;

@property (nonatomic, assign) BDDownloadStackMode stackMode DEPRECATED_MSG_ATTRIBUTE("Unused interface, new version is deprecated");    ///< 等待队列模式，deprecated
@property (nonatomic, copy) NSString *tempPath;   ///< 临时文件缓存位置，默认为NSTemporaryDirectory();
@property (nonatomic, assign) BOOL downloadResumeEnabled;   ///< 是否支持断点续传
@property (nonatomic, strong) NSOperationQueue *operationQueue; ///< 具体执行下载任务的queue
@property (nonatomic, strong, readonly) NSArray<BDDownloadTask *> *allTasks;    ///< 当前所有下载任务
@property (nonatomic, strong) Class downloadTaskClass;  ///< 具体执行下载任务实例的类

@end
