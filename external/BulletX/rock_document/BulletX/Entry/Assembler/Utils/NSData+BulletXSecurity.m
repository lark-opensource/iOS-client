//
//  NSData+BulletXSecurity.m
//  Bullet-Pods-Aweme
//
//  Created by zhaoyu on 2020/12/30.
//

#import <CommonCrypto/CommonCryptor.h>
#import "NSData+BulletXSecurity.h"

@implementation NSData (BulletXSecurity)

- (NSData *)bullet_AES128EncryptedDataWithKey:(NSString *)key
{
    return [self bullet_AES128Operation:kCCEncrypt key:key iv:nil];
}

- (NSData *)bullet_AES128Operation:(CCOperation)operation key:(NSString *)key iv:(nullable NSString *)iv
{
    char keyPtr[kCCKeySizeAES128 + 1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];

    char ivPtr[kCCBlockSizeAES128 + 1];
    bzero(ivPtr, sizeof(ivPtr));
    if (iv) {
        [iv getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
    }

    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);

    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(operation, kCCAlgorithmAES128, kCCOptionPKCS7Padding | kCCOptionECBMode, keyPtr, kCCBlockSizeAES128, ivPtr, [self bytes], dataLength, buffer, bufferSize, &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}

@end
