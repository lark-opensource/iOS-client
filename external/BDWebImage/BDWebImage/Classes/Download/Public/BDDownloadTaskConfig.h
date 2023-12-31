//
//  BDDownloadTaskConfig.h
//  BDWebImage
//
//  Created by wby on 2021/11/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDDownloadTaskConfig : NSObject

@property (nonatomic, assign) NSOperationQueuePriority priority;    ///< 任务优先级

@property (nonatomic, assign) CFTimeInterval timeoutInterval;       ///< 服务器响应时间， Chrome下载器默认为15s，NSURLSession 下载器默认为 30s
    
@property (nonatomic, assign) BOOL immediately;

@property (nonatomic, assign) BOOL progressDownload;                ///< 是否开启渐进式

@property (nonatomic, assign) BOOL progressDownloadForThumbnail;    ///< 是否开启 HEIC 静图渐进式

@property (nonatomic, assign) BOOL verifyData;      ///< 数据校验

@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *requestHeaders;   ///< 每个请求单独的 headers

@end

NS_ASSUME_NONNULL_END
