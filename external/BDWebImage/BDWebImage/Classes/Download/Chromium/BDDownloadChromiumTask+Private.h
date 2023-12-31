//
//  BDDownloadChromiumTask+Private.h
//  BDWebImage
//
//  Created by fengyadong on 2017/12/5.
//

#import "BDDownloadChromiumTask.h"
#import <TTNetworkManager/TTHttpTask.h>

@interface BDDownloadChromiumTask()<BDWebImageDownloadTaskResponseInfo>

@property (nonatomic, strong) TTHttpTask *task;
@property (nonatomic, strong) NSNumber *DNSDuration;  ///< DNS耗时 单位ms
@property (nonatomic, strong) NSNumber *connetDuration;   ///< 建立连接耗时 单位ms
@property (nonatomic, strong) NSNumber *sslDuration;  ///< SSL建连耗时 单位ms
@property (nonatomic, strong) NSNumber *sendDuration; ///< 发送耗时 单位ms
@property (nonatomic, strong) NSNumber *waitDuration; ///< 等待耗时 单位ms
@property (nonatomic, strong) NSNumber *receiveDuration;  ///< 接收耗时 单位ms
@property (nonatomic, strong) NSNumber *totalDuration;    ///< 下载总耗时 单位ms
@property (nonatomic, assign) NSInteger cacheControlTime; ///< 缓存控制时间
@property (nonatomic, strong) NSNumber *isSocketReused;
@property (nonatomic, strong) NSNumber *isCached;
@property (nonatomic, strong) NSNumber *isFromProxy;
@property (nonatomic, copy) NSString *remoteIP;
@property (nonatomic, strong) NSNumber *remotePort;
@property (nonatomic, copy) NSString *requestLog;
@property (nonatomic, copy) NSString *mimeType;/** 图片类型*/
@property (nonatomic, assign) NSInteger statusCode;/** http请求状态码*/
@property (nonatomic, copy) NSString *nwSessionTrace;/*图片系统在response header中增加的追踪信息，目前包含回复时间戳和处理总延迟*/
@property (nonatomic, copy) NSDictionary *responseHeaders;/**上报response header的相关信息*/
@property (nonatomic, strong) NSNumber *isHitCDNCache;  ///< 是否命中CDN缓存
@property (nonatomic, copy) NSString *imageXDemotion;  ///<处理是否降级
@property (nonatomic, copy) NSString *imageXWantedFormat;      ///<请求的图片格式
@property (nonatomic, copy) NSString *imageXRealGotFormat;      ///<真实下发的图片格式
@property (nonatomic, strong) NSNumber *imageXConsistent;    ///<比较请求格式与解码的图片格式，1为相同，0为不同，-1为未知

@end
