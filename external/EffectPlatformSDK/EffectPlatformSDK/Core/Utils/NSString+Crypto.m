//
//  NSString+Crypto.m
//  AAWELaunchOptimization-Pods
//
//  Created by ZhangYuanming on 2020/7/31.
//

#import "NSString+Crypto.h"
#import "NSData+Crypto.h"

@implementation NSString (Crypto)

// 加密
- (NSString *)ep_aes256_encrypt:(NSString *)key {
    
    const char *cstr = [self cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:self.length];
    //对数据进行加密
    NSData *result = [data ep_aes256_encrypt:key];
    
    //转换为2进制字符串
    if (result && result.length > 0) {
        
        Byte *datas = (Byte*)[result bytes];
        NSMutableString *output = [NSMutableString stringWithCapacity:result.length * 2];
        for(int i = 0; i < result.length; i++){
            [output appendFormat:@"%02x", datas[i]];
        }
        return output;
    }
    return nil;
}


// 解密
-(NSString *)ep_aes256_decrypt:(NSString *)key {
    
//    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    //转换为2进制Data
    NSMutableData *data = [NSMutableData dataWithCapacity:self.length / 2];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [self length] / 2; i++) {
        byte_chars[0] = [self characterAtIndex:i*2];
        byte_chars[1] = [self characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }

    //对数据进行解密
    NSData* result = [data ep_aes256_decrypt:key];
    if (result && result.length > 0) {
        
        return [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    }
    return nil;
}

- (NSString *)ep_aes256DecryptFromBase64WithKey:(NSString *)key {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:self options:NSDataBase64DecodingIgnoreUnknownCharacters];

    //对数据进行解密
    NSData* result = [data ep_aes256_decrypt:key];
    if (result && result.length > 0) {
        
        return [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    }
    return nil;
}

#pragma mark - AES 128

- (NSString *)ep_encryptAES128ECB:(NSString *)key {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *result = [data ep_encryptAES128ECB:key];
    
//    if (result && result.length > 0) {
//        return [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
//    }
    
    //转换为2进制字符串
    if (result && result.length > 0) {
        
        Byte *datas = (Byte*)[result bytes];
        NSMutableString *output = [NSMutableString stringWithCapacity:result.length * 2];
        for(int i = 0; i < result.length; i++){
            [output appendFormat:@"%02x", datas[i]];
        }
        return output;
    }
    
    return nil;
}

//Call this to Decrypt with ECB Cipher Transformation mode. Iv is not required for ECB
- (NSString *)ep_decryptAES128ECB:(NSString *)key {
//    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    
    //转换为2进制Data
    NSMutableData *data = [NSMutableData dataWithCapacity:self.length / 2];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [self length] / 2; i++) {
        byte_chars[0] = [self characterAtIndex:i*2];
        byte_chars[1] = [self characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    
    NSData *result = [data ep_decryptAES128ECB:key];
    if (result && result.length > 0) {
        return [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}


- (NSString *)ep_encryptAES128CBC:(NSString *)key {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
        
    NSData *result = [data ep_encryptAES128CBC:key iv: @""];
        
    //    if (result && result.length > 0) {
    //        return [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    //    }
        
    //转换为2进制字符串
    if (result && result.length > 0) {
        
        Byte *datas = (Byte*)[result bytes];
        NSMutableString *output = [NSMutableString stringWithCapacity:result.length * 2];
        for(int i = 0; i < result.length; i++){
            [output appendFormat:@"%02x", datas[i]];
        }
        return output;
    }
    
    return nil;
}

//Call this to Decrypt with ECB Cipher Transformation mode. Iv is not required for ECB
- (NSString *)ep_decryptAES128CBC:(NSString *)key {
    
    //转换为2进制Data
    NSMutableData *data = [NSMutableData dataWithCapacity:self.length / 2];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [self length] / 2; i++) {
        byte_chars[0] = [self characterAtIndex:i*2];
        byte_chars[1] = [self characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    
    NSData *result = [data ep_decryptAES128CBC:key iv: @""];
    if (result && result.length > 0) {
        return [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (NSString *)ep_aes128CBCDecryptFromBase64WithKey:(NSString *)key iv:(NSString *)iv {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:self options:0];

    NSData *result = [data ep_decryptAES128CBC:key iv: iv];
    if (result && result.length > 0) {
        NSString *output = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
        return output;
    }
    return nil;
}

@end
