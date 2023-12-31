//
//  AWESafeAssertMacro.h
//  AWESafeAssertMacro
//
//  Created by yaheng on 2019/12/1.
//  Copyright © 2019 yaheng.zheng All rights reserved.
//

#ifndef __AWESafeAssertMacro_H__
#define __AWESafeAssertMacro_H__

//#define DISABLE_ASSERT

//---------------------------------------------------------------------------

#if defined(DEBUG) && !defined(DISABLE_ASSERT)

FOUNDATION_EXPORT __attribute__((visibility("default"), used)) int disable_awe_safe_assert(void);

    #if defined (__APPLE__) && defined(TARGET_OS_IPHONE) && (defined(__arm__) || defined(__arm64__)) // iOS device
        #include <signal.h>
        #include <pthread.h>

        #define AWESafeAssert(condition, frmt, ...)                             \
        do                                                                      \
        {                                                                       \
            if (!(condition))                                                   \
            {                                                                   \
                void awe_safe_assert_log(const char *, int, const char *, const char *); \
                awe_safe_assert_log([[NSString stringWithUTF8String:__FILE__] lastPathComponent].UTF8String, __LINE__, #condition, [NSString stringWithFormat:frmt, ##__VA_ARGS__].UTF8String);          \
                bool awe_safe_assert_is_enable(void);                           \
                if (awe_safe_assert_is_enable()) {                              \
                    pthread_kill(pthread_self(), SIGINT);                       \
                }                                                               \
            }                                                                   \
        } while (0);

    #elif defined (__APPLE__) && defined(TARGET_IPHONE_SIMULATOR) && (defined(__i386__) || defined(__x86_64__)) // iOS simulator

        #define AWESafeAssert(condition, frmt, ...)                             \
        do                                                                      \
        {                                                                       \
            if (!(condition))                                                   \
            {                                                                   \
                void awe_safe_assert_log(const char *, int, const char *, const char *); \
                awe_safe_assert_log([[NSString stringWithUTF8String:__FILE__] lastPathComponent].UTF8String, __LINE__, #condition, [NSString stringWithFormat:frmt, ##__VA_ARGS__].UTF8String);          \
                bool awe_safe_assert_is_enable(void);                           \
                if (awe_safe_assert_is_enable()) {                              \
                    asm("int $3");                                              \
                }                                                               \
            }                                                                   \
        } while (0);

    #else

        #define AWESafeAssert(condition, frmt, ...) (void)0

    #endif

#else

    #define AWESafeAssert(condition, frmt, ...) (void)0

#endif

//---------------------------------------------------------------------------

#endif /* __AWESafeAssertMacro_H__ */
