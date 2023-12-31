//
//  BTDMacros.h
//  Pods
//
//  Created by willorfang on 16/8/5.
//
//

#import <Foundation/Foundation.h>
#import <pthread.h>

#ifndef __BTDMacros_H__
#define __BTDMacros_H__

#ifndef BTD_CLAMP
#define BTD_CLAMP(_x_, _low_, _high_)  (((_x_) > (_high_)) ? (_high_) : (((_x_) < (_low_)) ? (_low_) : (_x_)))
#endif

#ifndef BTD_SWAP
#define BTD_SWAP(_a_, _b_)  do { __typeof__(_a_) _tmp_ = (_a_); (_a_) = (_b_); (_b_) = _tmp_; } while (0)
#endif

#ifndef BTDAssertMainThread
#define BTDAssertMainThread() NSAssert([NSThread isMainThread], @"This method must be called on the main thread")
#endif

#ifndef btd_keywordify
#if DEBUG
    #define btd_keywordify autoreleasepool {}
#else
    #define btd_keywordify try {} @catch (...) {}
#endif
#endif

#ifndef weakify
    #if __has_feature(objc_arc)
        #define weakify(object) btd_keywordify __weak __typeof__(object) weak##_##object = object;
    #else
        #define weakify(object) btd_keywordify __block __typeof__(object) block##_##object = object;
    #endif
#endif

#ifndef strongify
    #if __has_feature(objc_arc)
        #define strongify(object) btd_keywordify __typeof__(object) object = weak##_##object;
    #else
        #define strongify(object) btd_keywordify __typeof__(object) object = block##_##object;
    #endif
#endif


/// 是否在主队列
static inline bool btd_dispatch_is_main_queue() {
    return dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue());
}

/// 是否在主线程
static inline bool btd_dispatch_is_main_thread() {
    return [NSThread isMainThread];
}

/**
 Submits a block for asynchronous execution on a main queue and returns immediately.
 */
static inline void btd_dispatch_async_on_main_queue(void (^block)(void))
{
    if (btd_dispatch_is_main_queue()) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

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

#ifndef BTD_MUTEX_LOCK
#define BTD_MUTEX_LOCK(lock) \
    pthread_mutex_lock(&(lock)); \
    @onExit{ \
        pthread_mutex_unlock(&(lock)); \
    };
#endif

#ifndef BTD_SEMAPHORE_LOCK
#define BTD_SEMAPHORE_LOCK(lock) \
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER); \
    @onExit{ \
        dispatch_semaphore_signal(lock); \
    };
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wunused-function"
static NSString *currentTimeString()
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSSSS"];
    return [dateFormatter stringFromDate:[NSDate date]];
}
#pragma clang diagnostic pop

#ifndef BTDLog
#if DEBUG
    #define BTDLog(s, ...) \
    fprintf(stderr, "%s <%s:%-4d> %s\n", [currentTimeString() UTF8String], [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:(s), ##__VA_ARGS__] UTF8String])
#else
    #define BTDLog(s, ...)
#endif
#endif

#ifndef BTD_isEmptyString
FOUNDATION_EXPORT BOOL BTD_isEmptyString(id param);
#endif

#ifndef BTD_isEmptyArray
FOUNDATION_EXPORT BOOL BTD_isEmptyArray(id param);
#endif

#ifndef BTD_isEmptyDictionary
FOUNDATION_EXPORT BOOL BTD_isEmptyDictionary(id param);
#endif

#endif
