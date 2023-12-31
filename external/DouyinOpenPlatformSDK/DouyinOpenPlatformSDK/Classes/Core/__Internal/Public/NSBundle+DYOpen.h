//
//  NSBundle+DYOpen.h
//  DouyinOpenPlatformSDK
//
//  Created by arvitwu on 2022/9/23.
//

#import <Foundation/Foundation.h>
#import "DYOpenInternalConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (DYOpen)

/// 通过 type 获取 bundle 实例
+ (nullable NSBundle *)dyopen_bundleWithType:(DYOpenResourceBundleType)type;

@end

NS_ASSUME_NONNULL_END
