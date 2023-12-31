//
//  TMAPluginFileSystemCustomImpl.m
//  TTMicroApp-Example
//
//  Created by yinyuan on 2019/1/8.
//  Copyright © 2019 muhuai. All rights reserved.
//

#import "TMAPluginFileSystemCustomImpl.h"
#import "EERoute.h"
#import "EMAAppEngine.h"
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <TTMicroApp/BDPTimorClient+Business.h>
#import <OPFoundation/OPFoundation-Swift.h>

@interface TMAPluginFileSystemCustomImpl () <BDPFileSystemPluginDelegate>

@end

@implementation TMAPluginFileSystemCustomImpl

#pragma mark - TMAPluginFileSystemDelegate
+ (id<BDPFileSystemPluginDelegate>)sharedPlugin
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (NSString *)bdp_documentRootDirectoryWithCustomAccountToken:(NSString * _Nullable)accountToken {
    // 设置支持多用户存储的小程序相关文件存放路径
    NSString *accountTokenName;
    if (!BDPIsEmptyString(accountToken)) {
        accountTokenName = accountToken;
    }else {
        accountTokenName = [self accountTokenDirecrotyName];
    }
    NSString *path = kTimorRootDir;
    NSString *dstDir = [path stringByAppendingPathComponent:accountTokenName];
    return dstDir;
}

- (NSString *)accountTokenDirecrotyName {
    return EMAAppEngine.currentEngine.account.accountToken;
}

@end
