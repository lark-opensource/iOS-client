//
//  BDUGLineShare.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/14.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BDUGLineShare;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const BDUGLineShareErrorDomain;

@protocol BDUGLineShareDelegate <NSObject>

@optional
/**
 *  line分享回调
 *
 *  @param lineShare BDUGLineShare实例
 *  @param error 分享错误
 */
- (void)lineShare:(BDUGLineShare * _Nullable)lineShare sharedWithError:(NSError * _Nullable)error;

@end

@interface BDUGLineShare : NSObject

@property (nonatomic, weak, nullable) id <BDUGLineShareDelegate> delegate;

+ (instancetype)sharedLineShare;

- (BOOL)lineAppInstalled;

- (void)shareImage:(UIImage *)image;

- (void)shareText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
