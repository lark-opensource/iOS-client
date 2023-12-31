//
//  OKMacros.h
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import <Foundation/Foundation.h>

#ifndef OKMacros_h
#define OKMacros_h

#ifndef OK_WeakSelf
#define OK_WeakSelf __weak typeof(self) wself = self
#endif

#ifndef OK_StrongSelf
#define OK_StrongSelf __strong typeof(wself) self = wself
#endif

#ifndef ok_keywordify
#if DEBUG
    #define ok_keywordify autoreleasepool {}
#else
    #define ok_keywordify try {} @catch (...) {}
#endif
#endif

#ifndef weakify
    #if __has_feature(objc_arc)
        #define weakify(object) ok_keywordify __weak __typeof__(object) weak##_##object = object;
    #else
        #define weakify(object) ok_keywordify __block __typeof__(object) block##_##object = object;
    #endif
#endif

#ifndef strongify
    #if __has_feature(objc_arc)
        #define strongify(object) ok_keywordify __typeof__(object) object = weak##_##object;
    #else
        #define strongify(object) ok_keywordify __typeof__(object) object = block##_##object;
    #endif
#endif

#ifndef OK_Lock
#define OK_Lock(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#endif

#ifndef OK_Unlock
#define OK_Unlock(lock) dispatch_semaphore_signal(lock);
#endif

#define _OK_CONCAT(A, B) A ## B
#define OKIdentifier(NAME, COUNTER) _OK_CONCAT(NAME, COUNTER)
#define OKSectionNameData(sectname) __attribute((used, no_sanitize_address, section("__DATA,"#sectname" ")))

static inline bool ok_dispatch_is_main_queue() {
    return dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue());
}

static inline bool ok_dispatch_is_main_thread() {
    return [NSThread isMainThread];
}

/**
 Submits a block for asynchronous execution on a main queue and returns immediately.
 */
static inline void ok_dispatch_async_on_main_queue(void (^block)(void))
{
    if (ok_dispatch_is_main_queue()) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

static inline void ok_dispatch_sync_on_main_queue(void (^block)(void))
{
    if (ok_dispatch_is_main_queue()) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

#endif /* OKMacros_h */
