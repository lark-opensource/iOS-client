//
//   DVEGlobalExternalInjectProtocol.h
//   NLEEditor
//
//   Created  by ByteDance on 2021/9/10.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import <Foundation/Foundation.h>
#import "DVEToastProtocol.h"
#import "DVEAlertProtocol.h"
#import "DVELoadingProtocol.h"
#import "DVELoggerProtocol.h"
#import <DVEFoundationKit/DVEResourceManagerProtocol.h>

NS_ASSUME_NONNULL_BEGIN

// 实现该协议所注入的对象的生命周期与 APP 绑定
@protocol DVEGlobalExternalInjectProtocol <DVEResourceManagerProtocol>

@optional

/// 草稿存放根目录
- (NSString *)draftFolderPath;

/// UI配置文件和icon资源存放的bundle
- (NSBundle *)customResourceProvideBundle;

/// 定制 Alert 提示框
- (id<DVEAlertProtocol>)provideAlert;

/// 定制 Toast 提示
- (id<DVEToastProtocol>)provideToast;

/// 定制 Loading 提示
- (id<DVELoadingProtocol>)provideLoading;

/// 日志能力
- (id<DVELoggerProtocol>)provideDVELogger;

/// 国际化字符串转换
/// @param key 字符key
/// @return 如果不需要转换则返回nil
- (NSString*)covertStringWithKey:(NSString*)key;

@end

NS_ASSUME_NONNULL_END
