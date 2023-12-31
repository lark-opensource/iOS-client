//
//  BDPMacros.h
//  Timor
//
//  Created by yinyuan on 2019/3/4.
//

#ifndef BDPMacros_h
#define BDPMacros_h

#import <Foundation/Foundation.h>
/**
 将一组任意类型（包括基本类型）参数直接编成 @"param1: value1, param2: value2, ..." 这样的字符串。最多支持 20 个参数。
 支持传入nil值。支持传入一些常见的结构体: CGPoint, CGSize, CGVector, CGRect, CGAffineTransform, UIEdgeInsets, NSDirectionalEdgeInsets, UIOffset
 不支持含有逗号','的表达式，例如 @[,,], @{,,}, block(,,){,,}等。
 **/
#define BDPParamStr(...) _BDPParamsMap2FlatString(BDPParamMap(__VA_ARGS__))
#define BDPParamMap(...) @{bdpmacro_foreach(_BDPParamMacro, _PARAM_SEP , __VA_ARGS__)}

#define _PARAM_SEP() ,

extern NSString * const NULL_STRING;
#define _BDPParamMacro(INDEX, VAR) \
@# VAR: _BDPBoxValue(NULL_STRING, @encode(__typeof__((VAR))), (VAR))

// __VA_ARGS__ 参数个数，最多支持 20 个
#define bdpmacro_argcount(...) bdpmacro_argcount_n(0, ##__VA_ARGS__, 20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0)
#define bdpmacro_argcount_n(_0, _1,_2,_3,_4,_5,_6,_7,_8,_9,_10,_11,_12,_13,_14,_15,_16,_17,_18,_19,_20, N,...) N

#define bdpmacro_concat_(A, B) A ## B
#define bdpmacro_concat(A, B) bdpmacro_concat_(A, B)

/**
 * 为 __VA_ARGS__ 的每个参数都调用 MACRO(INDEX, ARG) 并且使用 SEP_MACRO(INDEX) 作为分割符
 * For each consecutive variadic argument (up to twenty), MACRO is passed the
 * zero-based index of the current argument, and then the argument
 * itself. The results of adjoining invocations of MACRO are then separated by
 * SEP.
 *
 * Inspired by P99: http://p99.gforge.inria.fr
 */
#define bdpmacro_foreach(MACRO, SEP_MACRO, ...) \
bdpmacro_concat(bdpmacro_foreach, bdpmacro_argcount(__VA_ARGS__))(MACRO, SEP_MACRO, __VA_ARGS__)

// bdpmacro_foreach expansions
#define bdpmacro_foreach0(MACRO, SEP_MACRO, _0)

#define bdpmacro_foreach1(MACRO, SEP_MACRO, _0) MACRO(0, _0)

#define bdpmacro_foreach2(MACRO, SEP_MACRO, _0, _1) \
bdpmacro_foreach1(MACRO, SEP_MACRO, _0) SEP_MACRO() MACRO(1, _1)

#define bdpmacro_foreach3(MACRO, SEP_MACRO, _0, _1, _2) \
bdpmacro_foreach2(MACRO, SEP_MACRO, _0, _1) SEP_MACRO() MACRO(2, _2)

#define bdpmacro_foreach4(MACRO, SEP_MACRO, _0, _1, _2, _3) \
bdpmacro_foreach3(MACRO, SEP_MACRO, _0, _1, _2) SEP_MACRO() MACRO(3, _3)

#define bdpmacro_foreach5(MACRO, SEP_MACRO, _0, _1, _2, _3, _4) \
bdpmacro_foreach4(MACRO, SEP_MACRO, _0, _1, _2, _3) SEP_MACRO() MACRO(4, _4)

#define bdpmacro_foreach6(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5) \
bdpmacro_foreach5(MACRO, SEP_MACRO, _0, _1, _2, _3, _4) SEP_MACRO() MACRO(5, _5)

#define bdpmacro_foreach7(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6) \
bdpmacro_foreach6(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5) SEP_MACRO() MACRO(6, _6)

#define bdpmacro_foreach8(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7) \
bdpmacro_foreach7(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6) SEP_MACRO() MACRO(7, _7)

#define bdpmacro_foreach9(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8) \
bdpmacro_foreach8(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7) SEP_MACRO() MACRO(8, _8)

#define bdpmacro_foreach10(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9) \
bdpmacro_foreach9(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8) SEP_MACRO() MACRO(9, _9)

#define bdpmacro_foreach11(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10) \
bdpmacro_foreach10(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9) SEP_MACRO() MACRO(10, _10)

#define bdpmacro_foreach12(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11) \
bdpmacro_foreach11(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10) SEP_MACRO() MACRO(11, _11)

#define bdpmacro_foreach13(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12) \
bdpmacro_foreach12(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11) SEP_MACRO() MACRO(12, _12)

#define bdpmacro_foreach14(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13) \
bdpmacro_foreach13(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12) SEP_MACRO() MACRO(13, _13)

#define bdpmacro_foreach15(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14) \
bdpmacro_foreach14(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13) SEP_MACRO() MACRO(14, _14)

#define bdpmacro_foreach16(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15) \
bdpmacro_foreach15(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14) SEP_MACRO() MACRO(15, _15)

#define bdpmacro_foreach17(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16) \
bdpmacro_foreach16(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15) SEP_MACRO() MACRO(16, _16)

#define bdpmacro_foreach18(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17) \
bdpmacro_foreach17(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16) SEP_MACRO() MACRO(17, _17)

#define bdpmacro_foreach19(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18) \
bdpmacro_foreach18(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17) SEP_MACRO() MACRO(18, _18)

#define bdpmacro_foreach20(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19) \
bdpmacro_foreach19(MACRO, SEP_MACRO, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18) SEP_MACRO() MACRO(19, _19)

FOUNDATION_EXPORT id _BDPBoxValue(id defaulValue, const char *type, ...);   // not for direct use

FOUNDATION_EXPORT NSString *_BDPParamsMap2FlatString(NSDictionary * map); // not for direct use

#endif /* BDPMacros_h */
