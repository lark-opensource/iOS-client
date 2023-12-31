//
//  IWKUtils.h
//  BDWebCore
//
//  Created by li keliang on 2019/6/30.
//

#ifndef IWKUtils_h
#define IWKUtils_h

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

FOUNDATION_EXTERN BOOL IWKProtocolContainsSelector(Protocol* protocol, SEL sel);

FOUNDATION_EXTERN void IWKClassSwizzle(Class class, SEL originalSelector, SEL swizzledSelector);

FOUNDATION_EXTERN void IWKMetaClassSwizzle(Class class, SEL originalSelector, SEL swizzledSelector);

FOUNDATION_EXTERN NSMethodSignature *IWK_blockMethodSignature(id block);

typedef void (^IWK_cleanupBlock_t)(void);

#if defined(__cplusplus)
extern "C" {
#endif
    void IWK_executeCleanupBlock (__strong IWK_cleanupBlock_t *block);
#if defined(__cplusplus)
}
#endif

#define IWK_metamacro_concat_(A, B) \
    A ## B

#define IWK_metamacro_concat(A, B) \
    IWK_metamacro_concat_(A, B)


#if defined(DEBUG) && !defined(NDEBUG)
    #define IWK_keywordify autoreleasepool {}
#else
    #define IWK_keywordify try {} @catch (...) {}
#endif

#define IWK_onExit \
    IWK_keywordify \
    __strong IWK_cleanupBlock_t IWK_metamacro_concat(IWK_exitBlock_, __LINE__) __attribute__((cleanup(IWK_executeCleanupBlock), unused)) = ^


#ifndef IWK_BLOCK_INVOKE
#define IWK_BLOCK_INVOKE(block, ...) (block ? block(__VA_ARGS__) : 0)
#endif

#ifndef IWK_dispatch_queue_async_safe
#define IWK_dispatch_queue_async_safe(queue, block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
    block();\
} else {\
    dispatch_async(queue, block);\
}
#endif

#ifndef IWK_dispatch_main_async_safe
#define IWK_dispatch_main_async_safe(block) IWK_dispatch_queue_async_safe(dispatch_get_main_queue(), block)
#endif

#endif /* IWKUtils_h */
