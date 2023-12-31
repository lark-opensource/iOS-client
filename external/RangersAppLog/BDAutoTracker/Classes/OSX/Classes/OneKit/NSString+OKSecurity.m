//
//  NSString+OKSecurity.m
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "NSString+OKSecurity.h"

@implementation NSString (OKSecurity)

- (NSString *)ok_aesEncryptWithkey:(NSString *)key
                            keySize:(OKAESKeySize)keySize
                                 iv:(NSString *)iv {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSData *result = [data ok_aesEncryptWithkey:key
                                         keySize:keySize
                                              iv:iv];

    return [result base64EncodedStringWithOptions:0];
}

- (NSString *)ok_aesDecryptwithKey:(NSString *)key
                            keySize:(OKAESKeySize)keySize
                                 iv:(NSString *)iv {
    
    NSData *data = [[NSData alloc] initWithBase64EncodedString:self
                                                       options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSData *result = [data ok_aesDecryptwithKey:key
                                         keySize:keySize
                                              iv:iv];
    if (result == nil) {
        return  nil;
    }

    return [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
}

@end
