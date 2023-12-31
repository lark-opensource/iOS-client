//
//  TTSmallAppStorage.m
//  TTRexxar
//
//  Created by muhuai on 2017/11/24.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import "TMAPluginStorage.h"
#import <ECOInfra/NSString+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPRouteMediator.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <TTMicroApp/OPAPIDefine.h>

#define kPrivateStorageKeyPrefix @"jssdk_storage."

/// 定义本文件内的error log tag
#define kLogTagName BDPTag.storageAPI

@implementation TMAPluginStorage

/**
 JSSDK基础库使用的storage接口，仅用于基础库自己进行私有缓存，不对CP开放，
 考虑到不与cp的存储混淆，因此存放到sandbox的privageStorate里面
 协议文档：https://bytedance.feishu.cn/space/doc/doccnVl55PRzlroCr2ahkdbFgjb
 */
- (void)operateInternalStorageSyncWithParam:(NSDictionary * _Nullable)param
                                   callback:(BDPJSBridgeCallback _Nullable)callback
                                    context:(BDPPluginContext _Nullable)context {
    NSString *type = [param bdp_stringValueForKey:@"type"];
    OPAppUniqueID *uniqueID = context.engine.uniqueID;
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, uniqueID.appType);
    id<BDPSandboxProtocol> sandbox = [storageModule sandboxForUniqueId:uniqueID];
    if (!sandbox) {
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeUnknown, @"sandbox not found");
        return;
    }
    if ([type isEqualToString:@"get"]) {
        [self getPrivateStorageWithParam:param callback:callback uniqueId:uniqueID sandbox:sandbox];
    } else if ([type isEqualToString:@"set"]) {
        [self setPrivateStorageWithParam:param callback:callback uniqueId:uniqueID sandbox:sandbox];
    } else if ([type isEqualToString:@"remove"]) {
        [self removePrivateStorageWithParam:param callback:callback uniqueId:uniqueID sandbox:sandbox];
    } else if ([type isEqualToString:@"clear"]) {
        [self clearPrivateStorageWithParam:param callback:callback uniqueId:uniqueID sandbox:sandbox];
    } else if ([type isEqualToString:@"getInfo"]) {
        [self getPrivateStorageInfoWithParam:param callback:callback uniqueId:uniqueID sandbox:sandbox];
    } else {
        NSString *errorMessage = @"type invalid";
        BDPLogTagError(kLogTagName, BDPParamStr(uniqueID, errorMessage));
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, errorMessage)
    }
}

#pragma mark - private methond

- (void)setPrivateStorageWithParam:(NSDictionary *)param
                          callback:(BDPJSBridgeCallback)callback
                          uniqueId:(OPAppUniqueID * _Nullable)uniqueId
                           sandbox:(id<BDPSandboxProtocol>)sandbox {
    // 写入数据
    NSString *key = [self convertToStorageKey:[param bdp_stringValueForKey:@"key"]];
    NSString *data = [param bdp_stringValueForKey:@"data"];
    NSString *dataType = [param bdp_stringValueForKey:@"dataType"];
    // 检查本地存储限制
    NSUInteger dataSizeMB = [data lengthOfBytesUsingEncoding:NSUTF8StringEncoding] / 1024.f / 1024.f;
    double storageSizeMB = ([sandbox.privateStorage storageSizeInBytes] / 1024.f) / 1024.f;
    double limitedSizeMB = ([sandbox.privateStorage limitSize] / 1024.f) / 1024.f;
    
    BOOL isWriteOK = NO;
    if (storageSizeMB + dataSizeMB <= limitedSizeMB &&
        key.length && data.length && dataType.length) {
        isWriteOK = [sandbox.privateStorage setObject:@{@"data": data, @"dataType": dataType}
                                                      forKey:key];
    }
    if (isWriteOK) {
        BDP_CALLBACK_SUCCESS
    } else {
        NSString *errorMessage = @"privateStorage setObject failed or storage size illegal";
        BDPLogTagError(kLogTagName, BDPParamStr(uniqueId, errorMessage, key, dataType, storageSizeMB, dataSizeMB, limitedSizeMB));
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, errorMessage)
    }
}

// 读取数据
- (void)getPrivateStorageWithParam:(NSDictionary *)param
                          callback:(BDPJSBridgeCallback)callback
                          uniqueId:(OPAppUniqueID * _Nullable)uniqueId
                           sandbox:(id<BDPSandboxProtocol>)sandbox {
    NSString *key = [self convertToStorageKey:[param bdp_stringValueForKey:@"key"]];
    id object = [sandbox.privateStorage objectForKey:key];
    if (object) {
        BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeSuccess, [object isKindOfClass:[NSDictionary class]]? object: @{})
    } else {
        NSString *apiErrMsg = [NSString stringWithFormat:@"data not found, key == %@", [self convertToJSSDKKey:key]];
        object = @{@"data": @"", @"dataType": @"string", @"errMsg": apiErrMsg};
        BDPLogTagWarn(kLogTagName, @"getPrivateStorage success with %@", BDPParamStr(uniqueId));
        BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeFailed, object)
    }
}

// 删除数据
- (void)removePrivateStorageWithParam:(NSDictionary *)param
                             callback:(BDPJSBridgeCallback)callback
                             uniqueId:(OPAppUniqueID * _Nullable)uniqueId
                              sandbox:(id<BDPSandboxProtocol>)sandbox {
    NSString *key = [self convertToStorageKey:[param bdp_stringValueForKey:@"key"]];
    if ([sandbox.privateStorage removeObjectForKey:key]) {
        BDP_CALLBACK_SUCCESS
    } else {
        NSString *errMsg = [NSString stringWithFormat: @"privateStorage removeObjectForKey failed, key: %@", BDPSafeString(key)];
        BDPLogTagError(kLogTagName, BDPParamStr(uniqueId, errMsg));
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, errMsg)
    }
}

// 清除缓存，只清除带有前缀的数据
- (void)clearPrivateStorageWithParam:(NSDictionary *)param
                            callback:(BDPJSBridgeCallback)callback
                            uniqueId:(OPAppUniqueID * _Nullable)uniqueId
                             sandbox:(id<BDPSandboxProtocol>)sandbox {
    NSArray *allKeys = [sandbox.privateStorage allKeys];
    BOOL isOK = YES;
    for (NSString *key in allKeys) {
        if ([key hasPrefix:kPrivateStorageKeyPrefix]) {
            // 这里对数据库的操作，可能会有点耗时？
            if (![sandbox.privateStorage removeObjectForKey:key]) {
                isOK = NO;
            };
        }
    }
    if (isOK) {
        BDP_CALLBACK_SUCCESS
    } else {
        NSString *errorMessage = @"privateStorage removeObjectForKey failed";
        BDPLogTagError(kLogTagName, BDPParamStr(uniqueId, errorMessage));
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, errorMessage)
    }
}

// 清除存储信息
- (void)getPrivateStorageInfoWithParam:(NSDictionary *)param
                              callback:(BDPJSBridgeCallback)callback
                              uniqueId:(OPAppUniqueID * _Nullable)uniqueId
                               sandbox:(id<BDPSandboxProtocol>)sandbox {
    // 需要对key值进行转换，去除保存时自动添加的前缀
    NSArray *allkeys = [sandbox.privateStorage allKeys];
    NSMutableArray *jssdkKeys = [NSMutableArray array];
    for (NSString *key in allkeys) {
        NSString *actualKey = [self convertToJSSDKKey:key];
        if (actualKey.length) {
            [jssdkKeys addObject:actualKey];
        }
    }
    double currentSizeKB = [sandbox.privateStorage storageSizeInBytes] / 1024.f;
    double limitSizeKB = [sandbox.privateStorage limitSize] / 1024.f;
    NSDictionary *callBackDic = @{ @"keys": jssdkKeys? :@[],
                                   @"currentSize" : @(currentSizeKB),
                                   @"limitSize" : @(limitSizeKB) };
    BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeSuccess, callBackDic)
}

/**
 为了区分jssdk保存的数据，这里每个jssdk传过来的key值会加个前缀进行保存
 */
/// 转成保存时的key值
- (NSString *)convertToStorageKey:(NSString *)jssdkKey {
    if (!jssdkKey.length) {
        return nil;
    }
    return [kPrivateStorageKeyPrefix stringByAppendingString:jssdkKey];
}

/// 转成jssdk使用的key值
- (NSString *)convertToJSSDKKey:(NSString *)storageKey {
    if (![storageKey hasPrefix:kPrivateStorageKeyPrefix]) {
        return nil;
    }
    return [storageKey substringFromIndex:kPrivateStorageKeyPrefix.length];
}

@end
