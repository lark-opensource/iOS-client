//
//  TTAdSplashDelegate.h
//  Pods
//
//  Created by yin on 2017/8/13.
//
//

#ifndef TTAdSplashDelegate_h
#define TTAdSplashDelegate_h

#import "TTAdSplashHeader.h"

NS_ASSUME_NONNULL_BEGIN

@class TTAdSplashModel;

typedef NS_ENUM(NSInteger, TTAdSplashPreloadPolicy) {
    TTAdSplashPreloadPolicyNone = -1,          ///< -1代表 任何网络不做预加载
    TTAdSplashPreloadPolicyDefaultWiFi = 0,    ///< 默认WIFI加载
    TTAdSplashShowTypeIgnoreWifiAndGPRS = 1    ///< WIFI&GPRS加载
};

/** 宿主主动调用跳过广告，返回跳过的结果 */
typedef NS_ENUM(NSInteger, TTAdSplashSkipAdResult) {
    TTAdSplashSkipAdResultDefault = 0, //> 默认值
    TTAdSplashSkipAdResultFaiedDueToNoAdShowingNow, //> 跳过广告失败，因为当前没有广告在展示
    TTAdSplashSkipAdResultFaiedDueToOriginalAdShowingNow, //> 跳过广告失败，因为原生广告在展示
    TTAdSplashSkipAdResultSucceed //> 跳过广告成功
};

@protocol TTAdSplashDelegate <NSObject>

#pragma mark - Required

@required

/**
 * logoAreaHeight， logo区域的高度，一定要传，不然下发尺寸错误
 * uints: pixel
 * @return logo区域的高度
 */
- (NSUInteger)logoAreaHeight;

/**
 * 新样式跳过按钮centerY距离banner底部的距离, 这个距离是logo中心距离底部的距离
 * units: point
 * @return centerY Offset
 */
- (NSUInteger)skipButtonBottomOffsetWithBannerMode:(TTAdSplashBannerMode)mode;

/**
 * 接口baseUrl,此接口由于tiktok升级，强制SDK禁止带入硬编码url域名，所以必须调用方带入地址，不再提供默认地址
 * 请确保SplashManager的delegate在第一时间注册
 * @return schema + host
 */
- (NSString *)splashBaseUrl;

#pragma mark - Optional

@optional

/**
 * 开屏请求类
 *
 * @param urlString 开屏接口url
 * @param responseBlock 注入参数回调
 */
- (void)requestWithUrl:(NSString *)urlString responseBlock:(TTAdSplashResponseBlock)responseBlock;

/**
 * 开屏请求类
 *
 * @param urlString 开屏接口url
 * @param method 请求的方式，目前仅支持GET、POST即可
 * @param responseBlock 注入参数回调
 * @param headers 需要在header中额外设置的参数
 * @param body 需要在请求体中设置的参数
 * @param param POST请求的参数 id类型
 */
- (void)requestWithUrl:(NSString *)urlString
                method:(BDAdSplashRequestMethod)method
               headers:(nullable NSDictionary *)headers
                  body:(nullable NSDictionary *)body
                 param:(nullable NSDictionary *)param
         responseBlock:(BDAdSplashResponseBlock)responseBlock;

/**
 * 接入方定制开屏接口的path  可以不实现,默认用/api/ad/splash/app_name/v15/
 *
 * @return path
 */
- (NSString *)splashPathUrl;

/**
 * 实时网络类型
 No  : @"none"
 WWAN: @"mobile"
 WiFi: @"wifi"
 2G  : @"2g";
 3G  : @"3g"
 4G  : @"4g"
 * @return net type
 */
- (NSString *)splashNetwokType;

/**
  * 实时网络类型
  None   = -1,
  No     = 0,
  Mobile = 1,
  2G     = 2,
  3G     = 3,
  Wifi   = 4,
  4G     = 5
 * @return number
 */
- (NSNumber *)ntType;

/**
 * 实时device id

 * @return device id
 */
- (NSString *)deviceId;

/**
 * 实时install id

 * @return install id
 */
- (NSString *)installId;

/**
 * 开屏背景图
 * 例如用在非全屏视屏(16:9)广告下，非启动视图
 *
 * @return background image
 */
- (UIImage *)splashBgImage;

/**
 一个假的启动图,当视屏广告未加载出来前,贴上这个图进行过渡.
 优先由宿主 App 设置，如果宿主 App 没有设置，SDK 内部从 bundle 中读取.

 @return 外部设置的启动图
 */
- (nullable UIView *)splashFakeLaunchView;

/**
 * 视频logo图名
 *
 * @return video logo image
 */
- (UIImage *)splashVideoLogo;

/**
 *wifi icon图名
 *
 * @return image name
 */
- (UIImage *)splashWifiImage;

/**
 * view more button图片名
 *
 * @return view more image
 */
- (UIImage *)splashViewMoreImage;

/**
 * 箭头图片
 *
 * @return arrow image
 */
- (UIImage *)splashArrowImage;

/**
 * 跳过按钮文案
 *
 * @return button text
 */
- (NSString *)splashSkipBtnName;

/**
 * 跳过按钮是否在底部 右下角
 *
 * @return 是否在底部  默认在顶部右上角
 */
- (BOOL)isSplashSkipBtnInBottom __deprecated_msg("method deprecated");    

/**
 *是否开启本地日志
 *
 * @return 是否开启
 */
- (BOOL)enableSplashLog;

/**
 * 是否打开gif卡顿优化
 *
 * @return 是否打开 默认打开优化
 */
- (BOOL)enableSplashGifKadunOptimize;

/**
 * 是否使用BDImageView替换现有的图片库进行播放
 *
 * @return 是否打开 默认不使用替换
 */
- (BOOL)enableShowBDImageView;

/**
 *  @brief 是否开启视频广告音频卡顿的优化
 *
 *  @return 是否打开，默认关闭优化
 */
- (BOOL)enableSplashAudioSessionStalledOptimization;

/**
 *  @brief 针对实时需求对预加载队列逻辑的改造
 *  @return YES，预加载采用对列merge逻辑; NO 维持原有的预加载队列替换逻辑。 defaults NO
 */
- (BOOL)enablePreloadReconsitution;

/**
 * 开屏广告图将要展示 等同 kTTAdSplashShowStart 通知
 */
- (void)splashViewWillAppear;

/**
 * 开屏广告图将要展示
 * @param model 广告数据model
 */
- (void)splashViewWillAppearWithAdModel:(TTAdSplashModel *)model;

/**
 开屏广告展示
 @param adInfo 广告相关信息
 */
- (void)splashViewAppearWithAdInfo:(NSDictionary *)adInfo DEPRECATED_MSG_ATTRIBUTE("Please use -[splashViewAppearWithAdModel:] instead");
/**
 开屏广告展示
 @param model 广告数据model
 */
- (void)splashViewAppearWithAdModel:(TTAdSplashModel *)model;

- (void)splashViewDidDisappear DEPRECATED_MSG_ATTRIBUTE("Please use -[splashViewDidDisappearWithAdModel:] instead");

/**
 * 开屏广告图已经结束展示 等同 kTTAdSplashShowFinish 通知
 * @param model 广告数据model
 */
- (void)splashViewDidDisappearWithAdModel:(TTAdSplashModel *)model;

/// 开屏广告向上滑动完成
- (void)splashViewDidScrollCompleted;

/// 是否是新用户
- (BOOL)isNewUserForSplashSecondPhaseAnimation;

/**
 * 是否使用TTTrack中v3的接口，默认NO，
 * 即使用宿主实现的 trackWithTag:label:extra:
 * 如果返回YES开启，即使用 trackV3WithEvent:params:
 */
- (BOOL)enableTrackV3Format;

/**
 三方监测链接发送 如果外部实现,则走外部发送,否则用sdk发送逻辑

 @param URLs 监测链接
 @param trackDict 包含ad_id、log_extra等参数
 */
- (void)trackURLs:(NSArray *)URLs dict:(NSDictionary *)trackDict;

/**
 * 统计方法 V1 Format
 * @param tag 广告位
 * @param label 用户行为
 * @param extra ad_id、log_extra等透传参数
 */
- (void)trackWithTag:(NSString *)tag label:(NSString *)label extra:(NSDictionary *)extra;

/**
 * v3格式日志打点
 * @param event 时间名称
 * @param params 额外参数
 * @param isDoubleSending 是否为双发的v3事件，默认不是
 */
- (void)trackV3WithEvent:(NSString *)event params:(NSDictionary *_Nullable)params isDoubleSending:(BOOL)isDoubleSending;

/**
 * 广告点击回调
 *
 * @param condition ad_id、log_extra等参数
 */
- (void)splashActionWithCondition:(NSDictionary *)condition;

/**
 * Slardar异常增加广告报警信息，cid 和 log_extra，isisAdShowing
 *
 * @param dic
 * cid 最近展示的广告的cid
 * logExtra 最近展示的广告的信息
 * isAdShowing 广告是否正在展示
 */
- (void)reportInfoWithAdInfo:(NSDictionary *)param;
 
/**
 * 下载沉浸式资源
 *
 * @param dict 资源信息 ad_id, site_id
 */
- (void)downloadCanvasResource:(NSDictionary *)dict;

/**
 * 端监控打点
 *
 * @param serviceName 监控名
 * @param status 状态号
 * @param extra extra信息
 */
- (void)monitorService:(NSString *)serviceName status:(NSUInteger)status extra:(NSDictionary *)extra;

/**
 * 端监控打点
 * @param serviceName 监控名
 * @param params value集合
 * @param extra extra信息
 */
- (void)monitorService:(NSString *)serviceName value:(NSDictionary *)params extra:(NSDictionary *)extra;

/************************* 以下可以不用实现 专为国际化定制  **********************************/

/**
 * 开屏定制的背景图,国际化需要单独定制开屏背景
 * 默认可以不实现,则用splashBgImageName设置
 * @param frame 开屏frame
 * @return 定制背景图
 */
- (UIView *)splashBGViewWithFrame:(CGRect)frame;

/// 端上定制 logo 图，务必生成 size, sdk 内不再生成 size。根据色调可以传不同样式。
/// @param color logo 色调
- (UIView *)splashLogoViewWithColor:(BDASplashLogoColor)color;

/**
 * 外部定制头条logo的图 务必生成size,sdk内不再生成size
 * 不实现则用splashVideoLogoName方式设置
 * @return UIView
 */
- (UIView *)splashLogoView DEPRECATED_MSG_ATTRIBUTE("方法已废弃，请使用splashLogoViewWithColor:代替");

/**
 * 外部定制视频下wifi已加载的图  务必生成size,sdk内不再生成size
 * 不实现则用splashWifiImageName方式设置
 * @return UIView
 */
- (UIView *)splashWifiView;

/**
 * 玩不定制banner条查看更多view
 *
 * @return view
 */
- (UIView *)splashReadMoreView;

/**
 * 打开应用文案 国际化需要传英文
 *
 * @return 打开应用
 */
- (NSString *)splashOpenAppString;

/**
 * 查看更多文案 国际化需要传英文
 *
 * @return 查看更多
 */
- (NSString *)splashReadMoreString;

/**
 预加载策略
 @return
        1   wifi预加载
        2   wifi+移动流量 预加载
        -1  都不预加载
 
 @return 查看更多
 */
- (TTAdSplashPreloadPolicy)preloadPolicy;

/**
 *  广告素材展示的策略
 *  详情见TTAdSplashDisplayContentMode
 *  默认使用TTAdSplashDisplayContentModeScaleToFill
 */
- (TTAdSplashDisplayContentMode)displayContentMode;

- (BOOL)realTimeRequestUseTTNet;

/**
 开屏广告通知宿主预加载小程序

 @param mpURLList 小程序链接列表，列表中的值为小程序链接。
 */
- (void)preloadSplashAdMpURLList:(NSArray<NSString *> *)mpURLList;

/**
开屏广告通知宿主预加载落地页

@param splashList 开屏models
*/
- (void)preloadSplashAdWebSplashList:(NSArray *)splashList;

/**
 *  @brief 炫屏使用SDK预加载开关
 *  @return YES，预加载采用SDK预加载部分视频资源。 defaults NO
 */
- (BOOL)topViewSDKPreloadEnable;

/**
 预加载视频资源
 @{  @"key":@"123456",      预加载时使用的key
 @"videoId":@"123456",       视频id
 @"url":@"http://www.baidu.com",       视频的播放地址
 @“ad_id”:@"124",             广告id
 @"logextra":@"{}"               log_extra
 }
 @param dict
 */
- (void)preloadVideoWithCondition:(NSDictionary *)condition completionBlock:(TTAdSplashPreloadVideoFinishBlock)completionBlock;

/**
 清除炫屏预加载资源
 @param key 预加载返回的key
 */
- (void)removeTopViewResource:(NSString *)key;

/**
 检测视频是否预加载成功
 
 @param key 视频缓存时对应的key
 @param vid 视频id
 @return return 是否成功
 */
- (BOOL)isVideoPreloadSuccess:(NSString *)key videoId:(NSString *)vid;

/// 获取开屏广告调试日志
/// @param log 调试日志
- (void)splashDebugLog:(NSString *)log;

/// 是否展示个性化推荐广告，由端上决定
- (BOOL)shouldDisplayPersonalizedAd;

/// 开屏需要透传的参数中是否包含坐标
- (BOOL)splashShouldContainCoordinateInParams;

/// 摇一摇跳过按钮被点击
- (void)shakeViewSkipButtonClicked;

///开屏滑走需要的引导图，由端上提供
- (UIView *)splashSwipeGuideView:(BOOL)needShadow;

- (BOOL)isSupportLandscape;

@end

NS_ASSUME_NONNULL_END

#endif /* TTAdSplashDelegate_h */
