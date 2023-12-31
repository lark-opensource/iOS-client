//
//  BDUGMayaShare.h
//  TTShare
//
//  Created by chenjianneng on 2019/3/15.
//

#import <Foundation/Foundation.h>
#import <MYShareSDK/MYApi.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGMayaShareErrorDomain;

@class BDUGMayaShare;

@protocol BDUGMayaShareDelegate <NSObject>

@optional
/**
 *  分享回调
 *
 *  @param mayaShare BDUGMayaShare实例
 *  @param error 分享错误
 */
- (void)mayaShare:(BDUGMayaShare * _Nullable)mayaShare sharedWithError:(NSError * _Nullable)error;

@end


@interface BDUGMayaShare : NSObject

@property(nonatomic, weak, nullable) id<BDUGMayaShareDelegate> delegate;

/**
 *  注册
 *
 *  @params appID rsID
 */
+ (void)registerWithID:(NSString*)appID;

/**
 *  多闪 分享单例
 *
 *  @return 多闪分享单例
 */
+ (instancetype)sharedMYShare;

/**
 *  多闪是否可用
 *
 *  @return 多闪是否可用。没有安装多闪或者当前版本多闪不支持OpenApi，则返回NO。
 */
- (BOOL)isAvailable;

/**
 *  invoke in AppDelegate application:openURL:sourceApplication:annotation:
 *  如果返回YES， 其他应用就不要在handle了
 */
+ (BOOL)handleOpenURL:(NSURL *)url;

/**
 *  向多闪发送web page多媒体消息
 *
 *  @param scene 分享场景
 *  @param webpageURL web page url
 *  @param thumbnailImage 缩略图
 *  @param title 标题（不能超过512字节。如果超过，内部会二分截断）
 *  @param description 摘要（不能超过1k。如果超过，内部会二分截断）
 */
- (void)sendWebpageToScene:(MYScene)scene
            withWebpageURL:(NSString *)webpageURL
            thumbnailImage:(UIImage * _Nullable)thumbnailImage
                     title:(NSString * _Nullable)title
               description:(NSString * _Nullable)description;

@end

NS_ASSUME_NONNULL_END
