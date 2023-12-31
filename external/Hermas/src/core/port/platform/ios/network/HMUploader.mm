//
//  HMUploader.m
//  Hermas
//
//  Created by 崔晓兵 on 6/1/2022.
//

#import "HMUploader.h"
#import "HMURLSessionManager.h"
#import "HMRequestMonitor.h"
#import "HMConfig.h"
#import "HMTools.h"
#include "env.h"
#import <CommonCrypto/CommonCryptor.h>

static NSData *HMDAES128Operation(NSData *data, CCOperation operation, NSString *key, NSString *iv) {
    char keyPtr[kCCKeySizeAES128 + 1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    char ivPtr[kCCBlockSizeAES128 + 1];
    bzero(ivPtr, sizeof(ivPtr));
    if (iv) {
        [iv getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
    }
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(operation,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr,
                                          kCCBlockSizeAES128,
                                          ivPtr,
                                          [data bytes],
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
    
    
static id payloadWithDecryptData(NSData *data, NSString *key, NSString *iv) {
    if (!data || !key) {
        return nil;
    }
    NSData *base64DecodeData = [[NSData alloc] initWithBase64EncodedData:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSData *decryptedData = HMDAES128Operation(base64DecodeData, kCCDecrypt, key, iv);
    NSString *decryptString = [[NSString alloc] initWithData:decryptedData encoding:NSASCIIStringEncoding];
    NSRange range = [decryptString rangeOfString:@"$"];
    if (range.location == NSNotFound || range.location + range.length > decryptString.length) {
        return nil;
    }
    NSString *jsonString = [decryptString substringToIndex:range.location];
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:NSJSONReadingAllowFragments
                                                           error:&error];
    if (error || !json) {
        return nil;
    } else {
        return json;
    }
}

namespace hermas {

id<HMNetworkProtocol> HMUploader::m_customNetworkManager;

void HMUploader::RegisterCustomNetworkManager(id<HMNetworkProtocol> networkManager) {
    m_customNetworkManager = networkManager;
}

id<HMNetworkProtocol> HMUploader::GetNetworkManager() {
    id<HMNetworkProtocol> impl;
    BOOL useURLSessionUplod = GlobalEnv::GetInstance().GetUseURLSessionUpload();
    impl = useURLSessionUplod ? GetURLSessionManager() : m_customNetworkManager;
    return impl;
}

id<HMNetworkProtocol> HMUploader::GetURLSessionManager() {
    static dispatch_once_t onceToken;
    static id<HMNetworkProtocol> urlSessionManager;
    dispatch_once(&onceToken, ^{
        urlSessionManager = [[HMURLSessionManager alloc] init];
    });
    return urlSessionManager;
}

HMUploader::HMUploader() {
}

HMUploader::~HMUploader() {
}

std::shared_ptr<ResponseStruct> HMUploader::Upload(RequestStruct& request) {
    @autoreleasepool {
        NSLog(@"url: %s, data: %s", request.url.c_str(), request.request_data.c_str());
        HMRequestModel *model = [[HMRequestModel alloc] init];
        model.method = [NSString stringWithUTF8String:request.method.c_str()];
        model.requestURL = [NSString stringWithUTF8String:request.url.c_str()];
        model.postData = [NSData dataWithBytes:request.request_data.c_str() length:request.request_data.length()];
        model.headerField = @{}.mutableCopy;
        model.needEcrypt = request.need_encrypt ? YES : NO;
        for (auto& iter : request.header_field) {
            NSString *key = [NSString stringWithUTF8String:iter.first.c_str()];
            NSString *value = [NSString stringWithUTF8String:iter.second.c_str()];
            [model.headerField setValue:value forKey:key];
        }
        
        std::shared_ptr<hermas::HMRequestMonitor> monitor = std::make_shared<hermas::HMRequestMonitor>();
        JSONFinishBlock block = ^(NSError * _Nonnull error, id maybeDictionary) {
            @autoreleasepool {
                NSLog(@"URL = %@, data = %@", model.requestURL, maybeDictionary);
                if (error) {
                    monitor->GetResponse()->code = (int)error.code;
                } else {
                    NSDictionary *decryptedDict = nil;
                    NSInteger statusCode = error ? error.code : 0;
                    
                    if ([maybeDictionary isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *result = [maybeDictionary valueForKey:@"result"];
                        NSString *base64String = [result valueForKey:@"data"];
                        if (base64String.length > 0) {
                            NSData *encyptedData = [base64String dataUsingEncoding:NSUTF8StringEncoding];
                            //ran is the key for aes
                            NSString *ran = [maybeDictionary valueForKey:@"ran"];
                            if(ran != nil && [ran isKindOfClass:[NSString class]]){
                                decryptedDict = payloadWithDecryptData(encyptedData, ran, ran);
                            }
                        }
                        
                        // if decryptDict is empty, set it to result
                        if (!decryptedDict) {
                            decryptedDict = [maybeDictionary valueForKey:@"result"];
                        }
                        statusCode = [[maybeDictionary valueForKey:@"status_code"] integerValue];
                    }
                    monitor->GetResponse()->code = statusCode;
                    monitor->GetResponse()->response_data = stringWithDictionary(decryptedDict).UTF8String;
                }
                monitor->SignalDone(true);
            }
        };
        [GetNetworkManager() requestWithModel:model callback:block];
        monitor->WaitForDone();
        return monitor->GetResponse();
    }
}

void HMUploader::UploadSuccess(const std::string& module_id) {
    @autoreleasepool {
        NSString *moduleId = [NSString stringWithUTF8String:module_id.c_str()];
        [[NSNotificationCenter defaultCenter] postNotificationName:kModuleUploadSuccess object:nil userInfo:@{@"moduleId" : moduleId}];
    }
}

void HMUploader::UploadFailure(const std::string& module_id) {
    
}



}
