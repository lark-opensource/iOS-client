//
//  BDUGMailShare.h
//  Article
//
//  Created by 王霖 on 16/1/28.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const BDUGMailShareDomain;

@class BDUGMailShare;

@protocol TTMailShareDelegate <NSObject>

/**
 *  邮件发送回调
 *
 *  @param mailShare     BDUGMailShare实例
 *  @param error 分享错误
 *  @param customCallbackUserInfo 用户自定义的分享回调信息
 */
- (void)mailShare:(BDUGMailShare *)mailShare sharedWithError:(NSError * _Nullable)error customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo;

@end

@interface BDUGMailShare: NSObject

@property(nonatomic, weak, nullable)id <TTMailShareDelegate> delegate;

+ (nullable instancetype)sharedMailShare;

/**
 *  是否可以发送邮件
 *
 *  @return 是否可以发送邮件
 */
- (BOOL)isAvailable;

/**
 *  发送邮件
 *
 *  @param subject        标题
 *  @param toRecipients   收件人列表
 *  @param ccRecipients   抄送人列表
 *  @param bcRecipients   密送人列表
 *  @param body           邮件内容
 *  @param isHTML         邮件内容是否是HTML
 *  @param attachment     附件
 *  @param mimeType       mimeType
 *  @param filename       附件名称
 *  @param viewController presenting ViewController
 *  @param customCallbackUserInfo 分享回调透传
 */
- (void)sendMailWithSubject:(nullable NSString *)subject
               toRecipients:(nullable NSArray<NSString *> *)toRecipients
               ccRecipients:(nullable NSArray<NSString *> *)ccRecipients
               bcRecipients:(nullable NSArray<NSString *> *)bcRecipients
                messageBody:(nullable NSString *)body
                     isHTML:(BOOL)isHTML
          addAttachmentData:(nullable NSData *)attachment
                   mimeType:(nullable NSString *)mimeType
                   fileName:(nullable NSString *)filename
           inViewController:(nonnull UIViewController *)viewController
 withCustomCallbackUserInfo:(nullable NSDictionary *)customCallbackUserInfo;

@end

NS_ASSUME_NONNULL_END
