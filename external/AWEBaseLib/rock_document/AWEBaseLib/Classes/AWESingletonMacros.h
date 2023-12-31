//
//  AWESingletonMacros.h
//  AWEFoundation
//
//  Created by Stan Shan on 2018/5/31.
//  Copyright © 2018 bytedance. All rights reserved.
//

#ifndef AWESingletonMacros_h
#define AWESingletonMacros_h

// 在.h文件中声明单例
#undef  AWE_DECLARE_SINGLETON
#define AWE_DECLARE_SINGLETON \
+ (instancetype)sharedInstance;

// 在.m文件中实现单例
#undef  AWE_DEFINE_SINGLETON
#define AWE_DEFINE_SINGLETON( __class ) \
static __class * __singleton__ = nil; \
+ (instancetype)sharedInstance \
{ \
static dispatch_once_t once; \
dispatch_once( &once, ^{ __singleton__ = [[__class alloc] init]; } ); \
return __singleton__; \
} \
+ (instancetype)allocWithZone:(struct _NSZone *)zone \
{ \
static dispatch_once_t once; \
dispatch_once(&once, ^{ __singleton__ = [super allocWithZone:zone]; } ); \
return __singleton__; \
} \
- (instancetype)copyWithZone:(NSZone*)zone \
{ \
    return self; \
} \
- (instancetype)mutableCopyWithZone:(NSZone *)zone \
{ \
    return self; \
}

#endif
