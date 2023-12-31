//
//  BDUGWeiboShare.h
//  ss_app_ios_lib_share
//
//  Created by 王霖 on 15/10/10.
//  Copyright © 2015年 王霖. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGWeiboShareErrorDomain;

@class BDUGWeiboShare;
@class WBBaseRequest;

@protocol TTWeiboShareDelegate <NSObject>

@optional
/**
 *  微博消息发送完成回调
 *
 *  @param weiboShare  BDUGWeiboShare实例
 *  @param error 分享错误
 *  @param customCallbackUserInfo 用户自定义的分享回调信息
 */
- (void)weiboShare:(BDUGWeiboShare * _Nullable)weiboShare sharedWithError:(NSError * _Nullable)error customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

@end

@protocol TTWeiboShareRequestDelegate <NSObject>

@optional
/**
 *  来自微博请求
 *
 *  @param weiboShare  BDUGWeiboShare实例
 *  @param request 微博请求体
 */
- (void)weiboShare:(BDUGWeiboShare *)weiboShare receiveRequest:(WBBaseRequest * _Nullable)request;

@end

@interface BDUGWeiboShare : NSObject

@property (nonatomic, weak, nullable) id<TTWeiboShareDelegate> delegate;
@property (nonatomic, weak, nullable) id<TTWeiboShareRequestDelegate> requestDelegate;

/**
 *  微博单例
 *
 *  @return 微博单例
 */
+ (instancetype)sharedWeiboShare;

/**
 *  向微博客户端程序注册第三方应用
 *
 *  @param appID 微博开放平台第三方应用appID
 *  @param universalLink 开发者Universal Link
 */
+ (void)registerWithID:(NSString *)appID universalLink:(NSString *)universalLink;

/**
 *  微博是否可用
 *
 *  @return 是否可用
 */
- (BOOL)isAvailable;

/**
 *  微博SDK版本
 *
 *  @return 当前微博SDK版本
 */
- (NSString *)currentVersion;


/**
 *  should be invoked in [AppDelegate handleOpenURL:]
 */
+ (BOOL)handleOpenURL:(NSURL *)url;


/*! @brief 处理微博通过Universal Link启动App时传递的数据
 *
 * 需要在 application:continueUserActivity:restorationHandler:中调用。
 * @param userActivity 微博启动第三方应用时系统API传递过来的userActivity
 * @return 成功返回YES，失败返回NO。
 */
+ (BOOL)handleOpenUniversalLink:(NSUserActivity *_Nullable)userActivity;

/**
 *  发送纯文本内容
 *
 *  @param text 文本内容（不超过140个字符）
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendText:(NSString *)text withCustomCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

/**
 *  发送文本和图片内容
 *
 *  @param text 文本（不超过140个字符）
 *  @param image 图片（不超过10M）
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendText:(NSString * _Nullable)text withImage:(UIImage* _Nullable)image customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

/**
 *  向微博发送web page多媒体消息。
 *
 *  @param title web page标题（不超过1K）
 *  @param webpageURL web page url（不超过255字符）
 *  @param thumbnailImage web page缩略图
 *  @param description    web page描述（不超过1K）
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendWebpageWithTitle:(NSString * _Nullable)title webpageURL:(NSString *)webpageURL thumbnailImage:(UIImage * _Nullable)thumbnailImage description:(NSString * _Nullable)description customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

@end

NS_ASSUME_NONNULL_END
