//
//  IESMacros.h
//  Aweme
//
//  Created by willorfang on 16/8/8.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

//同步-慎用
#ifndef aweme_dispatch_queue_sync_safe
#define aweme_dispatch_queue_sync_safe(queue, block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
    block();\
} else {\
    dispatch_sync(queue, block);\
}
#endif

//异步-
#ifndef aweme_dispatch_queue_async_safe
#define aweme_dispatch_queue_async_safe(queue, block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
    block();\
} else {\
    dispatch_async(queue, block);\
}
#endif

#ifndef aweme_dispatch_main_async_safe
#define aweme_dispatch_main_async_safe(block) aweme_dispatch_queue_async_safe(dispatch_get_main_queue(), block)
#endif

#ifndef isEmptyString
#define isEmptyString(str) (!str || ![str isKindOfClass:[NSString class]] || str.length == 0)
#endif

#ifndef BTD_isEmptyString
#define BTD_isEmptyString(param)        ( !(param) ? YES : ([(param) isKindOfClass:[NSString class]] ? (param).length == 0 : NO) )
#endif

#ifndef BTD_isEmptyArray
#define BTD_isEmptyArray(param)         ( !(param) ? YES : ([(param) isKindOfClass:[NSArray class]] ? (param).count == 0 : NO) )
#endif

#ifndef btd_keywordify
#if DEBUG
#define btd_keywordify autoreleasepool {}
#else
#define btd_keywordify try {} @catch (...) {}
#endif
#endif

#ifndef AWEBLOCK_INVOKE
#define AWEBLOCK_INVOKE(block, ...) (block ? block(__VA_ARGS__) : 0)
#endif

#ifndef weakify
#if __has_feature(objc_arc)
#define weakify(object) btd_keywordify __weak __unused __typeof__(object) weak##_##object = object;
#else
#define weakify(object) btd_keywordify __block __unused __typeof__(object) block##_##object = object;
#endif
#endif

#ifndef strongify
#if __has_feature(objc_arc)
#define strongify(object) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    btd_keywordify __unused __typeof__(object) object = weak##_##object; \
    _Pragma("clang diagnostic pop")
#else
#define strongify(object) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    btd_keywordify __unused __typeof__(object) object = block##_##object; \
    _Pragma("clang diagnostic pop")
#endif
#endif

#ifndef onExit
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wunused-function"
static void blockCleanUp(__strong void(^*block)(void))
{
    (*block)();
}
#pragma clang diagnostic pop

#define onExit \
        btd_keywordify __strong void(^block)(void) __attribute__((cleanup(blockCleanUp), unused)) = ^

#endif


#ifndef AWE_MUTEX_LOCK
#define AWE_MUTEX_LOCK(lock) \
pthread_mutex_lock(&(lock)); \
@onExit{ \
pthread_mutex_unlock(&(lock)); \
};
#endif

#ifndef DYNAMIC_PROPERTY_OBJECT
#define DYNAMIC_PROPERTY_OBJECT(_getter_, _setter_, _association_, _type_) \
- (void)_setter_ : (_type_)object { \
[self willChangeValueForKey:@#_getter_]; \
objc_setAssociatedObject(self, _cmd, object, OBJC_ASSOCIATION_ ## _association_); \
[self didChangeValueForKey:@#_getter_]; \
} \
- (_type_)_getter_ { \
return objc_getAssociatedObject(self, @selector(_setter_:)); \
}
#endif
