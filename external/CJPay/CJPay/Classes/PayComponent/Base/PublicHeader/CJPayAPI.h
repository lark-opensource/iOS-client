//
//  CJPayAPI.h
//  CJPay
//
//  Created by wangxinhua on 2020/7/16.
//

#import <Foundation/Foundation.h>
#import "CJPayLocalizedPlugin.h"
#import "CJBizWebDelegate.h"
#import "CJMetaSecDelegate.h"
#import "CJPaySDKDefine.h"

NS_ASSUME_NONNULL_BEGIN

/// 支付SDK 基础信息配置Model
@interface CJPayAppInfo: NSObject

@property (nonatomic, copy) NSString * appName;  // App的名称，示例：头条
@property (nonatomic, copy) NSString * appID;    // App的应用id，示例：头条
@property (nonatomic, copy) NSString *(^deviceIDBlock)(void);  // deviceID的信息。因为DeviceID可能是异步生成，所以通过Block传递
@property (nonatomic, copy) NSString *(^userIDBlock)(void);// userID信息
@property (nonatomic, copy) NSString *(^userNicknameBlock)(void); // 登录用户昵称
@property (nonatomic, copy) NSString *(^userPhoneNumberBlock)(void); // 用户绑卡的手机号
@property (nonatomic, copy) NSString *(^accessTokenBlock)(void);  // // SaaS容器内支付账户信息
@property (nonatomic, copy) NSURL *(^userAvatarBlock)(void); // 登录用户头像
@property (nonatomic, copy) NSDictionary *(^infoConfigBlock)(void);  // 登录用户态信息，对应KV格式： @{@"userId" : 登录id, @"shopId": 店铺id }
@property (nonatomic, copy) NSDictionary *(^reskInfoBlock)(void);  // 风控参数信息。version_code， user_agent， iid，app_name，😶该名称历史原因拼写错误😶
@property (nonatomic, copy, nullable) NSString *wxH5PayRefer; // 微信H5支付的refer，用来在支付完成后回跳App，配置参考：

@property (nonatomic, copy) NSString *wxUniversalLink;    // 微信SDK支付，需要传入wxUniveralLink才能打开拉起SDK进行支付

@property (nonatomic, copy) NSString *secLinkDomain;   // seclinkDomain，国内App配置成功https://link.wtturl.cn/
@property (nonatomic, copy, nullable) NSString * _Nullable (^transferSecLinkSceneBlock)(NSDictionary * _Nullable fromDic); // 与seclinkDomain配套使用，主要是根据URL中的参数抓换成App在Seclink中配置的场景类型。

@property (nonatomic, assign) BOOL adapterIpadStyle;  // 是否适配iPad场景，默认为NO。
@property (nonatomic, assign) BOOL enableSaasEnv;  // 是否适配SaaS场景，默认为NO。

// TODO: 确认是否放在这里进行配置比较合适
//@property (nonatomic, copy) NSString *themeMode;    // 可选值： light  or   dark。 支付SDK主题色模式，默认是light模式
//@property (nonatomic, weak) id<CJBizWebDelegate> delegate; // 支付对宿主的依赖，在SDK需要登录或者使用宿主Router打开scheme时会通过该delegate进行调用


@end

@interface CJPayAPI : NSObject

//初始化方法注册，不耗时，需要业务方在较早的时机调用
+ (void)registerInitClass:(Class<CJPayInitDelegate>)initClass;
// 注册SDK需要的基本信息
+ (void)registerAppInfo:(CJPayAppInfo *)appInfo;
// 注册SDK的代理，SDK会在需要登录或者需要使用宿主路由打开页面时进行回调
+ (void)registerDelegate:(id<CJBizWebDelegate>) delegate;
+ (void)registerMetaSecDelegate:(id<CJMetaSecDelegate>) delegate;
// 是否使用Gecko的请求合并策略。
+ (void)enableMergeGeckoRequest:(BOOL)enable;
// 同步离线包资源。⚠️该方法会有js资源的下发，有可能会影响App审核，业务可以在审核期间不进行同步。 不同步不会影响SDK主流程的功能。
+ (void)syncOfflineWith:(NSString *)appid;
// 切到消息tab时触发
+ (void)syncResourcesWhenSelectNotify;
// 切到我的tab时触发
+ (void)syncResourcesWhenSelectHomepage;
// 配置SDK的域名。默认域名为https://tp-pay.snssdk.com
+ (void)configHost:(NSString *)hostString;
// 设置字体放大倍数。主要适用于适老化
+ (void)setupFontScale:(CGFloat)fontScale;

// 设置主题模式，浅色/深色/默认
+ (void)setTheme:(NSString *)theme;
// 设置语言
+ (void)setupLanguage:(CJPayLocalizationLanguage)language;

// url处理
+ (BOOL)canProcessURL:(NSURL *)url;
// 微信SDK支付，需要在AppDelegate的`application:continueUserActivity:restorationHandler:`方法中，调用该方法来处理微信支付的结果。
+ (BOOL)canProcessUserActivity:(NSUserActivity *)userActivity;

// 打开标准支付收银台。展示样式示例：飞书发红包收银台。
+ (void)openPayDeskWithConfig:(nullable NSDictionary<CJPayPropertyKey, id> *)configDic orderParams:(NSDictionary *) params withDelegate:(nullable id<CJPayAPIDelegate>)delegate;

// 打开H5支付收银台。
+ (void)openH5PayDeskWithConfig:(nullable NSDictionary<CJPayPropertyKey, id> *)configDic orderURL:(NSString *)url withDelegate:(nullable id<CJPayAPIDelegate>)delegate;

// 打开极速支付收银台。
+ (void)openFastPayDeskWithConfig:(nullable NSDictionary<CJPayPropertyKey, id> *)configDic orderParams:(NSDictionary *)params withDelegate:(id<CJPayAPIDelegate>)delegate;

// 三方收银台
+ (void)openBDPayDeskWithConfig:(nullable NSDictionary<CJPayPropertyKey, id> *)configDic orderParams:(NSDictionary *)params delegate:(nonnull id<CJPayAPIDelegate>)delegate;

// 提现收银台
+ (void)openWithdrawDeskWithConfig:(nullable NSDictionary<CJPayPropertyKey, id> *)configDic orderURL:(NSString *)url  withDelegate:(nullable id<CJPayAPIDelegate>)delegate;

// 打开银行卡列表
+ (void)openBankCardListWithMerchantId:(NSString *)merchantId appId:(NSString *)appId userId:(NSString *)userId;

// 发起支付账户授权
+ (void)requestAuth:(NSDictionary *)params withDelegate:(nullable id<CJPayAPIDelegate>)delegate;

// 通过路由方式打开SDK页面, scheme示例:  sslocal://cjpay/XXX?XXX=XXX
+ (void)openScheme:(NSString *)scheme withDelegate:(nullable id<CJPayAPIDelegate>)delegate;
+ (void)openWithConfig:(nullable NSDictionary<CJPayPropertyKey, id> *)configDic scheme:(NSString *)scheme withDelegate:(nullable id<CJPayAPIDelegate>)delegate;
+ (void)openScheme:(NSString *)scheme callBack:(nullable void(^)(CJPayAPIBaseResponse *))callback;

// 设置密码，目前需要channel_order_info、appID、merchantID
+ (void)openSetPasswordDeskWithParams:(NSDictionary *)params withDelegate:(id<CJPayAPIDelegate>)delegate;

// 端外通过宿主App拉起支付收银台
+ (void)openBytePayDeskWithSchemaParams:(NSDictionary *)schemaParams withDelegate:(nonnull id<CJPayAPIDelegate>)delegate;

// 端外通过宿主App拉起支付收银台前，预先请求创建订单接口
+ (void)requestCreateOrderBeforeOpenBytePayDesk:(NSDictionary *)schemaParams;

/// 拉起电商支付收银台
/// @param params 拉起电商收银台的参数，由后端返回，透传即可
/// @param delegate 回调代理，包含收银台支付结果的回调
+ (void)openEcommercePayDeskWithParams:(NSDictionary *)params
                          withDelegate:(id<CJPayAPIDelegate>)delegate;

// 打开余额提现页面
+ (void)openBalanceWithdrawDeskWithParams:(NSDictionary *)params withDelegate:(id<CJPayAPIDelegate>)delegate;
// 打开余额充值页面
+ (void)openBalanceRechargeDeskWithParams:(NSDictionary *)params withDelegate:(id<CJPayAPIDelegate>)delegate;
// 打开签约页面
+ (void)openUniteSign:(NSDictionary *)params withDelegate:(id<CJPayAPIDelegate>)delegate;

// 打开收银台，参数需要遵循ttpay-bridge规范 文档地址：https://bytedance.feishu.cn/docs/doccnXLrYkw7BBnxiIuXpQ5bFE3#
+ (void)openUniversalPayDeskWithParams:(NSDictionary *)params withDelegate:(nonnull id<CJPayAPIDelegate>)delegate;

+ (void)openPayUpgradeWithParams:(NSDictionary *)params withDelegate:(nonnull id<CJPayAPIDelegate>)delegate;

+ (void)getWalletUrlWithParams:(NSDictionary *)params completion:(void (^)(NSString * _Nonnull walletUrl))completionBlock;

// 获取API的版本
+ (NSString *)getAPIVersion;

+ (void)lazyInitCJPay;

@end


/// 该API会逐步进行废弃。
@interface CJPayAPI(Deprecated)

// 打开支付管理页面
+ (void)openPayManagerWithAppId:(NSString *)appId merchantId:(NSString *)merchantId DEPRECATED_MSG_ATTRIBUTE("Use `openScheme:WithDelegate` instead");

// 打开交易记录页面
+ (void)openTradeRecordWithAppId:(NSString *)appId merchantId:(NSString *)merchantId DEPRECATED_MSG_ATTRIBUTE("Use `openScheme:WithDelegate` instead");

@end

NS_ASSUME_NONNULL_END

