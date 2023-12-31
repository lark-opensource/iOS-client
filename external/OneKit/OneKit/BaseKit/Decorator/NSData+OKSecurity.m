//
//  NSData+OKSecurity.m
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "NSData+OKSecurity.h"
#import <CommonCrypto/CommonCryptor.h>

static size_t keyLengthWithKeySize(OKAESKeySize keySize) {
    size_t keyLength = kCCKeySizeAES256;
    switch (keySize) {
        case OKAESKeySizeAES256:
            keyLength = kCCKeySizeAES256;
            break;
        case OKAESKeySizeAES192:
            keyLength = kCCKeySizeAES192;
            break;
        case OKAESKeySizeAES128:
            keyLength = kCCKeySizeAES128;
            break;
    }

    return keyLength;
}

@implementation NSData (OKSecurity)


/// aes-ecb iv = nil
/// aes-cbc iv not nil
/// iv.length =  kCCBlockSizeAES128 = 16
- (NSData *)ok_aesEncryptWithkey:(NSString *)key
                          keySize:(OKAESKeySize)keySize
                               iv:(NSString *)iv {
    if (key.length < 1) {
        return nil;
    }

    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = [iv dataUsingEncoding:NSUTF8StringEncoding];

    return [self ok_aesEncryptWithkeyData:keyData keySize:keySize ivData:ivData];
}

- (NSData *)ok_aesEncryptWithkeyData:(NSData *)keyData
                              keySize:(OKAESKeySize)keySize
                               ivData:(NSData *)ivData {
    if (keyData.length < 1) {
        return nil;
    }

    size_t keyLength = keyLengthWithKeySize(keySize);
    /// key
    uint8_t cKey[keyLength];
    bzero(cKey, keyLength);
    [keyData getBytes:cKey length:keyLength];
    
    
    CCOptions option = 0;
    /// IV
    uint8_t cIv[kCCBlockSizeAES128];
    bzero(cIv, kCCBlockSizeAES128);
    if (ivData.length > 0) {
        [ivData getBytes:cIv length:kCCBlockSizeAES128];
        option = kCCOptionPKCS7Padding;
    } else {
        option = kCCOptionPKCS7Padding | kCCOptionECBMode;
    }
     /// buffer
    size_t bufferSize = [self length] + kCCBlockSizeAES128;
    void *buffer = malloc(sizeof(uint8_t) * bufferSize);
    
    if (buffer == NULL) {
        return nil;
    }
    
    size_t encryptedSize = 0;
    /// Encrypt
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES, option,
                                          cKey, keyLength, cIv,
                                          [self bytes], [self length],
                                          buffer, bufferSize, &encryptedSize);

    NSData *result = nil;
    if (cryptStatus == kCCSuccess && encryptedSize > 0) {
        result = [NSData dataWithBytesNoCopy:buffer length:encryptedSize];
    } else {
        free(buffer);
    }

    return result;
}

- (NSData *)ok_aesDecryptwithKey:(NSString *)key
                          keySize:(OKAESKeySize)keySize
                               iv:(NSString *)iv {
    if (key.length < 1) {
        return nil;
    }
    
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = [iv dataUsingEncoding:NSUTF8StringEncoding];
    
    return [self ok_aesDecryptwithKeyData:keyData keySize:keySize ivData:ivData];
}

- (NSData *)ok_aesDecryptwithKeyData:(NSData *)keyData
                              keySize:(OKAESKeySize)keySize
                               ivData:(NSData *)ivData {
    if (keyData.length < 1) {
        return nil;
    }
    
    size_t keyLength = keyLengthWithKeySize(keySize);
    uint8_t cKey[keyLength];
    bzero(cKey, keyLength);
    [keyData getBytes:cKey length:keyLength];

    uint8_t cIv[kCCBlockSizeAES128];
    bzero(cIv, kCCBlockSizeAES128);
    CCOptions option = 0;
    if (ivData.length > 0) {
        [ivData getBytes:cIv length:kCCBlockSizeAES128];
        option = kCCOptionPKCS7Padding;
    } else {
        option = kCCOptionPKCS7Padding | kCCOptionECBMode;
    }

    size_t bufferSize = [self length] + kCCBlockSizeAES128;
    void *buffer = malloc(sizeof(uint8_t) * bufferSize);

    if (buffer == NULL) {
        return nil;
    }
    
    size_t decryptedSize = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES, option,
                                          cKey, keyLength, cIv,
                                          [self bytes], [self length],
                                          buffer, bufferSize, &decryptedSize);

    NSData *result = nil;
    if (cryptStatus == kCCSuccess && decryptedSize > 0) {
        result = [NSData dataWithBytesNoCopy:buffer length:decryptedSize];
    } else {
        free(buffer);
    }

    return result;
}

@end
