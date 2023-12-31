//
//  NSData+HMDAES.m
//  Pods
//
//  Created by fengyadong on 2018/9/4.
//

#import "NSData+HMDAES.h"
#import <CommonCrypto/CommonCryptor.h>

@implementation NSData (HMDAES)

- (NSData *)HMDAES128EncryptedDataWithKey:(NSString *)key
{
    return [self HMDAES128EncryptedDataWithKey:key iv:nil];
}

- (NSData *)HMDAES128DecryptedDataWithKey:(NSString *)key
{
    return [self HMDAES128DecryptedDataWithKey:key iv:nil];
}

- (NSData *)HMDAES128EncryptedDataWithKey:(NSString *)key iv:(NSString *)iv
{
    return [self HMDAES128Operation:kCCEncrypt key:key iv:iv];
}

- (NSData *)HMDAES128DecryptedDataWithKey:(NSString *)key iv:(NSString *)iv
{
    return [self HMDAES128Operation:kCCDecrypt key:key iv:iv];
}

- (NSData *)HMDAES128Operation:(CCOperation)operation key:(NSString *)key iv:(NSString *)iv
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
    CCCryptorStatus cryptStatus = CCCrypt(operation,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr,
                                          kCCBlockSizeAES128,
                                          ivPtr,
                                          [self bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    if(buffer != NULL) free(buffer);
    return nil;
}

@end
