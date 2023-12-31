//
//  HTSBundleLoader.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/17.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>

#ifndef __LP64__
typedef struct mach_header HTSMachHeader;
#else
typedef struct mach_header_64 HTSMachHeader;
#endif

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT void * _Nullable HTSGetLazyPointer(NSString * bundleName, NSString * symbolName);
FOUNDATION_EXPORT HTSMachHeader * _Nullable HTSGetMachHeader(NSString * bundleName);

@interface HTSBundleLoader : NSObject

/// 加载动态库
+ (BOOL)loadName:(NSString *)name;

/// 释放动态库
+ (void)unloadName:(NSString *)name;

+ (instancetype)sharedLoader;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
