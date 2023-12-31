//
//  TTMLCommon.h
//  TTMLeaksFinder
//
//  Created by maruipu on 2020/11/11.
//

#ifndef TTMLCommon_h
#define TTMLCommon_h

#define _TTML_CONCAT(a, b) a##b
#define TTML_CONCAT(a, b) _TTML_CONCAT(a, b)

#define TTML_REGISTRATION _TTML_REGISTRATION(_ttml_register_, __COUNTER__)
#define _TTML_REGISTRATION(prefix, suffix) \
static void TTML_CONCAT(prefix, suffix)() __attribute__((constructor)); \
static void TTML_CONCAT(prefix, suffix)()

#if defined(__cplusplus)
    #define TTML_EXTERN_C_BEGIN extern "C" {
    #define TTML_EXTERN_C_END   }
#else
    #define TTML_EXTERN_C_BEGIN
    #define TTML_EXTERN_C_END
#endif

#endif /* TTMLCommon_h */
