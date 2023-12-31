//
//  BDUGMessageShare.h
//  Article
//
//  Created by 王霖 on 16/1/28.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGMessageShareDomain;

@class BDUGMessageShare;

@protocol TTMessageShareDelegate <NSObject>

/**
 *  信息发送回调
 *
 *  @param messageShare BDUGMessageShare实例
 *  @param error 分享错误
 *  @param customCallbackUserInfo 用户自定义的分享回调信息
 */
- (void)messageShare:(BDUGMessageShare *)messageShare sharedWithError:(NSError * _Nullable)error customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

@end

@interface BDUGMessageShare : NSObject

@property(nonatomic, weak, nullable)id <TTMessageShareDelegate> delegate;

+ (instancetype)sharedMessageShare;

/**
 *  是否能发送文本消息
 *
 *  @return 是否能发送文本消息
 */
- (BOOL)isAvailable;

/**
 *  发送信息
 *
 *  @param body           信息文本内容
 *  @param viewController presenting ViewController
 *  @param customCallbackUserInfo 用户自定义的分享回调信息
 */
- (void)sendMessageWithBody:(NSString * _Nullable)body
           inViewController:(UIViewController *)viewController
     customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

- (void)sendMessageWithBody:(NSString * _Nullable)body
                      image:(UIImage * _Nullable)image
           inViewController:(UIViewController *)viewController
     customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

@end

NS_ASSUME_NONNULL_END
