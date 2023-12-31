//
//  BDFishhookMacro.h
//  iOSTool
//
//  Created by sunrunwang on 2021/12/21.
//

#ifndef BDFishhookMacro_h
#define BDFishhookMacro_h

#include <stdio.h>
#include <os/base.h>

/*!
    @name COMPILE_ASSERT
    @abstract compiler assert, there is a spelling error. I know. For backward compact, the only way is to keep it.
 */


#ifndef COMPILE_ASSERT
#if __arm64__ && __LP64__
#define COMPILE_ASSERT(condition) ((void)sizeof(char[1 - 2*!(condition)]))
#else
#define COMPILE_ASSERT(condition)
#endif
#endif

/* Strong DEBUG macro */

// used in white box, when you know it should not happen

#ifndef DEBUG_ELSE
#ifdef DEBUG
#define DEBUG_ELSE else { DEBUG_POINT }
#else
#define DEBUG_ELSE
#endif
#endif

#ifndef DEBUG_POINT
#ifdef DEBUG
#define DEBUG_POINT do {                                                \
        fprintf(stderr, "[ERROR] %s:%d %s compileDate:%s %s ",          \
        __FILE__, __LINE__, __func__, __DATE__, __TIME__);              \
        BDFishhook_DEBUG_POINT_FUNC(); } while(0);
#else
#define DEBUG_POINT
#endif
#endif

#ifndef DEBUG_ASSERT
#ifdef DEBUG
#define DEBUG_ASSERT(x) do { if(!(x)) DEBUG_POINT; } while(0)
#else
#define DEBUG_ASSERT(x)
#endif
#endif

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

/* Weak DEBUG macro */

// used in parameter outside the back box, error handling should be done
// message should be as simple as possible, as [file, line] appended in output

#ifndef DEBUG_LOG
#ifdef DEBUG
#define DEBUG_LOG(format, ...) do {                         \
fprintf(stderr, "DEBUG_LOG %s:%d %s compileDate:%s %s\n",   \
__FILE__, __LINE__, __func__, __DATE__, __TIME__);          \
fprintf(stderr, "" format "\n", ## __VA_ARGS__);            \
} while(0)
#else
#define DEBUG_LOG(format, ...)
#endif
#endif

#ifndef ELSE_DEBUG_LOG
#ifdef DEBUG
#define ELSE_DEBUG_LOG(format, ...) else DEBUG_LOG(format, ## __VA_ARGS__);
#else
#define ELSE_DEBUG_LOG(format, ...)
#endif
#endif

#ifndef DEBUG_ELSE_LOG
#ifdef DEBUG
#define DEBUG_ELSE_LOG(format, ...) else DEBUG_LOG(format, ## __VA_ARGS__);
#else
#define DEBUG_ELSE_LOG(format, ...)
#endif
#endif

#ifdef DEBUG
  #ifdef __GNUC__
    #define BDFishhook_DEBUG_POINT_FUNC() __builtin_trap()
  #else
    #error unsupported compiler
  #endif
#else
  #define BDFishhook_DEBUG_POINT_FUNC()
#endif

// 防止当前函数末尾执行尾调用，在return前调用
#define GCC_FORCE_NO_OPTIMIZATION  os_prevent_tail_call_optimization();
// C/C++函数attribute，防止函数自身被内联 & 尾调用
#define HMD_NO_OPT_ATTRIBUTE OS_NOINLINE OS_NOT_TAIL_CALLED

#endif /* BDFishhookMacro_h */
