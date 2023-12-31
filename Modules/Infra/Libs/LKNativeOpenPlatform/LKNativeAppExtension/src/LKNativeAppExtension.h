//
//  LKNativeAppExtension.h
//  LKNativeAppExtension
//
//  Created by Bytedance on 2021/12/17.
//  Copyright © 2021 Bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LKNativeAppSec "LKNativeAppSec"
#define LKNativeAppExtensionDATA(sectname) __attribute((used, section("__DATA,"#sectname" ")))
#define LKNativeAppExtension(name,appId,preLaunch) \
class NSObject;char * k##name##_mod LKNativeAppExtensionDATA(LKNativeAppSec) = "{ \"name\" : \""#name"\", \"appId\" : \""#appId"\", \"preLaunch\" : \""#preLaunch"\"}";

NS_ASSUME_NONNULL_BEGIN

@interface LKNativeAppExtension : NSObject

/// 初始化接口. override 后需要调用 super
- (instancetype)init NS_DESIGNATED_INITIALIZER __attribute__((objc_requires_super));

/// 
- (void)destroy __attribute__((objc_requires_super));

/// 返回 extension 的 appId.
/// appId 为在飞书开放平台注册的应用
- (NSString *)appId;

@end

NS_ASSUME_NONNULL_END

