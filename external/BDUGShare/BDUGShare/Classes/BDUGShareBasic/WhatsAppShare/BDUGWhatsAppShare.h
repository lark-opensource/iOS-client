//
//  BDUGWhatsAppShare.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/29.
//

#import <Foundation/Foundation.h>

@class BDUGWhatsAppShare;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const BDUGWhatsAppShareErrorDomain;

@protocol BDUGWhatsAppShareDelegate <NSObject>

@optional
/**
 *  whatsApp分享回调
 *
 *  @param whatsappShare BDUGWhatsAppShare实例
 *  @param error 分享错误
 */
- (void)whatsappShare:(BDUGWhatsAppShare * _Nullable)whatsappShare sharedWithError:(NSError * _Nullable)error;

@end

@interface BDUGWhatsAppShare : NSObject

@property (nonatomic, weak, nullable) id <BDUGWhatsAppShareDelegate> delegate;

+ (instancetype)sharedWhatsAppShare;

+ (BOOL)whatsappInstalled;

+ (BOOL)openWhatsApp;

- (void)sendText:(NSString *)text;

- (void)sendImage:(UIImage *)image;

- (void)sendFileWithSandboxPath:(NSString *)sandboxPath;

@end

NS_ASSUME_NONNULL_END
