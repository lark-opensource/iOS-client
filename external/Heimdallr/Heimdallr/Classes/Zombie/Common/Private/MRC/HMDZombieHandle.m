//
//  HMDZombieHandle.m
//  ZombieDemo
//
//  Created by Liuchengqing on 2020/3/2.
//  Copyright © 2020 Liuchengqing. All rights reserved.
//

#import "HMDZombieHandle.h"
#import "HMDZombieMonitor.h"
#import "HMDZombieMonitor+private.h"
#import "HMDZombieObject.h"
#import <objc/runtime.h>
#import <malloc/malloc.h>
#include <dlfcn.h>
 #import "HMDMacro.h"
#import "hmd_objc_apple.h"
#include <pthread.h>
#include "HMDAsyncThread.h"
#import <mach/mach_init.h>

static bool HMDAtomicCompareAndSwap32Barrier(int32_t __oldValue, int32_t __newValue, volatile int32_t * __theValue);

# pragma mark - apple foundation

typedef struct __CFRuntimeClass {
    CFIndex version;
    const char *className; // must be a pure ASCII string, nul-terminated
    void (*init)(CFTypeRef cf);
    CFTypeRef (*copy)(CFAllocatorRef allocator, CFTypeRef cf);
    void (*finalize)(CFTypeRef cf);
    Boolean (*equal)(CFTypeRef cf1, CFTypeRef cf2);
    CFHashCode (*hash)(CFTypeRef cf);
    CFStringRef (*copyFormattingDesc)(CFTypeRef cf, CFDictionaryRef formatOptions);    // return str with retain
    CFStringRef (*copyDebugDesc)(CFTypeRef cf);    // return str with retain
#ifndef CF_RECLAIM_AVAILABLE
#define CF_RECLAIM_AVAILABLE 1
#endif
    void (*reclaim)(CFTypeRef cf); // Or in _kCFRuntimeResourcefulObject in the .version to indicate this field should be used
#ifndef CF_REFCOUNT_AVAILABLE
#define CF_REFCOUNT_AVAILABLE 1
#endif
    uint32_t (*refcount)(intptr_t op, CFTypeRef cf); // Or in _kCFRuntimeCustomRefCount in the .version to indicate this field should be used
        // this field must be non-NULL when _kCFRuntimeCustomRefCount is in the .version field
        // - if the callback is passed 1 in 'op' it should increment the 'cf's reference count and return 0
        // - if the callback is passed 0 in 'op' it should return the 'cf's reference count, up to 32 bits
        // - if the callback is passed -1 in 'op' it should decrement the 'cf's reference count; if it is now zero, 'cf' should be cleaned up and deallocated (the finalize callback above will NOT be called unless the process is running under GC, and CF does not deallocate the memory for you; if running under GC, finalize should do the object tear-down and free the object memory); then return 0
        // remember to use saturation arithmetic logic and stop incrementing and decrementing when the ref count hits UINT32_MAX, or you will have a security bug
        // remember that reference count incrementing/decrementing must be done thread-safely/atomically
        // objects should be created/initialized with a custom ref-count of 1 by the class creation functions
        // do not attempt to use any bits within the CFRuntimeBase for your reference count; store that in some additional field in your CF object

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#ifndef CF_REQUIRED_ALIGNMENT_AVAILABLE
#define CF_REQUIRED_ALIGNMENT_AVAILABLE 1
#endif
    uintptr_t requiredAlignment; // Or in _kCFRuntimeRequiresAlignment in the .version field to indicate this field should be used; the allocator to _CFRuntimeCreateInstance() will be ignored in this case; if this is less than the minimum alignment the system supports, you'll get higher alignment; if this is not an alignment the system supports (e.g., most systems will only support powers of two, or if it is too high), the result (consequences) will be up to CF or the system to decide

} CFRuntimeClass;

CF_INLINE CFTypeID hmd_cf_GenericTypeID_inline(const void *cf) {
    // yes, 10 bits masked off, though 12 bits are there for the type field; __CFRuntimeClassTableSize is 1024
    uint32_t *cfinfop = (uint32_t *)&(((CFRuntimeBase *)cf)->_cfinfo);
    CFTypeID typeID = (*cfinfop >> 8) & 0x03FF; // mask up to 0x0FFF
    return typeID;
}

enum { // Version field constants
    _kCFRuntimeScannedObject =     (1UL << 0),
    _kCFRuntimeResourcefulObject = (1UL << 2),  // tells CFRuntime to make use of the reclaim field
    _kCFRuntimeCustomRefCount =    (1UL << 3),  // tells CFRuntime to make use of the refcount field
    _kCFRuntimeRequiresAlignment = (1UL << 4),  // tells CFRuntime to make use of the requiredAlignment field
};

#ifndef __kCFAllocatorTypeID_CONST
#define __kCFAllocatorTypeID_CONST    2
#endif

// CF-master CFRuntime.h _CFRuntimeGetClassWithTypeID
const CFRuntimeClass * _CFRuntimeGetClassWithTypeID(CFTypeID typeID);

static pthread_mutex_t gZombieLock;
static Class gHMDZombieClass;
static size_t gRootObjSize;
static CFMutableSetRef gBacktraceClassSet;

@implementation HMDZombieHandle

static inline size_t max(size_t s1, size_t s2) {
    return s1 > s2 ? s1 : s2;
}

+ (void)setupVariable {
    pthread_mutex_init(&gZombieLock, nil);
    gHMDZombieClass = objc_lookUpClass("HMDZombieObject");
    gRootObjSize = max(class_getInstanceSize([NSObject class]),
                       class_getInstanceSize([NSProxy class]));
    gBacktraceClassSet = CFSetCreateMutable(NULL, 0, NULL);
    if ([HMDZombieMonitor sharedInstance].zombieConfig.classList.count > 0) {
        for (NSString *cn in [HMDZombieMonitor sharedInstance].zombieConfig.classList) {
            Class cls = NSClassFromString(cn);
            if (cls) {
                CFSetAddValue(gBacktraceClassSet, (__bridge void *)cls);
            }
        }
    }
}

+ (BOOL)deallocHandle:(__unsafe_unretained id)obj class:(__unsafe_unretained Class)cls {
    // 类对象不做干预，可能会捕获到__NSCFString的类对象
    if (__builtin_expect(object_isClass(obj), 0)) {
        return NO;
    }
    
    const char *name = class_getName(cls);
    
    // 获取僵尸类，同__dealloc_zombie中，用类名存储原始名
    if (__builtin_expect(name == NULL, 0)) name = "$class-unknown$";
    char *cname = NULL;
    asprintf(&cname, "hmd_zombie_%s", name);
    /*
     objc_duplicateClass(runtimeLock) --> addNamedClass(dyldLock)
     dyld3::AllImages::runImageCallbacks(dyldLock) --> objc_lookUpClass(runtimeLock)
    */
    pthread_mutex_lock(&gZombieLock);
    Class zclass = objc_lookUpClass(cname);
    if (__builtin_expect(zclass == NULL, 0)) {
        zclass = objc_duplicateClass(gHMDZombieClass, cname, 0);
    }
    pthread_mutex_unlock(&gZombieLock);
    free(cname);
    
    size_t instanceSize = class_getInstanceSize(cls);
        
    //在对象内存未被释放的情况下销毁对象的成员变量及关联引用。需要-fno-objc-arc
    objc_destructInstance(obj);
    /*
     修改对象的isa指针，令其指向特殊的僵尸类
     object_setClass可以替换一个类的isa，但是如果直接替换会发生死锁。
     这里先对obj对象进行0x55填充，然后将自己类的isa复制过去，之后调用object_setClass将原有类替换为代理类
     */
    size_t userSize = instanceSize - gRootObjSize;
    if (userSize > 0) {
        memset((uint8_t *)obj + gRootObjSize, 0x55, userSize);
    }
    object_setClass(obj, zclass);
    
    
    const char *backtrace = NULL;
    
    if (CFSetContainsValue(gBacktraceClassSet, (__bridge void *)cls)) {
        backtrace = [self getDeallocBackTrace];
    }
    size_t goodSize = malloc_good_size(instanceSize);
    // 持有
    [HMDZombieMonitor.sharedInstance cacheZombieObj:(__bridge void *)obj cfAllocator:NULL backtrace:backtrace size:goodSize];
    return YES;
}

+ (const char *)getDeallocBackTrace{
    // thread name \  time \ backtrace
    NSMutableString *strM = [NSMutableString string];
    [strM appendString:@"thread name:"];
    NSString *threadName = @"";
    if ([NSThread isMainThread]) {
        threadName = @"main thread";
    }
    else
    {
        hmd_thread thread = (hmd_thread)mach_thread_self();
        char thread_name_buffer[256];
        bool rt = hmdthread_getThreadName(thread, thread_name_buffer, sizeof(thread_name_buffer));
        if (rt)
        {
            threadName = [NSString stringWithCString:thread_name_buffer encoding:NSUTF8StringEncoding];
        }
        if (!rt || threadName.length == 0)
        {
            bool qn = hmdthread_getQueueName(thread, thread_name_buffer, sizeof(thread_name_buffer));
            if (qn)
            {
                NSString *queueName = [NSString stringWithCString:thread_name_buffer encoding:NSUTF8StringEncoding];
                threadName =[NSString stringWithFormat:@"Queue: %@", queueName];
            }
            else threadName = @"null";
        }
    }
    [strM appendString:threadName];
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];//获取当前时间0秒后的时间
    NSTimeInterval time=[date timeIntervalSince1970]*1000;// *1000 是精确到毫秒，不乘就是精确到秒
    NSString *timeString = [NSString stringWithFormat:@"\n dealloc timestamp: %.0f", time];
    [strM appendString:timeString];
    NSArray *syms = [NSThread  callStackSymbols];
    for (NSString *str in syms) {
        [strM appendString:@"##"];
        [strM appendString:str];
    }
    const char *t =(char*)[strM UTF8String];
    if (t) {
        return strdup(t);
    }
    return NULL;
}

+ (BOOL)cfNonObjCReleaseHandle:(__unsafe_unretained id)obj {
    // 类对象不做干预
    if (__builtin_expect(object_isClass(obj), 0)) {
        return NO;
    }
    
    // 原始名
    Class cls = object_getClass(obj);
    const char *name = class_getName(cls);
    
    // 获取僵尸类，同__dealloc_zombie中，用类名存储原始名
    if (__builtin_expect(name == NULL, 0)) name = "$class-unknown$";
    char *cname = NULL;
    asprintf(&cname, "hmd_zombie_%s", name);
    Class zclass = objc_lookUpClass(cname);
    if (__builtin_expect(zclass == NULL, 0)) {
        zclass = objc_duplicateClass(objc_lookUpClass("HMDZombieObject"), cname, 0);
    }
    free(cname);
    
    size_t memSize = malloc_size(obj);
    if (__builtin_expect(memSize < class_getInstanceSize(zclass), 0)) {
        return NO;
    }
    
    CFTypeRef cfObj = (__bridge CFTypeRef) obj;
    if (!hmd_cf_release_before_free(cfObj)) {
        return NO;
    }

    object_setClass(obj, zclass);
    
    CFAllocatorRef allocator = kCFAllocatorSystemDefault;
    if (__CFBitfieldGetValue(((const CFRuntimeBase *)cfObj)->_cfinfo[CF_INFO_BITS], 7, 7)) {
        allocator = kCFAllocatorSystemDefault;
    } else {
        allocator = CFGetAllocator(cfObj);
    }
    
    // 持有
    [HMDZombieMonitor.sharedInstance cacheZombieObj:(__bridge void *)obj cfAllocator:allocator backtrace:NULL size:memSize];
    return YES;
}

+ (void)free:(void *)obj cfAllocator:(CFAllocatorRef)allocator {
    if (obj == NULL) {
        return;
    }
    else if (allocator == NULL) {
        object_dispose(obj);
    }
    else {
        hmd_cf_free(obj, allocator);
    }
}

bool hmd_cf_release_before_free(CFTypeRef cf) {
    // ref: https://opensource.apple.com/source/CF/CF-550/CFRuntime.c
#if __LP64__
    uint32_t lowBits;
    do {
        lowBits = ((CFRuntimeBase *)cf)->_rc;
        if (1 != lowBits) return NO;    // Constant CFTypeRef
        // CANNOT WRITE ANY NEW VALUE INTO [CF_RC_BITS] UNTIL AFTER FINALIZATION
        CFTypeID typeID = hmd_cf_GenericTypeID_inline(cf);
        // cannot zombify allocators, which get deallocated by __CFAllocatorDeallocate (finalize)
        if (__builtin_expect(__kCFAllocatorTypeID_CONST == typeID, 0)) return NO;
        
        const CFRuntimeClass *cfClass = _CFRuntimeGetClassWithTypeID(typeID);
        if (cfClass->version & _kCFRuntimeResourcefulObject && cfClass->reclaim != NULL) {
            cfClass->reclaim(cf);
        }
        
        void (*func)(CFTypeRef) = _CFRuntimeGetClassWithTypeID(typeID)->finalize;
        if (NULL != func) {
            func(cf);
        }
        // We recheck lowBits to see if the object has been retained again during
        // the finalization process.  This allows for the finalizer to resurrect,
        // but the main point is to allow finalizers to be able to manage the
        // removal of objects from uniquing caches, which may race with other threads
        // which are allocating (looking up and finding) objects from those caches,
        // which (that thread) would be the thing doing the extra retain in that case.
        if (HMDAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&((CFRuntimeBase *)cf)->_rc)) {
            return YES;
        }
    } while (!HMDAtomicCompareAndSwap32Barrier(lowBits, lowBits - 1, (int32_t *)&((CFRuntimeBase *)cf)->_rc));
#else
#define RC_START 24
#define RC_END 31
    volatile UInt32 *infoLocation = (UInt32 *)&(((CFRuntimeBase *)cf)->_cfinfo);
    CFIndex rcLowBits = __CFBitfieldGetValue(*infoLocation, RC_END, RC_START);
    if (__builtin_expect(1 != rcLowBits, 0)) return NO;        // Constant CFTypeRef
    bool success = 0;
    do {
        UInt32 initialCheckInfo = *infoLocation;
        rcLowBits = __CFBitfieldGetValue(initialCheckInfo, RC_END, RC_START);
        if (1 != rcLowBits)  return NO;
        // we think cf should be deallocated
        // CANNOT WRITE ANY NEW VALUE INTO [CF_RC_BITS] UNTIL AFTER FINALIZATION
        CFTypeID typeID = hmd_cf_GenericTypeID_inline(cf);
        const CFRuntimeClass *cfClass = _CFRuntimeGetClassWithTypeID(typeID);
        if (cfClass->version & _kCFRuntimeResourcefulObject && cfClass->reclaim != NULL) {
            cfClass->reclaim(cf);
        }
        // cannot zombify allocators, which get deallocated by __CFAllocatorDeallocate (finalize)
        if (__builtin_expect(__kCFAllocatorTypeID_CONST == typeID, 0)) {
            return NO;
        } else {
            void (*func)(CFTypeRef) = _CFRuntimeGetClassWithTypeID(typeID)->finalize;
            if (NULL != func) {
                func(cf);
            }
            // We recheck rcLowBits to see if the object has been retained again during
            // the finalization process.  This allows for the finalizer to resurrect,
            // but the main point is to allow finalizers to be able to manage the
            // removal of objects from uniquing caches, which may race with other threads
            // which are allocating (looking up and finding) objects from those caches,
            // which (that thread) would be the thing doing the extra retain in that case.
            rcLowBits = __CFBitfieldGetValue(*infoLocation, RC_END, RC_START);
            UInt32 prospectiveNewInfo = initialCheckInfo;
            prospectiveNewInfo -= (1 << RC_START);
            success = HMDAtomicCompareAndSwap32Barrier(*(int32_t *)&initialCheckInfo, *(int32_t *)&prospectiveNewInfo, (int32_t *)infoLocation);
            if (__builtin_expect(success, 1)) {
                return YES;
            }
        }
    } while (__builtin_expect(!success, 0));
#endif
    return NO;
}

void hmd_cf_free(CFTypeRef cf, CFAllocatorRef allocator) {
    Boolean usesSystemDefaultAllocator = (allocator == kCFAllocatorSystemDefault);
    CFAllocatorDeallocate(allocator, (uint8_t *)cf - (usesSystemDefaultAllocator ? 0 : sizeof(CFAllocatorRef)));
    if (kCFAllocatorSystemDefault != allocator) {
        CFRelease(allocator);
    }
}

@end

static bool HMDAtomicCompareAndSwap32Barrier(int32_t __oldValue, int32_t __newValue, volatile int32_t * __theValue) {
    if(__theValue == NULL) DEBUG_RETURN(false);
    
    int32_t expected = __oldValue;
    return __atomic_compare_exchange_n(__theValue, &expected, __newValue, false,
                                       __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE);
}



