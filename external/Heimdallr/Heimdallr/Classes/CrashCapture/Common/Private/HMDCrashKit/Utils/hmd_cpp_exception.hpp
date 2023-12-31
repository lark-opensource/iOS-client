//
//  hmd_cpp_exception.hpp
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/9/29.
//

#ifndef hmd_cpp_exception_hpp
#define hmd_cpp_exception_hpp

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct hmd_cpp_exception_info {
    void *exception;
    void *type_info;
    void *dest;
    int skip_count;
    int backtrace_len;
    void *backtrace[100];
} hmd_cpp_exception_info;

void hmd_enable_cpp_exception_backtrace();

void hmd_disable_cpp_exception_backtrace();

hmd_cpp_exception_info hmd_current_cpp_exception_info();

void *hmd_current_cpp_exception();

#ifdef __cplusplus
} // extern "C"
#endif

#ifdef __cplusplus      // only for C++ file
#include <cxxabi.h>

extern "C" {
typedef void (*hmd_exception_recover_function_t)(void *, std::type_info *, void (*)(void*));
extern hmd_exception_recover_function_t hmd_exception_recover_handle;
} // extern "C"

#endif

#endif /* hmd_cpp_exception_hpp */
