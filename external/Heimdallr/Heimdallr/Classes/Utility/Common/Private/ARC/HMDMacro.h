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

#ifndef DEBUG_CONTINUE
#ifdef DEBUG
#define DEBUG_CONTINUE do{ DEBUG_POINT; continue; } while(0)
#else
#define DEBUG_CONTINUE continue
#endif
#endif


#ifndef DEBUG_ELSE
#ifdef DEBUG
#define DEBUG_ELSE else DEBUG_POINT
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

#ifndef DEBUG_ACTION
#ifdef DEBUG
#define DEBUG_ACTION(x) do { (x); } while(0)
#else
#define DEBUG_ACTION(x)
#endif
#endif

#ifndef DEBUG_LOG
#ifdef DEBUG
    #define DEBUG_LOG(format, ...) do {                                                                            \
        const char *_file_name_ = (strrchr)(__FILE__, '/') ? (strrchr)(__FILE__, '/') + 1 : __FILE__;              \
        fprintf(stderr, "[Heimdallr] %s:%d " format "\n", _file_name_, __LINE__, ## __VA_ARGS__);                  \
    } while(0)
#else
    #define DEBUG_LOG(format, ...)
#endif
#endif

#ifndef COND_DEBUG_LOG
#define COND_DEBUG_LOG(condition, format, ...) do {                                                             \
    if(condition) {                                                                                             \
        DEBUG_LOG(format, ## __VA_ARGS__);                                                                      \
    }                                                                                                           \
} while(0)
#endif

#ifndef DEBUG_ERROR
#define DEBUG_ERROR(format, ...) do {                                                                           \
    DEBUG_LOG(format, ## __VA_ARGS__);                                                                          \
    DEBUG_POINT;                                                                                                \
} while(0)
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

#pragma mark - Develop Debug Macro

#ifndef DEVELOP_DEBUG_POINT
#ifdef DEBUG
#define DEVELOP_DEBUG_POINT do {                     \
    HMD_EXTERN void HMDMacroDevelopDebugPoint(void); \
    HMDMacroDevelopDebugPoint();                     \
} while(0)
#else
#define DEVELOP_DEBUG_POINT
#endif
#endif

#ifndef DEVELOP_DEBUG_ASSERT
#ifdef DEBUG
#define DEVELOP_DEBUG_ASSERT(x) if(!(x)) DEVELOP_DEBUG_POINT
#else
#define DEVELOP_DEBUG_ASSERT(x)
#endif
#endif

#ifndef DEVELOP_DEBUG_RETURN
#ifdef DEBUG
#define DEVELOP_DEBUG_RETURN(x) do { DEVELOP_DEBUG_POINT; return (x); } while(0)
#else
#define DEVELOP_DEBUG_RETURN(x) return (x)
#endif
#endif

#ifndef DEVELOP_DEBUG_RETURN_NONE
#ifdef DEBUG
#define DEVELOP_DEBUG_RETURN_NONE do { DEVELOP_DEBUG_POINT; return; } while(0)
#else
#define DEVELOP_DEBUG_RETURN_NONE return
#endif
#endif

#pragma mark - Clang pragma

#ifndef CLANG_DIAGNOSTIC_PUSH
#define CLANG_DIAGNOSTIC_PUSH       _Pragma("clang diagnostic push")
#endif

#ifndef CLANG_DIAGNOSTIC_POP
#define CLANG_DIAGNOSTIC_POP        _Pragma("clang diagnostic pop")
#endif

#ifndef CLANG_DIAGNOSTIC_IGNORE_NONNULL
#define CLANG_DIAGNOSTIC_IGNORE_NONNULL     _Pragma("clang diagnostic ignored \"-Wnonnull\"")
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

#ifndef CLANG_DIAGNOSTIC_IGNORE_UNDECLARED_SELECTOR
#define CLANG_DIAGNOSTIC_IGNORE_UNDECLARED_SELECTOR _Pragma("clang diagnostic ignored \"-Wundeclared-selector\"")
#endif

#ifndef CLANG_DIAGNOSTIC_IGNORE_DEPRECATED_DECLARATIONS
#define CLANG_DIAGNOSTIC_IGNORE_DEPRECATED_DECLARATIONS _Pragma("clang diagnostic ignored \"-Wdeprecated-declarations\"")
#endif

#ifndef CLANG_DIAGNOSTIC_IGNORE_DOCUMENTATION
#define CLANG_DIAGNOSTIC_IGNORE_DOCUMENTATION _Pragma("clang diagnostic ignored \"-Wdocumentation\"")
#endif

#ifndef CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#define CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES _Pragma("clang diagnostic ignored \"-Wstrict-prototypes\"")
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

#ifndef HMD_AARCH64_POINTER_PAC_STRIP
#if __arm64__
#define HMD_AARCH64_POINTER_PAC_STRIP(pointer)  ((void *)(((uint64_t)(pointer)) & NONE_PAC_MASK))
#else
#define HMD_AARCH64_POINTER_PAC_STRIP(pointer)  (pointer)
#endif
#endif

#pragma mark - Clang Attribute

#ifndef CLANG_ATTR_OBJC_DIRECT
#define CLANG_ATTR_OBJC_DIRECT __attribute__((objc_direct))
#endif

#ifndef CLANG_ATTR_OBJC_DIRECT_MEMBERS
#define CLANG_ATTR_OBJC_DIRECT_MEMBERS __attribute__((objc_direct_members))
#endif

#ifndef CLANG_ATTR_OCLINT_SUPPRESS_BLOCK_CAPTURE_SELF
#define CLANG_ATTR_OCLINT_SUPPRESS_BLOCK_CAPTURE_SELF __attribute__((annotate("oclint:suppress[block captured instance self]")))
#endif

#pragma mark - Heimdallr Private
// 详情请见 HMDPublicMacro.h

#ifndef HMD_DISABLE_PRIVATE_UNAVAILABLE_ATTRIBUTE
#define HMD_DISABLE_PRIVATE_UNAVAILABLE_ATTRIBUTE
#endif

#ifdef  HMD_PRIVATE
#undef  HMD_PRIVATE
#define HMD_PRIVATE
#endif

#pragma mark - Apple Store Review Fixup

#define HMD_APPSTORE_REVIEW_FIXUP 1

#pragma mark - Debug Once

/*!@define @p DEBUG_ONCE
   @abstract 宏定义，DEBUG 环境下校验一段代码只会执行一次
   @note 在使用前请定义宏 @p HMD_USE_DEBUG_ONCE 在 @p HMDMacro.h 导入前
   @note 定义宏会导入 @p <stdatomic.h> 或者 @p <atomic> 头文件，我们不想给每个文件都导入，
   所以设计了必须要定义 @p HMD_USE_DEBUG_ONCE 宏才可以使用 @p DEBUG_ONCE
   @example @code
        void function(void) {
            DEBUG_ONCE      // 随便丢哪里都行，这里的代码只能执行一次，否则报错
            ...
        }
 */

#ifdef DEBUG
    #ifdef HMD_USE_DEBUG_ONCE
        #ifdef __cplusplus
            #include <atomic>
            #define HMD_DEBGUG_ASSERT_DEBUG_ONCE_CPP
        #elif __STDC_VERSION__ >= 201112L && ! defined __STDC_NO_ATOMICS__
            #include <stdatomic.h>
            #define HMD_DEBGUG_ASSERT_DEBUG_ONCE_C
        #else
            #define HMD_DEBGUG_ASSERT_DEBUG_ONCE_NO_ACCESS
        #endif
    #endif
#endif

#ifndef DEBUG_ONCE
    #ifdef DEBUG
        #ifdef HMD_DEBGUG_ASSERT_DEBUG_ONCE_CPP
            #define DEBUG_ONCE ((void)({                                                \
            static std::atomic_flag onceToken = ATOMIC_FLAG_INIT;                       \
            if(onceToken.test_and_set(std::memory_order_acq_rel)) {                     \
                DEBUG_POINT;                                                            \
            }}));
        #elif defined HMD_DEBGUG_ASSERT_DEBUG_ONCE_C
            #define DEBUG_ONCE ((void)({                                                \
            static atomic_flag onceToken = ATOMIC_FLAG_INIT;                            \
            if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_acq_rel)) {   \
                DEBUG_POINT;                                                            \
            }}));
        #elif defined HMD_DEBGUG_ASSERT_DEBUG_ONCE_NO_ACCESS
            #define DEBUG_ONCE _Pragma("GCC warning \"DEBUG_ONCE is not available on your platform\"")
        #elif ! defined HMD_USE_DEBUG_ONCE
            #define DEBUG_ONCE _Pragma("GCC warning \"DEBUG_ONCE is not available by default, you MUST define macro HMD_USE_DEBUG_ONCE before include HMDMacro.h file to enable this feature\"")
        #else
            #define DEBUG_ONCE _Pragma("GCC error \"undefined behavior for DEBUG_ONCE, maybe Swift file which is not supported, please check macro definition\"")
        #endif
    #else
        #define DEBUG_ONCE
    #endif
#endif

#pragma mark - Stringlization

#ifndef HMD_Stringlization
#define HMD_Stringlization(x) HMD_Stringlization_Internal(x)
#define HMD_Stringlization_Internal(x) #x
#endif

#pragma mark - Weak Strong Self

#ifndef keywordify
#if DEBUG
#define keywordify autoreleasepool {}
#else
#define keywordify try {} @catch (...) {}
#endif
#endif

#ifndef weakify
#if __has_feature(objc_arc)
#define weakify(object) keywordify __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) keywordify __block __typeof__(object) block##_##object = object;
#endif
#endif

#ifndef strongify
#if __has_feature(objc_arc)
#define strongify(object) keywordify __typeof__(object) object = weak##_##object;
#else
#define strongify(object) keywordify __typeof__(object) object = block##_##object;
#endif
#endif

#endif /* HMDMacro_h */
