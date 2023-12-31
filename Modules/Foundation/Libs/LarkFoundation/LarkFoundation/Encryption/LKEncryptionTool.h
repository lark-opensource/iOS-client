//
//  LKEncryptionTool.h
//  LarkWeb
//
//  Created by sniperj on 2019/4/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LKEncryptionTool : NSObject

/**
 对加密后的私有API解密

 @param string 加密字符串
 @return 解密字符串
 */
+ (NSString *)decryptString:(NSString *)string;

/**
 加密私有API

 @param string 需要加密的API
 @return 加密后的字符串
 */
+ (NSString *)encryptString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
