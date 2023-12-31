//
//  OKMARSAuthHelper.m
//  OneKit
//
//  Created by 朱元清 on 2021/3/30.
//

#import "OKMARSAuthHelper.h"
#import <CommonCrypto/CommonHMAC.h>
#import "NSData+OK.h"

@implementation OKMARSAuthHelper

/// 生成HmacSHA256签名
/// @param key key
/// @param data data
+ (NSString *)HmacSHA256WithKey:(NSString *)key data:(NSString *)data {
    if (!key || !data) {
        return nil;
    }
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *hmacSHA256 = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    return [hmacSHA256 ok_hexString];
}

/// HTTP Header中的X-mars-date字段
+ (NSString *)x_mars_date {
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    formater.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    formater.dateFormat = @"yyyyMMdd'T'HHmmss'Z'";
    
    return [formater stringFromDate:[NSDate date]];
}

/// 生成MD5
/// @param data 二进制数据
+ (NSString *)md5FromData:(NSData *)data {
    if (data.length > 0) {
        unsigned char result[CC_MD5_DIGEST_LENGTH];
        CC_MD5([data bytes], (unsigned int)data.length, result);
        NSString *md5 = [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
        ];
        return md5;
    }
    return @"";
}

@end
