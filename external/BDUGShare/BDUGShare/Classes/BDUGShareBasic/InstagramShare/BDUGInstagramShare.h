//
//  BDUGInstagramShare.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/5/30.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BDUGInstagramShare;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const BDUGInstagramShareErrorDomain;

@protocol BDUGInstagramShareDelegate <NSObject>

@optional
/**
 *  ins分享回调
 *
 *  @param insShare BDUGInstagramShare实例
 *  @param error 分享错误
 */
- (void)instagramShare:(BDUGInstagramShare * _Nullable)insShare sharedWithError:(NSError * _Nullable)error;

@end

@interface BDUGInstagramShare : NSObject

@property (nonatomic, weak, nullable) id <BDUGInstagramShareDelegate> delegate;

+ (instancetype)sharedInstagramShare;

+ (BOOL)instagramInstalled;

+ (BOOL)openInstagram;

- (void)sendFileWithAlbumIdentifier:(NSString *)identifier;

- (void)sendImageToStories:(UIImage *)image NS_AVAILABLE_IOS(10_0);

- (void)sendVideoDataToStories:(NSData *)videoData NS_AVAILABLE_IOS(10_0);

@end

NS_ASSUME_NONNULL_END
