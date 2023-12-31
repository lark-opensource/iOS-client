//
//  EffectPlatform.h
//  EffectPlatformSDK
//
//  Created by Keliang Li on 2017/10/29.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IESEffectModel.h"
#import "IESEffectDefines.h"
#import "IESCategoryModel.h"
#import "IESEffectPlatformResponseModel.h"
#import "IESMyEffectModel.h"
#import "IESEffectPlatformNewResponseModel.h"
#import "IESCategoryEffectsModel.h"
#import "IESEffectResourceResponseModel.h"
#import "EffectPlatformCache.h"
#import "IESCategorySampleEffectModel.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const EffectPlatformFinishCleanCacheNotification;

@class IESFileDownloader;
@class IESThirdPartyStickerModel;
@class IESThirdPartyResponseModel;
@class IESAlgorithmRecord;
@class IESEffectAlgorithmModel;

/**
 特效平台Tracking代理
 */
@protocol EffectPlatformTrackingDelegate <NSObject>

/**
 *  Track一个事件
 *
 *  @param serviceName         需要Track的服务名
 *  @param dic                 请求参数
 *  @param status              请求的status
 *
 */
- (void)postTracker:(NSString *)serviceName value:(NSDictionary *)dic status:(NSInteger)status;

@end

/**
 特效平台网络请求代理，用来创建网络请求
 */
@protocol EffectPlatformRequestDelegate <NSObject>

/**
 *  普通网络请求
 *
 *  @param urlString         URL字符串
 *  @param parameters        请求参数
 *  @param headerFields      HTTP 头
 *  @param httpMethod        请求方法
 *  @param completion        请求回调
 *
 */
- (void)requestWithURLString:(NSString *)urlString
                  parameters:(NSDictionary *)parameters
                headerFields:(NSDictionary *)headerFields
                  httpMethod:(NSString *)httpMethod
                  completion:(void (^)(NSError * _Nullable error, id _Nullable result))completion;

/**
 *  下载文件的网络请求
 *
 *  @param urlString         URL字符串
 *  @param path              文件下载位置
 *  @param downloadProgress  进度回调
 *  @param completion        请求回调
 *
 */
- (void)downloadFileWithURLString:(NSString *)urlString
                     downloadPath:(NSURL *)path
                 downloadProgress:(NSProgress * __autoreleasing *)downloadProgress
                       completion:(void (^)(NSError * _Nullable error, NSURL * _Nullable fileURL, NSDictionary * _Nullable extraInfo))completion;

@end

typedef void(^EffectPlatformDownloadProgressBlock)(CGFloat progress);

typedef void(^EffectPlatformMassiveDownloadCompletionBlock)(NSError *_Nullable error, BOOL success);
typedef void(^EffectPlatformDownloadCompletionBlock)(NSError *_Nullable error, NSString  *_Nullable filePath);
typedef void(^EffectPlatformFetchListCompletionBlock)(NSError *_Nullable error, IESEffectPlatformResponseModel *_Nullable response);
typedef void(^EffectPlatformFetchCategoryListCompletionBlock)(NSError *_Nullable error, IESEffectPlatformNewResponseModel *_Nullable response);
typedef void(^EffectPlatformFetchEffectListForCategoryCompletionBlock)(NSError *_Nullable error, IESCategoryEffectsModel *_Nullable response);
typedef void(^EffectPlatformFilterBoxUpdateCompletion)(NSError * _Nullable error, BOOL success);
typedef void(^EffectPlatformFetchMojiResourcesCompletionBlock)(NSError * _Nullable error, IESEffectResourceResponseModel * _Nullable response, NSArray<NSString *> * _Nullable filePaths);
typedef void (^EffectPlatformFetchEffectListCompletion)(NSError *_Nullable error, NSArray<IESEffectModel *> *_Nullable effects, NSArray<IESEffectModel *> *_Nullable bindEffects);
typedef NSDictionary *(^EffectPlatformNetworkParametersBlock)(void);

@interface EffectPlatform : NSObject

@property (atomic, copy) NSString *accessKey;
@property (atomic, copy) NSString *deviceIdentifier;
@property (atomic, copy) NSString *channel;
@property (atomic, copy) NSString *effectVersion;
@property (atomic, copy) NSString *region;
@property (atomic, copy) NSString *appVersion;
@property (atomic, copy) NSString *appId;
@property (atomic, copy) NSString *osVersion;
@property (atomic, copy) NSString *gpu;
@property (atomic, assign) BOOL autoDownloadEffects;
@property (atomic, assign) BOOL didAppUpdated;
@property (nonatomic, copy) NSString *domain;
@property (nonatomic, strong) NSMutableDictionary *downloadingProgressDic;
@property (nonatomic, strong) NSMutableDictionary *downloadingCompletionDic;
@property (nonatomic, strong) dispatch_queue_t networkCallBackQueue;
@property (atomic, copy) EffectPlatformNetworkParametersBlock networkParametersBlock;
@property (nonatomic, copy, nullable) EffectPlatformNetworkParametersBlock extraPerRequestNetworkParametersBlock;
@property (nonatomic, copy) EffectPlatformNetworkParametersBlock iopParametersBlock;
@property (atomic, strong) id<EffectPlatformRequestDelegate>requestDelegate;
@property (nonatomic, weak) id<EffectPlatformTrackingDelegate>trackingDelegate;
@property (atomic, strong) EffectPlatformCache *cache;
@property (nonatomic, strong) NSRecursiveLock *infoDictLock;
@property (nonatomic, readwrite, copy) NSArray<NSString *> *platformURLPrefix; // 从response中获取到的prefix
@property (nonatomic, strong) NSNumber *platformOptimizeStrategy; // 特效平台优化策略

/**
 * 是否开启精简字段的特效列表，开启后，拉取特效列表中的IESEffectModel的fileDownloadURLs和iconDownloadURLs需要使用 urlPrefix 加上 file_uri, icon_uri来拼接生成。默认为NO。
 * 仅设置一次 ⚠️
 */
@property (nonatomic, assign) BOOL enableReducedEffectList;

//先回滚该属性的定义
@property (nonatomic, assign) BOOL enableNewEffectManager DEPRECATED_MSG_ATTRIBUTE("This property was deprecated, please remove the calling");

@property (nonatomic, copy, nullable) void(^dbErrorBlock)(NSError * _Nullable error);


/**
 设置网络请求参数，每次网络请求前都会调用设置的block获取参数，如果没有设置则使用默认的网络请求参数
 @param networkParametersBlock 网络请求参数block
 */
+ (void)setNetworkParametersBlock:(EffectPlatformNetworkParametersBlock)networkParametersBlock;

/**
 设置网络请求参数，每次网络请求前都会调用设置的block获取参数,这个注意每次使用完以后会自动被清除
 @param networkParametersBlock 网络请求参数block
 */
+ (void)setExtraPerRequestNetworkParametersBlock:(EffectPlatformNetworkParametersBlock _Nullable)networkParametersBlock;

/**
 必须调用！！
 必须在配置完参数后调用这个接口，这是个 setup 接口
 请在获取列表前调用该接口
 @param accessKey 部署秘钥，在 应用管理 -> 部署秘钥中可以找到
 @return EffectPlatform 实例
 */
+ (EffectPlatform *)startWithAccessKey:(NSString *)accessKey;

/**
 默认 EffectPlatform 从服务端获取数据后会在内存中保留一份（且常驻）
 支持设置为 NO，当 enableMemoryCache = NO 的时候只有在业务主动获取的时候才会在内存中保留缓存，同时支持业务随时清空
 */
+ (void)setEnableMemoryCache:(BOOL)enable;


+ (EffectPlatform *)sharedInstance;
/**
 缓存的特效
 
 @param panel 面板标识
 @return 缓存的特效列表 model， 若无返回 nil
 */
+ (IESEffectPlatformResponseModel *)cachedEffectsOfPanel:(NSString *)panel;

/**
 缓存的特效
 
 @param panel 面板标识
 @param category 分类标识
 @return 缓存的特效列表 model， 若无返回 nil
 */
+ (IESEffectPlatformNewResponseModel *)cachedEffectsOfPanel:(NSString *)panel category:(NSString *)category;

/**
 缓存的特效(分页缓存)
 
 @param panel 面板标识
 @param category 分类标识
 @param cursor
 @param position
 @return 缓存的特效列表 model， 若无返回 nil
 */
+ (IESEffectPlatformNewResponseModel *)cachedEffectsOfPanel:(NSString *)panel category:(NSString *)category cursor:(NSInteger)cursor sortingPosition:(NSInteger)position;

/**
 缓存的分类
 
 @param panel 面板标识
 @return 缓存的分类/特效列表 model， 若无返回 nil
 */
+ (IESEffectPlatformNewResponseModel *)cachedCategoriesOfPanel:(NSString *)panel;

/**
Cached hot effects

@param panel 面板标识
@param cursor
@param position
@return 缓存的特效列表 model， 若无返回 nil
*/
+ (IESEffectPlatformNewResponseModel *)cachedHotEffectsOfPanel:(NSString *)panel cursor:(NSInteger)cursor sortingPosition:(NSInteger)position;

/**
 清除内存中缓存，目前 EffectPlatform 会在内存中缓存所有的贴纸资源，建议在视频创作流程结束后清除
 */
+ (void)clearMemoryCache;

/**
 清除所有缓存
 */
+ (void)clearCache;

/**
 * ⚠️ 此方法是给开启特效重构使用的，其它业务不要使用 ⚠️
 * 清理所有特效和算法模型
 * 如果开启特效重构，清理下旧目录下的特效和算法模型以节省磁盘空间
 */
+ (void)clearEffectsAndAlgorithms;

/**
 计算EffectPlatform缓存大小，返回值：占用空间，单位：Byte
 */
+ (NSUInteger)cacheSizeOfEffectPlatform;

/**
 save the decrypt response model data
 */
- (void)saveNewResponseModelData:(IESEffectPlatformNewResponseModel *)responseModel withKey:(NSString *)key;

/**
清除列表缓存
*/
+ (void)clearCacheForEffectFolderPath;
/**
 设置 EffectSDK 版本号
 不设置使用默认的 2.0.0

 @param sdkVersion EffectSDK版本号
 */
+ (void)setEffectSDKVersion:(NSString *)sdkVersion;

/**
 设置 App 版本号
 不设置不传
 
 @param appVersion App 版本号
 */
+ (void)setAppVersion:(NSString *)appVersion;

/**
 设置设备唯一 ID
 不设置会默认使用设备 UUID
 
 @param deviceIdentifier 设备ID
 */
+ (void)setDeviceIdentifier:(NSString *)deviceIdentifier;
/**
 Set Channel

 @param channel test/App Store
 */
+ (void)setChannel:(NSString *)channel;

/**
 设置地区，在面板中选择区分国家后生效

 @param region 地区名称
 */
+ (void)setRegion:(NSString *)region;

/**
 设置AppId
 
 @param appId 应用id
 */
+ (void)setAppId:(NSString *)appId;


/**
 设置GPU
 
 @param gpu GPU信息
 */
//+ (void)setGpu:(NSString *)gpu;

/**
 设置系统版本
 
 @param osVersion 系统版本
 */
+ (void)setOsVersion:(NSString *)osVersion;

/**
 设置域名
 不设置使用默认域名

 @param domain 域名
 */
+ (void)setDomain:(NSString *)domain;

/**
 设置网络请求代理
 不设置使用默认的网络请求方式，如果设置则使用网络请求代理来进行网络请求
 
 @param requestDelegate 网络请求代理
 */
+ (void)setRequestDelegate:(id<EffectPlatformRequestDelegate>)requestDelegate;

/**
 设置Tracking代理
 
 @param trackingDelegate tracking代理
 */
+ (void)setTrackingDelegate:(id<EffectPlatformTrackingDelegate>)trackingDelegate;

/**
 设置是否自动下载，若开启，会在拉取列表后自动下载特效
 @param autoDownloadEffects 是否自动下载
 */
+ (void)setAutoDownloadEffects:(BOOL)autoDownloadEffects;

/**
 设置App是否是更新后第一次启动
 @param didAppUpdated 是否是更新后第一次启动
 */
+ (void)setDidAppUpdated:(BOOL)didAppUpdated;

+ (void)setPlatformOptimizeStrategy:(NSNumber *)platformOptimizeStrategy;

+ (void)setEnableReducedEffectList:(BOOL)enableReducedEffectList;

/**
 创建特效下载的文件夹
 @return YES如果创建成功，NO如果创建失败
 */
+ (BOOL)createEffectDownloadFolderIfNeeded;

/******************************************************************************************************************************************
 * EffectPlatform+Additions 使用到的公共接口，非开放接口
******************************************************************************************************************************************/

- (NSString *)cacheKeyPrefixFromCommonParameters;

- (NSDictionary *)commonParameters;

- (void)autoDownloadIfNeededWithNewModel:(IESEffectPlatformNewResponseModel *)model;

@end

@interface EffectPlatform (EffectDownloader)

/**
 检查本地缓存的特效列表与服务器的是否一致

 @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
 @param completion 检查回调，needUpdate 为 YES 的情况下需要更新列表
 */
+ (void)checkEffectUpdateWithPanel:(NSString *)panel
                        completion:(void (^)(BOOL needUpdate))completion;

+ (void)checkEffectUpdateWithPanel:(NSString *)panel
              effectTestStatusType:(IESEffectModelTestStatusType)statusType
                        completion:(void (^)(BOOL))completion;

/**
 检查面板信息是否变化
 
 @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
 @param completion 检查回调，needUpdate 为 YES 的情况下需要更新列表
 */
+ (void)checkPanelUpdateWithPanel:(NSString *)panel
                       completion:(void (^)(BOOL needUpdate))completion;

+ (void)checkPanelUpdateWithPanel:(NSString *)panel
             effectTestStatusType:(IESEffectModelTestStatusType)statusType
                       completion:(void (^)(BOOL needUpdate))completion;

/**
 检查本地缓存的特效列表与服务器的是否一致
 
 @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
 @param category 分类名称
 @param completion 检查回调，needUpdate 为 YES 的情况下需要更新列表
 */
+ (void)checkEffectUpdateWithPanel:(NSString *)panel
                          category:(NSString *)category
                        completion:(void (^)(BOOL needUpdate))completion;

+ (void)checkEffectUpdateWithPanel:(NSString *)panel
                          category:(NSString *)category
              effectTestStatusType:(IESEffectModelTestStatusType)statusType
                        completion:(void (^)(BOOL needUpdate))completion;

/**
 下载特效列表

 @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)downloadEffectListWithPanel:(NSString *)panel
                         completion:(EffectPlatformFetchListCompletionBlock _Nullable)completion;

/**
 下载特效列表

 @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
 @param statusType 测试状态分类
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)downloadEffectListWithPanel:(NSString *)panel
               effectTestStatusType:(IESEffectModelTestStatusType)statusType
                         completion:(EffectPlatformFetchListCompletionBlock _Nullable)completion;

/**
 下载特效列表
 
 @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
 @param saveCache 是否保存cache
 @param statusType 测试状态分类
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)downloadEffectListWithPanel:(NSString *)panel
                          saveCache:(BOOL)saveCache
               effectTestStatusType:(IESEffectModelTestStatusType)statusType
                         completion:(EffectPlatformFetchListCompletionBlock _Nullable)completion;

/**
 下载特效列表
 
 @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
 @param saveCache 是否保存cache
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)downloadEffectListWithPanel:(NSString *)panel
                          saveCache:(BOOL)saveCache
                         completion:(EffectPlatformFetchListCompletionBlock _Nullable)completion;

/**
 * 目前仅滤镜panel使用
 *
 * 获取和更新滤镜显示（check）或隐藏（uncheck，仅在滤镜管理箱中展示）状态
 */
+ (void)fetchEffectListStateWithPanel:(NSString *)panel completion:(EffectPlatformFetchListCompletionBlock)completion;
+ (void)updateEffectListStateWithPanel:(NSString *)panel
                            checkArray:(NSArray *)checkArray
                          uncheckArray:(NSArray *)uncheckArray
                            completion:(EffectPlatformFilterBoxUpdateCompletion)completion;

/**
 获取面板信息（带分类列表）
 
 @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
 @param isLoad 是否指定需要加载的分类；默认不加载
 @param category 指定需要加载的分类；默认不加载
 @param pageCount 每页的个数
 @param cursor 当前页
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)fetchCategoriesListWithPanel:(NSString *)panel
        isLoadDefaultCategoryEffects:(BOOL)isLoad
                     defaultCategory:(NSString *)category
                           pageCount:(NSInteger)pageCount
                              cursor:(NSInteger)cursor
                          completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion;

/**
 获取面板信息（带分类列表）
 
 @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
 @param isLoad 是否指定需要加载的分类；默认不加载
 @param category 指定需要加载的分类；默认不加载
 @param pageCount 每页的个数
 @param cursor 当前页
 @param statusType 测试状态分类
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)fetchCategoriesListWithPanel:(NSString *)panel
        isLoadDefaultCategoryEffects:(BOOL)isLoad
                     defaultCategory:(NSString *)category
                           pageCount:(NSInteger)pageCount
                              cursor:(NSInteger)cursor
                effectTestStatusType:(IESEffectModelTestStatusType)statusType
                          completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion;

/**
 获取面板信息（带分类列表）
 
 @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
 @param isLoad 是否指定需要加载的分类；默认不加载
 @param category 指定需要加载的分类；默认不加载
 @param pageCount 每页的个数
 @param cursor 当前页
 @param saveCache 是否保存cache
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)fetchCategoriesListWithPanel:(NSString *)panel
        isLoadDefaultCategoryEffects:(BOOL)isLoad
                     defaultCategory:(NSString *)category
                           pageCount:(NSInteger)pageCount
                              cursor:(NSInteger)cursor
                           saveCache:(BOOL)saveCache
                          completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion;

/**
 获取面板信息（带分类列表）
 
 @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
 @param isLoad 是否指定需要加载的分类；默认不加载
 @param category 指定需要加载的分类；默认不加载
 @param pageCount 每页的个数
 @param cursor 当前页
 @param saveCache 是否保存cache
 @param statusType 测试状态分类
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)fetchCategoriesListWithPanel:(NSString *)panel
        isLoadDefaultCategoryEffects:(BOOL)isLoad
                     defaultCategory:(NSString *)category
                           pageCount:(NSInteger)pageCount
                              cursor:(NSInteger)cursor
                           saveCache:(BOOL)saveCache
                effectTestStatusType:(IESEffectModelTestStatusType)statusType
                          completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion;


+ (void)fetchCategoriesListWithPanel:(NSString *)panel
        isLoadDefaultCategoryEffects:(BOOL)isLoad
                     defaultCategory:(NSString *)category
                           pageCount:(NSInteger)pageCount
                              cursor:(NSInteger)cursor
                           saveCache:(BOOL)saveCache
                effectTestStatusType:(IESEffectModelTestStatusType)statusType
                     extraParameters:(NSDictionary * _Nullable)extra
                          completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion;


/**
 获取/effect/api/panel/info/one接口中的道具分类
 */
+ (void)fetchOneCategoryListWithPanel:(NSString *)panel
                         specCategory:(NSString *)specCategory
                 effectTestStatusType:(IESEffectModelTestStatusType)statusType
                      extraParameters:(NSDictionary * _Nullable)extra
                           completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion;

/**
 获取/effect/api/panel/info/theme接口中的道具分类
 */
+ (void)fetchThemeCategoryListWithPanel:(NSString *)panel
                           specCategory:(NSString *)specCategory
                   effectTestStatusType:(IESEffectModelTestStatusType)statusType
                        extraParameters:(NSDictionary * _Nullable)extra
                             completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion;

/**
 获取某个分类下的特效列表（支持分页）
 
 @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
 @param category 分类名称
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)downloadEffectListWithPanel:(NSString *)panel
                           category:(NSString *)category
                          pageCount:(NSInteger)pageCount
                             cursor:(NSInteger)cursor
                    sortingPosition:(NSInteger)position
                         completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion;

/**
 获取某个分类下的特效列表（支持分页）
 
 @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
 @param category 分类名称
 @param statusType 测试状态分类
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)downloadEffectListWithPanel:(NSString *)panel
                           category:(NSString *)category
                          pageCount:(NSInteger)pageCount
                             cursor:(NSInteger)cursor
                    sortingPosition:(NSInteger)position
               effectTestStatusType:(IESEffectModelTestStatusType)statusType
                         completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion;

/**
 获取某个分类下的特效列表（支持分页）
 
 @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
 @param category 分类名称
 @param saveCache 是否保存cache
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)downloadEffectListWithPanel:(NSString *)panel
                           category:(NSString *)category
                          pageCount:(NSInteger)pageCount
                             cursor:(NSInteger)cursor
                    sortingPosition:(NSInteger)position
                          saveCache:(BOOL)saveCache
                         completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion;

/**
 获取某个分类下的特效列表（支持分页）
 
 @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
 @param category 分类名称
 @param saveCache 是否保存cache
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)downloadEffectListWithPanel:(NSString *)panel
                           category:(NSString *)category
                          pageCount:(NSInteger)pageCount
                             cursor:(NSInteger)cursor
                    sortingPosition:(NSInteger)position
                          saveCache:(BOOL)saveCache
               effectTestStatusType:(IESEffectModelTestStatusType)statusType
                         completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion;

+ (void)downloadEffectListWithPanel:(NSString *)panel
                           category:(NSString *)category
                          pageCount:(NSInteger)pageCount
                             cursor:(NSInteger)cursor
                    sortingPosition:(NSInteger)position
                            version:(NSString * _Nullable)version
                          saveCache:(BOOL)saveCache
               effectTestStatusType:(IESEffectModelTestStatusType)statusType
                         completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion;

+ (void)downloadEffectListWithPanel:(NSString *)panel
                           category:(NSString *)category
                          pageCount:(NSInteger)pageCount
                             cursor:(NSInteger)cursor
                    sortingPosition:(NSInteger)position
                            version:(NSString * _Nullable)version
                          saveCache:(BOOL)saveCache
               effectTestStatusType:(IESEffectModelTestStatusType)statusType
                    extraParameters:(NSDictionary * _Nullable)extra
                         completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion;

+ (void)downloadHotEffectListWithPanel:(NSString *)panel
                             pageCount:(NSInteger)pageCount
                                cursor:(NSInteger)cursor
                       sortingPosition:(NSInteger)position
                             saveCache:(BOOL)saveCache
                  effectTestStatusType:(IESEffectModelTestStatusType)statusType
                            completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion;


/// Query hot effects
/// @param panel 面板名称，可在应用管理->选择应用->面板管理中找到面板标识码
/// @param pageCount NSInteger
/// @param cursor NSInteger
/// @param position NSInteger
/// @param saveCache BOOL
/// @param statusType IESEffectModelTestStatusType
/// @param extra NSDictionary extra request parameters
/// @param completion EffectPlatformFetchCategoryListCompletionBlock
+ (void)downloadHotEffectListWithPanel:(NSString *)panel
                             pageCount:(NSInteger)pageCount
                                cursor:(NSInteger)cursor
                       sortingPosition:(NSInteger)position
                             saveCache:(BOOL)saveCache
                  effectTestStatusType:(IESEffectModelTestStatusType)statusType
                       extraParameters:(NSDictionary * _Nullable)extra
                            completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion;


+ (void)downloadThemeEffectListWithPannel:(NSString *)panel
                             specCategory:(NSString *)specCategory
                                 category:(NSString *)category
                     effectTestStatusType:(IESEffectModelTestStatusType)statusType
                          extraParameters:(NSDictionary * _Nullable)extra
                               completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion;


/**
 下载特效
 
 @param effectModel 特效 model
 @param progressBlock 进度回调，返回进度 0~1
 @param completion 下载成功回调， 错误码参见 HTSEffectDefines
 */
+ (void)downloadEffect:(IESEffectModel *)effectModel
              progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
            completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion;

/**
 下载模型需求
 
 @param requirements 算法名
 @param completion  下载成功回调
 */
+ (void)downloadRequirements:(NSArray<NSString *> *)requirements
                  completion:(void (^)(BOOL success, NSError *error))completion;

/**
 指定模型名下载需求
 
 @param requirements 算法名
 @param modelNames 指定模型名
 @param completion 下载成功回调
 */
+ (void)fetchResourcesWithRequirements:(NSArray<NSString *> *)requirements
                            modelNames:(NSDictionary<NSString *, NSArray<NSString *> *> *)modelNames
                            completion:(void (^)(BOOL success, NSError *error))completion;

/**
 @param modelNames 模型名数组
 @param completion 下载回调
 */
+ (void)fetchOnlineInfosAndResourcesWithModelNames:(NSArray<NSString *> *)modelNames
                                             extra:(NSDictionary *)parameters
                                        completion:(void (^)(BOOL success, NSError *error))completion;

/**
 根据指定算法名和模型名返回本地缓存模型的信息
 @param requirements  algorithmNames
 @param modelNames  assigned model names
 */
+ (NSDictionary<NSString *, IESAlgorithmRecord *> *)checkoutModelInfosWithRequirements:(NSArray<NSString *> *)requirements
                                                                            modelNames:(NSDictionary<NSString *, NSArray<NSString *> *> *)modelNames;

/*!
 下载特效
 @param effectModel 特效 model
 @param queuePriority 进度回调，返回进度 0~1
 @param qualityOfService 下载operation的queuePriority
 @param progressBlock 下载operation的qualityOfService
 @param completion 下载成功回调， 错误码参见 HTSEffectDefines
 */
+ (void)downloadEffect:(IESEffectModel *)effectModel
 downloadQueuePriority:(NSOperationQueuePriority)queuePriority
downloadQualityOfService:(NSQualityOfService)qualityOfService
              progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
            completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion;


/**
 请求特效列表

 @param effectIDs 特效id数组
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)fetchEffectListWithEffectIDS:(NSArray<NSString *> *)effectIDs
                          completion:(EffectPlatformFetchEffectListCompletion _Nullable)completion;

+ (void)fetchEffectListWithEffectIDS:(NSArray<NSString *> *)effectIDs
                       urlCompletion:(void(^)(NSError *_Nullable error,
                                              NSArray<IESEffectModel *> *_Nullable effects,
                                              NSArray<IESEffectModel *> *_Nullable bindEffects,
                                              NSArray<NSString *> *_Nullable urlPrefixs))completion;

/**
 请求特效列表

 @param effectIDs 特效id数组
 @param gradeKey   分级包标志
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)fetchEffectListWithEffectIDS:(NSArray<NSString *> *)effectIDs
                            gradeKey:(NSString *)gradeKey
                          completion:(EffectPlatformFetchEffectListCompletion _Nullable)completion;

/**
 下载我的特效列表

 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)downloadMyEffectListWithPanel:(NSString*)panel
                           completion:(void (^)(NSError *_Nullable error, NSArray<IESMyEffectModel *> *_Nullable effects))completion;

/**
 取消/收藏特效

 @param effectIDS 特效数组
 @param favorite YES: 收藏特效, NO: 取消收藏
 @param completion  success为YES代表操作成功，操作失败或者请求失败值为NO，错误信息参见error
 */
+ (void)changeEffectsFavoriteWithEffectIDs:(NSArray<NSString *> *)effectIDS
                                     panel:(NSString *)panel
                             addToFavorite:(BOOL)favorite
                                completion:(void (^)(BOOL success, NSError *_Nullable error))completion;

/**
 根据resourceIds下载特效列表
 
 @param resourceIds 资源ids
 @param panel 面板
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)downloadEffectListWithResourceIds:(NSArray<NSString *> *)resourceIds
                                    panel:(NSString *)panel
                               completion:(void (^)(NSError *_Nullable error, NSArray<IESEffectModel *> *_Nullable effects))completion;

/**
 第三方贴纸推荐列表
 
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)thirdPartyStickerRecommandListWithCompletion:(void (^)(IESThirdPartyResponseModel *_Nullable response, NSError *_Nullable error))completion;


/**
 第三方贴纸推荐列表（带推荐类型）
 
 @param type 默认"giphy"，自研"lab"
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)thirdPartyStickerRecommendListWithType:(NSString *)type
                                    completion:(void (^)(IESThirdPartyResponseModel *_Nullable response, NSError *_Nullable error))completion;

/**
 第三方贴纸推荐列表
 
 @param pageCount 每页的个数（传入NSNotFound则默认返回30个）
 @param cursor 当前页
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)thirdPartyStickerRecommandListWithPageCount:(NSInteger)pageCount
                                             cursor:(NSInteger)cursor
                                         completion:(void (^)(IESThirdPartyResponseModel *_Nullable response, NSError *_Nullable error))completion;

/**
 第三方贴纸推荐列表（带推荐类型）
 
 @param type 默认"giphy"，自研"lab"
 @param pageCount 每页的个数（传入NSNotFound则默认返回30个）
 @param cursor 当前页
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)thirdPartyStickerRecommendListWithType:(NSString *)type
                                     pageCount:(NSInteger)pageCount
                                        cursor:(NSInteger)cursor
                                    completion:(void (^)(IESThirdPartyResponseModel *_Nullable response, NSError *_Nullable error))completion;


/**
第三方贴纸推荐列表（带推荐类型）

@param type 默认"giphy"，自研"lab"
@param pageCount 每页的个数（传入NSNotFound则默认返回30个）
@param cursor 当前页
@param extraParameters 额外的参数
@param completion 下载回调， 错误码参见 HTSEffectDefines
*/
+ (void)thirdPartyStickerRecommendListWithType:(NSString *)type
                                     pageCount:(NSInteger)pageCount
                                        cursor:(NSInteger)cursor
                               extraParameters:(NSDictionary *)extraParameters
                                    completion:(void (^)(IESThirdPartyResponseModel *_Nullable response, NSError *_Nullable error))completion;

/**
 第三方贴纸搜索列表
 
 @param keyword 关键词
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)thirdPartyStickefListWithKeyword:(NSString *)keyword
                              completion:(void (^)(IESThirdPartyResponseModel *_Nullable response, NSError *_Nullable error))completion;

/**
 第三方贴纸搜索列表（带推荐类型）
 
 @param keyword 关键词
 @param type 默认"giphy"，自研"lab"
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)thirdPartyStickefListWithKeyword:(NSString *)keyword
                                    type:(NSString *)type
                              completion:(void (^)(IESThirdPartyResponseModel *_Nullable response, NSError *_Nullable error))completion;

/**
 第三方贴纸搜索列表
 
 @param keyword 关键词
 @param pageCount 每页的个数（传入NSNotFound则默认返回30个）
 @param cursor 当前页
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)thirdPartyStickefListWithKeyword:(NSString *)keyword
                               pageCount:(NSInteger)pageCount
                                  cursor:(NSInteger)cursor
                              completion:(void (^)(IESThirdPartyResponseModel *_Nullable response, NSError *_Nullable error))completion;

/**
 第三方贴纸搜索列表（带推荐类型）
 
 @param keyword 关键词
 @param type 默认"giphy"，自研"lab"
 @param pageCount 每页的个数（传入NSNotFound则默认返回30个）
 @param cursor 当前页
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)thirdPartyStickefListWithKeyword:(NSString *)keyword
                                    type:(NSString *)type
                               pageCount:(NSInteger)pageCount
                                  cursor:(NSInteger)cursor
                              completion:(void (^)(IESThirdPartyResponseModel *_Nullable response, NSError *_Nullable error))completion;

/**
 第三方贴纸搜索列表（带推荐类型）
 
 @param keyword 关键词
 @param type 默认"giphy"，自研"lab"
 @param pageCount 每页的个数（传入NSNotFound则默认返回30个）
 @param cursor 当前页
 @param extraParameters 额外的参数
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 */
+ (void)thirdPartyStickefListWithKeyword:(NSString *)keyword
                                    type:(NSString *)type
                               pageCount:(NSInteger)pageCount
                                  cursor:(NSInteger)cursor
                         extraParameters:(NSDictionary *)extraParameters
                              completion:(void (^)(IESThirdPartyResponseModel *_Nullable response, NSError *_Nullable error))completion;

/**
 Gif Anchor
 Fetch gif sticker list and download stickers in the list
 @param gifIDs 动态图id数组字符串，eg. @"911212,122132,123232" or @"123122"
 @param extraParameter 额外的参数
 @param completion 回调
 */
+ (void)fetchAndDownloadThirdPartyStickerListWithGifIDs:(NSString *)gifIDs
                                        extraParameters:(NSDictionary *)extraParameters
                                             completion:(void(^)(NSError * _Nullable error,
                                                                 IESThirdPartyResponseModel * _Nullable response,
                                                                 NSArray<IESThirdPartyStickerModel *> * _Nullable downloadSuccessStickers,
                                                                 NSArray<IESThirdPartyStickerModel *> * _Nullable downloadFailedStickers))completion;

/**
 根据resourceIds下载特效列表
 @param resourceIds 资源ids
 @param panel 面板
 @param completion 下载回调，将IESEffectModel列表和urlPrefix列表一并回调， 错误码参见 HTSEffectDefines
 */
+ (void)fetchEffectListWithResourceIds:(NSArray<NSString *> *)resourceIds
                                 panel:(NSString *)panel
                            completion:(void (^)(NSError *_Nullable error, NSArray<IESEffectModel *> *_Nullable effects, NSArray<NSString *> *_Nullable urlPrefixs))completion;

/**
 获取用户最近使用过的道具
 @param completion The completion callback.
 */
+ (void)fetchUserUsedStickersWithCompletion:(void (^)(NSError *_Nullable error, NSArray<IESEffectModel *> *_Nullable effects))completion;

/**
 下载第三方贴纸
 
 @param thirdPartyModel 第三方model
 @param progressBlock 进度回调，返回进度 0~1
 @param completion 下载成功回调， 错误码参见 HTSEffectDefines
 */
+ (void)downloadThirdPartyModel:(IESThirdPartyStickerModel *)thirdPartyModel
          downloadQueuePriority:(NSOperationQueuePriority)queuePriority
       downloadQualityOfService:(NSQualityOfService)qualityOfService
                       progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
                     completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion;


/**
 下载Moji资源包

 @param idMap 特征id列表json
 @param completion 回调
 */
+ (void)downloadMojiResourceWithIDMap:(NSString *)idMap completion:(nonnull void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion;

/**
 下载特效资源
 
 @param model 资源model
 @param progressBlock 进度
 @param completion 回调
 */
+ (void)downloadResourceWithEffectResourceModel:(IESEffectResourceModel *)model
                                       progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
                                     completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion;

/**
 是否模型已经下载完成
 */
+ (BOOL)isRequirementsDownloaded:(NSArray<NSString *> *)requirements;

/**
 * @return The downloaded effect path. nil if not download.
 */
+ (nullable NSString *)effectPathForEffectMD5:(NSString *)effectMD5;

/******************************************************************************************************************************************
 * EffectPlatform+Additions 使用到的公共接口，非开放接口
******************************************************************************************************************************************/

- (NSString *)urlWithPath:(NSString *)path;

+ (NSError *)serverErrorFromJSON:(NSDictionary *)jsonDic;

+ (NSDictionary *)errorDescriptionMappingDic;

+ (long long )folderSizeAtPath:(NSString*)folderPath;

- (NSString *)effectCloudLibVersionWithPanel:(NSString *)panel;

+ (void)requestWithURLString:(NSString *)urlString
                   parameters:(NSDictionary *)parameters
                   completion:(void (^)(NSError * _Nullable error, NSDictionary * _Nullable jsonDict))completion;


@end

FOUNDATION_EXTERN NSDictionary * addErrorInfoToTrackInfo(NSDictionary *trackInfo, NSError *error);

/**
 以下方法因服务端接口返回的数据变动已过期，请改用相应的方法
 */
@interface EffectPlatform (DEPRECATED)

/**
 下载特效列表

 @param effectIDs 特效id数组
 @param completion 下载回调， 错误码参见 HTSEffectDefines
 已过期，改用fetchEffectListWithEffectIDS:completion:
 */
+ (void)downloadEffectListWithEffectIDS:(NSArray<NSString *> *)effectIDs
                             completion:(void (^)(NSError *_Nullable error, NSArray<IESEffectModel *> *_Nullable effects))completion API_DEPRECATED("Use fetchEffectListWithEffectIDS APIs instead.", ios(8.0, 13.7));

/**
下载特效列表

@param effectIDs 特效id数组
@param gradeKey 分级包标志
@param completion 下载回调， 错误码参见 HTSEffectDefines
已过期，改用fetchEffectListWithEffectIDS:gradeKey:completion:
 */
 + (void)downloadEffectListWithEffectIDS:(NSArray<NSString *> *)effectIDs
                                gradeKey:(NSString *)gradeKey
                              completion:(void (^)(NSError *_Nullable error, NSArray<IESEffectModel *> *_Nullable effects))completion API_DEPRECATED("Use fetchEffectListWithEffectIDS APIs instead.", ios(8.0, 13.7));

/**
 清理特效资源缓存，目录：effect_uncompress
 @param targetSize 自动清理缓存的阈值，单位：Mb
 */

- (void)trimDiskCacheToSize:(NSUInteger)fireSize targetSize:(NSUInteger)targetSize completion:(void(^)(NSDictionary *params, NSError * _Nullable error))completion API_DEPRECATED("This method was deprecated, please remove the calling.", ios(8.0, 13.7));


/**
 自动清缓存白名单
 @param list panel名称数组
 */
- (void)addAllowList:(NSArray<NSString *> *)list API_DEPRECATED("This method was deprecated, please remove the calling.", ios(8.0, 13.7));

/**
 进入拍摄器取消自动清缓存任务
 */
- (void)cancelCacheCleanIfNeeded API_DEPRECATED("This method was deprecated, please remove the calling.", ios(8.0, 13.7));

@end

NS_ASSUME_NONNULL_END
