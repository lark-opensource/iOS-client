//
//  NSData+Crypto.m
//  AAWELaunchOptimization-Pods
//
//  Created by ZhangYuanming on 2020/7/31.
//

#import "NSData+Crypto.h"
#import <CommonCrypto/CommonCryptor.h>

@implementation NSData (Crypto)

// 加密
- (NSData *)ep_aes256_encrypt:(NSString *)key{
    
    char keyPtr[kCCKeySizeAES256 + 1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding | kCCOptionECBMode, keyPtr, kCCBlockSizeAES128, NULL, [self bytes], dataLength, buffer, bufferSize, &numBytesEncrypted);
    
    if (cryptStatus == kCCSuccess) {
        
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer);
    return nil;
}


// 解密
- (NSData *)ep_aes256_decrypt:(NSString *)key{
    
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeAES128,
                                          NULL,
                                          [self bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
        
    }
    free(buffer);
    return nil;
}


#pragma mark - AES 128

//Call this to Enrypt with ECB Cipher Transformation mode. Iv is not required for ECB
- (NSData *)ep_encryptAES128ECB:(NSString *)key {
    return [self ep_aes128Operation:kCCEncrypt key:key iv:nil ecb:true];
}

//Call this to Decrypt with ECB Cipher Transformation mode. Iv is not required for ECB
- (NSData *)ep_decryptAES128ECB:(NSString *)key {
    return [self ep_aes128Operation:kCCDecrypt key:key iv:nil ecb:true];
}

//Call this to Encrypt with CBC Cipher Transformation mdoe.
- (NSData *)ep_encryptAES128CBC:(NSString *)key iv:(NSString *)iv {
    return [self ep_aes128Operation:kCCEncrypt key:key iv:iv ecb:false];
}

//Call this to Decrypt with CBC Cipher Transformation mode.
- (NSData *)ep_decryptAES128CBC:(NSString *)key iv:(NSString *)iv {
    return [self ep_aes128Operation:kCCDecrypt key:key iv:iv ecb:false];
}

//Used internally. Encrypts or Decrypts based on CCOperation
- (NSData *)ep_aes128Operation:(CCOperation)operation key:(NSString *)key iv:(NSString *)iv ecb:(BOOL) ecb {
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
    CCCryptorStatus cryptStatus;
    if (ecb) {
        cryptStatus = CCCrypt(operation, kCCAlgorithmAES128, kCCOptionPKCS7Padding | kCCOptionECBMode, keyPtr,  kCCBlockSizeAES128, ivPtr, [self bytes], dataLength, buffer, bufferSize, &numBytesEncrypted);
    } else {
        cryptStatus = CCCrypt(operation, kCCAlgorithmAES128, kCCOptionPKCS7Padding, keyPtr,  kCCBlockSizeAES128, ivPtr, [self bytes], dataLength, buffer, bufferSize, &numBytesEncrypted);
    }
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}

@end
