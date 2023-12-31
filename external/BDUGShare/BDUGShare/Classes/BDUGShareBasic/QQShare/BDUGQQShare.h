//
//  BDUGQQShare.h
//  Article
//
//  Created by 王霖 on 15/9/21.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGQQShareErrorDomain;

@class BDUGQQShare;
@class QQBaseReq;

@protocol BDUGQQShareDelegate <NSObject>

@optional
/**
 *  qq分享回调
 *
 *  @param qqShare BDUGQQShare实例
 *  @param error 分享错误
 *  @param customCallbackUserInfo 用户自定义的分享回调信息
 */
- (void)qqShare:(BDUGQQShare * _Nullable)qqShare sharedWithError:(NSError * _Nullable)error customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

@end

@protocol BDUGQQShareRequestDelegate <NSObject>

@optional
/**
 *  来自qq请求
 *
 *  @param qqShare BDUGQQShare实例
 *  @param request QQ请求体
 */
- (void)qqShare:(BDUGQQShare * _Nullable)qqShare receiveRequest:(QQBaseReq * _Nullable)request;

@end

@interface BDUGQQShare : NSObject

@property(nonatomic, weak, nullable) id<BDUGQQShareDelegate> delegate;
@property(nonatomic, weak, nullable) id<BDUGQQShareRequestDelegate> requestDelegate;

/**
 *  QQ分享单例
 *
 *  @return QQ分享单例
 */
+ (instancetype)sharedQQShare;

/**
 *  QQ授权
 *
 *  @param appID 第三方应用在互联开放平台申请的唯一标识
 */
+ (void)registerWithID:(NSString *)appID;

+ (void)registerWithID:(NSString *)appID universalLink:(NSString *)universalLink;

/**
 *  QQ是否可用
 *
 *  @return QQ是否可用。没有安装QQ或者当前版本QQ不支持OpenApi，则返回NO。
 */
- (BOOL)isAvailable;

/**
 *  QQ SDK版本
 *
 *  @return 当前QQ SDK版本
 */
- (NSString *)currentVersion;

/*
 *  invoke in AppDelegate application:openURL:sourceApplication:annotation:
 *  如果返回YES， 其他应用就不要在handle了
 */
+ (BOOL)handleOpenURL:(NSURL *)url;

/// handle universiallink
/// @param universallink 参数
+ (BOOL)handleOpenUniversallink:(NSURL *)universallink;

/**
 *  打开QQ
 *
 *  @return 是否成功打开
 */
+ (BOOL)openQQ;

#pragma mark - 分享到QQ好友
/**
 *  发送文本消息给好友
 *
 *  @param text 文本消息（最长1536字符。如果超过，内部会截断到1536）
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendText:(NSString *)text withCustomCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

/**
 *  发送图片给QQ好友
 *
 *  @param imageData 图片（不能超过5M）
 *  @param thumbnailImageData 缩略图（不能超过1M）
 *  @param title 图片标题（不超过128字符。如果超过，内部会截断到128）
 *  @param description 图片描述（不超过512字符。如果超过，内部会截断到512）
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendImageWithImageData:(NSData *)imageData
            thumbnailImageData:(NSData * _Nullable)thumbnailImageData
                         title:(NSString * _Nullable)title
                   description:(NSString * _Nullable)description
        customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

/**
 *  发送图片给QQ好友，方法内部构造分享的图片的缩略图
 *
 *  @param image 图片
 *  @param title 图片标题（不超过128字符。如果超过，内部会截断到128）
 *  @param description 图片描述（不超过512字符。如果超过，内部会截断到512）
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendImage:(UIImage *)image
        withTitle:(NSString * _Nullable)title
      description:(NSString * _Nullable)description
customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

/**
 *  发送新闻给QQ好友。Note:缩略图可以指定的图片，也可以是指定的url。如果两个都有，使用url。
 *
 *  @param url 新闻url（不超过512字符）
 *  @param thumbnailImage 新闻缩略图
 *  @param thumbnailImageURL 新闻缩略图url（不超过512字符）
 *  @param title 新闻标题（不超过128字符。如果超过，内部会截断到128）
 *  @param description 新闻描述（不超过512字符。如果超过，内部会截断到512）
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendNewsWithURL:(NSString *)url
         thumbnailImage:(UIImage * _Nullable)thumbnailImage
      thumbnailImageURL:(NSString * _Nullable)thumbnailImageURL
                  title:(NSString * _Nullable)title
            description:(NSString * _Nullable)description
 customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

#pragma mark - 分享到QQ空间

/**
 *  发送图片到QQ空间
 *
 *  @param image 图片
 *  @param title 标题（不超过128字符。如果超过，内部会截断到128）
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendImageToQZoneWithImage:(UIImage *)image title:(NSString * _Nullable)title customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

/**
 *  发送图片到QQ空间
 *  
 *  @param imageData 图片data
 *  @param thumbnailImageData 缩略图data
 *  @param title 标题（不超过128字符。如果超过，内部会截断到128）
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendImageToQZoneWithImageData:(NSData *)imageData thumbnailImageData:(NSData * _Nullable)thumbnailImageData title:(NSString * _Nullable)title customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

/**
 *  发送新闻到QZone。Note:如果新闻缩略图URL（imageURL）非空，使用URL指定的图片，如果新闻缩略图URL空，使用新闻缩略图（image）
 *
 *  @param url 新闻url
 *  @param thumbnailImage 新闻缩略图
 *  @param thumbnailImageURL 新闻缩略图URL（不超过512字符）
 *  @param title 新闻标题（不超过128字符。如果超过，内部会截断到128）
 *  @param description 新闻描述（不超过512字符。如果超过，内部会截断到512）
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendNewsToQZoneWithURL:(NSString *)url
                thumbnailImage:(UIImage * _Nullable)thumbnailImage
             thumbnailImageURL:(NSString * _Nullable)thumbnailImageURL
                         title:(NSString * _Nullable)title
                   description:(NSString * _Nullable)description
        customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

@end

NS_ASSUME_NONNULL_END
