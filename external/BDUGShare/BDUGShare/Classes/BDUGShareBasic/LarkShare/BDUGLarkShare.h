//
//  BDUGLarkShare.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2020/3/27.
//  Copyright © 2020 xunianqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGLarkShareErrorDomain;

@class BDUGLarkShare;

@protocol BDUGLarkShareDelegate <NSObject>

@optional
/**
 *  分享回调
 *
 *  @param larkShare BDUGLarkShare实例
 *  @param error 分享错误
 */
- (void)larkShare:(BDUGLarkShare * _Nullable)larkShare sharedWithError:(NSError * _Nullable)error;

@end

@interface BDUGLarkShare : NSObject

@property(nonatomic, weak, nullable) id<BDUGLarkShareDelegate> delegate;

+ (instancetype)sharedLarkShare;

+ (void)registerWithID:(NSString*)appID;

+ (BOOL)handleOpenURL:(NSURL *)url;

- (BOOL)isAvailable;

- (BOOL)isAvailableWithNotifyError:(BOOL)notifyError;

- (BOOL)larkInstalled;

- (BOOL)larkSupportAPI;

- (NSString *)currentVersion;

+ (void)setDisplayAppName:(NSString *)displayName;

+ (void)setAppScheme:(NSString *)scheme;

#pragma mark - send

- (void)sendText:(NSString *)text;

- (void)sendImage:(UIImage * _Nullable)image imageURL:(NSString * _Nullable)imageURL;

- (void)sendWebPageURL:(NSString *)webPageURL title:(NSString * _Nullable)title;

- (void)sendVideoWithSandboxPath:(NSString *)videoSandboxPath;

@end

NS_ASSUME_NONNULL_END
