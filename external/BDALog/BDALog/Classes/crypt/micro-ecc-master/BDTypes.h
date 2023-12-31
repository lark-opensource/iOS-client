/* Copyright 2015, Kenneth MacKay. Licensed under the BSD 2-clause license. */

#ifndef _BDUECC_TYPES_H_
#define _BDUECC_TYPES_H_

#ifndef BDuECC_PLATFORM
    #if __AVR__
        #define BDuECC_PLATFORM BDuECC_avr
    #elif defined(__thumb2__) || defined(_M_ARMT) /* I think MSVC only supports Thumb-2 targets */
        #define BDuECC_PLATFORM BDuECC_arm_thumb2
    #elif defined(__thumb__)
        #define BDuECC_PLATFORM BDuECC_arm_thumb
    #elif defined(__arm__) || defined(_M_ARM)
        #define BDuECC_PLATFORM BDuECC_arm
    #elif defined(__aarch64__)
        #define BDuECC_PLATFORM BDuECC_arm64
    #elif defined(__i386__) || defined(_M_IX86) || defined(_X86_) || defined(__I86__)
        #define BDuECC_PLATFORM BDuECC_x86
    #elif defined(__amd64__) || defined(_M_X64)
        #define BDuECC_PLATFORM BDuECC_x86_64
    #else
        #define BDuECC_PLATFORM BDuECC_arch_other
    #endif
#endif

#ifndef BDuECC_ARM_USE_UMAAL
    #if (BDuECC_PLATFORM == BDuECC_arm) && (__ARM_ARCH >= 6)
        #define BDuECC_ARM_USE_UMAAL 1
    #elif (BDuECC_PLATFORM == BDuECC_arm_thumb2) && (__ARM_ARCH >= 6) && !__ARM_ARCH_7M__
        #define BDuECC_ARM_USE_UMAAL 1
    #else
        #define BDuECC_ARM_USE_UMAAL 0
    #endif
#endif

#ifndef BDuECC_WORD_SIZE
    #if BDuECC_PLATFORM == BDuECC_avr
        #define BDuECC_WORD_SIZE 1
    #elif (BDuECC_PLATFORM == BDuECC_x86_64 || BDuECC_PLATFORM == BDuECC_arm64)
        #define BDuECC_WORD_SIZE 8
    #else
        #define BDuECC_WORD_SIZE 4
    #endif
#endif

#if (BDuECC_WORD_SIZE != 1) && (BDuECC_WORD_SIZE != 4) && (BDuECC_WORD_SIZE != 8)
    #error "Unsupported value for BDuECC_WORD_SIZE"
#endif

#if ((BDuECC_PLATFORM == BDuECC_avr) && (BDuECC_WORD_SIZE != 1))
    #pragma message ("BDuECC_WORD_SIZE must be 1 for AVR")
    #undef BDuECC_WORD_SIZE
    #define BDuECC_WORD_SIZE 1
#endif

#if ((BDuECC_PLATFORM == BDuECC_arm || BDuECC_PLATFORM == BDuECC_arm_thumb || \
        BDuECC_PLATFORM ==  BDuECC_arm_thumb2) && \
     (BDuECC_WORD_SIZE != 4))
    #pragma message ("BDuECC_WORD_SIZE must be 4 for ARM")
    #undef BDuECC_WORD_SIZE
    #define BDuECC_WORD_SIZE 4
#endif

#if defined(__SIZEOF_INT128__) || ((__clang_major__ * 100 + __clang_minor__) >= 302)
    #define SUPPORTS_INT128 1
#else
    #define SUPPORTS_INT128 0
#endif

typedef int8_t wordcount_t;
typedef int16_t bitcount_t;
typedef int8_t cmpresult_t;

#if (BDuECC_WORD_SIZE == 1)

typedef uint8_t BDuECC_word_t;
typedef uint16_t BDuECC_dword_t;

#define HIGH_BIT_SET 0x80
#define BDuECC_WORD_BITS 8
#define BDuECC_WORD_BITS_SHIFT 3
#define BDuECC_WORD_BITS_MASK 0x07

#elif (BDuECC_WORD_SIZE == 4)

typedef uint32_t BDuECC_word_t;
typedef uint64_t BDuECC_dword_t;

#define HIGH_BIT_SET 0x80000000
#define BDuECC_WORD_BITS 32
#define BDuECC_WORD_BITS_SHIFT 5
#define BDuECC_WORD_BITS_MASK 0x01F

#elif (BDuECC_WORD_SIZE == 8)

typedef uint64_t BDuECC_word_t;
#if SUPPORTS_INT128
typedef unsigned __int128 BDuECC_dword_t;
#endif

#define HIGH_BIT_SET 0x8000000000000000ull
#define BDuECC_WORD_BITS 64
#define BDuECC_WORD_BITS_SHIFT 6
#define BDuECC_WORD_BITS_MASK 0x03F

#endif /* BDuECC_WORD_SIZE */

#endif /* _BDUECC_TYPES_H_ */
