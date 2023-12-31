//
//  HMDPublicMacro.h
//  Heimdallr
//
//  Created by fengyadong on yesterday
//

#ifndef HMDPublicMacro_h
#define HMDPublicMacro_h

#ifndef HMD_EXTERN
#    ifdef __cplusplus
#        define HMD_EXTERN extern "C"
#    else
#        define HMD_EXTERN extern
#    endif /* __cplusplus */
#endif /* HMD_EXTERN */

#ifndef HMD_EXTERN_SCOPE_BEGIN
#    ifdef __cplusplus
#        define HMD_EXTERN_SCOPE_BEGIN extern "C" {
#    else
#        define HMD_EXTERN_SCOPE_BEGIN
#    endif /* __cplusplus */
#endif /* HMD_EXTERN_SCOPE_BEGIN */

#ifndef HMD_EXTERN_SCOPE_END
#    ifdef __cplusplus
#        define HMD_EXTERN_SCOPE_END }
#    else
#        define HMD_EXTERN_SCOPE_END
#    endif /* __cplusplus */
#endif /* HMD_EXTERN_SCOPE_END */

#ifndef HMD_PACKED
#    define HMD_PACKED __attribute__((packed))
#endif /* HMD_PACKED */

#ifndef HMD_ALIGNED
#    define HMD_ALIGNED(num_bytes) __attribute__((aligned(num_bytes)))
#endif /* HMD_ALIGNED */

#ifndef HMD_TYPEDEF_EXTERN
#    ifdef __cplusplus
#        define HMD_TYPEDEF_EXTERN extern "C"
#    else
#        define HMD_TYPEDEF_EXTERN
#    endif /* __cplusplus */
#endif /* HMD_TYPEDEF_EXTERN */

#ifndef HMD_NOINLINE
#define HMD_NOINLINE __attribute__((noinline))
#endif /* HMD_NOINLINE */

#ifndef HMD_NOT_TAIL_CALLED
#define HMD_NOT_TAIL_CALLED __attribute__((not_tail_called))
#endif /* HMD_NOT_TAIL_CALLED */

/**@code HMD_PRIVATE
 *
 * 欢迎使用 HMD_PRIVATE 宏定义，当你声明了一个头文件，但是又想
 * 保留某部分方法不留给业务方进行调用的时刻，你可以加上 HMD_PRIVATE 宏定义
 * 这样业务方就没有办法调用到啦
 *
 * void function(void) HMD_PRIVATE;    // C 函数声明如何加上去
 * -(void)method HMD_PRIVATE;          // OC 方法声明如何加上去
 *
 * 当你需要用到的时刻，只需要优先导入 HMDMacro.h 头文件(需要在本文件导入之前)，即可解除封印
 */
#ifdef HMD_PRIVATE
#    undef HMD_PRIVATE
#endif /* HMD_PRIVATE */
#if __has_extension(attribute_unavailable_with_message)
#    ifdef HMD_DISABLE_PRIVATE_UNAVAILABLE_ATTRIBUTE
#        define HMD_PRIVATE
#    else
#        define HMD_PRIVATE __attribute__((unavailable("ERROR: Private API, MUST NOT be used. this attribute should only be used by Heimdallr SDK internally, any other SDK MUST NOT call this api under any circumstances")))
#    endif /* HMD_DISABLE_PRIVATE_UNAVAILABLE_ATTRIBUTE */
#else
#    define HMD_PRIVATE
#    ifdef DEBUG
#        error clang unavailable attribute not supported
#    else
#        warning clang unavailable attribute not supported
#    endif /* DEBUG */
#endif /* attribute_unavailable_with_message */

#endif /* HMDPublicMacro_h */
