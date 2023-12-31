//
//  NSData+ETag.m
//  IESGeckoKit
//
//  Created by li keliang on 2018/10/11.
//

#import "NSData+ETag.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSData (ETag)

- (NSString *)ies_eTag
{
    return [self ies_md5String];
}

- (NSString *)ies_md5String
{
    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
    CC_MD5_Update(&md5, self.bytes, (CC_LONG)self.length);
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(result, &md5);
    NSMutableString *resultString = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [resultString appendFormat:@"%02X", result[i]];
    }
    return resultString;
}

@end
