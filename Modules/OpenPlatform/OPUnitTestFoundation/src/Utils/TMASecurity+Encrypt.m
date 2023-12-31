//
//  TMASecurity+Encrypt.m
//  OPUnitTestFoundation
//
//  Created by baojianjun on 2023/7/20.
//

#import "TMASecurity+Encrypt.h"
#import <OPFoundation/NSData+BDPExtension.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonCryptor.h>

static NSErrorDomain const kCocoaSecurityDomian = @"Cocoa Security";

@implementation NSData(Encrypt)

- (nullable NSData *)tma_aesEncrypt:(NSData *)key iv:(NSData *)iv error:(NSError **)error {
    if (!self.length) {
        return nil;
    }
    // check length of key and iv
    if ([iv length] != 16) {
        NSDictionary *userInfo = @{
            NSLocalizedFailureReasonErrorKey: @"Length of iv is wrong. Length of iv should be 16(128bits)"
        };
        *error = [[NSError alloc] initWithDomain:kCocoaSecurityDomian code:-1 userInfo:userInfo];
        return nil;
    }
    if ([key length] != 16 && [key length] != 24 && [key length] != 32 ) {
        NSDictionary *userInfo = @{
            NSLocalizedFailureReasonErrorKey: @"Length of key is wrong. Length of iv should be 16, 24 or 32(128, 192 or 256bits)"
        };
        *error = [[NSError alloc] initWithDomain:kCocoaSecurityDomian code:-1 userInfo:userInfo];
        return nil;
    }
    
    // setup output buffer
    size_t bufferSize = [self length] + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    // do encrypt
    size_t encryptedSize = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
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
        NSDictionary *userInfo = @{
            NSLocalizedFailureReasonErrorKey: @"Decrypt Error!"
        };
        *error = [[NSError alloc] initWithDomain:kCocoaSecurityDomian code:-1 userInfo:userInfo];
        return nil;
    }
}
@end
