//
//  OPAES256Utils.m
//  ECOInfra
//
//  Created by ByteDance on 2022/10/10.
//

#import "OPAES256Utils.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import "BDPUtils.h"

@implementation OPAES256Utils

+ (NSString *)encryptWithContent:(NSString *)content key:(NSString *)key iv:(NSString *)iv {
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encryptedData = [self encryptWithData:data key:key iv:iv];
    return [self getHexStrWithData:encryptedData];
}

+ (NSString *)decryptWithContent:(NSString *)content key:(NSString *)key iv:(NSString *)iv {
    NSData *data = [self getDataWithHexStr:content];
    NSData *decryptedData = [self decryptWithData:data key:key iv:iv];
    NSString *decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    return decryptedStr;
}

+ (NSData *)encryptWithData:(NSData *)data key:(NSString *)key iv:(NSString *)iv {
    return [self cryptAES256WithOperation:kCCEncrypt data:data key:key iv:iv];
}

+ (NSData *)decryptWithData:(NSData *)data key:(NSString *)key iv:(NSString *)iv {
    return [self cryptAES256WithOperation:kCCDecrypt data:data key:key iv:iv];
}

+ (NSData *)cryptAES256WithOperation:(CCOperation)operation data:(NSData *)data key:(NSString *)key iv:(NSString *)iv {
    // 私钥SHA256加密
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char encryptedKey[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256([keyData bytes], (CC_LONG)[keyData length], encryptedKey);
    // 明文AES256加密
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(operation, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          encryptedKey, kCCKeySizeAES256, [iv UTF8String],
                                          [data bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}

+ (NSString *)getHexStrWithData:(NSData *)data {
    const unsigned char *bytes = (const unsigned char *)data.bytes;
    if (!bytes) {
        return [NSString string];
    }
    NSUInteger dataLen = data.length;
    NSMutableString *hexStr = [NSMutableString stringWithCapacity:dataLen * 2];
    for (int i = 0; i < dataLen; i++) {
        [hexStr appendFormat:@"%02x", (unsigned char)bytes[i]];
    }
    return [hexStr copy];
}

+ (NSData *)getDataWithHexStr:(NSString *)string {
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *mData = [[NSMutableData alloc] init];
    unsigned char curCharCode;
    char rawChars[3] = {'\0', '\0', '\0'};
    for (int i = 0; i < string.length / 2; i++) {
        rawChars[0] = [string characterAtIndex:i * 2];
        rawChars[1] = [string characterAtIndex:i * 2 + 1];
        curCharCode = strtol(rawChars, NULL, 16);
        [mData appendBytes:&curCharCode length:1];
    }
    return mData;
}

+ (NSString *)getIV:(NSString *)ivInfo backup:(NSString *)backup {
    NSString *iv1 = [self buildIvStr:ivInfo];
    if (BDPIsEmptyString(iv1)) {
        NSString *iv2 = [self buildIvStr:backup];
        if (BDPIsEmptyString(iv2)) {
            return @"abcd12349876oify";
        }
        return iv2;
    }
    return iv1;
}

+ (NSString *)buildIvStr:(NSString *)origin {
    if (BDPIsEmptyString(origin)) {
        return @"";
    }
    if (origin.length < 16) {
        NSInteger len = origin.length;
        NSInteger left = 16 - len;
        NSMutableString *ret = [NSMutableString string];
        [ret appendString:origin];
        for (int i = 0; i < left; i++) {
            [ret appendString:@"#"];
        }
        return [ret copy];
    } else if (origin.length == 16) {
        return origin;
    }
    return [origin substringWithRange:NSMakeRange(0, 16)];
}

@end
