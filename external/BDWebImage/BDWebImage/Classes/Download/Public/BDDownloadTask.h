//
//  BDDownloadTask.h
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/28.
//

#import <Foundation/Foundation.h>
#import "BDWebImageDownloader.h"

@class BDDownloadTask;

typedef NS_ENUM(NSUInteger, BDDownloadTaskOptions)
{
    BDDownloadTaskDefaultOption = 0,
    BDDownloadTaskLowPriority = 1<<0,
    BDDownloadTaskHighPriority = 1<<1,
};

extern NSString *const kBDDownloadTaskInfoHTTPResponseHeaderKey;
extern NSString *const kBDDownloadTaskInfoHTTPRequestHeaderKey;
extern NSString *const kBDDownloadTaskInfoOriginalURLKey;
extern NSString *const kBDDownloadTaskInfoCurrentURLKey;
extern NSString *const kHTTPResponseCacheControl;
extern NSString *const kHTTPResponseContentLength;
extern NSString *const kHTTPResponseContentType;
extern NSString *const kHTTPResponseImageMd5;
extern NSString *const kHTTPResponseImageXLength;
extern NSString *const kHTTPResponseImageXCropRs;
extern NSString *const kHTTPResponseCache;
extern NSString *const kHTTPImageXDemotion;
extern NSString *const kHTTPImageXFmt;

@protocol BDDownloadTaskDelegate <NSObject>
- (void)downloadTask:(BDDownloadTask *)task failedWithError:(NSError *)error;
- (void)downloadTask:(BDDownloadTask *)task finishedWithData:(NSData *)data savePath:(NSString *)savePath;
- (void)downloadTaskDidCanceled:(BDDownloadTask *)task;

@optional
- (void)downloadTask:(BDDownloadTask *)task receivedSize:(NSInteger)receivedSize expectedSize:(NSInteger)expectedSize;
- (void)downloadTask:(BDDownloadTask *)dataTask didReceiveData:(NSData *)data finished:(BOOL)finished;

//heic 缩略图解码repack功能相关
- (BOOL)isRepackNeeded:(NSData *)data; //是否是需要剥离缩略图的heic图
- (NSMutableData *)heicRepackData:(NSData *)data;//剥离heic缩略图
@end

@interface BDDownloadTask : NSOperation <BDWebImageDownloadTaskBaseInfo, BDWebImageDownloadTaskHEICProgressiveInfo, BDWebImageDownloadTaskTimeInfo>

@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *defaultHeaders;//http request default headers
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *requestHeaders;   ///< 每个请求单独的 headers

@property (nonatomic, assign) BDDownloadTaskOptions options;

@property (nonatomic, copy) NSString *tempPath;//临时文件缓存路径，由DownloadManager管理

@property (nonatomic, assign) BOOL downloadResumeEnabled;//是否支持断点续传
@property (nonatomic, weak) id<BDDownloadTaskDelegate> delegate;

@property (nonatomic, assign) BOOL enableLog;
@property (nonatomic, assign) BOOL checkMimeType;
@property (nonatomic, assign) BOOL checkDataLength;
@property (nonatomic, assign) BOOL isCocurrentCallback; // default : NO

@property (nonatomic, assign) BOOL isProgressiveDownload; //是否是渐进下载

- (instancetype)initWithURL:(NSURL *)url;

- (void)setupSmartCropRectFromHeaders:(NSDictionary *)headers;

- (NSError *)checkDataError:(NSError *)error data:(NSData *)data dataSizeBias:(NSInteger)dataSizeBias headers:(NSDictionary *)headers;

- (void)repackStart;
- (void)repackEnd;

+ (NSInteger) getCacheControlTimeFromResponse:(NSString *)cacheControl;
+ (BOOL)checkData:(NSData *)data md5:(NSString *)md5;

@end
