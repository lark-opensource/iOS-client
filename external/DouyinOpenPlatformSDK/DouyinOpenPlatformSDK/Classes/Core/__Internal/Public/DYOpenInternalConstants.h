//
//  DYOpenInternalConstants.h
//  DouyinOpenPlatformSDK
//
//  Created by ByteDance on 2022/8/25.
//
//  这个文件仅对内，对外的常量文件是 DouyinOpenSDKConstants.h

#ifndef DYOPEN_CONSTANTS_H
#define DYOPEN_CONSTANTS_H
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@class DouyinOpenSDKAuthResponse;
 
/// bundle 资源，对应 podspec 里描述的 resource_bundles
typedef NS_ENUM(NSInteger, DYOpenResourceBundleType) {
    DYOpenResourceBundleTypeUnknown         = 0,
    DYOpenResourceBundleTypeMain            = 1, // [NSBundle mainBundle]
    DYOpenResourceBundleTypeAuth            = 2, // DYOpenAuth
    DYOpenResourceBundleTypeFollow          = 3, // DYOpenFollow
    DYOpenResourceBundleTypeProfileGeneral  = 4, // DYOpenProfileGeneral
    DYOpenResourceBundleTypeProfileMLBB     = 5, // DYOpenProfileMLBB
    DYOpenResourceBundleTypePhone           = 6, // DYOpenPhone
};

/// 动态添加属性
#ifndef DYOPEN_DYNAMIC_PROPERTY_OBJECT
#define DYOPEN_DYNAMIC_PROPERTY_OBJECT(_getter_, _setter_, _association_, _type_) \
- (void)_setter_ : (_type_)object { \
    [self willChangeValueForKey:@#_getter_]; \
    objc_setAssociatedObject(self, _cmd, object, OBJC_ASSOCIATION_ ## _association_); \
    [self didChangeValueForKey:@#_getter_]; \
} \
- (_type_)_getter_ { \
    return objc_getAssociatedObject(self, @selector(_setter_:)); \
}
#endif

#ifndef DYOPEN_DYNAMIC_PROPERTY_WEAK_OBJECT
#define DYOPEN_DYNAMIC_PROPERTY_WEAK_OBJECT(_getter_, _setter_, _type_) \
- (void)_setter_ : (_type_)object { \
    [self willChangeValueForKey:@#_getter_]; \
    id __weak weakObject = object; \
    id (^block)() = ^{ return weakObject; }; \
    objc_setAssociatedObject(self, _cmd, block, OBJC_ASSOCIATION_COPY); \
    [self didChangeValueForKey:@#_getter_]; \
} \
- (_type_)_getter_ { \
    id (^block)() = objc_getAssociatedObject(self, @selector(_setter_:)); \
    id object = (block ? block() : nil); \
    return object; \
}
#endif

#ifndef DYOPEN_DYNAMIC_PROPERTY_NUMBER
#define DYOPEN_DYNAMIC_PROPERTY_NUMBER(_getter_, _setter_, _type_, _numberValue_) \
- (void)_setter_ : (_type_)number { \
    [self willChangeValueForKey:@#_getter_]; \
    objc_setAssociatedObject(self, _cmd, @(number), OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
    [self didChangeValueForKey:@#_getter_]; \
} \
- (_type_)_getter_ { \
    return [objc_getAssociatedObject(self, @selector(_setter_:)) _numberValue_]; \
}
#endif


#endif
