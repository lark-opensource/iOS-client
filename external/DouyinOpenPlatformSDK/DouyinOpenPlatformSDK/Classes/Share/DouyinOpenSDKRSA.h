//
//  DouyinOpenSDKApiObject.m
//
//  Created by ByteDance on 18/9/2017.
//  Copyright (c) 2018年 ByteDance. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DYOpenIsEmptyString
    #undef DYOpenIsEmptyString
#endif
#define DYOpenIsEmptyString(str) \
(!str || ![str isKindOfClass:[NSString class]] || str.length == 0)

@interface DouyinOpenSDKRSA : NSObject

// return base64 encoded string
+ (NSString * _Nullable)douyin_encryptString:(NSString * _Nullable)str publicKey:(NSString * _Nullable)pubKey;
// return raw data
+ (NSData * _Nullable)douyin_encryptData:(NSData * _Nullable)data publicKey:(NSString * _Nullable)pubKey;
// return base64 encoded string
+ (NSString * _Nullable)douyin_encryptString:(NSString * _Nullable)str privateKey:(NSString * _Nullable)privKey;
// return raw data
+ (NSData * _Nullable)douyin_encryptData:(NSData * _Nullable)data privateKey:(NSString * _Nullable)privKey;

// decrypt base64 encoded string, convert result to string(not base64 encoded)
+ (NSString * _Nullable)douyin_decryptString:(NSString *_Nullable)str publicKey:(NSString *_Nullable)pubKey;
+ (NSData * _Nullable)douyin_decryptData:(NSData * _Nullable)data publicKey:(NSString * _Nullable)pubKey;
+ (NSString * _Nullable)douyin_decryptString:(NSString * _Nullable)str privateKey:(NSString * _Nullable)privKey;
+ (NSData * _Nullable)douyin_decryptData:(NSData * _Nullable)data privateKey:(NSString * _Nullable)privKey;

@end
