//
//  TTAdSplashHeader.h
//  TTAdSplashSDK
//
//  Created by yin on 2017/7/31.
//  Copyright © 2017年 yin. All rights reserved.
//

#ifndef TTAdSplashHeader_h
#define TTAdSplashHeader_h

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define TTAdSplashActionTypeWeb @"web"
#define TTAdSplashActionTypeApp @"app"

#define kTTAdSplashManagerSplashModelsKey @"kTTAdSplashManagerSplashModelsKeyV4"//保存area广告modelskey， 目前api5.0版本
#define kTTAdSplashManagerModelsKey @"kTTAdSplashManagerModelsKeyV4" //保存广告key， 目前api5.0版本, model版本兼容老版本。
#define kTTAdSplashManagerFirstLuanchModelsKey @"kTTAdSplashManagerFirstLuanchModelsKey"    ///< 首刷广告存储 key

#define kTTAdSplashRecentlyEnterBackgroudTimeKey @"kTTAdSplashRecentlyEnterBackgroudTimeKey"//保存最近一次退到后台的时间
#define kTTAdSplashRecentlyShowAdTimeKey @"kTTAdSplashRecentlyShowAdTimeKey"//保存最近一次展示splash广告的时间
/// 调用didbecomeAcitve允许的最小间隔，单位秒。 0.4.0开始iOS支持后台下发，如果下发的数据无效（ <= 0），则使用此数值。
#define kTTAdSplashDidBecomeActiveMinInterval 20



#pragma mark - Request Params

#define TT_DEVICE_ID            @"device_id"
#define TT_OPEN_UDID            @"openudid"
#define TT_MAC_ADDRESS          @"mac_address"
#define TT_OS                   @"os"
#define TT_IP_ADDRESS           @"ip_address"
#define TT_LATITUDE             @"latitude"
#define TT_LONGITUDE            @"longitude"
#define TT_ACCES                @"access"
#define TT_DIS_DENSITY          @"display_density"
#define TT_CARRIER              @"carrier"
#define TT_MCC_MNC              @"mcc_mnc"
#define TT_IID                  @"iid"
#define TT_AC                   @"ac"
#define TT_CHANNEL              @"channel"
#define TT_APP_ID               @"aid"
#define TT_APP_NAME             @"app_name"
#define TT_VERSION_CODE         @"version_code"
#define TT_VERSION_NAME         @"version_name"
#define TT_DEVICE_PLATFORM      @"device_platform"
#define TT_AB_VERSION           @"ab_version"
#define TT_AB_CLIENT            @"ab_client"
#define TT_AB_GROUP             @"ab_group"
#define TT_AB_FEATURE           @"ab_feature"
#define TT_AB_FLAG              @"abflag"
#define TT_SS_MIX               @"ssmix"
#define TT_DEVICE_TYPE          @"device_type"
#define TT_DEVICE_BRAND         @"device_brand"
#define TT_LANGUAGE             @"language"
#define TT_OS_VERSION           @"os_version"
#define TT_RESOLUTION           @"resolution"
#define TT_UPDATE_VERSION       @"update_version_code"
#define TT_VID                  @"vid"
#define TT_SDK_VERSION          @"sdk_version"
#define TT_BANNER_HEIGHT          @"bh"
#define TT_EXTRA                @"param_extra"
#define TT_USER_ID              @"user_id"
#define TT_OLD_MODE             @"is_old_mode"

#pragma mark -Action Params

#define TT_OPEN_URL             @"open_url"
#define TT_WEB_URL              @"web_url"
#define TT_APP_OPEN_URL         @"app_open_url"
#define TT_ADID                 @"ad_id"
#define TT_LOG_EXTRA            @"log_extra"
#define TT_ACTION_TYPE          @"action_type"
#define TT_WEB_TITLE            @"web_title"
#define TT_DOWN_URL             @"donwload_url"
#define TT_APPLE_ID             @"apple_id"
#define TT_WEB_TITLE            @"web_title"
#define TT_CLICK_BANNER         @"click_banner"   //是否点击banner区域
#define TT_STYLE                @"style"          //沉浸式style
#define TT_SITE_ID              @"site_id"        //沉浸式site_id
#define TT_SHARE_URL            @"share_url"        //dsp落地页分享url
#define TT_SHARE_COVER_URL      @"share_cover_url"  //dsp落地页分享封面图片url
#define TT_SHARE_DESC           @"share_description"//dsp落地页分享摘要
#define TT_SHARE_TITLE          @"share_title"      //dsp落地页分享标题
#define TT_LP_STYLE             @"ad_lp_style"    //独立webview开关
#define TT_INTERCEPT_FLAG       @"intercept_flag" //二跳拦截flag
#define TT_OPEN_TYPE            @"enable_open_type" //开屏加粉开关
#define TT_AD_MP_URL            @"mp_url"    ///< 开屏广告小程序链接
#define TT_AD_WEB_CHANNAEL_ID   @"web_channel_id"
#define TT_AD_PRELOAD_WEB       @"preload_web"
#define TT_AD_SKAN_PRODUCT_PARMAS @"skan_product_parameter"
#define BDA_SPLASH_SHAKE_TYPE @"shake_type"
#define BDA_SPLASH_HIDE_OPEN_WEB_ANIMATION @"hide_open_web_animation"
#define BDA_SPLASH_IS_BANNER_ACTION @"is_banner_action"

const static NSInteger TTAdSplashMinShowInterval  = 600; // 开屏广告最小展示间隔 10 min = 600s
const static NSInteger TTAdSplashMinLeaveInterval = 30; // 开屏广告最小离开前台间隔 30s

//广告展示开始的通知
static NSString *const kTTAdSplashShowStart = @"kTTAdSplashShowStart";
//广告展示结束的通知
static NSString *const kTTAdSplashShowFinish = @"kTTAdSplashShowFinish";

//广告数据models为空
static NSString *const kTTAdSplashEmptyKey = @"kTTAdSplashEmptyKey";

/// 首刷广告数据 model
static NSString *const kTTAdFirstLaunchSplashEmptyKey = @"kTTAdFirstLaunchSplashEmptyKey";

//当天首次尝试展示广告的标识
static NSString *const kTTAdSplashTodayShowIdentify = @"kTTAdSplashTodayShowIdentify";

//当天展示广告次数的标识
static NSString *const kTTAdSplashTodayShowCounts = @"kTTAdSplashTodayShowCounts";

///< 当天预期展示（符合频控条件，但是不一定会展示出来）广告次数的标识
static NSString *const kTTAdSplashExceptedTodayShowCounts = @"kTTAdSplashExceptedTodayShowCounts";

static NSString *const kTTAdSplashChangeMainControlerNotification = @"kTTAdSplashChangeMainControlerNotification";
static NSString * const kBDASplashRecentlyShowTime = @"kBDASplashRecentlyShowTime"; ///< 这个是给冷启动使用，App 被杀死时候不清除。
static NSString * const kSplashEventTag = @"splash_ad";  ///< 开屏事件上报 tag
static NSString * const kSplashCommonAdId = @"84378473382"; ///< 开屏事件公共 ad_id，当上报事件没有对应创意时，使用这个 ad_id。

static NSString *const kisHotLaunch = @"isHotLaunch";

/** 开屏广告类型 */
typedef NS_ENUM(NSInteger, TTAdSplashAdStyle) {
    TTAdSplashAdStyleNormal,        ///< 普通类型广告
    TTAdSplashAdStylePersonalized   ///< 个性化推荐广告
};

typedef NS_ENUM(NSInteger, TTAdSplashShowType) {
    TTAdSplashShowTypeHide,     //不显示,但是还请求
    TTAdSplashShowTypeShow,     //显示
    TTAdSplashShowTypeIgnore    //不显示，不请求
};


typedef NS_ENUM(NSInteger, TTAdSplashResouceType) { //开屏广告素材类型
    TTAdSplashResouceType_None,
    TTAdSplashResouceType_Image,
    TTAdSplashResouceType_Gif,
    TTAdSplashResouceType_Video
};

/**
 *  广告类型
 */
typedef NS_ENUM(NSUInteger, TTAdSplashModelType) {
    TTAdSplashModelTypeDisplayArea = 1, // banner , umeng app list etc ...  @2017-6-16 删除所有area相关代码
    TTAdSplashModelTypeSplash,          // 开屏广告
    TTAdSplashModelTypeChannelRefresh   // 频道下拉刷新广告位
};

/**
 *  广告停投方式类型
 */
typedef NS_ENUM(NSUInteger, BDASplashModelStopShowType) {
    BDASplashModelStopShowTypeNone = 0, // 不停投
    BDASplashModelStopShowTypeUDP = 1,  // UDP 停投
    BDASplashModelStopShowTypeLongConnection = 2  // 长连接停投
};

/**
 * 开屏广告 对应具体广告类型
 */
typedef NS_ENUM(NSInteger, TTAdSplashCommerceType) {
    TTAdSplashCommerceTypeDefault   = 0,   ///< 占位符
    TTAdSplashCommerceTypeFirst     = 1,   ///< 开屏首刷广告
    TTAdSplashCommerceTypeCPT       = 2,   ///< CPT 广告
    TTAdSplashCommerceTypeGD        = 3,   ///< GD 广告
    TTAdSplashCommerceTypePeriodFirst = 4, ///< 分时段首刷
};


/**
 普通开屏视频声音控制开关
 */
typedef NS_ENUM(NSUInteger, TTAdSplashVideoSound) {
    TTAdSplashVideoSoundDefatult = 0,           ///< 默认状态, 静音不可调节
    TTAdSplashVideoSoundMuteAndDdjustable,      ///< 默认静音可调节
    TTAdSplashVideoSoundGradualAndDdjustable,   ///< 默认不静音渐变大可调节
    TTAdSplashVideoSoundDdjustable,             ///< 默认不静音可调节
    TTAdSplashVideoSoundMuteAndRestore,         ///<默认静音并可恢复媒体音量
};

/**
 *  开屏广告类型
 */
typedef NS_ENUM(NSUInteger, TTAdSplashADType) {
    TTAdSplashADTypeImage = 0,                // 图片类型，包括GIF图。
    TTAdSplashADTypeVideoFullscreen = 2,      // 视频类型A，铺满全屏。
    TTAdSplashADTypeVideoCenterFit_16_9 = 3,   // 视频类型B，16:9居中于屏幕，有底图。
    TTAdSplashADTypeImage_ninebox = 4          //图片九宫格样式,不同区域对应不同落地页
};

/**
 *  开屏广告展示类型，为区分与已存在的TTAdSplashShowType，这个类型决定广告展示出来的形式
 */
typedef NS_ENUM(NSUInteger, TTAdSplashDisplayType) {
    TTAdSplashDisplayTypeDefault = 0,  //> 默认开屏展示样式
    TTAdSplashDisplayTypeOriginal = 1,  //> 原生开屏展示，目前抖音侧接入使用
    TTAdSplashDisplayTypeInteractiveVideo = 3, ///> 互动视频样式
};

/**
 *  splash广告banner的类型
 */
typedef NS_ENUM(NSUInteger, TTAdSplashBannerMode) {
    TTAdSplashBannerModeNoBanner    = 0, // 全图展示
    TTAdSplashBannerModeShowBanner  = 1 // 头条标识固定底部，与广告拼接
};

/**
 开屏广告中 图片类型广告中间的 点击引导按钮样式
 */
typedef NS_ENUM(NSUInteger, TTAdSplashClikButtonStyle) {
    TTAdSplashClikButtonStyleNone             = 0, //不展示
    TTAdSplashClikButtonStyleStrip            = 1, //展示为长条，默认值
    TTAdSplashClikButtonStyleRoundRect        = 2,
    TTAdSplashClikButtonStyleStripAction      = 3, //展示为长条 附带第二动作
    TTAdSplashClikButtonStyleDefault          = TTAdSplashClikButtonStyleStrip
};

typedef NS_ENUM(NSInteger, TTAdSplashReadyType) {
    TTAdSplashReadyTypeUnknow = -1,
    TTAdSplashReadyTypeSuccess = 0,
    TTAdSplashReadyTypeNonArrival = 1, // 时间未到
    TTAdSplashReadyTypeExpired = 2, // 时间过期
    TTAdSplashReadyTypeIntervalFromBGNotMach = 3,//从后台切回前台频率过快
    TTAdSplashReadyTypeIntervalFromLastNotMatch = 4,//图片展示频率过快
    TTAdSplashReadyTypeHide = 5,//wifi only或者 hide_if_exist
    TTAdSplashReadyTypeImageEmpty = 6, //广告图片没有加载完成
    TTAdSplashReadyTypeSizeNotMatch = 7,
    
    TTAdSplashReadyTypeFullscreenVideoEmpty = 8,    // 全屏类型的视频 not ready
    TTAdSplashReadyTypeVideoReadyWithoutImage = 9,  // 非全屏类型视频，有视频无图
    TTAdSplashReadyTypeImageReadyWithoutVideo = 10, // 非全屏类型视频，有图无视频
    TTAdSplashReadyTypeVideoImageAllEmpty = 11,     // 非全屏类型视频，无图无视频
    TTAdSplashReadyTypeFirstSplash = 12,             // CPT广告命中首刷逻辑
    TTAdSplashReadyTypeNoRemainCount = 13,           // 当前无剩余展示次数
    TTAdSplashReadyTypeLandScape = 14,               // 当前为横屏不展示
    TTAdSplashReadyTypeFirstLaunch = 15,             // 推送、openUrl等不出开屏
    TTAdSplashReadyTypeRequstEmpty = 16,             // 请求到广告数据为空
    TTAdSplashReadyTypeLocalEmpty = 17,              // 本地广告数据为空
    TTAdSplashReadyTypeRequestImageEmpty = 18,       // 请求图片数据<10K  白屏
    TTAdSplashReadyTypeShowImageEmpty = 19,          // 展示的图片数据<10K 白屏
    TTAdSplashReadyTypeOthers = 20,
    TTAdSplashReadyTypeRealTimeEmpty = 21,
    TTAdSplashReadyTypeVideoInvalid = 22,           //不合法视频
    TTAdSplashReadyTypeImageInvalid = 23,            //不合法图片
    TTAdSplashReadyTypeNoTopviewMark = 24,           ///< 没有 topview 相关标记
    TTAdSplashReadyTypeNoSelected = 25,              ///< 在队列中，但是因为前面数据先展示，在后面的没有被选中
    TTAdSplashReadyTypeInvalidType = 26,             ///< 类型不对，例如本次应该是首刷，非首刷广告直接略过。
    TTAdSplashReadyTypeInvalidStyle = 27,          ///< 不是可以展示的广告类型。例如此创意为个性化广告，但是端上规定不让展示个性化广告
    TTAdSplashReadyTypeDisplayCountOver = 28,   ///< 这个创意展示次数达到上限
    TTAdSplashReadyTypeColdLaunchDisplayFrequency = 29, ///< 冷启动展示太频繁
};

/// 视频广告中断原因，用作事件统计.
typedef NS_ENUM(NSUInteger, TTAdSplashVideoBreakReason) {
    TTAdSplashVideoBreakReasonUnknown = 0, // 未知中断
    TTAdSplashVideoBreakReasonEnterDetail, // 点击进落地页
    TTAdSplashVideoBreakReasonSkip,        // 点击Skip跳过
    TTAdSplashVideoBreakReasonShakeSkip,        // 宿主主动跳过，如抖音抖一抖跳过
    TTAdSplashVideoBreakReasonEnterBackground = 7 // app 进入后台
};

// 开屏广告请求method枚举
typedef NS_ENUM(NSUInteger, BDAdSplashRequestMethod) {
    BDAdSplashRequestMethodGET = 0,
    BDAdSplashRequestMethodPOST
};

typedef NS_ENUM(NSUInteger, TTAdSplashDisplayContentMode) {
    TTAdSplashDisplayContentModeScaleToFill = 0, //> 拉伸铺满区域，可能会破坏素材原有的比例
    TTAdSplashDisplayContentModeScaleAspectFill, //> 保持素材原有比例居中铺满区域，可能会剪裁素材的四周
};

typedef NS_ENUM(NSUInteger, TTAdSplashMPPreloadPolicy) {
    TTAdSplashMPPreloadPolicyNone = 0,      ///< 不进行预加载
    TTAdSplashMPPreloadPolicyAlways = 1,    ///< 始终进行预加载
    TTAdSplashMPPreloadPolicyOnlyWifi = 2,  ///< wifi 下预加载
};

/** 开屏右上角 logo 色调 */
typedef NS_ENUM(NSUInteger, BDASplashLogoColor) {
    BDASplashLogoColorDefault = 0,  ///< 默认样式
    BDASplashLogoColorLight,        ///< 高亮颜色样式
    BDASplashLogoColorDark,         ///< 黑色颜色样式
    BDASplashLogoColorGrey,         ///< 灰色，黑白色调样式
    BDASplashLogoColorTransparent,  ///< 全透明，也就是隐藏
};

/// 点击开屏跳过按钮时退出开屏的方式定义
typedef NS_ENUM(NSUInteger, BDASplashSkipInfoActionType) {
    BDASplashSkipInfoActionTypeDefault, /// 线上默认行为：直接跳过
    BDASplashSkipInfoActionTypeSwipeUp, /// 上滑退出
};

///<开屏上滑操作类型
typedef NS_ENUM(NSUInteger, BDASplashViewSwipeUpMode) {
    BDASplashViewSwipeUpModeDisable = 0,  ///<不启用上滑操作
    BDASplashViewSwipeUpModeMta,   ///<启用上滑操作，但是只上报统计事件，视图不上滑
    BDASplashViewSwipeUpModeScroll, ///启用上滑操作，且开屏视图上滑
};

///<开屏上滑点击操作类型
typedef NS_ENUM(NSUInteger, BDASplashViewSwipeTapMode) {
    BDASplashViewSwipeTapModeDisable = 0,  ///点击无响应
    BDASplashViewSwipeTapModeClickDone,   ///点击进入落地页等
    BDASplashViewSwipeTapModeScrollUpExit, ///点击上滑退出开屏
};

/** 挑选广告阶段，广告 model 的各种状态码 */
typedef NS_ENUM(NSUInteger, BDASModelStatusCode) {
    BDASModelStatusCodeShowNormalSplash = 1000,             ///< 普通广告（非炫屏）展示。
    BDASModelStatusCodeShowFrequently = 1001,               ///< 受到频控限制，此次不展示。
    BDASModelStatusCodeShowLimit = 1002,                    ///< 受到 show_limit 限制，此次不展示。
    BDASModelStatusCodeUDPStop = 1003,                      ///< UDP 停投返回结果是停止展示
    BDASModelStatusCodeCacheStop = 1004,                    ///< UDP 未及时返回，但命中预加载停投时间段，不展示。
    BDASModelStatusCodeTimeInvalid = 1005,                  ///< 开启了时间校验校验，时间有问题（重启过），不展示。
    BDASModelStatusCodeAdSelected = 1006,                   ///< 普通广告最终被选中，理论上和 1000 一样。
    BDASModelStatusCodeDataValid = 2001,                    ///< 数据不合法（可能是打包下发数据有问题）,例如素材 URL 为空。
    BDASModelStatusCodeNoFirstLaunchData = 2006,            ///< 首刷次，但不符合展示条件(不是首刷也不是 GD)，所以不展示。
    BDASModelStatusCodeNoPeriodFirstLaunchData = 2007,      ///< 分时段首刷次，但不符合展示条件，所以不展示。
    BDASModelStatusCodeAdNoSelected = 2008,                 ///< 广告未被选中，无展示机会。
    BDASModelStatusCodeShowTopview = 2009,                  ///< Topview 广告被确认展示。
    BDASModelStatusCodeRejectedTopview = 2010,              ///< Topview 广告被拒绝展示。
    BDASModelStatusCodeResourceLoss = 2011,                 ///< 广告资源不存在，无法被展示。
    BDASModelStatusCodeShowEarly = 5001,                    ///< 广告未到展示时间。
    BDASModelStatusCodeShowExpired = 5002,                  ///< 广告已过期。
    BDASModelStatusCodeAdByRecyled = 5003,                  ///< 广告已召回，如push停投，UDP报文升级的停投。
    BDASModelStatusCodeUnknowError = 5006,                  ///< 未知错误。
    BDASModelStatusCodeAdByIntercept = 5005                 ///< 业务方拦截了该广告。
};

/// 开屏整改优化特效类型
typedef NS_ENUM(NSUInteger, BDASplashButtonAnimationStyleEdition) {
    BDASplashButtonAnimationStyleEditionNone = 0,   ///< 无特效
    BDASplashButtonAnimationStyleEditionFirst,      ///< 一期特效，算色加光晕
    BDASplashButtonAnimationStyleEditionSecond,     ///< 二期特效，按钮缩放加动图加光晕
};

typedef void(^TTAdSplashViewButtonTapHandler)(UITapGestureRecognizer *tap);

typedef NSDictionary* (^TTAdSplashParamBlock)(void);

typedef void (^TTAdSplashPreloadVideoFinishBlock)(NSString *key, NSDictionary *videoEngineModelInfo);

typedef void (^TTAdSplashResponseBlock)(NSData * data, NSError * error, NSInteger statusCode);

typedef void (^TTAdSplashResultBlock)(NSData * data, NSError * error, NSInteger statusCode, BOOL success);

typedef void (^BDAdSplashResponseBlock)(NSData * data, NSError * error, NSInteger statusCode);

typedef void (^BDAdSplashResultBlock)(NSData * data, NSError * error, NSInteger statusCode, BOOL success);

#define tta(x) [TTAdSplashDeviceHelper newPadding:(x)]

#define ttfont(x) [TTAdSplashDeviceHelper newFontSize:(x)]

#define bdaScaleFont(x) [TTAdSplashDeviceHelper scaleFontWithScreenWidth:(x)]

#ifndef emptyString
#define emptyString(str) (!str || ![str isKindOfClass:[NSString class]] || str.length == 0)
#endif

#ifndef emptyArray
#define emptyArray(array) (!array || ![array isKindOfClass:[NSArray class]] || array.count == 0)
#endif

#ifndef emptyDictionary
#define emptyDictionary(dict) (!dict || ![dict isKindOfClass:[NSDictionary class]] || ((NSDictionary *)dict).count == 0)
#endif

#ifndef BDASplashStr4SEL
#define BDASplashStr4SEL(sel) NSStringFromSelector(@selector(sel))
#endif

#if 0
#define DLog(...) NSLog(__VA_ARGS__)
#else
#define DLog(...)
#endif

#ifndef TTADSplashMsgCtrShared
#define TTADSplashMsgCtrShared [TTAdSplashMessageCenter shareInstance]
#endif

#endif /* TTAdSplashHeader_h */
