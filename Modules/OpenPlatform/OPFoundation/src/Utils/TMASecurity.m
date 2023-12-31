//
//  TMASecurity.m
//  Timor
//
//  Created by muhuai on 2018/4/8.
//

#import "TMASecurity.h"
#import "NSData+BDPExtension.h"
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonCryptor.h>
#import <ECOInfra/OPError.h>
#import <OPFoundation/OPFoundation-Swift.h>

@implementation NSData(tma_security)

- (NSData *)tma_aesDecrypt:(NSData *)key iv:(NSData *)iv {
    if (!self.length) {
        return nil;
    }
    // check length of key and iv
    if ([iv length] != 16) {
        @throw [NSException exceptionWithName:@"Cocoa Security"
                                       reason:@"Length of iv is wrong. Length of iv should be 16(128bits)"
                                     userInfo:nil];
    }
    if ([key length] != 16 && [key length] != 24 && [key length] != 32 ) {
        @throw [NSException exceptionWithName:@"Cocoa Security"
                                       reason:@"Length of key is wrong. Length of iv should be 16, 24 or 32(128, 192 or 256bits)"
                                     userInfo:nil];
    }
    
    // setup output buffer
    size_t bufferSize = [self length] + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    // do encrypt
    size_t encryptedSize = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          [key bytes],     // Key
                                          [key length],    // kCCKeySizeAES
                                          [iv bytes],       // IV
                                          [self bytes],
                                          [self length],
                                          buffer,
                                          bufferSize,
                                          &encryptedSize);
    if (cryptStatus == kCCSuccess) {
        NSData *result = [NSData dataWithBytes:buffer length:encryptedSize];
        free(buffer);
        return result;
    }
    else {
        free(buffer);
        @throw [NSException exceptionWithName:@"Cocoa Security"
                                       reason:@"Decrypt Error!"
                                     userInfo:nil];
        return nil;
    }
}
@end

@implementation NSString(tma_security)

- (NSData *)tma_aesDecrypt:(NSString *)key iv:(NSString *)iv {
    if (!self.length) {
        return nil;
    }
    NSData *encrypt = [NSData ss_dataWithBase64EncodedString:self];
    
    NSData *result = nil;
    @try {
        result = [encrypt tma_aesDecrypt:[key dataUsingEncoding:NSUTF8StringEncoding]
                                      iv:[iv dataUsingEncoding:NSUTF8StringEncoding]];
    } @catch (NSException *exception) {
        NSString *errorMessage = [NSString stringWithFormat:@"aesDecrypt exception(name(%@), reason(%@)) for string(%@) with key(%@) & iv(%@)", exception.name, exception.reason, self, key, iv];
        OPErrorWithMsg(CommonMonitorCode.encrypt_decrypt_failed, errorMessage);
        result = nil;
    }
    
    return result;
}
@end
