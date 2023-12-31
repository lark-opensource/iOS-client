//
//  BDUGAliShare.h
//  Article
//
//  Created by Huaqing Luo on 27/8/15.
//
//

#import <Foundation/Foundation.h>
#import <BDAlipayShareSDK/APOpenAPI.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGAliShareErrorDomain;

@class BDUGAliShare;

@protocol TTAliShareDelegate <NSObject>

@optional
/**
 *  支付宝消息发送完成回调
 *
 *  @param aliShare BDUGAliShare实例
 *  @param error 分享错误
 *  @param customCallbackUserInfo 用户自定义的分享回调信息
 */
- (void)aliShare:(BDUGAliShare * _Nullable)aliShare sharedWithError:(NSError * _Nullable)error customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

@end

@protocol TTAliShareRequestDelegate <NSObject>

@optional
/**
 *  来自支付宝请求
 *
 *  @param aliShare BDUGAliShare实例
 *  @param request 支付宝请求体
 */
- (void)aliShare:(BDUGAliShare * _Nullable)aliShare receiveRequest:(APBaseReq * _Nullable)request;

@end

@interface BDUGAliShare : NSObject

@property(nonatomic, weak, nullable) id<TTAliShareDelegate> delegate;
@property(nonatomic, weak, nullable) id<TTAliShareRequestDelegate> requestDelegate;

/**
 *  阿里分享实例
 */
+ (instancetype)sharedAliShare;

/*! @brief 向支付宝终端程序注册第三方应用。
 *
 * 需要在每次启动第三方应用程序时调用。第一次调用后，会在支付宝的可用应用列表中出现。
 * iOS7及以上系统需要调起一次支付宝才会出现在支付宝的可用应用列表中。
 * @attention 请保证在主线程中调用此函数
 * @param appID 支付宝开发者ID
 */
+ (void)registerWithID:(NSString*)appID;

/**
 *  支付宝是否可用
 *
 *  @return 支付宝是否可用。没有安装支付宝或者当前版本支付宝不支持OpenApi，则返回NO。
 */
- (BOOL)isAvailable;

/**
 *  是否支持分享到支付宝生活圈
 */
- (BOOL)isSupportShareTimeLine;

/**
 *  获取当前支付宝SDK的版本号
 */
- (NSString *)currentVersion;

/**
 *  invoke in AppDelegate application:openURL:sourceApplication:annotation:
 *  如果返回YES， 其他应用就不要在handle了
 */
+ (BOOL)handleOpenURL:(NSURL *)url;

/**
 *  向支付宝发送文本
 *
 *  @param scene 发送场景
 *  @param text 发送的文本（文本长度必须小于10k）
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendTextToScene:(APScene)scene withText:(NSString *)text customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

/**
 *  向支付宝发送图片
 *
 *  @param scene 发送场景
 *  @param image 图片
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendImageToScene:(APScene)scene withImage:(UIImage *)image customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

/**
 *  以URL的方式向支付宝发送图片
 *
 *  @param scene 发送场景
 *  @param imageURL 图片URL
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendImageToScene:(APScene)scene withImageURL:(NSString *)imageURL customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

/**
 *  向支付宝发送web page多媒体消息，消息由image，thumbnailURLString，title，description以及web page信息组成。当用户在支付宝点击消息时，支付宝会用内置浏览器打开urlString指定的页面。
 *
 *  @param scene 发送场景
 *  @param webpageURL web page url
 *  @param thumbnailImage 缩略图
 *  @param thumbnailImageURL 缩略图url
 *  @param title 标题
 *  @param description 摘要
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendWebpageToScene:(APScene)scene withWebpageURL:(NSString *)webpageURL thumbnailImage:(UIImage * _Nullable)thumbnailImage thumbnailImageURL:(NSString * _Nullable)thumbnailImageURL title:(NSString * _Nullable)title description:(NSString * _Nullable)description customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

@end

NS_ASSUME_NONNULL_END
