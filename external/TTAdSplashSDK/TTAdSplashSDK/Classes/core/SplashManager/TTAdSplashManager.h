//
//  TTAdSplashManager.h
//  Article
//
//  Created by Zhang Leonardo on 12-11-13.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TTAdSplashModel.h"
#import "TTAdSplashHeader.h"
#import "TTAdSplashDelegate.h"
#import "TTAdSplashInterceptDelegate.h"
#import "BDASplashOMTrackDelegate.h"

@class TTAdSplashDownloader;
@class TTAdSplashControllerView;
@class TTAdSplashRealTimeFetchModel;

typedef NS_ENUM(NSInteger, TTAdTopViewShowFailedType) {
    TTAdTopViewShowFailedTypeNoResource = 1,    ///< 素材预加载失败
    TTAdTopViewShowFailedTypeFrequency,         ///< 因为频控等原因导致无法提供数据
    TTAdTopViewShowFailedTypeNotInFeed,         ///< 热启动没有在信息流
    TTAdTopViewShowFailedTypeNoRefresh,          ///< 没有进行自动刷新
    TTAdTopViewShowFailedTypeAdWillShow,          ///< 播放前校验失败
};

// 传入这个block，宿主来检查此原生广告是否可以展示
typedef BOOL(^TTAdSplashOriginalAdCheckArea)(TTAdSplashModel *model);

/**
 * TTAdSplashManager 负责维护开开屏主要的逻辑，并负责对外暴露公有API.
 */
@interface TTAdSplashManager : NSObject

#pragma mark - Properties
/**
 *  展示广告的类型:显示，不显示但是请求广告数据，不显示也不请求
 */
@property (nonatomic, assign) TTAdSplashShowType splashADShowType;

/**
 *  开屏广告资源的类型:image, gif, video
 */
@property (nonatomic, assign, readonly) TTAdSplashResouceType resouceType;

@property (nonatomic, assign) BOOL showByForground  __deprecated_msg("deprecated");

/**
 *  判断广告是否要展示
 */
@property (nonatomic, assign) BOOL adWillShow;

/**
 *  当前广告是否正在展示
 */
@property (nonatomic, assign) BOOL isAdShowing;

/**
 *  是否忽略首刷逻辑，忽略传YES，遵循传NO，如果支持首刷务必设为NO，默认忽略
 */
@property(nonatomic, assign) BOOL ignoreFirstLaunch;

/**
 *  是否支持实时下发控制，默认关闭
 */
@property(nonatomic, assign) BOOL enableRealTimeFetch;

/**
 *  第一次检查广告标志位，启动时默认NO. 无论是否启动开屏广告，检查完标记为YES； 进入后台前标记为 NO
 */
@property (nonatomic, assign) BOOL finishCheck;

/**
 *  controllerView 是开屏UI控件层级的最底层的view
 */
@property(nonatomic, strong) TTAdSplashControllerView *controllerView;

/**
 *  TTAdSplashDownloader 开屏素材下载器
 */
@property(nonatomic, strong) TTAdSplashDownloader *splashDownloadManager;

/**
 *  realTimeModel 实时开屏下发数据模型
 */
@property (nonatomic, strong) TTAdSplashRealTimeFetchModel *realTimeModel;

/**
 *  标志位用于判断实时接口是否返回数据
 */
@property (nonatomic, assign) BOOL isRealTimeLoadComplete;

/**
 *  是否需要在展示开屏广告前先请求一个指令，UDP停投需求。
 *  YES 会立即调用startFetchSwitchCommand走udp请求
 *  NO  不作任何处理
 */
@property (nonatomic, assign) BOOL shouldFetchCmdBeforeShowingSplashAd;
@property (nonatomic, assign) BOOL enableTotalSwitch;
@property (nonatomic, assign) BOOL isEnableFirstLaunchRetrieval; ///< 是否开启首刷回捞, 默认关闭
@property (nonatomic, assign, readonly) BOOL isHotLaunch;   ///< 本次广告展示是否为热启动
@property (nonatomic, assign, readonly) BOOL isLaunchCovered;
@property (nonatomic, strong) NSArray * ipList;
@property (nonatomic, assign) BOOL isEnableTimeCheck;   ///< 是否打开时间校验
@property (nonatomic, strong) NSNumber *checkTimeErrorRange; ///< 时间校验误差范围
/**
 *  当前是否正在展示原生开屏广告，由宿主来设置，SDK内部根据真是状况来影响isAdShowing
 *  注意：⚠️更改此参数的时机应该在宿主返回了原生广告的ad_id之后执行，
 *  因为SDK内部依赖是否有原生广告的ad_id来判断是否真的在展示原生广告
 */
@property (nonatomic, assign) BOOL isShowingOriginalSplash;
@property (nonatomic, assign) BOOL isNotFirstTimeToCallSendStockHint;
@property (nonatomic, assign) BOOL isCheckUDPSwitch;
@property (nonatomic, assign) NSInteger splashReqeustDelayTime; ///< 开屏数据预加载接口延迟请求时间，单位 s，默认为 0.
@property (nonatomic, assign) NSTimeInterval imageAdStartShowTime;  ///<图片开屏广告开始展示时的时间
@property (nonatomic, assign) BOOL isSupportWebP;
@property (nonatomic, assign) BOOL enableFirstLaunchNewLogic;   ///<是否开启新版首刷消耗逻辑，默认为NO
@property (nonatomic, assign) BOOL shouldMuteGlobal;    ///< 启动开屏是否全局静音，默认为 YES.
@property (nonatomic, assign) BOOL isAddShowCountForBye; ///< 数据轮空时，是否进行展示次数计次，默认为 NO.
@property (nonatomic, assign) BOOL shouldLimitClickArea; ///< 是否限制点击区域，默认为 NO，不限制，全屏可点击；设置为 YES 之后只有特定区域可以点击.
@property (nonatomic, assign) BOOL enableUseOwnerVideoPlayer; ///<是否切换为自研播放器，默认为NO.
@property (nonatomic, copy) NSDictionary *splashSRConfig; ///<超分功能配置
@property (nonatomic, assign) CGFloat dismissDuration; ///< 开屏展示结束消失过度动画时间，默认为 0.2s.
@property (nonatomic, strong, readonly) TTAdSplashModel *selectedNormalSplashModelInAdvance;

#pragma mark - Global instance
/**
 * 全局单例
 * @return TTAdSplashManager开屏管理单例对象
 */
+ (TTAdSplashManager *)shareInstance;


#pragma mark - Public Method

/**
 * 注册代理传入参数
 *
 * @param delegate 代理
 * @param paramsBlock 必要参数回调 详细参数可以refer wiki:https://wiki.bytedance.net/pages/viewpage.action?pageId=226074616
 */
- (TTAdSplashManager *)registerDelegate:(id<TTAdSplashDelegate>)delegate paramsBlock:(TTAdSplashParamBlock)paramsBlock;

/**
 * 注册原生开屏代理
 *
 * @param splashInterceptDelegate 开屏拦截代理
 */
- (TTAdSplashManager *)registerSplashInterceptDelegate:(id<TTAdSplashInterceptDelegate>)splashInterceptDelegate;

/** 注册 OM SDK 事件上报代理 */
- (TTAdSplashManager *)registerSplashOMTrackDelegate:(id<BDASplashOMTrackDelegate>)omTrackDelegate;

/**
 * 业务特殊需要的 请求透传参数
 * @param paramsBlock 可选的业务透传 参数
 */
- (TTAdSplashManager *)registerExtraParamsBlock:(TTAdSplashParamBlock)paramsBlock;

/** 初始化 TTVideoEngine，根据 TTVideoEngine SDK 规定，startOpenGLESActivity 需要在app delegate 的 -[applicationDidBecomeActive:] 里面调用,并且需要放在函数的第一行，不要使用通知监听的方式，否则会有crash或是黑屏。
 
    或者直接调用 [TTVideoEngine startOpenGLESActivity];
 */
+ (void)startOpenGLESActivityForSplash;

/** 初始化 TTVideoEngine，根据 TTVideoEngine SDK 规定，stopOpenGLESActivity需要在app delegate 的 -[applicationWillResignActive:] 里面调用,并且需要放在函数的第一行，不要使用通知监听的方式，否则会有crash或是黑屏
 
    或者直接调用 [TTVideoEngine stopOpenGLESActivity];
 */
+ (void)stopOpenGLESActivityForSplash;

/// 是否满足进入后台的时间间隔
+ (BOOL)isEnterBackgroundFit;

///是否满足两次展示开屏的时间间隔
+ (BOOL)isShowTimeFit;


/**
 *  是否启用停投，会先设置appID 然后 走shouldFetchCmdBeforeShowingSplashAd的setter方法
 *  @param should 设置为YES，即启用
 *  @param appId 这里加这个参数是因为有可能调用停投时SDK中registerParams还没有走完，导致AppId为空
 */
- (void)setShouldFetchCmdBeforeShowingSplashAd:(BOOL)should withAppId:(NSString *)appId;

/**
 * 展示开屏广告
 * @param keyWindow Key Window或者View 保证放在key window的最高层级上
 * @param type 展示并请求、不展示但请求、不展示不请求
 * @param isHotLaunch 是否为热启动, 不传默认为 NO
 * @return 是否展示广告
 */
- (BOOL)displaySplashOnWindow:(UIView *)keyWindow
               splashShowType:(TTAdSplashShowType)type
                  isHotLaunch:(BOOL)isHotLaunch;

/**
 * 开屏广告缓存召回
 * @param adIDs 召回广告的ad_id数组
 * @return 召回成功与否
 */
- (BOOL)discardAd:(NSArray<NSString *> *)adIDs;

- (void)startFetchSwitchCommand;

/**
 *  @brief 原生广告确认展示广告后发送ack
 */
- (void)sendAwesomeSplashACK;

/**
 *  @brief 跳过SDK当前正在展示的广告，移除controllerView
 *  @return 跳过广告的结果
 */
- (TTAdSplashSkipAdResult)skipAd;

/**
 * 从缓存中获取 suitable model
 * @return splash model
 */
+ (TTAdSplashModel *)splashModel;

/**
 * 判断某个广告model是否是可展示的: YES可以展示; NO不可以展示
 * @param model 广告model
 * @param type 不展示理由
 * @return 是否可展示
 */
+ (BOOL)isSuitableADModel:(TTAdSplashModel *)model readyType:(TTAdSplashReadyType *)type;

/**
 * 清除资源缓存
 */
+ (void)clearResouceCache;

/**
 * 获取下轮次缓存的广告model array
 * @return model array
 */
+ (NSArray *)getSplashModels;

/**
 * 资源缓存路径
 * @return path
 */
+ (NSString *)resouceCachePath;

/**
 * 资源缓存大小
 * @return size
 */
+ (float)resouceCacheSize;

/**
 * 记录最近一次展示splash广告时间，用于热启动
 */
+ (void)saveSSADRecentlyShowSplashADTime;

/// 记录最近一次开屏广告展示时间，用于冷启动
+ (void)saveRecentlyShowTime;

/// 最近一次开屏广告展示时间，用于冷启动。
+ (NSTimeInterval)recentlyShowTime;

/**
 * 记录最近一次退到后台的时间
 */
+ (void)saveSSADRecentlyEnterBackgroundTime;


#pragma mark - 原生开屏`同步`方法，宿主主动调用 ========== ⚠️⚠️⚠️调用下面方法意味着不要和 TTAdSplashInterceptDelegate 中的 pick方法混合使用⚠️⚠️⚠️ ==========

/**
 开屏SDK提前去检查原生广告可否展示并且返回可展示的原生广告，副作用：为了挑选原生开屏广告，需要过滤一遍非原生开屏广告
 @warning 1. ⚠️调用此方法，请务必在本次展示广告之前，即在调用 `displaySplashOnWindow:splashShowType:` 之前
          2. ⚠️调用此方法，请务必保证此次调用 `displaySplashOnWindow:splashShowType:` 时 showType == TTAdSplashShowTypeShow
          3. ⚠️调用此方法，会有埋点等发送，请务必保证TTAdSplashManager.delegate已被正确指定
 @param checkArea 宿主传入的检查广告可用性的Block，这个Block调用的次数取决于队列中原生广告的数量，不能为null
 @param isHotLaunch 本次是不是热启动
 @return 返回可以展示的原生开屏广告，如果没有可展示的原生开屏广告，则返回`nil`
 */
- (TTAdSplashModel *)pickOriginalAdWithCheckArea:(TTAdSplashOriginalAdCheckArea)checkArea
                                     isHotLaunch:(BOOL)isHotLaunch;

/**
 @brief 返回传入的开屏Model所需素材的本地path
 返回缓存路径的格式:
 1. 图片(包括gif)广告: 返回 @[@"image_path"]
 2. 视频广告:
    2.1 全屏视频广告: 返回 @[@"video_path"]
    2.2 半屏视频广告(带底图): 返回 @[@"video_path", @"image_path"]]
 @warning ⚠️如果此model所需的素材没有缓存成功或者没有完全缓存成功，则返回`nil`
 @param model 开屏Model
 @return Model所需素材的本地path
 */
- (NSArray<NSString *> *)resoucePathForSplashModel:(TTAdSplashModel *)model;

/**
 上报原生开屏视频广告播放中断，中断的类型定义请见`TTAdSplashVideoBreakReason`

 @param reason 中断的原因
 @param model 当前播放的视频广告对应的model
 @param extra 需要透传的字段, value为 String Number
 @param adExtraData 对应 ad_extra_data
 */
- (void)trackOriginalAdPlayBreakWithReason:(TTAdSplashVideoBreakReason)reason
                                     model:(TTAdSplashModel *)model
                                     extra:(NSDictionary *)extra
                               adExtraData:(NSDictionary *)adExtraData;;

/**
 上报原生开屏视频广告开始播放

 @param model 当前播放的视频广告对应的model
 @param extra 需要透传的字段, value为 String Number
 @param adExtraData 对应 ad_extra_data
 */
- (void)trackOriginalAdPlayWithModel:(TTAdSplashModel *)model
                               extra:(NSDictionary *)extra
                         adExtraData:(NSDictionary *)adExtraData;

/**
 上报原生开屏视频广告播放失败

 @param model 当前播放的视频广告对应的model
 @param extra 需要透传的字段, value为 String Number
 @param adExtraData 对应 ad_extra_data */
- (void)trackOriginalAdPlayFailWithModel:(TTAdSplashModel *)model
                                   extra:(NSDictionary *)extra
                                   adExtraData:(NSDictionary *)adExtraData;

/**
 上报原生开屏视频广告播放失败

 @param model 当前播放的视频广告对应的model
 @param extra 需要透传的字段, value为 String Number
 @param adExtraData 对应 ad_extra_data */
- (void)trackOriginalAdRealPlayWithModel:(TTAdSplashModel *)model
                                   extra:(NSDictionary *)extra
                                   adExtraData:(NSDictionary *)adExtraData;


/**
 上报原生开屏视频广告全部时长播放完毕

 @param model 当前播放的视频广告对应的model
 @param extra 需要透传的字段, value为 String Number
 @param adExtraData 对应 ad_extra_data*/
- (void)trackOriginalAdPlayOverWithModel:(TTAdSplashModel *)model
                                   extra:(NSDictionary *)extra
                             adExtraData:(NSDictionary *)adExtraData;

/**
 上报原生开屏展示失败原因, 宿主 App 和 SDK 分别上报自己的原因

 @param tag 客户端和 SDK 同不同的 tag, 客户端是 'embeded_ad', SDK 是 'splash_ad'
 @param model 当前播放的视频广告对应的model
 @param extra 需要透传的字段, value为 String Number
 @param adExtraData 对应 ad_extra_data
 */
- (void)trackOriginalAdShowFailWithTag:(NSString *)tag
                                 model:(TTAdSplashModel *)model
                                 extra:(NSDictionary *)extra
                           adExtraData:(NSDictionary *)adExtraData;



/**
  上报原生开屏视频信息流强制刷新埋点

 @param model 当前播放的视频广告对应的model
 @param extra 需要透传的字段, value为 String Number
 @param adExtraData 对应 ad_extra_data
 */
- (void)trackOriginalAdForceRefreshWithModel:(TTAdSplashModel *)model
                                       extra:(NSDictionary *)extra
                                 adExtraData:(NSDictionary *)adExtraData;

/**
 发送埋点的通用方法
 @param model 开屏model
 @param tag tag
 @param label label
 @param extra extra
 @param adExtraData adExtraData
  */
- (void)trackOriginalAdWithModel:(TTAdSplashModel *)model
                             tag:(NSString *)tag
                           label:(NSString *)label
                           extra:(NSDictionary *)extra
                     adExtraData:(NSDictionary *)adExtraData;

- (void)trackOriginalAdShowWithModel:(TTAdSplashModel *)model
                             extra:(NSDictionary *)extra
                       adExtraData:(NSDictionary *)adExtraData;
@end
