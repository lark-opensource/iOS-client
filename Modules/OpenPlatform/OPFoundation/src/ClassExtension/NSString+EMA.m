//
//  NSString+EMA.m
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/19.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import "NSString+EMA.h"
#import "NSObject+BDPExtension.h"
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonCrypto.h>
#import <LKLoadable/Loadable.h>

#pragma GCC diagnostic ignored "-Wundeclared-selector"
LoadableMainFuncBegin(NSStringEMAAdditionSwizzle)
[NSString performSelector:@selector(bdp_string_adddition_swizzle)];
LoadableMainFuncEnd(NSStringEMAAdditionSwizzle)

@implementation NSString (EMAAddition)

+ (void)bdp_string_adddition_swizzle {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self bdp_swizzleOriginInstanceMethod:@selector(stringByAppendingPathComponent:) withHookInstanceMethod:@selector(ema_stringByAppendingPathComponent:)];
    });
}

- (NSString *)ema_stringByAppendingPathComponent:(NSString *)str {
    BOOL isURLPath = [self hasPrefix:@"http://"] || [self hasPrefix:@"https://"];
    NSAssert(!isURLPath, @"You should't use stringByAppendingPathComponent: for url path");
    if (isURLPath) {
        return [self ema_urlStringByAppendingPathComponent:str];
    }
    return [self ema_stringByAppendingPathComponent:str];
}

- (NSString *)ema_urlStringByAppendingPathComponent:(NSString *)path {
    NSString *result = self;
    if (path.length == 0) {
        return result;
    }

    result = [self ema_stringByAppendingPathComponent:path];
    NSString *wrongPrefix = @"http:/";
    NSString *rightPrefix = @"http://";
    if ([result hasPrefix:wrongPrefix] && ![result hasPrefix:rightPrefix]) {
        result = [result stringByReplacingOccurrencesOfString:wrongPrefix withString:rightPrefix options:0 range:NSMakeRange(0, wrongPrefix.length)];
    }
    wrongPrefix = @"https:/";
    rightPrefix = @"https://";
    if ([result hasPrefix:wrongPrefix] && ![result hasPrefix:rightPrefix]) {
        result = [result stringByReplacingOccurrencesOfString:wrongPrefix withString:rightPrefix options:0 range:NSMakeRange(0, wrongPrefix.length)];
    }
    return result;
}
    
- (NSString *)ema_base64Decode {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:self options:0];
    if (data != nil) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}

- (NSString *)ema_md5 {
    const char *cStr = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest );
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

- (NSString *)ema_sha256EncodeWithSalt:(NSString *)salt
{
    NSString *compose = salt.length > 0 ? [self stringByAppendingString:salt] : self;
    const char *cStr = [compose cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cStr length:compose.length];
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }

    return output.copy;
}

- (NSString *)ema_sha1 {
    const char *cstr = [self cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:self.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, data.length, digest);

    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }

    return output.copy;
}

- (BOOL)ema_hasPrefix:(NSString * _Nullable)str {
    if (!str) {
        return NO;
    }
    return [self hasPrefix:str];
}

@end
