//
//  TTAdSplashModel.h
//  Article
//
//  Created by Zhang Leonardo on 12-11-18.
//
//

/**
 * 广告的model， 目前splash广告、area广告共用，通过adModelType区分
 * API wiki https://wiki.bytedance.net/pages/viewpage.action?pageId=70869190
 *
 **/

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "TTAdSplashHeader.h"
#import <JSONModel/JSONModel.h>
#import "BDAExtraVideoInfoModel.h"
#import "TTAdSplashSubFieldModels.h"

@protocol TTAdSplashModel;

@interface TTAdSplashModel : JSONModel<NSCoding>

#pragma mark - Public properties
@property (nonatomic, assign) TTAdSplashModelType adModelType;
@property (nonatomic, assign) TTAdSplashDisplayType splashDisplayType;
@property (nonatomic, copy)   NSString *splashAdId;   //原生开屏广告对应的adid
@property (nonatomic, assign) NSTimeInterval requestTimeInterval;        // 广告请求下来的时间，client receive time, 单位 s
@property (nonatomic, copy) NSString *splashID;                        // 此处为创意id
@property (nonatomic, copy) NSString *logExtra;                        // 发送统计的时候带回去

#pragma mark - Ad
@property (nonatomic, copy)   NSString *display_density;
@property (nonatomic, assign) NSTimeInterval displayTime;
@property (nonatomic, assign) NSTimeInterval splashDisplayAfterSecond;        //延时显示时间
@property (nonatomic, assign) NSTimeInterval splashExpireSeconds;

@property (nonatomic, copy)   NSString *splashOpenURL;                   // 落地页1： 某详情页
@property (nonatomic, strong) NSArray *splashOpenUrlList;              //针对图片九宫格openUrls
@property (nonatomic, copy)   NSString *splashActionType;                // 落地页2： web, app
@property (nonatomic, copy)   NSString *splashStyle;                    //是否沉浸式
@property (nonatomic, copy)   NSString *splashSiteId;                   //沉浸式siteId

@property (nonatomic, copy)   NSString *splashDownloadURLStr;
@property (nonatomic, copy)   NSString *splashAppName;
@property (nonatomic, copy)   NSString *splashAppleID;

@property (nonatomic, copy)   NSString *splashWebURLStr;
@property (nonatomic, copy)   NSArray *splashWebUrlList;            //针对图片九宫格webUrls
@property (nonatomic, copy)   NSString *splashWebTitle;
@property (nonatomic, assign) TTAdSplashMPPreloadPolicy mpPreloadPolicy;     ///< 预加载小程序策略

@property (nonatomic, copy)   NSString *splashMPURLStr;   ///< 小程序链接
@property (nonatomic, strong) NSArray *splashTrackURLStrings;
@property (nonatomic, strong) NSArray *splashClickTrackURLStrings;

@property (nonatomic, copy)   NSDictionary *imageInfo;

#pragma mark - Control
/// 允许再什么网络状况下加载，参考 @see SSNetworkFlags 默认展示(SSNetworkFlagWifi)
@property (nonatomic, strong) NSNumber *predownload;
@property (nonatomic, strong) NSNumber *splashBannerMode;
/// 是否展示跳过按钮和查看按钮，默认展示(YES)
@property (nonatomic, strong) NSNumber *displaySkipButton;               // skip_btn 服务器下发字段
// 跳过按钮样式实验控制位，默认为0
@property (nonatomic, strong) NSNumber *skipButtonStyle;

/** 是否开启加粉形式, app_open_url跳转个人主页并加关注
 https://wiki.bytedance.net/pages/viewpage.action?pageId=363824916
 */
@property (nonatomic, assign) BOOL enableOpenType;

/// 是否展示广告点击按钮，0不显示按钮，1显示新样式，2显示旧样式，默认为1。
@property (nonatomic, strong) NSNumber *displayViewButton;               // click_btn
@property (nonatomic, copy)   NSString *buttonText;
@property (nonatomic, assign) NSInteger buttonTextDisplayAfter;          // buttonText 的展示时长
@property (nonatomic, copy)   NSString *appOpenURL;                      // 落地页3： 第三方

@property (nonatomic, assign) TTAdSplashCommerceType commerceType;  // 开屏广告的商业类型

@property (nonatomic, assign) TTAdSplashVideoSound soundControl;    ///< 声音控制开关
@property (nonatomic, assign) NSInteger showSoundTime; /// 视频按照 show_sound_time单位（毫秒）出声音
// 分时广告
@property (nonatomic, strong) NSArray *intervalCreatives;

/// 如果是gif，是否循环播放
@property (nonatomic, strong) NSNumber *repeats;
@property (nonatomic, strong) NSNumber *clickHeight;
// 开机视频广告
@property (nonatomic, assign) TTAdSplashADType splashADType;
@property (nonatomic, assign) BOOL isGif;
@property (nonatomic, copy)   NSString *videoId;
@property (nonatomic, copy)   NSString *videoGroupId;
@property (nonatomic, copy)   NSArray *videoURLArray;
@property (nonatomic, copy)   NSArray *videoPlayTrackURLArray;
@property (nonatomic, copy)   NSArray *videoPlayOverTrackURLArray;
@property (nonatomic, copy)   NSString *video_density;
@property (nonatomic, copy) NSString *videoSecretKey;

// 抖音开屏样式优化新加字段
@property (nonatomic, copy) NSDictionary *skipInfo; ///< 跳过按钮相关
@property (nonatomic, strong) TTAdSplashSwipeUpConfigModel *swipeUpConfig;/// 手势上滑相关配置
@property (nonatomic, copy) NSDictionary *labelInfo; ///< '广告'标签相关
@property (nonatomic, copy) NSString *predownloadText; ///< wifi预加载文案

@property (nonatomic, strong) BDAExtraVideoInfoModel * extraVideoInfo;  ///< 互动开屏新增字段
@property (nonatomic, assign) BOOL isInteractiveVideoMode;  ///<是否是互动开屏
@property (nonatomic, copy) NSString * action;      ///<互动开屏点击按钮标题
@property (nonatomic, copy) NSDictionary *shakeStyleInfo;
@property (nonatomic, assign) BOOL enablePreRenderWeb;  ///< 是否预渲染 webview 落地页
@property (nonatomic, copy) NSDictionary *clickArea;
@property (nonatomic, copy) NSDictionary *addFansInfo;

#pragma mark - Share
///分享相关字段,只针对dsp广告的落地页页面里取分享信息取不到,即从开屏里透传到落地页
@property (nonatomic, copy)   NSString *shareTitle;
@property (nonatomic, copy)   NSString *shareUrl;
@property (nonatomic, copy)   NSString *shareCoverUrl;
@property (nonatomic, copy)   NSString *shareDesc;

@property (nonatomic, copy)   NSString *splashURLString;
@property (nonatomic, strong) NSNumber *splashHideIfExist;
@property (nonatomic, copy)   NSString *adLandingPageStyle;
@property (nonatomic, strong) NSNumber *adInterceptFlag;
@property (nonatomic, strong) NSNumber *showExpected;   //打点辅助字段 判断是否在首位要下次展示
@property (nonatomic, copy) NSDictionary *promotionIcon; // 活动ICON
@property (nonatomic, copy) NSDictionary *vastInfo;     ///< OM SDK 埋点上报相关信息
@property (nonatomic, assign) TTAdSplashAdStyle adStyle;    ///< 广告类型，普通的 or 个性化

#pragma mark - Helper Property 非 model 直接下发的字段, 通过解析或者通过其他方式合成的一些字段

@property (nonatomic, copy) NSDictionary *adVerifications; ///< vastInfo 里面的一个字段

#pragma mark - Real time
//实时下发相关字段
@property (nonatomic, strong) NSString *realTimeLogExtra;
@property (nonatomic, assign) BOOL useRealTime;
@property (nonatomic, assign) NSInteger errorCode;

@property (nonatomic, assign) BOOL isRetrieval; ///< 是否为回捞上来的广告，临时设计方案加的一个属性，后续重构时改掉.
@property (nonatomic, assign) NSInteger preloadWeb; ///< preload_web = 4 第三方落地页预加载方案，
@property (nonatomic, strong) NSNumber *repeatTimes; ///< 当天内这个广告可以展示多少次，0 代表无限次。1 代表 1 次，2 代表 2 次...
@property (nonatomic, assign) BDASplashLogoColor logoColor; ///< Logo 色调
@property (nonatomic, copy) NSString *skanProductParams;    ///< iOS 14 系统上，请求 App Store 使用的参数，透传到端上使用

#pragma mark - TopView

@property (nonatomic, assign) BOOL isAutoRefresh; ///< 是否自动刷新 1:自动刷新 0:主动强制刷新.

@property (nonatomic, assign) BDASplashModelStopShowType stopShowType;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

+ (TTAdSplashModel *)splashModelWithDictionary:(NSDictionary *)dict;


- (CGSize)imageSize;
- (CGSize)videoSize;

/**
 * @return 是否是视频相关广告类型 YES是 NO否
 */
- (BOOL)isVideoRelatedAdType;

/**
 *  @brief 对model中的参数进行微调，单位换算，请求时间戳设置等等
 */
- (void)setDefaultValuesWithRequestTime:(NSTimeInterval)requestTime;

/*
 *  小小程序链接列表
 */
- (NSArray *)getPreloadMPAppList;

- (NSString *)adWebPrelodChannelId;

/// 点击跳过按钮时的退出效果
- (BDASplashSkipInfoActionType)skipInfoAction;

@end
