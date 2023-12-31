//
//  OKMARSAuthHelper.h
//  OneKit
//
//  Created by 朱元清 on 2021/3/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// MARS请求签名工具类
@interface OKMARSAuthHelper : NSObject

+ (NSString *)HmacSHA256WithKey:(NSString *)key data:(NSString *)data;

+ (NSString *)x_mars_date;

+ (NSString *)md5FromData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
