//
//  NSString+EffectPlatformUtils.m
//  EffectPlatformSDK
//
//  Created by 赖霄冰 on 2019/8/8.
//

#import "NSString+EffectPlatformUtils.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (EffectPlatformUtils)

- (NSString *)ep_md5String {
    const char *cString = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(cString, (CC_LONG)strlen(cString), digest);
    
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02X", digest[i]];
    }
    
    return result;
}

- (NSString *)ep_generateMD5Key {
    const char *cString = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(cString, (CC_LONG)strlen(cString), digest);
    NSMutableString *result = [[NSMutableString alloc] init];
    
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", digest[i]];
    }
    NSString *MD5Key = [result substringWithRange:NSMakeRange(8, 16)];
    return MD5Key;
}

@end
