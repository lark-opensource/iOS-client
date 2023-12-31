//
//  BDImageConfigUtil.m
//  BDWebImageToB
//
//  Created by 陈奕 on 2020/6/22.
//

#import "BDImageConfigUtil.h"
#import "BDWebImageCompat.h"
#import "BDImageConfigConstants.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation BDImageConfigUtil

#pragma mark - NetWork

+ (void)networkAsyncRequestForURL:(NSString *)requestURL
                           headers:(NSDictionary *)headerField
                           method:(NSString *)method
                            queue:(dispatch_queue_t)queue
                         callback:(BDImageNetworkFinishBlock)callback {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestURL]];
    [request setHTTPMethod:method];
    [request setTimeoutInterval:15];
    if (headerField.count > 0) {
        [headerField enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }
    dispatch_async(queue ?: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *taskData, NSURLResponse *taskResponse, NSError *taskError) {
            if (callback) {
                NSDictionary *result = [self responseData:(NSHTTPURLResponse *)taskResponse data:taskData error:taskError];
                dispatch_async(queue ?: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    callback(taskError, result);
                });
            }
        }] resume];
    });
}

+ (NSDictionary *)defalutHeaderFieldWithAppId:(NSString *)appid {
    NSMutableDictionary *headerFiled = [NSMutableDictionary new];
    [headerFiled setValue:@"application/json; encoding=utf-8" forKey:@"Content-Type"];
    [headerFiled setValue:@"application/json" forKey:@"Accept"];
    [headerFiled setValue:@"keep-alive" forKey:@"Connection"];
    NSString *aid = [appid mutableCopy];
    [headerFiled setValue:aid forKey:kBDImageAid];

    return headerFiled;
}

+ (NSString *)commonParametersWithAppId:(NSString *)appid {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result setValue:BDWebImageSDKVersion()  forKey:kBDImageSDKVersion];       
    [result setValue:@"iOS" forKey:kBDImageOS];
    [result setValue:[[UIDevice currentDevice] systemVersion] forKey:kBDImageOSVersion];
    [result setValue:[self sandboxReleaseVersion] forKey:kBDImageAppVersion];
    [result setValue:appid forKey:kBDImageAid];
    NSMutableArray *keyValuePairs = [NSMutableArray array];
    NSCharacterSet *set = [self URLQueryAllowedCharacterSet];
    for (id key in result) {
        NSString *queryKey = [[key description] stringByAddingPercentEncodingWithAllowedCharacters:set];
        NSString *queryValue = [[result[key] description] stringByAddingPercentEncodingWithAllowedCharacters:set];

        [keyValuePairs addObject:[NSString stringWithFormat:@"%@=%@", queryKey, queryValue]];
    }

    return [keyValuePairs componentsJoinedByString:@"&"];
}

#pragma mark Verify Signature

+ (NSDictionary *)decodeWithBase64Str:(NSString *)base64Str {
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64Str options:0];
    NSError *err = nil;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:decodedData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if (err) {
        return nil;
    }
    if ([dic isKindOfClass:[NSDictionary class]]) {
        return dic;
    }
    return nil;
}

+ (NSString *)bdImageJSONRepresentation:(id)param {
    if (!param || ![NSJSONSerialization isValidJSONObject:param]) {
        return nil;
    }

    NSData *data = [NSJSONSerialization dataWithJSONObject:param
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

// verify Signature
+ (BOOL)verify:(NSString *)content signature:(NSString *)signature withPublicKey:(NSString *)publicKey {
    
    SecKeyRef publicKeyRef = [self addPublicKey:publicKey];
    if (!publicKeyRef) {
        return NO;
    }
    NSData *originData = [self sha256:content];
    NSData *signatureData = [[NSData alloc] initWithBase64EncodedString:signature options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!originData || !signatureData) {
        return NO;
    }
    OSStatus status =  SecKeyRawVerify(publicKeyRef, kSecPaddingPKCS1SHA256, [originData bytes], originData.length, [signatureData bytes], signatureData.length);
    
    if (status ==noErr) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark Private

+ (NSDictionary *)responseData:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *)error {
    NSMutableDictionary *rs = [NSMutableDictionary new];
    NSInteger statusCode = response.statusCode;
    /// 小于 100 非法
    if (statusCode > 99) {
        [rs setValue:@(statusCode) forKey:kBDImageStatusCode];
    }
    if (!error) {
        @try {
            NSDictionary * jsonObj = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:&error];
            if ([jsonObj isKindOfClass:[NSDictionary class]] && jsonObj.count > 0) {
                [rs addEntriesFromDictionary:jsonObj];
            }
        } @catch (NSException *exception) {
        } @finally {
        }
    }
    return rs;
}

+ (NSCharacterSet *)URLQueryAllowedCharacterSet {
    static NSCharacterSet *turing_set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *set = [NSMutableCharacterSet new];
        [set formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
        [set addCharactersInString:@"$-_.+!*'(),"];
        turing_set = set;
    });
    
    return turing_set;
}

+ (NSString *)sandboxReleaseVersion {
    static NSString *versionName = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        versionName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];;
    });
    
    return versionName;
}

+ (SecKeyRef)addPublicKey:(NSString *)pubKey {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:pubKey options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    //a tag to read/write keychain storage
    NSString *tag = @"RSA_PUBLIC_KEY";
    NSData *d_tag = [NSData dataWithBytes:[tag UTF8String] length:[tag length]];
    
    // Delete any old lingering key with the same tag
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(__bridge id) kSecClassKey forKey:(__bridge id)kSecClass];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [publicKey setObject:d_tag forKey:(__bridge id)kSecAttrApplicationTag];
    SecItemDelete((__bridge CFDictionaryRef)publicKey);
    
    // Add persistent version of the key to system keychain
    [publicKey setObject:data forKey:(__bridge id)kSecValueData];
    [publicKey setObject:(__bridge id) kSecAttrKeyClassPublic forKey:(__bridge id)kSecAttrKeyClass];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnPersistentRef];
    
    CFTypeRef persistKey = nil;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)publicKey, &persistKey);
    if (persistKey != nil){
        CFRelease(persistKey);
    }
    
    if ((status != noErr) && (status != errSecDuplicateItem)) { return nil; }
    
    [publicKey removeObjectForKey:(__bridge id)kSecValueData];
    [publicKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    // Now fetch the SecKeyRef version of the key
    SecKeyRef keyRef = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)publicKey, (CFTypeRef *)&keyRef);
    if(status != noErr){
        return nil;
    }
    return keyRef;
}

// digest message with sha256
+ (NSData *)sha256:(NSString *)str {
    const void *data = [str cStringUsingEncoding:NSUTF8StringEncoding];
    CC_LONG len = (CC_LONG)strlen(data);
    uint8_t * md = malloc( CC_SHA256_DIGEST_LENGTH * sizeof(uint8_t));
    CC_SHA256(data, len, md);
    NSData *result = [NSData dataWithBytes:md length:CC_SHA256_DIGEST_LENGTH];
    free(md);
    return result;
}
@end
