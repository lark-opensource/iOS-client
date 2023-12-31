//
//  BDUGToutiaoShare.h
//  TTShare
//
//  Created by chenjianneng on 2019/3/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGToutiaoShareErrorDomain;

@class BDUGToutiaoShare;

@protocol BDUGToutiaoShareDelegate <NSObject>

@optional
/**
 *  分享回调
 *
 *  @param toutiaoShare BDUGToutiaoShare实例
 *  @param error 分享错误
 */
- (void)toutiaoShare:(BDUGToutiaoShare * _Nullable)toutiaoShare sharedWithError:(NSError * _Nullable)error;

@end


@interface BDUGToutiaoShare : NSObject

@property(nonatomic, weak, nullable) id<BDUGToutiaoShareDelegate> delegate;

/**
 *  注册
 *
 *  @params appID rsID
 */
+ (void)registerWithID:(NSString*)appID source:(NSString *)source;

/**
 *  头条 分享单例
 *
 *  @return 头条分享单例
 */
+ (instancetype)sharedInstance;

/**
 *  头条是否可用
 *
 *  @return 头条是否可用。没有安装头条或者当前版本头条不支持OpenApi，则返回NO。
 */
- (BOOL)isAvailable;

/**
 *  invoke in AppDelegate application:openURL:sourceApplication:annotation:
 *  如果返回YES， 其他应用就不要在handle了
 */
+ (BOOL)handleOpenURL:(NSURL *)url;


- (void)sendWebpage:(NSString *)webpageURL title:(NSString * _Nullable)title imageURL:(NSString * _Nullable)imageURL isVideo:(BOOL)isVideo;

- (void)sendImage:(UIImage * _Nullable)image title:(NSString * _Nullable)title postExtra:(NSString * _Nullable)postExtra;

@end

NS_ASSUME_NONNULL_END
