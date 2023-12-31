//
//  BDUGShareManager.h
//  Pods
//
//  Created by 延晋 张 on 16/6/1.
//
//  不使用默认展示样式的

/*
 文档地址:https://doc.bytedance.net/docs/359/536/22676/
 */

#import <Foundation/Foundation.h>
#import "BDUGActivityProtocol.h"
#import "BDUGActivityPanelControllerProtocol.h"
#import "BDUGShareActivityDataModel.h"
#import "BDUGShareBaseContentItem.h"
#import "BDUGActivityContentItemProtocol.h"
#import "BDUGShareAbilityProtocol.h"
#import "BDUGSharePanelContent.h"
#import "BDUGShareConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kBDUGShareKitchenConfigKey;

//服务端下发的分享类型。contentItem.serverDataModel.method
extern NSString* const kBDUGShareMethodServerStringDefault;
extern NSString* const kBDUGShareMethodServerStringSystem;
extern NSString* const kBDUGShareMethodServerStringToken;
extern NSString* const kBDUGShareMethodServerStringImage;
extern NSString* const kBDUGShareMethodServerStringVideo;

//服务端下发的渠道字段。contentItem.serverDataModel.channel
extern NSString* const kBDUGSharePlatformServerStringQQ;
extern NSString* const kBDUGSharePlatformServerStringQQZone;
extern NSString* const kBDUGSharePlatformServerStringWechat;
extern NSString* const kBDUGSharePlatformServerStringTimeline;
extern NSString* const kBDUGSharePlatformServerStringSystem;
extern NSString* const kBDUGSharePlatformServerStringSMS;
extern NSString* const kBDUGSharePlatformServerStringCopyLink;
extern NSString* const kBDUGSharePlatformServerStringDingtalk;
extern NSString* const kBDUGSharePlatformServerStringAweme;
extern NSString* const kBDUGSharePlatformServerStringWeibo;
extern NSString* const kBDUGSharePlatformServerStringFacebook;
extern NSString* const kBDUGSharePlatformServerStringWhatsApp;
extern NSString* const kBDUGSharePlatformServerStringMessenger;
extern NSString* const kBDUGSharePlatformServerStringInstagram;
extern NSString* const kBDUGSharePlatformServerStringTiktok;
extern NSString* const kBDUGSharePlatformServerStringTwitter;
extern NSString* const kBDUGSharePlatformServerStringLine;
extern NSString* const kBDUGSharePlatformServerStringSnapChat;
extern NSString* const kBDUGSharePlatformServerStringKakaoTalk;
extern NSString* const kBDUGSharePlatformServerStringRocket;
extern NSString* const kBDUGSharePlatformServerStringMaya;
extern NSString* const kBDUGSharePlatformServerStringToutiao;
extern NSString* const kBDUGSharePlatformServerStringFeishu;
extern NSString* const kBDUGSharePlatformServerStringLongImage;

@class BDUGShareManager;
@class BDUGShareInitializeModel;

@protocol BDUGShareManagerDataSource <NSObject>

@optional

/// 修改面板渠道，面板展示前调用
/// @param array current contentItem array
/// @param panelContent display时传入的panelContent
- (NSArray *)resetPanelItems:(NSArray *)array panelContent:(BDUGSharePanelContent *)panelContent;

/// 重设渠道数据，渠道点击后，请求分享数据前调用
/// @param contentItem 渠道contentItem
- (void)resetContentItemOriginalData:(BDUGShareBaseContentItem *)contentItem;

/// 重设服务端数据，渠道点击后，请求分享数据成功后调用
/// @param contentItem 渠道contentItem
- (void)resetContentItemServerData:(BDUGShareBaseContentItem *)contentItem;

#pragma mark - 下列回调在1x版本中使用，已被废弃，请参照文档使用新版回调。

/**
 获取分享所需的某人数据

 @param panelId 面板ID
 @return origin数据model
 */
- (BDUGShareActivityOriginDataModel *)originModelWithPanelId:(NSString *)panelId;

/**
 业务方根据自己的需求处理不同平台的分享数据。 SDK支持的分享平台。
 @param contentItem contentItem
 */
- (void)shareContentItemProcess:(BDUGShareBaseContentItem *)contentItem;

/**
 业务方根据自己的需求重新排序。

 @param array 二维数组，第一行为默认数组，第二行为custom数组。已经过UG策略排好序。
 @return 业务方根据自己的需求重新排序。
 */
- (NSArray *)resortContentItemOrderWithCurrentArray:(NSArray *)array;

@end

@protocol BDUGShareManagerDelegate <NSObject>

@optional

#pragma mark - callback

/**
 面板上的点击事件

 @param shareManager shareManager实例
 @param activity activity实例
 @param panelController 面板实例
 */
- (void)shareManager:(BDUGShareManager *)shareManager
        clickedWith:(id<BDUGActivityProtocol>)activity
          sharePanel:(id<BDUGActivityPanelControllerProtocol> _Nullable)panelController;


/**
 分享取消回调

 @param shareManager 实例
 @param panelController panel实例
 */
- (void)shareManager:(BDUGShareManager *)shareManager
    sharePanelCancel:(id<BDUGActivityPanelControllerProtocol> _Nullable)panelController;

/**
 分享数据请求完毕，即将开始分享行为。如果不实现改回调默认直接进行下一步，如果实现改回调必须手动调用continueBlock。
 
 @param shareManager 实例
 @param activity activity实例
 @param itemModel 服务端数据model
 @param continueBlock 继续进行分享action的block
 */
- (void)shareManager:(BDUGShareManager *)shareManager
   willShareActivity:(id <BDUGActivityProtocol>)activity
      serverDataitem:(BDUGShareDataItemModel * _Nullable)itemModel
       continueBlock:(void(^)(void))continueBlock;

/**
 分享结束回调

 @param shareManager shareManager实例
 @param activity activity实例
 @param panelController 面板实例
 @param error 错误信息
 @param desc 错误描述
 */
- (void)shareManager:(BDUGShareManager *)shareManager
       completedWith:(id<BDUGActivityProtocol>)activity
          sharePanel:(id<BDUGActivityPanelControllerProtocol> _Nullable)panelController
               error:(NSError * _Nullable)error
                desc:(NSString * _Nullable)desc;



/**
 口令弹窗展示回调

 @param shareManager shareManager回调
 @param activity activity回调
 */
- (void)shareManager:(BDUGShareManager *)shareManager
tokenShareDialogDidShowWith:(id<BDUGActivityProtocol>)activity;

@end

@interface BDUGShareManager : NSObject

@property (nonatomic, weak) id<BDUGShareManagerDelegate> _Nullable delegate;
@property (nonatomic, weak) id<BDUGShareManagerDataSource> _Nullable dataSource;
@property (nonatomic, weak) id<BDUGShareAbilityProtocol> _Nullable abilityDelegate;

/* 使用本库展示并分享，三步曲：
 1、注册外部自定义分享类型Activities，不额外注册，就是仅使用本库支持分享类型
 2、调用展示方法，传入分享内容，交给本库完成展示和后续分享
 */

/*!
 *  @brief 添加自定义的Activities
 *
 *  @param activities 添加自定义的Activities,符合BDUGActivityProtocol协议的对象
 */
+ (void)addUserDefinedActivitiesFromArray:(NSArray *)activities;

+ (void)addUserDefinedActivity:(id <BDUGActivityProtocol>)activity;

/**
 初始化SDK
 */
+ (void)initializeShareSDK;

+ (void)initializeShareSDKWithConfiguration:(BDUGShareConfiguration *)configuration;

#pragma mark - 2.0 display

- (void)displayPanelWithContent:(BDUGSharePanelContent *)panelContent;

#pragma mark - single platform

- (void)beginRequestShareDataWithPanelContent:(BDUGSharePanelContent *)panelContent;

- (void)shareToContent:(BDUGSharePanelContent *)panelContent presentingViewController:(UIViewController *)presentingViewController;

#pragma mark - cancel share process

+ (void)cancelShareProcess;

#pragma mark - panel

/**
 设置面板类

 @param panelClassName 面板类名
 */
- (void)setPanelClassName:(NSString *)panelClassName;

/**
 面板隐藏
 */
- (void)hideSharePanel;

#pragma mark - tricky

+ (void)configInitlizeDataWithItemModel:(BDUGShareInitializeModel *)model;

#pragma mark - clean request cache

- (void)cleanSequenceCache;

- (void)cleanShareInfoCache;

#pragma mark - 以下接口已被废弃，请使用最新版API。

/**
 @param contentItemArray 自定义的contentItem数组。即调用addUserDefinedActivity注册的activity对应的contentItem
 @param panelId 面板ID
 @param panelClassName 如果自定义了面板，传入面板类名。
 */
- (void)displayActivitySheetWithContentItemArray:(NSArray <id<BDUGActivityContentItemProtocol>> *)contentItemArray panelId:(NSString *)panelId panelClassName:(NSString *)panelClassName __attribute__((deprecated("Deprecated, use 'displayPanelWithContent:' instead")));

/**
 @param contentItem 外露平台的contentItem实例
 @param presentingViewController 当前VC，用于弹出分享面板。
 @param panelId 面板ID
*/
- (void)shareToActivity:(id <BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController panelId:(NSString *)panelId __attribute__((deprecated("Deprecated, use 'shareToContent:presentingViewController' instead")));

@end

NS_ASSUME_NONNULL_END
