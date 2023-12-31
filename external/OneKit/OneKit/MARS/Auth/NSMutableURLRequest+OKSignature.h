//
//  NSMutableURLRequest+Signature.h
//  OneKit
//
//  Created by 朱元清 on 2021/1/13.
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableURLRequest (OKSignature)

/*! 根据OneKit自动获取的AK,SK来签名 */
- (void)ok_autoSign;

/*! 根据传入的AK,SK参数来签名
 * @param AK AppKey
 * @param SK AppSecretKey
 */
- (void)ok_signWithAK:(NSString *)AK SK:(NSString *)SK;

@end

NS_ASSUME_NONNULL_END
