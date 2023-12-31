//
//  StingerMacro.h
//  Stinger
//
//  Created by sunrunwang on 2022/6/6.
//

#ifndef StingerMacro_h
#define StingerMacro_h

#ifndef DEBUG_ASSERT
#ifdef DEBUG
#define DEBUG_ASSERT(x) if(!(x)) DEBUG_POINT
#else
#define DEBUG_ASSERT(x)
#endif
#endif

/*!
    @name COMPILE_ASSERT
    @abstract compiler assert, there is a spelling error. I know. For backward compact, the only way is to keep it.
 */
#ifndef COMPILE_ASSERT
#define COMPILE_ASSERT(condition) ((void)sizeof(char[1 - 2*!(condition)]))
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

#ifndef DEPRECATED_POINT
#ifdef DEBUG
#define DEPRECATED_POINT __builtin_trap();
#else
#define DEPRECATED_POINT
#endif
#endif

#ifndef DEBUG_LOG
#ifdef DEBUG
#include <stdio.h>
#define DEBUG_LOG(format, ...) do {                         \
fprintf(stderr, "" format "\n", ## __VA_ARGS__);            \
} while(0)
#else
#define DEBUG_LOG(format, ...)
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

#ifndef DEBUG_RETURN_NONE
#ifdef DEBUG
#define DEBUG_RETURN_NONE do { DEBUG_POINT; return; } while(0)
#else
#define DEBUG_RETURN_NONE return
#endif
#endif

#ifndef ELSE_DEBUG_RETURN
#ifdef DEBUG
#define ELSE_DEBUG_RETURN(x) else do { DEBUG_POINT; return (x); } while(0)
#else
#define ELSE_DEBUG_RETURN(x) else return (x)
#endif
#endif

#if __arm64__ && __LP64__

#ifndef NONE_PAC_MASK
#define NONE_PAC_MASK   UINT64_C(0x0000000FFFFFFFFF)
#endif

#ifndef PAGE_ZERO
#define PAGE_ZERO       UINT64_C(0x0000000100000000)
#endif

#endif /* __arm64__ && __LP64__ */

/*!@name @p VM_ADDRESS_CONTAIN(address_u64)
   @abstract 快速判断地址是否在有效虚拟地址空间中的宏定义 ( 运行效率特别快 )
   @param address_u64 期望输入是 uint64_t 格式的整数，对应实际指针地址
   @return 0 如果该地址一定非法，1 如果验证该地址存在于可分配使用的地址空间中
   @discussion [ 地址非法 ] 意味着该地址不属于可使用的虚拟内存地址，意味着一定不可读、不可写、不可执行 ( 三大皆空 )
    内部实际上是通过 Page zero 地址和 VM_MAX_ADDRESS 判断得出的，也就是实际不一定就能 RWX ( Read Write Execute )
 */
#if __arm64__ && __LP64__
#define VM_ADDRESS_CONTAIN(address_u64)                     \
        (((uint64_t)(address_u64) >= NONE_PAC_MASK) ? 0 :   \
         ((uint64_t)(address_u64) <= PAGE_ZERO)     ? 0 : 1)
#else
#define VM_ADDRESS_CONTAIN(alwaysValid) 1
#endif

#pragma mark - Clang 编译宏定义

#ifndef CLANG_ASSUME_NONNULL_BEGIN
#define CLANG_ASSUME_NONNULL_BEGIN  _Pragma("clang assume_nonnull begin")
#endif

#ifndef CLANG_ASSUME_NONNULL_END
#define CLANG_ASSUME_NONNULL_END    _Pragma("clang assume_nonnull end")
#endif

#ifndef CLANG_DIAGNOSTIC_PUSH
#define CLANG_DIAGNOSTIC_PUSH       _Pragma("clang diagnostic push")
#endif

#ifndef CLANG_DIAGNOSTIC_POP
#define CLANG_DIAGNOSTIC_POP        _Pragma("clang diagnostic pop")
#endif

#ifndef CLANG_DIAGNOSTIC_IGNORE_NONNULL
#define CLANG_DIAGNOSTIC_IGNORE_NONNULL     _Pragma("clang diagnostic ignored \"-Wnonnull\"")
#endif

#ifndef CLANG_DIAGNOSTIC_IGNORE_UNUSED
#define CLANG_DIAGNOSTIC_IGNORE_UNUSED  _Pragma("clang diagnostic ignored \"-Wunused-function\"")   \
                                        _Pragma("clang diagnostic ignored \"-Wunused-variable\"")   \
                                        _Pragma("clang diagnostic ignored \"-Wunreachable-code\"")
#endif

#ifndef CLANG_DIAGNOSTIC_IGNORE_UNUSED_FUNCTION
#define CLANG_DIAGNOSTIC_IGNORE_UNUSED_FUNCTION _Pragma("clang diagnostic ignored \"-Wunused-function\"")
#endif

#ifndef CLANG_DIAGNOSTIC_IGNORE_UNUSED_VARIABLE
#define CLANG_DIAGNOSTIC_IGNORE_UNUSED_VARIABLE _Pragma("clang diagnostic ignored \"-Wunused-variable\"")
#endif

#ifndef CLANG_DIAGNOSTIC_IGNORE_UNREACHABLE
#define CLANG_DIAGNOSTIC_IGNORE_UNREACHABLE _Pragma("clang diagnostic ignored \"-Wunreachable-code\"")
#endif

#ifndef CLANG_DIAGNOSTIC_IGNORE_DEPRECATED
#define CLANG_DIAGNOSTIC_IGNORE_DEPRECATED  _Pragma("clang diagnostic ignored \"-Wdeprecated-declarations\"")
#endif

#ifndef CLANG_DIAGNOSTIC_IGNORE_FORMAT
#define CLANG_DIAGNOSTIC_IGNORE_FORMAT      _Pragma("clang diagnostic ignored \"-Wformat\"")
#endif

#ifndef CLANG_INGORE_RETURN
#define CLANG_INGORE_RETURN(rt)   ({_Pragma("clang diagnostic push")                    \
                                    _Pragma("clang diagnostic ignored \"-Wnonnull\"")   \
                                    return (rt);                                        \
                                    _Pragma("clang diagnostic pop")})
#endif

#pragma mark - likely and unlikely

/*!
    @header 欢迎使用编译优化小宏定义 likely & unlikely
    @discussion 它的使用非常简单：
    if(likely(condition))  和 if(condition) 这两个的意思是相同的
    同理 unlikely 也是不对代码逻辑改变的，所以放心使用～
 
    它们唯一的作用就是标记这件事情很可能发生 like 和 不太可能发生 unlikely
    if(likely(condition)) {
        // 这里是更容易进入的代码位置，这样就会有编译器优化，让代码执行更快喔
    } else {
        // 这里是更不容易发生的进入的代码位置
    }
*/
#define likely(x)   __builtin_expect(!!(x), 1)
#define unlikely(x) __builtin_expect(!!(x), 0)

#pragma mark - 日志信息

#pragma mark Disable DEBUG_LOG (只有我们内部需要查问题再打开)

#undef  DEBUG_LOG
#define DEBUG_LOG(format, ...)

#pragma mark Disable DEPRECATED_POINT

#undef  DEPRECATED_POINT
#define DEPRECATED_POINT

#endif /* StingerMacro_h */
