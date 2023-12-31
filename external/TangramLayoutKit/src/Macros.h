//
//  Macros.h
//  Pods
//
//  Created by qihongye on 2021/4/4.
//

#pragma once

/// TL_EXPORT_EXTERN defination
#ifdef __cplusplus
#define TL_EXTERN_C_BEGIN extern "C" {
#define TL_EXTERN_C_END }
#else
#define TL_EXTERN_C_BEGIN
#define TL_EXTERN_C_END
#endif

/// TL_EXPORT defination
#ifndef TL_EXPORT
#ifdef _MSC_VER
#define TL_EXPORT
#else
#define TL_EXPORT __attribute__((visibility("default")))
#endif
#endif

/// TL_INTERNAL defination
#ifndef  TL_LOCAL
#ifdef _MSC_VER
#define TL_LOCAL
#else
#define TL_LOCAL __attribute__((visibility("hidden")))
#endif
#endif

#ifndef TL_ARG_COUNT
#define TL_ARG_COUNT(...) \
TL_ARG_COUNT_N(__VA_ARGS__,TL_ARG_16)
#define TL_ARG_COUNT_N(...) \
TL_ARG_COUNT_16(__VA_ARGS__)
#define TL_ARG_COUNT_16( \
_1, _2, _3, _4, _5, _6, _7, _8, _9,_10, \
_11,_12,_13,_14,_15, _16, N,...) N
#define TL_ARG_16 \
16,15,14,13,12,11,10, \
9,8,7,6,5,4,3,2,1,0
#endif

#ifndef TL_ENUM_DEF
#define TL_ENUM_DEF(NAME,...) \
enum NAME { \
TL_ARG_FOR_EACH(TL_CONCAT,NAME,__VA_ARGS__) \
};
/// __VA_ARGS__ for each loop, seperator by comma, only work when the count of arguments is less than or equal to **16**.
/// Arguments: function, function argument, value.
#define TL_ARG_FOR_EACH(f,a,...) \
TL_CONCAT(TL_SCAN_ARG,TL_ARG_COUNT(__VA_ARGS__))(f,a,__VA_ARGS__)

#define TL_CONCAT_(A,B) A##B
#define TL_CONCAT(A,B) TL_CONCAT_(A,B)

/// function, function argument, value
#define TL_SCAN_ARG0(f,a,v,...)
#define TL_SCAN_ARG1(f,a,v,...) f(a,v)
#define TL_SCAN_ARG2(f,a,v,...) TL_SCAN_ARG1(f,a,v) , TL_SCAN_ARG1(f,a,__VA_ARGS__)
#define TL_SCAN_ARG3(f,a,v,...) TL_SCAN_ARG1(f,a,v) , TL_SCAN_ARG2(f,a,__VA_ARGS__)
#define TL_SCAN_ARG4(f,a,v,...) TL_SCAN_ARG1(f,a,v) , TL_SCAN_ARG3(f,a,__VA_ARGS__)
#define TL_SCAN_ARG5(f,a,v,...) TL_SCAN_ARG1(f,a,v) , TL_SCAN_ARG4(f,a,__VA_ARGS__)
#define TL_SCAN_ARG6(f,a,v,...) TL_SCAN_ARG1(f,a,v) , TL_SCAN_ARG5(f,a,__VA_ARGS__)
#define TL_SCAN_ARG7(f,a,v,...) TL_SCAN_ARG1(f,a,v) , TL_SCAN_ARG6(f,a,__VA_ARGS__)
#define TL_SCAN_ARG8(f,a,v,...) TL_SCAN_ARG1(f,a,v) , TL_SCAN_ARG7(f,a,__VA_ARGS__)
#define TL_SCAN_ARG9(f,a,v,...) TL_SCAN_ARG1(f,a,v) , TL_SCAN_ARG8(f,a,__VA_ARGS__)
#define TL_SCAN_ARG10(f,a,v,...) TL_SCAN_ARG1(f,a,v) , TL_SCAN_ARG9(f,a,__VA_ARGS__)
#define TL_SCAN_ARG11(f,a,v,...) TL_SCAN_ARG1(f,a,v) , TL_SCAN_ARG10(f,a,__VA_ARGS__)
#define TL_SCAN_ARG12(f,a,v,...) TL_SCAN_ARG1(f,a,v) , TL_SCAN_ARG11(f,a,__VA_ARGS__)
#define TL_SCAN_ARG13(f,a,v,...) TL_SCAN_ARG1(f,a,v) , TL_SCAN_ARG12(f,a,__VA_ARGS__)
#define TL_SCAN_ARG14(f,a,v,...) TL_SCAN_ARG1(f,a,v) , TL_SCAN_ARG13(f,a,__VA_ARGS__)
#define TL_SCAN_ARG15(f,a,v,...) TL_SCAN_ARG1(f,a,v) , TL_SCAN_ARG14(f,a,__VA_ARGS__)
#define TL_SCAN_ARG16(f,a,v,...) TL_SCAN_ARG1(f,a,v) , TL_SCAN_ARG15(f,a,__VA_ARGS__)
#endif

#ifndef TLVALUE_GETTER_SETTER_DEF
#define TLVALUE_GETTER_SETTER_DEF(NAME) \
TLValue NAME() const { return { _##NAME, (TLUnit)_flags[_##NAME##Unit] }; } \
void NAME(const TLValue NAME) { \
_##NAME = NAME.value; \
_flags[_##NAME##Unit] = NAME.unit; \
}
#endif
