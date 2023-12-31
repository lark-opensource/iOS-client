//
//  HMDMacro.h
//  Heimdallr
//
//  Created by fengyadong on 2018/3/7.
//

#ifndef HMDMacro_h
#define HMDMacro_h

#include <os/base.h>
#include "HMDPublicMacro.h"

#ifndef HMDIsEmptyString
#define HMDIsEmptyString(str) (!str || ![str isKindOfClass:[NSString class]] || str.length == 0)
#endif

#ifndef HMD_MB
#define HMD_MB (1024.f * 1024.f)
#endif

#ifndef HMD_GB
#define HMD_GB (1024.f * 1024.f * 1024.f)
#endif

#ifndef HMD_KB
#define HMD_KB (1024.f)
#endif

#ifndef HMDIsEmptyArray
#define HMDIsEmptyArray(array) (!array || ![array isKindOfClass:[NSArray class]] || array.count == 0)
#endif

#ifndef HMDIsEmptyDictionary
#define HMDIsEmptyDictionary(dict) (!dict || ![dict isKindOfClass:[NSDictionary class]] || ((NSDictionary *)dict).count == 0)
#endif

#ifndef HMDStartUploadDelayTime
#define HMDStartUploadDelayTime 15
#endif

#ifdef __APPLE__
#include <TargetConditionals.h>
#define HMDCRASH_HOST_APPLE 1
#endif

#pragma mark - OS_NOT_TRAIL_CALLED

#define MilliSecond(x) (long long)(1000ll * x)

/*!@name @p GCC_FORCE_NO_OPTIMIZATION
 * @abstract 防止函数在 Slardar 调用栈中消失，以及 backtrace 无法识别到这个栈
 * @discussion 假设有三个函数，A 调用 B，B 调用 C，就像：A => B => C 关系
 * 但是如果 B 在调用 C 之后没有任何别的操作，那么它就可以选择让 C 直接返回 A
 * 也就是虽然是 A -> B -> C 的关系，但是执行到 C 之后，栈回溯只能看到 A -> C
 * 那么如果想要 B 在栈上不消失，那么必须在 return 前加入 @p GCC_FORCE_NO_OPTIMIZATION
 * @warning @b return返回的必须是值，不能是表达式
 *
 * @code
 * id function(void) {
 *     // 这样写是错的！⚠️ return 里面是表达式; 不是一个简单的值
 *     GCC_FORCE_NO_OPTIMIZATION return [NSString stingWithFormat:@""];
 * }
 * @endcode
 *
 * @code
 * id function(void) {
 *     // 返回的必须是值，不能是表达式，把值用一个变量计算好再返回变量
 *     id string = [NSString stingWithFormat:@""];
 *     GCC_FORCE_NO_OPTIMIZATION return string;
 * }
 * @endcode
 *
 * @code
 * id function(void) {
 *     if(condition) {
 *         // 如果一个函数在多处都有 return; 那么每一处都要执行上述标准
 *         id date = [NSDate date];
 *         GCC_FORCE_NO_OPTIMIZATION return date;
 *     }
 *     id string = [NSString stingWithFormat:@""];
 *     GCC_FORCE_NO_OPTIMIZATION return string;
 * }
 * @endcode
 *
 * @code
 * void function(void) {
 *      functionA();
 *      functionB();
 *      ...
 *
 *      // 如果一个函数返回类型是void;
 *      // 在每一个隐式存在 return 的地方都要补上
 *      GCC_FORCE_NO_OPTIMIZATION
 * }
 * @endcode
 */
#define GCC_FORCE_NO_OPTIMIZATION os_prevent_tail_call_optimization();

// C/C++函数的 Clang attribute，防止函数自身被(内联/不返回调用)
#define HMD_NO_OPT_ATTRIBUTE OS_NOINLINE OS_NOT_TAIL_CALLED

#pragma mark - DEBUG Macro

#ifndef COMPILE_ASSERT
#define COMPILE_ASSERT(condition) ((void)sizeof(char[1 - 2*!(condition)]))
#endif

#ifndef DEBUG_C_ASSERT
#ifdef DEBUG
#define DEBUG_C_ASSERT(x) (assert(x))
#else
#define DEBUG_C_ASSERT(x)
#endif
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

/*      DEBUG_RETURN_NONE
        这个和 return; 的含义相同, 除了在 DEBUG 模式下, 这里相当于断点   */
#ifndef DEBUG_RETURN_NONE
#ifdef DEBUG
#define DEBUG_RETURN_NONE do { DEBUG_POINT; return; } while(0)
#else
#define DEBUG_RETURN_NONE return
#endif
#endif

#pragma mark - Clang pragma

#ifndef CLANG_DIAGNOSTIC_PUSH
#define CLANG_DIAGNOSTIC_PUSH       _Pragma("clang diagnostic push")
#endif

#ifndef CLANG_DIAGNOSTIC_POP
#define CLANG_DIAGNOSTIC_POP        _Pragma("clang diagnostic pop")
#endif

#ifndef CLANG_DIAGNOSTIC_IGNORE_UNUSED_VARIABLE
#define CLANG_DIAGNOSTIC_IGNORE_UNUSED_VARIABLE _Pragma("clang diagnostic ignored \"-Wunused-variable\"")
#endif

#ifndef CLANG_DIAGNOSTIC_IGNORE_UNUSED_VALUE
#define CLANG_DIAGNOSTIC_IGNORE_UNUSED_VALUE _Pragma("clang diagnostic ignored \"-Wunused-value\"")
#endif

#ifndef CLANG_DIAGNOSTIC_IGNORE_UNUSED_FUNCTION
#define CLANG_DIAGNOSTIC_IGNORE_UNUSED_FUNCTION _Pragma("clang diagnostic ignored \"-Wunused-function\"")
#endif

#ifndef CLANG_DIAGNOSTIC_IGNORE_UNREACHABLE
#define CLANG_DIAGNOSTIC_IGNORE_UNREACHABLE _Pragma("clang diagnostic ignored \"-Wunreachable-code\"")
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

#pragma mark - VM Address Contain

#ifndef NONE_PAC_MASK
#define NONE_PAC_MASK   UINT64_C(0x0000000FFFFFFFFF)
#endif

#ifndef PAGE_ZERO
#define PAGE_ZERO       UINT64_C(0x0000000100000000)
#endif

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

#pragma mark - Clang Attribute

#ifndef CLANG_ATTR_OBJC_DIRECT
#define CLANG_ATTR_OBJC_DIRECT __attribute__((objc_direct))
#endif

#endif /* HMDMacro_h */
