//
//  BDWebImageMacro.h
//  BDWebImage
//
//  Created by fengyadong on 2017/12/10.
//

#ifndef BDWebImageMacro_h
#define BDWebImageMacro_h

#ifndef dispatch_queue_async_safe
#define dispatch_queue_async_safe(queue, block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0) {\
    block();\
} else {\
    dispatch_async(queue, block);\
}
#endif

#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block) dispatch_queue_async_safe(dispatch_get_main_queue(), block)
#endif

#ifndef isEmptyString
#define isEmptyString(str) (!str || ![str isKindOfClass:[NSString class]] || str.length == 0)
#endif

#ifndef isEmptyArray
#define isEmptyArray(array) (!array || ![array isKindOfClass:[NSArray class]] || array.count == 0)
#endif

#ifndef isEmptyDictionary
#define isEmptyDictionary(dict) (!dict || ![dict isKindOfClass:[NSDictionary class]] || ((NSDictionary *)dict).count == 0)
#endif

#ifndef BD_CATEGORY_PROPERTY
#define BD_CATEGORY_PROPERTY
#import <objc/runtime.h>
#define BD_GET_PROPERTY(property) objc_getAssociatedObject(self, @selector(property));
#define BD_SET_STRONG(property) objc_setAssociatedObject(self, @selector(property), property, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
#define BD_SET_COPY(property) objc_setAssociatedObject(self, @selector(property), property, OBJC_ASSOCIATION_COPY_NONATOMIC);
#define BD_SET_UNSAFE_UNRETAINED(property) objc_setAssociatedObject(self, @selector(property), property, OBJC_ASSOCIATION_ASSIGN);
#define BD_SET_ASSIGN(property, value) objc_setAssociatedObject(self, @selector(property), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
#define BD_SET_WEAK(property) id __weak __weak_object = property; \
id (^__weak_block)(void) = ^{ return __weak_object; }; \
objc_setAssociatedObject(self, @selector(property), __weak_block, OBJC_ASSOCIATION_COPY);
#define BD_GET_WEAK(property) objc_getAssociatedObject(self, @selector(property)) ? ((id (^)(void))objc_getAssociatedObject(self, @selector(property)))() : nil;
#endif

#ifndef DEBUG_ASSERT
#ifdef DEBUG
#define DEBUG_ASSERT(x) if(!(x)) DEBUG_POINT
#else
#define DEBUG_ASSERT(x)
#endif
#endif

#ifndef DEBUG_ELSE
#ifdef DEBUG
#define DEBUG_ELSE else DEBUG_POINT;
#else
#define DEBUG_ELSE
#endif
#endif

#ifndef DEBUG_POINT
#ifdef DEBUG
#define DEBUG_POINT __builtin_trap();
#else
#define DEBUG_POINT
#endif
#endif

#ifndef DEBUG_LOG
#ifdef DEBUG
#include <stdio.h>
#define DEBUG_LOG(format, ...) do {                         \
fprintf(stderr, "DEBUG_LOG %s:%d %s compileDate:%s %s ",    \
__FILE__, __LINE__, __func__, __DATE__, __TIME__);          \
fprintf(stderr, "" format "\n", ## __VA_ARGS__);            \
} while(0)
#else
#define DEBUG_LOG(format, ...)
#endif
#endif


#ifndef DEBUG_ERROR
#ifdef DEBUG
#include <stdio.h>
#define DEBUG_ERROR(format, ...) do {                       \
fprintf(stderr, "DEBUG_ERROR %s:%d %s compileDate:%s %s ",  \
__FILE__, __LINE__, __func__, __DATE__, __TIME__);          \
fprintf(stderr, "" format "\n", ## __VA_ARGS__);            \
DEBUG_POINT;                                                \
} while(0)
#else
#define DEBUG_ERROR(format, ...)
#endif
#endif

#ifndef ELSE_DEBUG_LOG
#ifdef DEBUG
#define ELSE_DEBUG_LOG(format, ...) else DEBUG_LOG(format, ## __VA_ARGS__)
#else
#define ELSE_DEBUG_LOG(format, ...)
#endif
#endif


/*      DEBUG_RETURN(x)
        这个和 return x 的含义相同, 除了在 DEBUG 模式下, 这里相当于断点   */
#ifndef DEBUG_RETURN
#ifdef DEBUG
#define DEBUG_RETURN(x) do { DEBUG_POINT; return (x); } while(0)
#else
#define DEBUG_RETURN(x) return (x)
#endif
#endif

#ifndef ELSE_DEBUG_RETURN
#ifdef DEBUG
#define ELSE_DEBUG_RETURN(x) else do { DEBUG_POINT; return (x); } while(0)
#else
#define ELSE_DEBUG_RETURN(x) else return (x)
#endif
#endif

#endif /* BDWebImageMacro_h */
