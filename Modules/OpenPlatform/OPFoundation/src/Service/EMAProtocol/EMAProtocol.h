//
//  EMAProtocol.h
//  EEMicroAppSDK
//
//  Created by fanlv on 2018/7/3.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <CoreLocation/CoreLocation.h>
#import <ECOProbe/OPMonitorReportPlatform.h>
#import "EMAProtocolDefine.h"
#import <LarkOPInterface/LarkOPInterface-Swift.h>

@class SendMessagecardChooseChatParams;
@class EMASendCardInfo, EMASendCardAditionalTextInfo;
@class AppBadgeNode;
@class PullBadgeRequestParameters, PullAppBadgeNodeResponse;
@class UpdateBadgeRequestParameters, UpdateAppBadgeNodeResponse;

typedef NS_OPTIONS(NSUInteger, EMAShareOptions) {
    EMAShareOptionsNone = 0,
    EMAShareOptionsIOS = 1 << 0,
    EMAShareOptionsAndroid = 1 << 1,
    EMAShareOptionsPC = 1 << 2,
};

typedef NS_ENUM(NSInteger, EMASendMessageCardErrorCode) {
    EMASendMessageCardNoError = 0,
    EMASendMessageCardOpenChatIDsTriggerCodeEmpty = -1,
    EMASendMessageCardOpenChatIDsCountExceed = -2,
    EMASendMessageCardCardContentEmpty = -3,
    EMASendMessageCardCardContentFormatError = -4,
    EMASendMessageCardSendFailed = -5,
    EMASendMessageCardUserCancel = -6,
    EMASendMessageCardOtherError = -7,
    EMASendMessageCardSendTextError = 42406
};

///openURL场景
typedef NS_ENUM(NSUInteger, OpenUrlFromScene)  {
    OpenUrlFromSceneDocument     = 0,
    OpenUrlFromSceneDebugPage    = 1,
    OpenUrlFromSceneAppRunner    = 2,
    OpenUrlFromSceneFileSystem   = 3,
    OpenUrlFromSceneWebView      = 4,
    OpenUrlFromSceneOpenSchemaExternalFalse    = 5,
    OpenUrlFromSceneOpenSchemaExternalTrue     = 6 //!<  openSchema打开并且external参数为true
};

typedef void(^EMAShareResultBlock)(NSDictionary<NSString *, id> *dict, BOOL isCancel);
typedef void(^EMATriggerContextResultBlock)(NSDictionary<NSString *, id> * _Nullable dict);
typedef void(^EMASendMessageCardResultBlock)(EMASendMessageCardErrorCode errCode,
                                             NSString * _Nullable errMsg,
                                             NSArray<NSString *> * _Nullable failedChatIDs,
                                             NSArray<EMASendCardInfo *> * _Nullable sendCardInfos,
                                             NSArray<EMASendCardAditionalTextInfo *> * _Nullable sendTextInfos);
/// Message Action相关的回调定义
typedef void(^EMAGetMessageDetailResultBlock)(NSError * _Nullable error,
                                              NSDictionary<NSString *, id> * _Nullable result);

// 拆分活体相关依赖能力，使得登陆前能使用其能力
@protocol EMALiveFaceProtocol <NSObject>

//开启活体检测
- (void)checkFaceLiveness:(NSDictionary *)params shouldShow:(BOOL(^)())shouldShow block:(void(^)(NSDictionary *, NSDictionary<NSString *, id>*))block;

#pragma mark - offline verify

/// @param callback 结果回调，Error 为 nil 则为成功，否则为失败
- (void)checkOfflineFaceVerifyReady:(void (^ _Nonnull )(NSError * _Nullable error))callback;

/// 加载离线人脸认证环境（模型文件下载）
/// @param callback 结果回调，Error 为 nil 则为成功，否则为失败
- (void)prepareOfflineFaceVerifyWithCallback:(void (^ _Nonnull )(NSError * _Nullable error))callback;

/// 开始离线人脸认证
/// @param callback 结果回调，Error 为 nil 则为成功，否则为失败
- (void)startOfflineFaceVerify:(nonnull NSDictionary *)params callback:(void (^ _Nonnull )(NSError * _Nullable error))callback;

/// 唤起人脸质量检测
/// @param beautyIntensity 美颜参数 0-100
/// @param backCamera 启用后置摄像头
/// @param angleLimit 俯仰角限制
/// @param fromViewController fromViewController
/// @param callback 回调
- (void)startFaceQualityDetectWithBeautyIntensity:(int)beautyIntensity
                                       backCamera:(BOOL)backCamera
                                   faceAngleLimit:(int)angleLimit
                               fromViewController:(UIViewController *_Nullable)fromViewController
                                         callback:(void (^ _Nonnull )(NSError * _Nullable error, UIImage *_Nullable faceImage, NSDictionary *_Nullable result))callback;

#pragma mark -

@end

@protocol EMAProtocol <NSObject>

- (void)regist;

/// 支持 TEA & Slardar 双打的埋点上报
/// @param event event 名称
/// @param params event 打点数据
/// @param option 打点平台 Tea | Slardar
- (void)trackerEvent:(nullable NSString *)event params:(nullable NSDictionary *)params option:(OPMonitorReportPlatform) option;

/**
 分享H5连接给Lark用户
 */
- (void)shareWebUrl:(nullable NSString *)url title:(nullable NSString *)title content:(nullable NSString *)content;

/// 小程序分享消息卡片
- (void)shareCardWithTitle:(nullable NSString *)title
      uniqueID:(nullable BDPUniqueID *)uniqueID
                 imageData:(nullable NSData *)imageData
                       url:(nullable NSString *)url
               appLinkHref:(nullable NSString *)appLinkHref
                   options:(EMAShareOptions)options
                  callback:(nullable EMAShareResultBlock)callback;

/**
 是否可以打开该URL

 @param url URL
 @return BOOL
 */

- (BOOL)canOpenURL:(NSURL *)url fromScene:(OpenUrlFromScene)fromScene;

/**
 打开URL

 @param url URL
 */
- (void)openURL:(NSURL *)url fromScene:(OpenUrlFromScene)fromScene uniqueID:(OPAppUniqueID * _Nullable)uniqueID fromController:(UIViewController * _Nullable)fromController;
/**

 跳转Lark内部WebView

 @param url URL
 @return 是否跳转成功
 */
- (BOOL)openInternalWebView:(NSURL *)url uniqueID:(OPAppUniqueID * _Nullable)uniqueID fromController:(UIViewController * _Nullable)controller;


///  选择附件
/// @param maxSelectedCount 不限制就传Int.MAX
/// @param title 文件选择器标题
/// @param comfirm 文件选择器确认按钮文案
/// @param block block 返回操作结果 字典用的key为（kEMASDKFilePickerName, kEMASDKFilePickerPath)
- (void)filePicker:(NSInteger)maxSelectedCount
       pickerTitle:(NSString *_Nullable)title
     pickerComfirm:(NSString *_Nullable)comfirm
          uniqueID:(OPAppUniqueID * _Nullable)uniqueID
    fromController:(UIViewController * _Nullable)fromController
             block:(void(^ _Nonnull )(BOOL, NSArray<NSDictionary *> * _Nullable))block;

/**
 *  处理QRCode的扫描，如果不能处理返回NO
 */
- (BOOL)handleQRCode:(NSString *)qrCode
            uniqueID:(OPAppUniqueID * _Nullable)uniqueID
      fromController:(UIViewController * _Nullable)fromController;

/// 检查宿主是否启用了全局水印（该值用来体现 Admin 后端的配置）
- (BOOL)checkWatermark;

/// 检查宿主是否显示了全局水印
- (BOOL)hasWatermark;

//打开云空间选择器页面
- (void)docsPickerTitle:(NSString *)title
                 maxNum:(NSInteger)num
                confirm:(NSString *)confirm
               uniqueID:(OPAppUniqueID * _Nullable)uniqueID
         fromController:(UIViewController * _Nullable)fromController
                  block:(void(^)(NSDictionary *dict, BOOL isCancel))block;

//开启密码二次验证
- (void)passwordVerifyForUniqueID:(BDPUniqueID * _Nullable)uniqueID block:(void(^)(NSDictionary<NSString *, id> *dict))block;

//打开回话选择页面
- (void)chooseChat:(NSDictionary<NSString *, id> *)params
             title:(NSString *)title
        selectType:(NSInteger)type
          uniqueID:(OPAppUniqueID * _Nullable)uniqueID
    fromController:(UIViewController * _Nullable)controller
             block:(void(^)(NSDictionary<NSString *, id> *dict, BOOL isCancel))block;

- (NSDictionary *)getChatInfo:(NSString *)chatId;

- (void)getAtInfo:(NSString *)chatId block:(void (^)(NSDictionary *dict))block;

- (void)onBadgeChange:(NSString *)chatId block:(void(^)(NSDictionary<NSString *, id> *dict))block;

- (void)offBadgeChange:(NSString *)chatId;

/**
 通过uniqueID打开小程序关于页面

 @param uniqueID 小程序ID
 @param appVersion 小程序版本号
 */
- (void)openAboutVCWithUniqueID:(BDPUniqueID *_Nullable )uniqueID appVersion:(NSString * _Nonnull)appVersion;

- (void)openMineAboutVCWithUniqueID:(OPAppUniqueID * _Nullable)uniqueID fromController:(UIViewController * _Nullable)controller;

/**
 宿主app名 用于判断是Feishu还是Lark

 @return 宿主app名
 */
- (NSString *)appName;

/**
 KA 获取用户信息
 */
- (void)getUserInfoExSuccess:(void (^)(NSDictionary<NSString *, id> *info))success fail:(dispatch_block_t)fail;

/// 获取TriggerContext
/// @param triggerCode 进入小程序的来源标志
/// @param block 回调方法
- (void)getTriggerContextWithTriggerCode:(NSString * _Nonnull)triggerCode
                                   block:(_Nullable EMATriggerContextResultBlock)block;

/// 发送消息卡片
/// @param uniqueID 小程序的uniqueID
/// @param scene 小程序场景值
/// @param triggerCode 进入小程序的来源标志
/// @param chatIDs 会话的ChatID
/// @param cardContent 卡片的json数据
/// @param block 回调方法
- (void)sendMessageCardWithUniqueID:(BDPUniqueID *_Nullable)uniqueID
                           scene:(NSString * _Nonnull)scene
                     triggerCode:(NSString * _Nullable)triggerCode
                         chatIDs:(NSArray<NSString *> * _Nullable)chatIDs
                     cardContent:(NSDictionary * _Nonnull)cardContent
                     withMessage:(BOOL)withMessage
                           block:(_Nullable EMASendMessageCardResultBlock)block;
/// 选择会话+发送消息卡片
/// @param uniqueID 唯一标志符
/// @param cardContent 卡片json
/// @param params 选人的参数model
/// @param res 回调
- (void)chooseSendCardWithUniqueID:(OPAppUniqueID * _Nullable)uniqueID
                       cardContent:(NSDictionary * _Nonnull)cardContent
                       withMessage:(BOOL)withMessage
                            params:(SendMessagecardChooseChatParams * _Nonnull)params
                               res:(nonnull EMASendMessageCardResultBlock)res;

/// 埋点代理出去
/// @param service 埋点名称
/// @param metrics 埋点 metrics 数据
/// @param categories 埋点 categories 数据
/// @param platform  埋点上传到的平台
- (void)monitorService:(NSString * _Nonnull)service
           metricsData:(NSDictionary * _Nonnull)metricsData
        categoriesData:(NSDictionary * _Nonnull)categoriesData
              platform:(OPMonitorReportPlatform)platform;

- (void)setHMDInjectedInfoWith:(NSNotification *)notification
         localLibVersionString:(NSString *)localLibVersionString;
- (void)removeHMDInjectedInfo;

/// 返回宿主的deviceID
- (NSString * _Nonnull)hostDeviceID;

//protocol
- (id _Nullable)getExperimentValueForKey:(NSString * _Nonnull)key
                            withExposure:(BOOL)withExposure;

/// 启动应用badgePush数据变化的监听
- (void)onServerBadgePush:(NSString * _Nonnull)appId
                subAppIds:(NSArray<NSString *> * _Nonnull)subAppIds
               completion:(void (^ _Nonnull)(AppBadgeNode * _Nonnull result))completion;

/// 关闭应用badgePush数据变化的监听
- (void)offServerBadgePush:(NSString * _Nonnull)appId
                 subAppIds:(NSArray<NSString *> * _Nonnull)subAppIds;

/// 调用Rust updateAppBadge API，用于更新badgeNum/needShow
- (void)updateAppBadge:(NSString *)appID appType:(AppBadgeAppType)appType extra:(UpdateBadgeRequestParameters *)extra completion:(void (^ _Nonnull)(UpdateAppBadgeNodeResponse * _Nullable result, NSError * _Nullable error))completion;

/// 调用Rust updateAppBadge API，用于更新badgeNum
- (void)updateAppBadge:(NSString *)appID appType:(BDPType)appType badgeNum:(NSInteger)badgeNum completion:(void (^ _Nonnull)(UpdateAppBadgeNodeResponse * _Nullable result, NSError * _Nullable error))completion;

/// 调用Rust pullAppBadge  API
- (void)pullAppBadge:(NSString *)appID appType:(AppBadgeAppType)appType extra:(PullBadgeRequestParameters *)extra completion:(void (^ _Nonnull)(PullAppBadgeNodeResponse * _Nullable result, NSError * _Nullable error))completion;

- (void)openSDKPreview:(NSString *)fileName fileUrl:(NSURL *)fileUrl fileType:(NSString *)fileType fileID:(NSString *)fileID showMore:(BOOL)showMore from:(UIViewController *)from thirdPartyAppID:(NSString *)thirdPartyAppID padFullScreen:(BOOL)padFullScreen;

/// 调用社交分享功能
- (void)snsShare:(UIViewController *)controller appID:(NSString *)appID channel:(NSString *)channel contentType:(NSString *)contentType traceId:(NSString *)traceId title:(NSString *)title url:(NSString *)url desc:(NSString *)desc  imageData:(NSData *)imageData successHandler:(void (^ _Nonnull)())successHandler failedHandler:(void (^ _Nonnull)(NSError * _Nullable error))failedHandler;

// 注入的js worker 解释器
- (nullable NSDictionary *)registerWorkerInterpreters;
@end
