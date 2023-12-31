//
//  BDUGDouyinShare.h
//  NewsLite
//
//  Created by 杨阳 on 2019/4/24.
//

#import <Foundation/Foundation.h>

@class BDUGAwemeShare;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const BDUGAwemeShareErrorDomain;

@protocol BDUGAwemeShareDelegate <NSObject>

@optional
/**
 *  微信分享回调
 *
 *  @param awemeShare BDUGAwemeShare实例
 *  @param error 分享错误
 */
- (void)awemeShare:(BDUGAwemeShare * _Nullable)awemeShare sharedWithError:(NSError * _Nullable)error;
@end

@interface BDUGAwemeShare : NSObject

@property(nonatomic, weak) id<BDUGAwemeShareDelegate> delegate;

+ (instancetype)sharedDouyinShare;

+ (void)registerWithID:(NSString *)appID;

+ (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

+ (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

- (NSString *)currentVersion;

- (BOOL)isAvailable;

- (BOOL)isAvailableWithNotifyError:(BOOL)notifyError;

+ (BOOL)openAweme;

- (void)sendVideoWithPath:(NSString *)videoPath extraInfo:(NSDictionary * _Nullable)extraInfo state:(NSString * _Nullable)state hashtag:(NSString * _Nullable)hashtag;

- (void)sendImageWithPath:(NSString *)imagePath extraInfo:(NSDictionary * _Nullable)extraInfo state:(NSString * _Nullable)state hashtag:(NSString * _Nullable)hashtag;

@end

NS_ASSUME_NONNULL_END
