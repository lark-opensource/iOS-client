//
//  SAMKeyChain+CJPay.h
//  CJPay
//
//  Created by 王新华 on 2019/4/8.
//

#import <Foundation/Foundation.h>
#import <SAMKeychain/SAMKeychain.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAMKeychain(CJPay)

+ (BOOL)cj_save:(NSString *)content forKey:(NSString *)key;

+ (nullable NSString *)cj_stringForKey:(NSString *)key;

+ (BOOL)cj_deleteForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
