//
//  BDUGKakaoTalkShare.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/17.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BDUGKakaoTalkShare;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGKakaoTalkShareErrorDomain;

@protocol BDUGKakaoTalkShareDelegate <NSObject>

@optional
/**
 *  kakaoTalk分享回调
 *
 *  @param kakaoTalkShare BDUGTwitterShare实例
 *  @param error 分享错误
 */
- (void)kakaoTalkShare:(BDUGKakaoTalkShare * _Nullable)kakaoTalkShare sharedWithError:(NSError * _Nullable)error;

@end

@interface BDUGKakaoTalkShare : NSObject

@property (nonatomic, weak, nullable) id <BDUGKakaoTalkShareDelegate> delegate;

+ (instancetype)sharedKakaoTalkShare;

- (BOOL)kakaoTalkInstalled;

- (void)shareURL:(NSURL *)URL;

- (void)shareImage:(UIImage *)image title:(NSString * _Nullable)title;

@end

NS_ASSUME_NONNULL_END
