//
//  BDPSDKConfig.h
//  Timor
//
//  Created by muhuai on 2018/5/9.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OPRuntimeType);

@interface BDPSDKConfig : NSObject

/**
 服务整体下线的展示页面
 默认值https://developer.toutiao.com/systemdown
 */
@property (nonatomic, copy) NSString *disableServiceURL;

/**
 某个小程序下线的展示页面
 默认值https://developer.toutiao.com/appdown
 */
@property (nonatomic, copy) NSString *disableAppURL;

/**
 不支持的设备或者系统时的展示页面
 默认值https://developer.toutiao.com/unsupported
 */
@property (nonatomic, copy) NSString *unsupportedContextURL;

/**
 系统不支持的展示页面
 默认值https://developer.toutiao.com/unsupported?type=os_unsupported
 */
@property (nonatomic, copy) NSString *unsupportedOSVersion;

/**
 iOS 系统不支持的展示页面
 默认值https://developer.toutiao.com/unsupported?type=ios_unsupported
 */
@property (nonatomic, copy) NSString *unsupportediOSSystem;

/**
 机型不支持的展示页面
 默认值https://developer.toutiao.com/unsupported?type=model_unsupported
 */
@property (nonatomic, copy) NSString *unsupportedDeviceModel;

/**
 不支持横屏时的展示页面
 默认值https://developer.toutiao.com/unsupported?type=orientation_landscape_unsupported
 */
@property (nonatomic, copy) NSString *unsupportedLandscapeURL;

/**
 不支持竖屏的展示页面
 默认值https://developer.toutiao.com/unsupported?type=orientation_portrait_unsupported
 */
@property (nonatomic, copy) NSString *unsupportedPortraitURL;

/**
 跳转到未配置的schema时失败的展示页面
 默认值https://developer.toutiao.com/unsupported?unconfig_schema=
 */
@property (nonatomic, copy) NSString *unsupportedUnconfigSchemaURL;

/**
 跳转到未配置的domain时失败的展示页面
 默认值https://developer.toutiao.com/unsupported?unconfig_domain=
 */
@property (nonatomic, copy) NSString *unsupportedUnconfigDomainURL;

/**
 登录接口地址
 默认值https://developer.toutiao.com/api/apps/login
 */
@property (nonatomic, copy) NSString *userLoginURL;

/**
 获取小程序用户信息接口地址
 默认值https://developer.toutiao.com/api/apps/user/info
 */
@property (nonatomic, copy) NSString *userInfoURL;

/**
获取H5应用用户信息接口地址
默认值https://open.feishu.cn/open-apis/mina/jssdk/getUserInfo
*/
@property (nonatomic, copy) NSString *userInfoH5URL;

/**
 检查session是否过期接口地址
 默认值为空
 */
@property (nonatomic, copy) NSString *checkSessionURL;

/**
 获取小程序基本信息接口地址
 默认值https://developer.toutiao.com/api/apps/meta
 */
@property (nonatomic, copy, nonnull) NSString *appMetaURL;

/**
 获取小程序批量信息接口地址
 */
@property (nonatomic, copy, nonnull) NSString *batchAppMetaURL;


/**
 获取卡片基本信息接口地址
 */
@property (nonatomic, copy, nullable) NSArray<NSString *> *cardMetaUrls;

/**
 小游戏排行榜数据接口
 默认值https://developer.toutiao.com/api/apps/rank
 */
@property (nonatomic, copy) NSString *rankDataURL;

/**
 关于页面数据接口
 默认值https://developer.toutiao.com/api/apps/about
 */
@property (nonatomic, copy) NSString *aboutURL;

/**
 小游戏加入挑战组接口
 默认值https://developer.toutiao.com/api/apps/user/group
 */
@property (nonatomic, copy) NSString *setUserGroupURL;

/**
 解析 share token数据接口
 默认值 https://developer.toutiao.com/api/apps/share/decode_token
 */
@property (nonatomic, copy) NSString *decodeShareTokenURL;

/**
 增加使用记录接口
 默认值 https://developer.toutiao.com/api/apps/history/add
 */
@property (nonatomic, copy) NSString *usageRecordURL;
/**
 获取使用记录接口
 默认值 https://developer.toutiao.com/api/apps/history
 */
@property (nonatomic, copy) NSString *getUsageRecordURL;
/**
 删除使用记录接口
 默认值 https://developer.toutiao.com/api/apps/history/remove
 */
@property (nonatomic, copy) NSString *removeUsageRecordURL;

/**
 分享上传图片链接
 默认值 https://developer.toutiao.com/api/apps/share/upload_image
 */
@property (nonatomic, copy) NSString *shareImgUploadURL;

/**
 分享获取token链接
 默认值 https://developer.toutiao.com/api/apps/share/default_share_info
 */
@property (nonatomic, copy) NSString *shareDefaultMsgURL;

/**
 分享获取token链接
 默认值 https://developer.toutiao.com/api/apps/share/share_message
 */
@property (nonatomic, copy) NSString *shareMsgURL;

/**
 清除无效分享数据
 默认值 https://developer.toutiao.com/api/apps/share/delete_share_token
 */
@property (nonatomic, copy) NSString *deleteShareDataURL;

/**
 保存授权设置的链接
 default is https://developer.toutiao.com/api/apps/authorization/set
 */
@property (nonatomic, copy) NSString *authorizationSetURL;

/**
 获取手机号api
 默认值 https://developer.toutiao.com/api/apps/user/phonenumber
 */
@property (nonatomic, copy) NSString *getPhoneNumberURL;

/**
 默认值 https://developer.toutiao.com/api/apps/share/query_open_gid
 */
@property (nonatomic, copy) NSString *getShareInfoUrl;

/**
 meta接口里所需的RSA公钥
 */
@property (nonatomic, copy) NSString *appMetaPubKey;

/**
 上报问题日志
 默认值: https://developer.toutiao.com/api/apps/report
 */
@property (nonatomic, copy) NSString *logReportURL;

/**
 查询是否已关注头条号
 默认值https://developer.toutiao.com/api/apps/follow/state
 */
@property (nonatomic, copy) NSString *followStateURL;

/**
 查询小程序绑定的头条号信息
 默认值https://developer.toutiao.com/api/apps/follow/media/get
 */
@property (nonatomic, copy) NSString *followMediaGetURL;

/**
 关注头条号
 默认值https://developer.toutiao.com/api/apps/follow/media/follow
 */
@property (nonatomic, copy) NSString *followMediaFollowURL;

/**
 小程序webview默认可以访问的host白名单
 默认值: developer.toutiao.com
 */
@property (nonatomic, copy) NSArray *defaultWebViewHostWhiteList;

/**
在线时长上报接口
默认值:https://gms-api.bytedance.com/health/v2/update_time
*/
@property (nonatomic, copy) NSString *onlineTimeReportedURL;

/**
实名认证接口
默认值:https://gms-api.bytedance.com//health/v2/update_identity_info
*/
@property (nonatomic, copy) NSString *identityAuthenticationURL;

/**
 客服消息url
 默认值https://developer.toutiao.com/api/apps/im/url/generate
 */
@property (nonatomic, copy) NSString *customerServiceURL;

/**
 小程序Refer
 默认值 https://tmaservice.developer.toutiao.com
*/
@property (nonatomic, copy) NSString* serviceRefererURL;

/**
 定位URL
 默认值 https://developer.toutiao.com/api/apps/location/user
*/
@property (nonatomic, copy) NSString* locationURL;

/**
 CloudStorage
 默认值 https://developer.toutiao.com/api/apps
 */
@property (nonatomic, copy) NSString *openDataBaseURL;

/**
 宿主定制的JSSDK环境变量
*/
@property (nonatomic, copy) NSDictionary *jssdkEnvConfig;

/// 强制开启小程序调试(VConsole)
@property (nonatomic, assign) BOOL forceAppDebugOpen;

/// 调试小程序的AppID(调试小程序禁止打开VConsole)
@property (nonatomic, copy) NSString * debuggerAppID;

@property (nonatomic, assign) BOOL shouldUseNewBridge;

/// JSSDK 下载地址，用于真机调试 initWorker 参数传递
@property (nonatomic, copy) NSString *jssdkDownloadURL;

/// 当前 JSSDK 版本，用于真机调试 initWorker 参数传递
@property (nonatomic, copy) NSString *jssdkVersion;

/// 当前 JSSDK 灰度版本，用于真机调试 initWorker 参数传递
@property (nonatomic, copy) NSString *jssdkGreyHash;

@property (nonatomic, assign) OPRuntimeType debugRuntimeType;

@property (nonatomic, assign) BOOL showDebugWorkerTypeToast;

@property (nonatomic, copy) NSString * _Nullable appLaunchInfoDeleteOldDataDays;

+ (instancetype _Nonnull)sharedConfig;

@end
