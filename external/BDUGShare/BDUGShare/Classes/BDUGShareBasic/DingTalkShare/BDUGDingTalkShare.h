//
//  BDUGDingTalkShare.h
//  Article
//
//  Created by 朱斌 on 16/8/22.
//
//

#import <Foundation/Foundation.h>
#import <DTShareKit/DTOpenKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGDingTalkShareErrorDomain;

@class BDUGDingTalkShare;

@protocol BDUGDingTalkShareDelegate <NSObject>

@optional
/**
 *  钉钉分享回调
 *
 *  @param dingTalkShare  BDUGDingTalkShare实例
 *  @param error 分享错误
 *  @param customCallbackUserInfo 用户自定义的分享回调信息
 */
- (void)dingTalkShare:(BDUGDingTalkShare * _Nullable)dingTalkShare sharedWithError:(NSError * _Nullable)error customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

@end

@protocol BDUGDingTalkShareRequestDelegate <NSObject>

@optional

/**
 *  来自钉钉请求
 *
 *  @param dingTalkShare  BDUGDingTalkShare实例
 *  @param request 钉钉请求体
 */
- (void)dingTalkShare:(BDUGDingTalkShare *)dingTalkShare receiveRequest:(DTBaseReq * _Nullable)request;

@end

@interface BDUGDingTalkShare : NSObject

@property (nonatomic, weak, nullable) id<BDUGDingTalkShareDelegate> delegate;
@property (nonatomic, weak, nullable) id<BDUGDingTalkShareRequestDelegate> requestDelegate;

/**
 *  钉钉分享单例
 *  @return 钉钉分享单例
 */
+ (instancetype)sharedDingTalkShare;

/**
 *  第三方APP向钉钉注册申请的appId
 *  第三方应用程序需要在程序启动时调用
 *  @note 请在主线程中调用此方法
 *  @param appID 在钉钉开放平台申请的应用ID
 */
+ (void)registerWithID:(NSString *)appID;

/**
 *  钉钉是否可用
 *
 *  @return 钉钉是否可用。没有安装钉钉或者当前版本钉钉不支持OpenApi，则返回NO。
 */
- (BOOL)isAvailable;

/**
 *  invoke in AppDelegate application:openURL:sourceApplication:annotation:
 *  如果返回YES， 其他应用就不要在handle了
 */
+ (BOOL)handleOpenURL:(NSURL *)url;

/**
 打开钉钉客户端.
 
 @return YES 成功打开钉钉客户端. NO 未能打开钉钉客户端.
 */
+ (BOOL)openDingTalk;

/**
 * 向钉钉发送文本
 *
 *  @param scene 发送场景
 *  @param text 发送的文本(不超过1k。如果超过，内部会二分截断)
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendTextToScene:(DTScene)scene withText:(NSString *)text customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

/**
 * 向钉钉发送图片
 *
 *  @param scene 发送场景
 *  @param image 图片
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendImageToScene:(DTScene)scene withImage:(UIImage *)image customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

/**
 * 以URL的方式向钉钉发送图片
 *
 *  @param scene 发送场景
 *  @param imageURL 图片的URL(不超过10k)
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendImageToScene:(DTScene)scene withImageURL:(NSString *)imageURL customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

/**
 *  向钉钉发送web page多媒体消息
 *
 *  @paramm scene 发送场景
 *  @param webpageURL web page url（不超过10k）
 *  @param thumbnailImage 缩略图（不超过32k）
 *  @param thumbnailImageURL 缩略图url（不超过10k）
 *  @param title 标题（不能超过512字节。如果超过，内部会二分截断）
 *  @param description 摘要（不能超过1k。如果超过，内部会二分截断）
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendWebpageToScene:(DTScene)scene withWebpageURL:(NSString *)webpageURL thumbnailImage:(UIImage * _Nullable)thumbnailImage thumbnailImageURL:(NSString * _Nullable)thumbnailImageURL title:(NSString * _Nullable)title description:(NSString * _Nullable)description customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

@end

NS_ASSUME_NONNULL_END
