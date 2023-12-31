//
//  BDPAppManagerCommonObj.h
//  Timor
//
//  Created by liubo on 2018/12/7.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPNetworkOperation.h>
#import <OPFoundation/BDPModel.h>

#define kBDPAppManagerLogTag    @"Load"

static inline NSString *BDPEmptyStringIfNil(NSString *string){ return [string length] > 0 ? string : @""; }

extern NSString * const BDPAppManagerErrorDomain;
extern NSString * const BDPOriginNetworkErrorKey;

#define kBDPAppUpdateRequestKeyStartTime    @"startTime"
#define kBDPAppUpdateRequestKeyEndTime      @"endTime"

#pragma mark - BDPAppManagerErrorCode

typedef NS_ENUM(NSInteger, BDPAppManagerErrorCode){
    BDPAppManagerErrorUnknow = 0,           //未知错误(占位兜底)
    BDPAppManagerErrorInvalidParams = 1,    //参数无效
    BDPAppManagerErrorNetwork = 2,          //网络错误
    BDPAppManagerErrorEncryptFailed = 3,    //加密失败
    BDPAppManagerErrorInvaildDownloadPath=4,//下载地址无效
    BDPAppManagerErrorInvalidMD5 = 5,       //md5校验失败
    BDPAppManagerErrorUnzipFailed = 6,      //解压失败
    BDPAppManagerErrorMoveFileFailed = 7,   //移动文件失败
    BDPAppManagerErrorNetworkCancelled = 8, //下载取消
    BDPAppManagerErrorPreempted = 9,        //下载任务被抢占
    BDPAppManagerErrorResponseError,        // response body 返回的error 非0。
    BDPAppManagerErrorInvaildResponseBody,  // response body 不能解析。
    BDPAppManagerErrorInvaildModelVersion,
};

#pragma mark - BDPAppModelFetchType

typedef NS_ENUM(NSInteger, BDPAppModelFetchType){
    BDPAppModelFetchTypeNone = 0,   //无信息
    BDPAppModelFetchTypeLocal = 1,  //从本地获取
    BDPAppModelFetchTypeServer = 2, //从服务端获取
};

#pragma mark - BDPAppDataFetchType

typedef NS_ENUM(NSInteger, BDPAppDataFetchType){
    BDPAppDataFetchTypeNone = 0,    //无信息
    BDPAppDataFetchTypeLocal = 1,   //从本地获取
    BDPAppDataFetchTypeServer = 2,  //从服务端获取
    BDPAppDataFetchTypeAsync = 3,   //从异步加载结果获取
    BDPAppDataFetchTypePreload = 4, //从预加载结果获取
};

#pragma mark - BDPAppUpdateRequestType

typedef NS_ENUM(NSInteger, BDPAppUpdateRequestType){
    BDPAppUpdateRequestTypeNone = 0,    //无信息
    BDPAppUpdateRequestTypeNormal = 1,  //正常加载
    BDPAppUpdateRequestTypeSilence = 2, //后台加载
    BDPAppUpdateRequestTypePreload = 3, //预加载
};

/**
 @brief 处理Model获取结果，返回将要加载的model信息（注意：该block将会被同步调用，不建议上层在该block中处理长时间任务）
 @param fetchType MetaInfo的获取类型
 @param appModel 获取到的MetaInfo
 @param error 获取MetaInfo的错误信息
 @param domainStatus 每个域名的请求结果
 @param shouldDownload 是否继续下载AppData
 */
typedef void (^AppModelCompletionBlock)(BDPAppModelFetchType fetchType, BDPModel *appModel, NSError *error, NSDictionary *domainStatus, BOOL *shouldDownload);

/**
 @brief 处理Data获取进度，下载app包过程回调，可用来处理界面加载进度
 @param percent 下载百分比
 @param elapsedTime 下载百分比对应的耗时
 */
typedef void (^AppDataProgressBlock)(CGFloat percent, NSTimeInterval elapsedTime);

/**
 @brief 处理Data获取结果，app包下载完成后返回对应的BDPModel
 @param fetchType AppData获取类型
 @param appModel AppData对应的BDPModel
 @param error 获取AppData的错误信息
 @param domainStatus 每个域名的请求结果
 */
typedef void (^AppDataCompletionBlock)(BDPAppDataFetchType fetchType, BDPModel *appModel, NSError *error, NSDictionary *domainStatus);

/**
 @brief 处理后台Model获取结果，后台获取完MetaInfo信息后回调结果
 @param appModel 后台获取到的MetaInfo
 @param error 获取MetaInfo的错误信息
 @param domainStatus 每个域名的请求结果
 */
typedef void (^AppSilenceModelCompletionBlock)(BDPModel *appModel, NSError *error, NSDictionary *domainStatus);

/**
 @brief 处理后台下载结果，后台下载最新版本完成后回调下载结果
 @param fetchType AppData获取类型
 @param appModel 后台下载AppData对应的BDPModel
 @param error 后台获取AppData的错误信息
 @param domainStatus 每个域名的请求结果
 */
typedef void (^AppSilenceDataCompletionBlock)(BDPAppDataFetchType fetchType, BDPModel *appModel, NSError *error, NSDictionary *domainStatus);
