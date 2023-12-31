//
//  BDUGRocketShare.h
//  Article
//
//  Created by 蔡伟龙 on 2018/11/14.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGRocketShareErrorDomain;

@class BDUGRocketShare;

typedef NS_ENUM(NSUInteger, BDUGRocketShareScene) {
    BDUGRocketShareSceneSession          = 0,   /**< 聊天界面    */
    BDUGRocketShareSceneTimeline         = 1,   /**< 动态     */
};

@protocol BDUGRocketShareDelegate <NSObject>

@optional
/**
 *  分享回调
 *
 *  @param rocketShare BDUGRocketShare实例
 *  @param error 分享错误
 */
- (void)rocketShare:(BDUGRocketShare * _Nullable)rocketShare sharedWithError:(NSError * _Nullable)error;

@end

@interface BDUGRocketShare : NSObject

@property(nonatomic, weak, nullable) id<BDUGRocketShareDelegate> delegate;

/**
 *  注册
 *
 *  @params appID rsID
 */
+ (void)registerWithID:(NSString*)appID;

/**
 *  R 分享单例
 *
 *  @return R分享单例
 */
+ (instancetype)sharedRocketShare;

/**
 *  R是否可用
 *
 *  @return R是否可用。没有安装R或者当前版本R不支持OpenApi，则返回NO。
 */
- (BOOL)isAvailable;

- (BOOL)isAvailableWithNotifyError:(BOOL)notifyError;

/**
 *  @return 是否可处理该URL
 */
+ (BOOL)canHandleOpenURL:(NSURL *)url;

/**
 *  invoke in AppDelegate application:openURL:sourceApplication:annotation:
 *  如果返回YES， 其他应用就不要在handle了
 */
+ (BOOL)handleOpenURL:(NSURL *)url;

/**
 *  发送文本消息到R
 *
 *  @param scene 分享场景
 *  @param text 发送的文本（文本长度必须小于10k。如果超过，内部会二分截断）
 */
- (void)sendTextToScene:(BDUGRocketShareScene)scene withText:(NSString *)text;

/**
 *  发送图片到R
 *
 *  @param scene 分享场景
 *  @param image 图片
 */
- (void)sendImageToScene:(BDUGRocketShareScene)scene withImage:(UIImage*)image;

/**
 *  向R发送web page多媒体消息
 *
 *  @param scene 分享场景
 *  @param webpageURL web page url
 *  @param thumbnailImage 缩略图
 *  @param title 标题（不能超过512字节。如果超过，内部会二分截断）
 *  @param description 摘要（不能超过1k。如果超过，内部会二分截断）
 */
- (void)sendWebpageToScene:(BDUGRocketShareScene)scene
            withWebpageURL:(NSString *)webpageURL
            thumbnailImage:(UIImage * _Nullable)thumbnailImage
                     title:(NSString * _Nullable)title
               description:(NSString * _Nullable)description;

/**
 *  向R发送web page多媒体消息
 *
 *  @param scene 分享场景
 *  @param webpageURL web page url
 *  @param thumbnailImage 缩略图
 *  @param title 标题（不能超过512字节。如果超过，内部会二分截断）
 *  @param description 摘要（不能超过1k。如果超过，内部会二分截断）
 *  @param style  钻石用传 diamond
 */
- (void)sendWebpageToScene:(BDUGRocketShareScene)scene
            withWebpageURL:(NSString *)webpageURL
            thumbnailImage:(UIImage * _Nullable)thumbnailImage
                     title:(NSString * _Nullable)title
               description:(NSString * _Nullable)description
                     style:(NSString * _Nullable)style;


- (void)sendVideoToScene:(BDUGRocketShareScene)scene
           videoURLString:(NSString *)videoURLString;

@end

NS_ASSUME_NONNULL_END
