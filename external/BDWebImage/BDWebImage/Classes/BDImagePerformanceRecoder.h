//
//  BDImagePerformanceRecoder.h
//  BDWebImage
//
//  Created by fengyadong on 2017/12/6.
//

#import <Foundation/Foundation.h>
#import "BDImageCache.h"
#import "BDWebImageRequest.h"
#import "BDImage.h"

typedef NS_ENUM(NSUInteger, BDImageExceptionType) {
    BDImageExceptionDefault = 0,        /// 无异常情况，正常请求
    BDImageExceptionBackground,         /// 后台统计监控数据，加载耗时异常
    BDImageExceptionBGWeaknet,          /// 后台弱网
    BDImageExceptionFGWeaknet,          /// 前台弱网
};

@interface BDImagePerformanceRecoder : NSObject

#pragma mark - 创建 recorder 的方法

@property(weak, readonly, nullable) BDWebImageRequest *request;

- (instancetype _Nullable)init __attribute__((unavailable("use initWithRequest:")));

- (instancetype _Nullable)initWithRequest:(BDWebImageRequest * _Nullable)request;

#pragma mark - 生成 recorder 数据

- (NSDictionary<NSString *, id> * _Nullable)imageMonitorV2Log;

#ifdef DEBUG
- (NSString * _Nullable)description;
#endif

#pragma mark - 设置 recorder 相关数据

@property (nonatomic, assign, readwrite) BOOL enableReport;/** 是否进行上报，控制重复请求只上报一次 */

@property (nonatomic, copy, readwrite, nullable) NSString *identifier;/** 请求标示 */
@property (nonatomic, copy, readwrite, nullable) NSString *category;/** 所属模块 */

@property (nonatomic, strong, readwrite, nullable) NSURL *imageURL; /** 图片url*/
@property (nonatomic, copy, readwrite, nullable) NSString *mimeType;/** 图片类型*/

@property (nonatomic, assign, readwrite) double timeStamp;/** 开始时间戳 */
@property (nonatomic, assign, readwrite) double overallStartTime;/** 整体开始时间 */
@property (nonatomic, assign, readwrite) BDImageRequestOptions options; /** 请求设置 */

@property (nonatomic, strong, readwrite, nullable) NSError *error;
@property (nonatomic, assign, readwrite) NSInteger statusCode;/** http请求状态码*/

//Resolition
@property (nonatomic, assign, readwrite) CGSize requestImageSize; /** 业务请求的size */
@property (nonatomic, assign, readwrite) CGSize originalImageSize;/** 图片原始的size */
@property (nonatomic, assign, readwrite) CGSize viewSize;/** 图片原始的size */

//Cache
@property (nonatomic, assign, readwrite) double cacheSeekStartTime;/** 缓存开始查找时间 */
@property (nonatomic, assign, readwrite) double cacheSeekEndTime;/** 缓存结束查找时间 */
@property (nonatomic, assign, readwrite) double thumbCacheSeekStartTime;/** 缩略图缓存开始查找时间 */
@property (nonatomic, assign, readwrite) double thumbCacheSeekEndTime;/** 缩略图缓存结束查找时间 */
@property (nonatomic, readonly) double cacheSeekDuration;/** 缓存查找耗时 单位ms */
@property (nonatomic, readonly) double thumbCacheSeekDuration;/** 缩略图缓存查找耗时 单位ms */
@property (nonatomic, assign, readwrite) BDImageCacheType cacheType;/** 命中缓存类型 */
    
// queue
@property (nonatomic, readonly) double queueDuration;/** 排队耗时 单位ms */

//Download
@property (nonatomic, assign, readwrite) double downloadStartTime;/** 下载开始时间 */
@property (nonatomic, assign, readwrite) double downloadEndTime;/** 下载结束时间 */
@property (nonatomic, strong, readwrite, nullable) NSNumber *DNSDuration;/** DNS耗时 单位ms */
@property (nonatomic, strong, readwrite, nullable) NSNumber *connetDuration;/** 建立连接耗时 单位ms */
@property (nonatomic, strong, readwrite, nullable) NSNumber *sslDuration;/** SSL建连耗时 单位ms */
@property (nonatomic, strong, readwrite, nullable) NSNumber *sendDuration;/** 发送耗时 单位ms */
@property (nonatomic, strong, readwrite, nullable) NSNumber *waitDuration;/** 等待耗时 单位ms */
@property (nonatomic, strong, readwrite, nullable) NSNumber *receiveDuration;/** 接收耗时 单位ms */
@property (nonatomic, readonly) double downloadDuration;/** 下载总体耗时 单位ms */

@property (nonatomic, assign, readwrite) double totalBytes;   /** 图片大小 单位byte */
@property (nonatomic, assign, readwrite) double receivedBytes; /** 已经接收的图片大小 单位byte */
@property (nonatomic, strong, readwrite, nullable) NSNumber *isSocketReused;
@property (nonatomic, strong, readwrite, nullable) NSNumber *isCached;
@property (nonatomic, strong, readwrite, nullable) NSNumber *isFromProxy;
@property (nonatomic, copy,   readwrite, nullable) NSString *remoteIP;
@property (nonatomic, strong, readwrite, nullable) NSNumber *remotePort;
@property (nonatomic, copy,   readwrite, nullable) NSString *requestLog;
@property (nonatomic, copy, readwrite, nullable) NSString *nwSessionTrace;/*图片系统在response header中增加的追踪信息，目前包含回复时间戳和处理总延迟*/

@property (nonatomic, copy, readwrite, nullable) NSDictionary *responseHeaders;   /*上报response header中的相关字段*/
@property (nonatomic, strong, readwrite, nullable) NSNumber *isHitCDNCache;  ///< 是否命中CDN缓存
@property (nonatomic, copy, readwrite, nullable) NSString *imageXDemotion;  ///<处理是否降级
@property (nonatomic, copy, readwrite, nullable) NSString *imageXWantedFormat;      ///<请求的图片格式
@property (nonatomic, copy, readwrite, nullable) NSString *imageXRealGotFormat;      ///<真实下发的图片格式
@property (nonatomic, strong, readwrite, nullable) NSNumber *imageXConsistent;    ///<比较请求格式与解码的图片格式，1为相同，0为不同，-1为未知


//Decode
@property (nonatomic, assign, readwrite) BDImageCodeType codeType;/** 图片编码方式 */
@property (nonatomic, assign, readwrite) double decodeStartTime;/** 解码开始时间 */
@property (nonatomic, assign, readwrite) double decodeEndTime;/** 解码结束时间 */
@property (nonatomic, assign, readwrite) double thumbDecodeStartTime;/** 缩略图解码开始时间 */
@property (nonatomic, assign, readwrite) double thumbDecodeEndTime;/** 缩略图解码结束时间 */
@property (nonatomic, readonly) double decodeDuration;/** 解码耗时 单位ms */
@property (nonatomic, readonly) double thumbDecodeDuration;/** 缩略图解码耗时 单位ms */
@property (nonatomic, copy, readwrite, nullable) NSString *isDecodeImageQualityAbnormal; /** 是否解码异常，出现白屏/黑屏，1为异常*/

//setImage
@property (nonatomic, assign, readwrite) double cacheImageBeginTime;/** 缓存图片开始时间 */
@property (nonatomic, assign, readwrite) double cacheImageEndTime;/** 缓存图片结束时间 */
@property (nonatomic, readonly) double cacheImageDuration;/** 缓存图片耗时 单位ms */

@property (nonatomic, assign, readwrite) double overallEndTime;/** 整体结束时间 */
@property (nonatomic, readonly) double overallDuration;/** 整体耗时 单位ms */

//Thumbnail For Heic
@property (nonatomic, assign, readwrite) double repackStartTime;/** 缩略图repack开始时间 */
@property (nonatomic, assign, readwrite) double repackEndTime;/** 缩略图repack结束时间 */
@property (nonatomic, assign, readwrite) double thumbFindLocationEndTime;/** 找到缩略图位置结束时间 */
@property (nonatomic, assign, readwrite) double thumbDownloadEndTime;/** 缩略图下载结束时间 */
@property (nonatomic, assign, readwrite) double thumbOverallEndTime;/** 缩略图整体结束时间 */
@property (nonatomic, assign, readwrite) double thumbBytes;   /** 图片大小 单位byte */
@property (nonatomic, readonly) double repackDuration;/** repack总用时 */
@property (nonatomic, readonly) double thumbFindLocationDuration;/** 缩略图总用时 */
@property (nonatomic, readonly) double thumbDownloadDuration;/** 缩略图下载总用时 */
@property (nonatomic, readonly) double thumbOverallDuration;/** 缩略图整体总用时 */

// Exception
@property (nonatomic, assign, readwrite) BDImageExceptionType exceptionType;/** 是否存在异常 case */

@end
