//
//  BDUGWeChatShare.h
//  Article
//
//  Created by 王霖 on 15/9/21.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGWechatShareErrorDomain;

@class BDUGWeChatShare;
@class PayResp;
@class BaseReq;

typedef NS_ENUM(NSUInteger, BDUGWechatShareScene) {
    BDUGWechatShareSceneSession          = 0,   /**< 聊天界面    */
    BDUGWechatShareSceneTimeline         = 1,   /**< 朋友圈     */
    BDUGWechatShareSceneFavorite         = 2,   /**< 收藏       */
    BDUGWechatShareSceneSpecifiedSession = 3,   /**< 指定联系人  */
};

@protocol BDUGWechatShareDelegate <NSObject>

@optional
/**
 *  微信分享回调
 *
 *  @param weChatShare BDUGWeChatShare实例
 *  @param error 分享错误
 *  @param customCallbackUserInfo 用户自定义的分享回调信息
 */
- (void)weChatShare:(BDUGWeChatShare * _Nullable)weChatShare sharedWithError:(NSError * _Nullable)error customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;
@end

@protocol BDUGWechatSharePayDelegate <NSObject>

@optional
/**
 *  微信支付回调
 *
 *  @param weChatShare BDUGWeChatShare实例
 *  @param payResponse 微信支付Response
 */
- (void)weChatShare:(BDUGWeChatShare *)weChatShare payResponse:(PayResp * _Nullable)payResponse;
@end

@protocol BDUGWechatShareRequestDelegate <NSObject>

@optional
/**
 *  来自微信请求
 *
 *  @param weChatShare BDUGWeChatShare实例
 *  @param request 微信请求体
 */
- (void)weChatShare:(BDUGWeChatShare *)weChatShare receiveRequest:(BaseReq * _Nullable)request;
@end

@interface BDUGWeChatShare : NSObject

@property(nonatomic, weak, nullable) id<BDUGWechatShareDelegate> delegate;
@property(nonatomic, weak, nullable) id<BDUGWechatSharePayDelegate> payDelegate;
@property(nonatomic, weak, nullable) id<BDUGWechatShareRequestDelegate> requestDelegate;

/**
 *  微信分享单例
 *
 *  @return 微信分享单例
 */
+ (instancetype)sharedWeChatShare;

/*! @brief WXApi的成员函数，向微信终端程序注册第三方应用。
 *
 *  需要在每次启动第三方应用程序时调用。第一次调用后，会在微信的可用应用列表中出现。 iOS7及以上系统需要调起一次微信才会出现在微信的可用应用列表中。
 *  @Attention: 请保证在主线程中调用此函数
 *
 *  @param appID 微信开发者ID
 */
+ (void)registerWithID:(NSString*)appID universalLink:(NSString *)universalLink;


//+ (void)registerWxxcxID:(NSString *)wxxcxID;
//+ (void)registerWxxcxPath:(NSString *)wxxcxPath;

/**
 *  微信是否可用
 *
 *  @return 微信是否可用。没有安装微信或者当前版本微信不支持OpenApi，则返回NO。
 */
- (BOOL)isAvailable;

/**
 *  微信SDK版本
 *
 *  @return 当前微信SDK版本
 */
- (NSString *)currentVersion;

/**
 *  invoke in AppDelegate application:openURL:sourceApplication:annotation:
 *  如果返回YES， 其他应用就不要在handle了
 */
+ (BOOL)handleOpenURL:(NSURL *)url;

+ (BOOL)handleOpenUniversalLink:(NSUserActivity *)userActivity;

/**
 *  打开微信
 *
 *  @return 是否成功打开
 */
+ (BOOL)openWechat;

/**
 *  发送文本消息到微信
 *
 *  @param scene 发送场景
 *  @param text 发送的文本（文本长度必须小于10k。如果超过，内部会二分截断）
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendTextToScene:(BDUGWechatShareScene)scene withText:(NSString *)text customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

/**
 *  发送图片到微信
 *
 *  @param scene 发送场景
 *  @param image 图片
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendImageToScene:(BDUGWechatShareScene)scene withImage:(UIImage*)image customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

- (void)sendWebpageToScene:(BDUGWechatShareScene)scene withWebpageURL:(NSString *)webpageURL thumbnailImage:(UIImage * _Nullable)thumbnailImage title:(NSString * _Nullable)title description:(NSString * _Nullable)description customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

/**
 *  向微信发送web page多媒体消息
 *
 *  @paramm scene 发送场景
 *  @param webpageURL web page url
 *  @param thumbnailImage 缩略图
 *  @param imageURLString 缩略图URL
 *  @param title 标题（不能超过512字节。如果超过，内部会二分截断）
 *  @param description 摘要（不能超过1k。如果超过，内部会二分截断）
 *  @param customCallbackUserInfo 分享回调透传
 */ 
- (void)sendWebpageToScene:(BDUGWechatShareScene)scene withWebpageURL:(NSString *)webpageURL thumbnailImage:(UIImage * _Nullable)thumbnailImage imageURL:(NSString * _Nullable)imageURLString title:(NSString * _Nullable)title description:(NSString * _Nullable)description customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

/**
 *  向微信发送带有视频数据对象的消息
 *
 *  @paramm scene 发送场景
 *  @param videoURL 视频网页的URL（不超过10k）
 *  @param thumbnailImage 缩略图
 *  @param title 标题（不超过512字节。如果超过，内部会二分截断）
 *  @param description 摘要（不超过1K。如果超过，内部会二分截断）
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendVideoToScene:(BDUGWechatShareScene)scene withVideoURL:(NSString *)videoURL thumbnailImage:(UIImage * _Nullable)thumbnailImage title:(NSString * _Nullable)title description:(NSString * _Nullable)description customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

/**
 分享小程序到微信

 @param scene 发送场景
 @param thumbnailImage 缩略图
 @param title 标题，512字节
 @param description 摘要，1k
 @param miniProgramUserName 小程序原始ID
 @param path 小程序path
 @param webPageURLString 针对旧版本的优化。
 */
- (void)sendMiniProgramToScene:(BDUGWechatShareScene)scene thumbnailImage:(UIImage * _Nullable)thumbnailImage title:(NSString * _Nullable)title description:(NSString * _Nullable)description miniProgramUserName:(NSString *)miniProgramUserName miniProgramPath:(NSString * _Nullable)path webPageURLString:(NSString * _Nullable)webPageURLString launchMiniProgram:(BOOL)launchMiniProgram;

/**
 分享文件到微信

 @param title 文件名，必须包含后缀
 @param fileURL 文件路径，必须是本地路径
 @param thumbImage 缩略图
 */
- (void)sendFileWithFileName:(NSString * _Nullable)title fileURL:(NSURL *)fileURL thumbImage:(UIImage * _Nullable)thumbImage;

@end

NS_ASSUME_NONNULL_END
