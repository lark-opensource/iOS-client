//
//  BDUGTiktokShare.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/11.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BDUGTiktokShare;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const BDUGTiktokShareErrorDomain;

@protocol BDUGTiktokShareDelegate <NSObject>

@optional
/**
 *  微信分享回调
 *
 *  @param tiktokShare BDUGTiktokShare实例
 *  @param error 分享错误
 */
- (void)tiktokShare:(BDUGTiktokShare * _Nullable)tiktokShare sharedWithError:(NSError * _Nullable)error;
@end

@interface BDUGTiktokShare : NSObject

@property(nonatomic, weak, nullable) id<BDUGTiktokShareDelegate> delegate;

+ (instancetype)sharedDouyinShare;

+ (void)registerWithID:(NSString *)appID;

+ (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary * _Nullable)launchOptions;

+ (BOOL)application:(UIApplication * _Nullable)application openURL:(NSURL *)url sourceApplication:(NSString * _Nullable)sourceApplication annotation:(id)annotation;

- (NSString *)currentVersion;

- (BOOL)isAvailable;

- (BOOL)isAvailableWithNotifyError:(BOOL)notifyError;

- (void)sendVideoWithPath:(NSString *)videoPath;

- (void)sendImageWithPath:(NSString *)imagePath;

@end

NS_ASSUME_NONNULL_END
