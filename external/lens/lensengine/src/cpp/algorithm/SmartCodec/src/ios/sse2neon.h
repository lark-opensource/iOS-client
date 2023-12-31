//
//  sse2neon.h
//  Pods
//
//  Created by bytedance on 2022/6/7.
//

#define ENABLE_SSE

#define ENABLE_ARM_NEON 1

#ifndef __SSE2NEON_H__
#define __SSE2NEON_H__

#if defined(__GNUC__) || defined(__clang__)
#   pragma push_macro("FORCE_INLINE")
#   pragma push_macro("ALIGN_STRUCT")
#   define FORCE_INLINE       inline __attribute__((always_inline))
#   define ALIGN_STRUCT(x)    __attribute__((aligned(x)))
#elif defined(_MSC_VER)
#   define FORCE_INLINE       __forceinline
#   define ALIGN_STRUCT(x)    __declspec(align(x))
#   define __attribute__(x)
#   define aligned(x) (x)
#else
#   error "Macro name collisions may happens with unknown compiler"
#endif

#ifdef ENABLE_ARM_NEON

typedef  signed   char       int8;
typedef  unsigned char       uint8, Byte;
typedef           short      int16;
typedef  unsigned short      uint16, Word, float16;
typedef           int        int32;
typedef  unsigned int        uint32, DWord;


typedef uint16 uint10;
//typedef Byte uint10;
typedef uint16 fix13;
typedef uint32 int4x8;
typedef uint8 int4x2;
typedef uint8 int4;

#include <arm_neon.h>

typedef float32x4_t __m128;
typedef float32x2_t __m64;
typedef int32x4_t __m128i;
typedef int32x2_t __m64i;
typedef int32x4x2_t __m128ix2;
typedef int32x2x2_t __m64ix2;
// Cast vector of type __m128 to type __m128i. This intrinsic is only used for compilation and does not generate any instructions, thus it has zero latency.
static FORCE_INLINE __m128i _mm_castps_si128(__m128 a) { return vreinterpretq_s32_f32(a); }
// Cast vector of type __m128i to type __m128. This intrinsic is only used for compilation and does not generate any instructions, thus it has zero latency.
static FORCE_INLINE __m128 _mm_castsi128_ps(__m128i a) { return vreinterpretq_f32_u32(a); }

/*  expands to the following value */
#define _MM_SHUFFLE(z, y, x, w)    ( (z<<6) | (y<<4) | (x<<2) | w )
#define GET_UINT2(x, i)  ((x)>>(2*(i)))&0x03

/***************************************************************************
*                malloc
***************************************************************************/
#include "stdlib.h"
typedef unsigned int IndexType_t;
static FORCE_INLINE void* _mm_malloc(size_t size, size_t align)
{
    size_t n=(align<sizeof(IndexType_t)?sizeof(IndexType_t):align);
    IndexType_t* pBuf=(IndexType_t*)malloc(size+n+sizeof(IndexType_t));
    if(pBuf)
    {
        IndexType_t* p=(IndexType_t*)(((size_t)pBuf+sizeof(IndexType_t)+n-1)&(~(n-1)));
        p[-1]=(IndexType_t)((size_t)p-(size_t)pBuf-1);
        //Printf(TEXT_COLOR_CYAN, "pBuf=%p\np=%p  p[-1]=%d\n", pBuf, p, p[-1]);
        return p;
    }
    return 0;
}
static FORCE_INLINE void _mm_free(void* pData)
{
    if(pData)
    {
        IndexType_t* pBuf=(IndexType_t*)((size_t)pData-((IndexType_t*)pData)[-1]-1);
        //Printf(TEXT_COLOR_CYAN, "pBuf=%p\n", pBuf);
        free(pBuf);
    }
}
//#define _mm_malloc(a, b) memalign(b, a)
//#define _mm_free(a) free(a)

/***************************************************************************
*                convert
***************************************************************************/
// int16 r[8]={int16(a.i32[0]), int16(a.i32[1]), int16(a.i32[2]), int16(a.i32[3]), int16(b.i32[0]), int16(b.i32[1]), int16(b.i32[2]), int16(b.i32[3])}
static FORCE_INLINE __m128i _mm_packs_epi32(__m128i a, __m128i b) { return (__m128i)vcombine_s16(vqmovn_s32(a), vqmovn_s32(b)); }
// uint16 r[8]={uint16(a.i32[0]), uint16(a.i32[1]), uint16(a.i32[2]), uint16(a.i32[3]), uint16(b.i32[0]), uint16(b.i32[1]), uint16(b.i32[2]), uint16(b.i32[3])}
static FORCE_INLINE __m128i _mm_packus_epi32(__m128i a, __m128i b) { return (__m128i)vcombine_u16(vqmovun_s32(a), vqmovun_s32(b)); }
// int8 r[16]={int8(a.i16[0]), int8(a.i16[1]), int8(a.i16[2]), int8(a.i16[3]), int8(a.i16[4]), int8(a.i16[5]), int8(a.i16[6]), int8(a.i16[7]), int8(b.i16[0]), int8(b.i16[1]), int8(b.i16[2]), int8(b.i16[3]), int8(b.i16[4]), int8(b.i16[5]), int8(b.i16[6]), int8(b.i16[7])}
static FORCE_INLINE __m128i _mm_packs_epi16(const __m128i a, const __m128i b) { return (__m128i)vcombine_s8(vqmovn_s16((int16x8_t)a), vqmovn_s16((int16x8_t)b)); }
// uint8 r[16]={uint8(a.i16[0]), uint8(a.i16[1]), uint8(a.i16[2]), uint8(a.i16[3]), uint8(a.i16[4]), uint8(a.i16[5]), uint8(a.i16[6]), uint8(a.i16[7]), uint8(b.i16[0]), uint8(b.i16[1]), uint8(b.i16[2]), uint8(b.i16[3]), uint8(b.i16[4]), uint8(b.i16[5]), uint8(b.i16[6]), uint8(b.i16[7])}
static FORCE_INLINE __m128i _mm_packus_epi16(const __m128i a, const __m128i b) { return (__m128i)vcombine_u8(vqmovun_s16((int16x8_t)a), vqmovun_s16((int16x8_t)b)); }

// int16 r[8]={int16(a.i32[0]), int16(a.i32[1]), int16(a.i32[2]), int16(a.i32[3]), int16(b.i32[0]), int16(b.i32[1]), int16(b.i32[2]), int16(b.i32[3])}
static FORCE_INLINE __m128i _mm_cvt2_i32_i16x8(__m128i a, __m128i b) { return (__m128i)vcombine_s16(vqmovn_s32(a), vqmovn_s32(b)); }
// uint16 r[8]={uint16(a.i32[0]), uint16(a.i32[1]), uint16(a.i32[2]), uint16(a.i32[3]), uint16(b.i32[0]), uint16(b.i32[1]), uint16(b.i32[2]), uint16(b.i32[3])}
static FORCE_INLINE __m128i _mm_cvt2_i32_u16x8(__m128i a, __m128i b) { return (__m128i)vcombine_u16(vqmovun_s32(a), vqmovun_s32(b)); }
// int8 r[16]={int8(a.i16[0]), int8(a.i16[1]), int8(a.i16[2]), int8(a.i16[3]), int8(a.i16[4]), int8(a.i16[5]), int8(a.i16[6]), int8(a.i16[7]), int8(b.i16[0]), int8(b.i16[1]), int8(b.i16[2]), int8(b.i16[3]), int8(b.i16[4]), int8(b.i16[5]), int8(b.i16[6]), int8(b.i16[7])}
static FORCE_INLINE __m128i _mm_cvt2_i16_i8x16(__m128i a, __m128i b) { return (__m128i)vcombine_s8(vqmovn_s16(a), vqmovn_s16(b)); }
// uint8 r[16]={uint8(a.i16[0]), uint8(a.i16[1]), uint8(a.i16[2]), uint8(a.i16[3]), uint8(a.i16[4]), uint8(a.i16[5]), uint8(a.i16[6]), uint8(a.i16[7]), uint8(b.i16[0]), uint8(b.i16[1]), uint8(b.i16[2]), uint8(b.i16[3]), uint8(b.i16[4]), uint8(b.i16[5]), uint8(b.i16[6]), uint8(b.i16[7])}
static FORCE_INLINE __m128i _mm_cvt2_i16_u8x16(__m128i a, __m128i b) { return (__m128i)vcombine_u8(vqmovun_s16(a), vqmovun_s16(b)); }

// uint8 r[16]={a.u8[0], b.u8[0], a.u8[1], b.u8[1], a.u8[2], b.u8[2], a.u8[3], b.u8[3], a.u8[4], b.u8[4], a.u8[5], b.u8[5], a.u8[6], b.u8[6], a.u8[7], b.u8[7]};
static FORCE_INLINE __m128i _mm_unpacklo_epi8(__m128i a, __m128i b) { int8x8x2_t r = vzip_s8(vget_low_s8(a), vget_low_s8(b)); return (__m128i)vcombine_s8(r.val[0], r.val[1]); }
// uint16 r[8]={a.u16[0], b.u16[0], a.u16[1], b.u16[1], a.u16[2], b.u16[2], a.u16[3], b.u16[3]};
static FORCE_INLINE __m128i _mm_unpacklo_epi16(__m128i a, __m128i b) { int16x4x2_t r = vzip_s16(vget_low_s16(a), vget_low_s16(b)); return (__m128i)vcombine_s16(r.val[0], r.val[1]); }
// uint32 r[4]={a.u32[0], b.u32[0], a.u32[1], b.u32[1]};
static FORCE_INLINE __m128i _mm_unpacklo_epi32(__m128i a, __m128i b) { int32x2x2_t r = vzip_s32(vget_low_s32(a), vget_low_s32(b)); return (__m128i)vcombine_s32(r.val[0], r.val[1]); }
// uint64 r[2]={a.u64[0], b.u64[0]};
static FORCE_INLINE __m128i _mm_unpacklo_epi64(__m128i a, __m128i b) { return (__m128i)vcombine_s64(vget_low_s64(a), vget_low_s64(b)); }
// uint8 r[16]={a.u8[8], b.u8[8], a.u8[9], b.u8[9], a.u8[10], b.u8[10], a.u8[11], b.u8[11], a.u8[12], b.u8[12], a.u8[13], b.u8[13], a.u8[14], b.u8[14], a.u8[15], b.u8[15]};
static FORCE_INLINE __m128i _mm_unpackhi_epi8(__m128i a, __m128i b) { int8x8x2_t r = vzip_s8(vget_high_s8(a), vget_high_s8(b)); return (__m128i)vcombine_s8(r.val[0], r.val[1]); }
// uint16 r[8]={a.u16[4], b.u16[4], a.u16[5], b.u16[5], a.u16[6], b.u16[6], a.u16[7], b.u16[7]};
static FORCE_INLINE __m128i _mm_unpackhi_epi16(__m128i a, __m128i b) { int16x4x2_t r = vzip_s16(vget_high_s16(a), vget_high_s16(b)); return (__m128i)vcombine_s16(r.val[0], r.val[1]); }
// uint32 r[4]={a.u32[2], b.u32[2], a.u32[3], b.u32[3]};
static FORCE_INLINE __m128i _mm_unpackhi_epi32(__m128i a, __m128i b) { int32x2x2_t r = vzip_s32(vget_high_s32(a), vget_high_s32(b)); return (__m128i)vcombine_s32(r.val[0], r.val[1]); }
// uint64 r[2]={a.u64[1], b.u64[1]};
static FORCE_INLINE __m128i _mm_unpackhi_epi64(__m128i a, __m128i b) { return (__m128i)vcombine_s64(vget_high_s64(a), vget_high_s64(b)); }
// float r[4]={a.f32[0], b.f32[0], a.f32[1], b.f32[1]};
static FORCE_INLINE __m128 _mm_unpacklo_ps(__m128 a, __m128 b) { float32x2x2_t r= vzip_f32(vget_low_f32(a), vget_low_f32(b)); return vcombine_f32(r.val[0], r.val[1]); }
// float r[4]={a.f32[2], b.f32[2], a.f32[3], b.f32[3]};
static FORCE_INLINE __m128 _mm_unpackhi_ps(__m128 a, __m128 b) { float32x2x2_t r = vzip_f32(vget_high_f32(a), vget_high_f32(b)); return vcombine_f32(r.val[0], r.val[1]); }

// r0=a0;  r1=a1;  r2=b0;  r3=b1
static FORCE_INLINE __m128 _mm_movelh_ps(__m128 a, __m128 b) { return vcombine_f32(vget_low_f32(a), vget_low_f32(b)); }

// r0=b2;  r1=b3;  r2=a2;  r3=a3
static FORCE_INLINE __m128 _mm_movehl_ps(__m128 a, __m128 b) { return vcombine_f32(vget_high_f32(b), vget_high_f32(a)); }

static FORCE_INLINE __m128 _mm_cvtepi32_ps(__m128i a) { return vcvtq_f32_s32(a); }
static FORCE_INLINE __m128i _mm_cvtps_epi32(__m128 a) { return vcvtq_s32_f32(a); }
static FORCE_INLINE __m128i _mm_cvttps_epi32(__m128 a) { return vcvtq_s32_f32(a); }
#define _mm_cvtf32x4_i32x4(x) vcvtq_s32_f32(x)//vcvtq_s32_f32(vrndnq_f32(x))

static FORCE_INLINE __m64i _mm64_get_i64_l(__m128i a) { return (__m64i)vget_low_s8(a); }
static FORCE_INLINE __m64i _mm64_get_i64_h(__m128i a) { return (__m64i)vget_high_s8(a); }

#define _mm_cvt_i8x8_i16x8(x) vmovl_s8(x)
#define _mm_cvt_u8x8_i16x8(x) vmovl_u8(x)
#define _mm_cvt_i16x4_i32x4(x) vmovl_s16(x)
#define _mm_cvt_u16x4_i32x4(x) vmovl_u16(x)
#define _mm_cvt_i8x8_i32x4(x) _mm_cvt_i16x4_i32x4(vget_low_s8(_mm_cvt_i8x8_i16x8(x)))
#define _mm_cvt_u8x8_i32x4(x) _mm_cvt_i16x4_i32x4(vget_low_u8(_mm_cvt_u8x8_i16x8(x)))
#define _mm_cvt_u8x8_f32x4(x) _mm_cvtepi32_ps(_mm_cvt_u8x8_i32x4(x))
#define _mm_cvt_u16x4_f32x4(x) _mm_cvtepi32_ps(_mm_cvt_u16x4_i32x4(x))
#define _mm_cvt_i16x4_f32x4(x) _mm_cvtepi32_ps(_mm_cvt_i16x4_i32x4(x))
#define _mm_cvt_i32x4_u16x4(x) vqmovun_s32(x) //_mm_packus_epi32(x,_mm_setzero_si128())
#define _mm_cvt_i32x4_i16x4(x) vqmovn_s32(x) //_mm_packs_epi32(x,_mm_setzero_si128())
#define _mm_cvt_f32x4_i16x4(x) _mm_cvt_i32x4_i16x4(_mm_cvtf32x4_i32x4(x))
#define _mm_cvt_i16x8_u8x8(x) vqmovun_s16(x) //_mm_packus_epi16(x, _mm_setzero_si128())
#define _mm_cvt_i16x8_i8x8(x) vqmovn_s16(x) //_mm_packs_epi16(x, _mm_setzero_si128())
#define _mm_cvt_i32x4_u8x8(x) _mm_cvt_i16x8_u8x8(vcombine_s16(_mm_cvt_i32x4_i16x4(x), vdup_n_s16(0)))//_mm_packus_epi16(_mm_packs_epi32(x,_mm_setzero_si128()),_mm_setzero_si128())
#define _mm_cvt_i32x4_i8x8(x) _mm_cvt_i16x8_i8x8(vcombine_s16(_mm_cvt_i32x4_i16x4(x), vdup_n_s16(0)))
#define _mm_cvt_f32x4_u8x8(x) _mm_cvt_i16x8_u8x8(vcombine_s16(_mm_cvt_i32x4_i16x4(_mm_cvtf32x4_i32x4(x)), vdup_n_s16(0)))

#define _mm_cvtepi8_epi16(x) vmovl_s8(vget_low_s8(x))//_mm_unpacklo_epi8(x,_mm_setzero_si128())
#define _mm_cvtepu8_epi16(x) vmovl_u8(vget_low_u8(x))//_mm_unpacklo_epi8(x,_mm_setzero_si128())
#define _mm_cvtepu16_epi32(x) vmovl_u16(vget_low_u16(x)) //_mm_unpacklo_epi16(x, _mm_setzero_si128())
#define _mm_cvtepi16_epi32(x) vmovl_s16(vget_low_s16(x)) //_mm_unpacklo_epi16(x, _mm_srai_epi16(x, 16))
#define _mm_cvtepi8_epi32(x) _mm_cvtepi16_epi32(_mm_cvtepi8_epi16(x))//_mm_unpacklo_epi16(_mm_unpacklo_epi8(x,_mm_setzero_si128()), _mm_setzero_si128())
#define _mm_cvtepu8_epi32(x) _mm_cvtepi16_epi32(_mm_cvtepu8_epi16(x))//_mm_unpacklo_epi16(_mm_unpacklo_epi8(x,_mm_setzero_si128()), _mm_setzero_si128())

#define _mm_cvtepu8_ps(x) _mm_cvtepi32_ps(_mm_cvtepu8_epi32(x))
#define _mm_cvtepu16_ps(x) _mm_cvtepi32_ps(_mm_cvtepu16_epi32(x))
#define _mm_cvtepi16_ps(x) _mm_cvtepi32_ps(_mm_cvtepi16_epi32(x))
#define _mm_cvtepi32_epu16(x) vcombine_u16(vqmovun_s32(x), vdup_n_u16(0)) //_mm_packus_epi32(x,_mm_setzero_si128())
#define _mm_cvtepi32_epi16(x) vcombine_s16(vqmovn_s32(x), vdup_n_s16(0)) //_mm_packs_epi32(x,_mm_setzero_si128())
#define _mm_cvtepi16_epu8(x) vcombine_u8(vqmovun_s16(x), vdup_n_u16(0)) //_mm_packus_epi16(x, _mm_setzero_si128())
#define _mm_cvtepi16_epi8(x) vcombine_s8(vqmovn_s16(x), vdup_n_s16(0)) //_mm_packs_epi16(x, _mm_setzero_si128())
#define _mm_cvtepi32_epu8(x) _mm_cvtepi16_epu8(_mm_cvtepi32_epi16(x))//_mm_packus_epi16(_mm_packs_epi32(x,_mm_setzero_si128()),_mm_setzero_si128())
#define _mm_cvtepi32_epi8(x) _mm_cvtepi16_epi8(_mm_cvtepi32_epi16(x))//_mm_packus_epi16(_mm_packs_epi32(x,_mm_setzero_si128()),_mm_setzero_si128())

#define _mm_cvtps_epu8(x) _mm_cvtepi32_epu8(_mm_cvtf32x4_i32x4(x))
#define _mm_cvtps_epi16(x) _mm_cvtepi32_epi16(_mm_cvtf32x4_i32x4(x))
#define _mm_cvtps_epu16(x) _mm_cvtepi32_epu16(_mm_cvtf32x4_i32x4(x))

#define _mm_cvtepi16_epi32_l(x) vmovl_s16(vget_low_s16(x)) // _mm_unpacklo_epi16(x, _mm_srai_epi16(x, 16))
#define _mm_cvtepi16_epi32_h(x) vmovl_s16(vget_high_s16(x)) //_mm_unpackhi_epi16(x, _mm_srai_epi16(x, 16))
#define _mm_cvtepi16_ps_l(x) _mm_cvtepi32_ps(_mm_cvtepi16_epi32_l(x))
#define _mm_cvtepi16_ps_h(x) _mm_cvtepi32_ps(_mm_cvtepi16_epi32_h(x))
#define _mm_cvtepu8_ps_l(x) _mm_cvtepi32_ps(_mm_cvtepi16_epi32_l(_mm_cvtepu8_epi16(x)))
#define _mm_cvtepu8_ps_h(x) _mm_cvtepi32_ps(_mm_cvtepi16_epi32_h(_mm_cvtepu8_epi16(x)))

#define _mm_cvtepu8_epi16_l(x) vmovl_u8(vget_low_u8(x))//_mm_unpacklo_epi16(x, _mm_setzero_si128())
#define _mm_cvtepu8_epi16_h(x) vmovl_u8(vget_high_u8(x))//_mm_unpackhi_epi16(x, _mm_setzero_si128())
#define _mm_cvtepu16_epi32_l(x) vmovl_u16(vget_low_u16(x))//_mm_unpacklo_epi16(x, _mm_setzero_si128())
#define _mm_cvtepu16_epi32_h(x) vmovl_u16(vget_high_u16(x))//_mm_unpackhi_epi16(x, _mm_setzero_si128())
#define _mm_cvtepu16_ps_l(x) _mm_cvtepi32_ps(_mm_cvtepu16_epi32_l(x))
#define _mm_cvtepu16_ps_h(x) _mm_cvtepi32_ps(_mm_cvtepu16_epi32_h(x))

/***************************************************************************
*                SET  and GET
***************************************************************************/
// r0 := a; r1 := 0x0 ; r2 := 0x0 ; r3 := 0x0
static FORCE_INLINE __m128i _mm_cvtsi32_si128(int a) { return vsetq_lane_s32(a, vdupq_n_s32(0), 0); }

static FORCE_INLINE __m128i _mm_set1_epi8(char b) { return (__m128i)vdupq_n_s8((int8_t)b); }
static FORCE_INLINE __m128i _mm_set1_epi16(short w) { return (__m128i)vdupq_n_s16((int16_t)w); }
static FORCE_INLINE __m128i _mm_set1_epi32(int i) { return vdupq_n_s32(i); }
static FORCE_INLINE __m128 _mm_set1_ps(float w) { return vdupq_n_f32(w); }
#define _mm_set_ps1 _mm_set1_ps

static FORCE_INLINE __m128 _mm_set_ps(float w, float z, float y, float x)
{
    float __attribute__((aligned(16))) data[4] ={x, y, z, w};
    return vld1q_f32(data);
}

static FORCE_INLINE __m128i _mm_setr_epi16(short w0, short w1, short w2, short w3, short w4, short w5, short w6, short w7)
{
    short __attribute__((aligned(16))) data[8] ={w0, w1, w2, w3, w4, w5, w6, w7};
    return (__m128i)vld1q_s16((int16_t*)data);
}
static FORCE_INLINE __m128i _mm_set_epi16(short w7, short w6, short w5, short w4, short w3, short w2, short w1, short w0)
{
    short __attribute__((aligned(16))) data[8] ={w0, w1, w2, w3, w4, w5, w6, w7};
    return (__m128i)vld1q_s16((int16_t*)data);
}
static FORCE_INLINE __m128i _mm_set_epi8(char _B15, char _B14, char _B13, char _B12, char _B11, char _B10, char _B9, char _B8, char _B7, char _B6, char _B5, char _B4, char _B3, char _B2, char _B1, char _B0)
{
    char __attribute__((aligned(16))) data[16] ={_B0,_B1,_B2,_B3,_B4,_B5,_B6,_B7,_B8,_B9,_B10,_B11,_B12,_B13,_B14,_B15};
    return (__m128i)vld1q_s8((int8_t*)data);
}
static FORCE_INLINE __m128i _mm_setr_epi8(char _B0, char _B1, char _B2, char _B3, char _B4, char _B5, char _B6, char _B7, char _B8, char _B9, char _B10, char _B11, char _B12, char _B13, char _B14, char _B15)
{
    char __attribute__((aligned(16))) data[16] ={_B0,_B1,_B2,_B3,_B4,_B5,_B6,_B7,_B8,_B9,_B10,_B11,_B12,_B13,_B14,_B15};
    return (__m128i)vld1q_s8((int8_t*)data);
}
static FORCE_INLINE __m128i _mm_setzero_si128() { return vdupq_n_s32(0); }
static FORCE_INLINE __m128 _mm_setzero_ps(void) { return vdupq_n_f32(0); }

// uint32 r[4]={a.u32[i.u2[0]], a.u32[i.u2[1]], b.u32[i.u2[2]], b.u32[i.u2[3]]}
static FORCE_INLINE __m128i _mm_shuffle_epi32(__m128i a, int imm)
{
    int32_t __attribute__((aligned(16))) data[4] = {((int32_t*)&a)[GET_UINT2(imm,0)], ((int32_t*)&a)[GET_UINT2(imm,1)], ((int32_t*)&a)[GET_UINT2(imm,2)], ((int32_t*)&a)[GET_UINT2(imm,3)]};
    return (__m128i)vld1q_s32((int32_t*)data);
}
// float r[4]={a.f32[i.u2[0]], a.f32[i.u2[1]], b.f32[i.u2[2]], b.f32[i.u2[3]]}
static FORCE_INLINE __m128 _mm_shuffle_ps(__m128 a, __m128 b, int imm)
{
    float __attribute__((aligned(16))) data[4] = {((float*)&a)[GET_UINT2(imm,0)], ((float*)&a)[GET_UINT2(imm,1)], ((float*)&b)[GET_UINT2(imm,2)], ((float*)&b)[GET_UINT2(imm,3)]};
    return (__m128)vld1q_f32((float*)data);
}
static FORCE_INLINE __m128i _mm_table16_epu8(__m128i a, __m128i i)
{
    return vcombine_u64(vtbl2_u8(*(uint8x8x2_t*)&a, vget_low_u8(i)), vdup_n_s32(0));
}
static FORCE_INLINE __m128i _mm_table32_epu8(__m128i a0, __m128i a1, __m128i i)
{
    uint8x8x4_t a={((uint8x8_t*)&a0)[0],((uint8x8_t*)&a0)[1],((uint8x8_t*)&a1)[0],((uint8x8_t*)&a1)[1]};
    return vcombine_u64(vtbl4_u8(a, vget_low_u8(i)), vdup_n_s32(0));
}

// Moves the least significant 32 bits of a to a 32-bit integer.
static FORCE_INLINE int _mm_cvtsi128_si32(__m128i a) { return vgetq_lane_s32(a, 0); }
static FORCE_INLINE float _mm_cvtss_f32(__m128 a) { return vgetq_lane_f32(a, 0); }

/***************************************************************************
*                abs
***************************************************************************/
static FORCE_INLINE __m128i _mm_abs_epi8(__m128i a){ return vabsq_s8(a); }
static FORCE_INLINE __m128i _mm_abs_epi16(__m128i a){ return vabsq_s16(a); }
static FORCE_INLINE __m128i _mm_abs_epi32(__m128i a){ return vabsq_s32(a); }
static FORCE_INLINE __m128 _mm_abs_ps(__m128 a){ return vabsq_f32(a); }
static FORCE_INLINE __m128 _mm_fabs_ps(__m128 a){ return vabsq_f32(a); }
// |a-b|
static FORCE_INLINE __m128i _mm_abd_epu8(__m128i a, __m128i b) { return vabdq_u8(a, b); }
// |a-b|
static FORCE_INLINE __m128i _mm_abd_epi16(__m128i a, __m128i b) { return vabdq_s16(a, b); }

/***************************************************************************
*                max and min
***************************************************************************/
static FORCE_INLINE __m128i _mm_max_epu8(__m128i a, __m128i b) { return vmaxq_u8(a, b); }
static FORCE_INLINE __m128i _mm_max_epi16(__m128i a, __m128i b) { return vmaxq_s16(a, b); }
static FORCE_INLINE __m128i _mm_max_epi8(__m128i a, __m128i b) { return vmaxq_s8(a, b); } // SSE4.1
static FORCE_INLINE __m128i _mm_max_epu16(__m128i a, __m128i b) { return vmaxq_u16(a, b); } // SSE4.1
static FORCE_INLINE __m128i _mm_max_epi32(__m128i a, __m128i b) { return vmaxq_s32(a, b); }
static FORCE_INLINE __m128 _mm_max_ps(__m128 a, __m128 b) { return vmaxq_f32(a, b); }

static FORCE_INLINE __m128i _mm_min_epu8(__m128i a, __m128i b) { return vminq_u8(a, b); }
static FORCE_INLINE __m128i _mm_min_epi16(__m128i a, __m128i b) { return vminq_s16(a, b); }
static FORCE_INLINE __m128i _mm_min_epi8(__m128i a, __m128i b) { return vminq_s8(a, b); }// SSE4.1
static FORCE_INLINE __m128i _mm_min_epu16(__m128i a, __m128i b) { return vminq_u16(a, b); } // SSE4.1
static FORCE_INLINE __m128i _mm_min_epi32(__m128i a, __m128i b) { return vminq_s32(a, b); }
static FORCE_INLINE __m128 _mm_min_ps(__m128 a, __m128 b) { return vminq_f32(a, b); }

/***************************************************************************
*                add and sub
***************************************************************************/
static FORCE_INLINE __m128i _mm_add_epu8(__m128i a, __m128i b) { return vaddq_u8(a, b); }
static FORCE_INLINE __m128i _mm_add_epi8(__m128i a, __m128i b) { return vaddq_s8(a, b); }
static FORCE_INLINE __m128i _mm_add_epi16(__m128i a, __m128i b) { return vaddq_s16(a, b); }
static FORCE_INLINE __m128i _mm_add_epi32(__m128i a, __m128i b) { return vaddq_s32(a, b); }
static FORCE_INLINE __m128i _mm_sub_epu8(__m128i a, __m128i b) { return vsubq_u8(a, b); }
static FORCE_INLINE __m128i _mm_sub_epi8(__m128i a, __m128i b) { return vsubq_s8(a, b); }
static FORCE_INLINE __m128i _mm_sub_epi16(__m128i a, __m128i b) { return vsubq_s16(a, b); }
static FORCE_INLINE __m128i _mm_sub_epi32(__m128i a, __m128i b) { return vsubq_s32(a, b); }
static FORCE_INLINE __m128 _mm_add_ps(__m128 a, __m128 b) { return vaddq_f32(a, b); }
static FORCE_INLINE __m128 _mm_sub_ps(__m128 a, __m128 b) { return vsubq_f32(a, b); }

// saturation add and sub
static FORCE_INLINE __m128i _mm_adds_epu8(__m128i a, __m128i b) { return vqaddq_u8(a, b); }
static FORCE_INLINE __m128i _mm_adds_epi8(__m128i a, __m128i b) { return vqaddq_s8(a, b); }
static FORCE_INLINE __m128i _mm_adds_epi16(__m128i a, __m128i b) { return vqaddq_s16(a, b); }
static FORCE_INLINE __m128i _mm_adds_epu16(__m128i a, __m128i b) { return vqaddq_u16(a, b); }
static FORCE_INLINE __m128i _mm_subs_epi8(__m128i a, __m128i b) { return vqsubq_s8(a, b); }
static FORCE_INLINE __m128i _mm_subs_epu8(__m128i a, __m128i b) { return vqsubq_u8(a, b); }
static FORCE_INLINE __m128i _mm_subs_epu16(__m128i a, __m128i b) { return vqsubq_u16(a, b); }
static FORCE_INLINE __m128i _mm_subs_epi16(__m128i a, __m128i b) { return vqsubq_s16(a, b); }

// float r[4]={a.f32[0]+a.f32[1], a.f32[2]+a.f32[3], b.f32[0]+b.f32[1], b.f32[2]+b.f32[3]};
static FORCE_INLINE __m128 _mm_hadd_ps(__m128 a, __m128 b) { return vcombine_f32(vpadd_f32(vget_low_f32(a), vget_high_f32(a)), vpadd_f32(vget_low_f32(b), vget_high_f32(b))); }
// int16 r[8]={a.i16[0]+a.i16[1], a.i16[2]+a.i16[3], a.i16[4]+a.i16[5], a.i16[6]+a.i16[7], b.i16[0]+b.i16[1], b.i16[2]+b.i16[3], b.i16[4]+b.i16[5], b.i16[6]+b.i16[7]};
static FORCE_INLINE __m128i _mm_hadd_epi16(__m128i a, __m128i b) { return (__m128i)vcombine_s16(vqmovn_s32(vpaddlq_s16(a)), vqmovn_s32(vpaddlq_s16(b))); }
// int32 r[4]={a.i32[0]+a.i32[1], a.i32[2]+a.i32[3], b.i32[0]+b.i32[1], b.i32[2]+b.i32[3]};
static FORCE_INLINE __m128i _mm_hadd_epi32(__m128i a, __m128i b) { return (__m128i)vcombine_s32(vqmovn_s64(vpaddlq_s32(a)), vqmovn_s64(vpaddlq_s32(b))); }

static FORCE_INLINE __m128i _mm_addw_i8x8(__m128i a, __m64i b) { return (__m128i)vaddw_s8((int16x8_t)a, (int8x8_t)b); }
static FORCE_INLINE __m128i _mm_addw_u8x8(__m128i a, __m64i b) { return (__m128i)vaddw_u8((uint16x8_t)a, (uint8x8_t)b); }
static FORCE_INLINE __m128i _mm_subw_u8x8(__m128i a, __m64i b) { return (__m128i)vsubw_u8((uint16x8_t)a, (uint8x8_t)b); }
static FORCE_INLINE __m128i _mm_addw_u16x4(__m128i a, __m64i b) { return (__m128i)vaddw_u16((uint32x4_t)a, (uint16x4_t)b); }
static FORCE_INLINE __m128i _mm_addw_i16x4(__m128i a, __m64i b) { return (__m128i)vaddw_s16((int32x4_t)a, (int16x4_t)b); }
static FORCE_INLINE __m128i _mm_subw_i16x4(__m128i a, __m64i b) { return (__m128i)vsubw_s16((int32x4_t)a, (int16x4_t)b); }
static FORCE_INLINE __m128i _mm_subw_u16x4(__m128i a, __m64i b) { return (__m128i)vsubw_u16((uint32x4_t)a, (uint16x4_t)b); }

static FORCE_INLINE __m128i _mm_addl_u8x8(__m64i a, __m64i b) { return vaddl_u8(a, b); }
static FORCE_INLINE __m128i _mm_subl_u8x8(__m64i a, __m64i b) { return vsubl_u8(a, b); }
static FORCE_INLINE __m128i _mm_addl_i16x4(__m64i a, __m64i b) { return vaddl_s16(a, b); }
static FORCE_INLINE __m128i _mm_subl_i16x4(__m64i a, __m64i b) { return vsubl_s16(a, b); }
/***************************************************************************
*                Multiply
***************************************************************************/
static FORCE_INLINE __m128i _mm_mulhi_epi16(__m128i a, __m128i b) { return vshrq_n_s16(vqdmulhq_s16(a, b), 1); }
static FORCE_INLINE __m128i _mm_mullo_epi16(__m128i a, __m128i b) { return vmulq_s16(a, b); }
static FORCE_INLINE __m128i _mm_mullo_epi32(__m128i x, __m128i y) { return (__m128i)vmulq_s32((int32x4_t)x, (int32x4_t)y); }
static FORCE_INLINE __m128 _mm_mul_ps(__m128 a, __m128 b) { return vmulq_f32(a, b); }

static FORCE_INLINE __m128i _mm_mull_u8x8(__m64i a, __m64i b) { return (__m128i)vmull_u8((uint8x8_t)a, (uint8x8_t)b); }

// int32 r[4]={a.i16[0]*b.i16[0]+a.i16[1]*b.i16[1], a.i16[2]*b.i16[2]+a.i16[3]*b.i16[3], a.i16[4]*b.i16[4]+a.i16[5]*b.i16[5], a.i16[6]*b.i16[6]+a.i16[7]*b.i16[7]};
static FORCE_INLINE __m128i _mm_madd_epi16(__m128i a, __m128i b)
{
    int32x4_t r_l = vmull_s16(vget_low_s16((int16x8_t)a), vget_low_s16((int16x8_t)b));
    int32x4_t r_h = vmull_s16(vget_high_s16((int16x8_t)a), vget_high_s16((int16x8_t)b));
    return vcombine_s32(vpadd_s32(vget_low_s32(r_l), vget_high_s32(r_l)), vpadd_s32(vget_low_s32(r_h), vget_high_s32(r_h)));
}
// a*b
static FORCE_INLINE __m128i _mm_muln_i16(__m128i a, int16 b) { return vmulq_n_s16(a,b); }
static FORCE_INLINE __m128i _mm_muln_i32(__m128i a, int32 b) { return vmulq_n_s32(a, b); }
static FORCE_INLINE __m128 _mm_muln_f32(__m128 a, float b) { return vmulq_n_f32(a, b); }
// a*x+b
static FORCE_INLINE __m128i _mm_maddn_i16(int16 a, __m128i x, __m128i b) { return vmlaq_n_s16(b, x, a); }
// a*x+b
static FORCE_INLINE __m128i _mm_maddn_i32(int a, __m128i x, __m128i b) { return vmlaq_n_s32(b, x, a); }
// a-b*c
static FORCE_INLINE __m128i _mm_submn_i16(__m128i a, __m128i b, int16 c) { return vmlsq_n_s16(a, b, c); }
// a*x+b
static FORCE_INLINE __m128 _mm_maddn_f32(float a, __m128 x, __m128 b) { return vmlaq_n_f32(b, x, a); }
// a*b+c
static FORCE_INLINE __m128 _mm_madd_f32(__m128 a, __m128 b, __m128 c) { return vmlaq_f32(c, a, b); }
// a*b-c
static FORCE_INLINE __m128 _mm_msub_f32(__m128 a, __m128 b, __m128 c) { return vsubq_f32(vmulq_f32(a, b), c); }
// a-b*c
static FORCE_INLINE __m128 _mm_subm_f32(__m128 a, __m128 b, __m128 c) { return vmlsq_f32(a, b, c); }


/***************************************************************************
*                absdiff
***************************************************************************/
// int64 r[2]={|a0-b0|+|a1-b1|+|a2-b2|+|a3-b3|+|a4-b4|+|a5-b5|+|a6-b6|+|a7-b7|, |a8-b8|+|a9-b9|+|a10-b10|+|a11-b11|+|a12-b12|+|a13-b13|+|a14-b14|+|a15-b15|}
static FORCE_INLINE __m128i _mm_sad_epu8(__m128i a, __m128i b)
{
    uint16x8_t t = vpaddlq_u8(vabdq_u8((uint8x16_t)a, (uint8x16_t)b));
    uint32x4_t x = vpaddlq_u16(t);
    uint64x2_t y = vpaddlq_u32(x);
    return y;
}

/***************************************************************************
*                divides
***************************************************************************/
static FORCE_INLINE __m128 _mm_div_ps(__m128 a, __m128 b)
{
    // get an initial estimate of 1/b.
    float32x4_t reciprocal = vrecpeq_f32(b);

    // use a couple Newton-Raphson steps to refine the estimate.  Depending on your
    // application's accuracy requirements, you may be able to get away with only
    // one refinement (instead of the two used here).  Be sure to test!
    reciprocal = vmulq_f32(vrecpsq_f32(b, reciprocal), reciprocal);
    // reciprocal = vmulq_f32(vrecpsq_f32(b, reciprocal), reciprocal);

    // and finally, compute a/b = a*(1/b)
    float32x4_t result = vmulq_f32(a, reciprocal);
    return result;
}

static FORCE_INLINE __m128 _mm_rcp_ps(__m128 a) { return vrecpeq_f32(a); }

static FORCE_INLINE __m128 _mm_sqrt_ps(__m128 in)
{
    __m128 recipsq = vrsqrteq_f32(in);
    __m128 sq = vrecpeq_f32(recipsq);
    // use step versions of both sqrt and recip for better accuracy?
    //precision loss
    // __m128 recipsq = vrsqrtsq_f32(in,vdupq_n_f32(1.0));
    // __m128 sq = vrecpsq_f32(recipsq,vdupq_n_f32(1.0));
    return sq;
}
static FORCE_INLINE __m128 _mm_rsqrt_ps(__m128 x) { return vrsqrteq_f32(x); }
static FORCE_INLINE float rsqrt(const float x)
{
    float32x2_t x2=vrsqrte_f32(vld1_dup_f32(&x));
    return vget_lane_f32(x2, 0);
}
/***************************************************************************
*                logic
***************************************************************************/
static FORCE_INLINE __m128i _mm_or_si128(__m128i a, __m128i b) { return vorrq_s32(a, b); }
static FORCE_INLINE __m128 _mm_or_ps(__m128 a, __m128 b) { return vorrq_s32((__m128i)a, (__m128i)b); }
static FORCE_INLINE __m128i _mm_xor_si128(__m128i a, __m128i b) { return veorq_s32(a, b); }
static FORCE_INLINE __m128 _mm_xor_ps(__m128 a, __m128 b) { return (__m128)veorq_s32((__m128i)a, (__m128i)b); }
static FORCE_INLINE __m128i _mm_and_si128(__m128i a, __m128i b) { return vandq_s32(a, b); }
static FORCE_INLINE __m128 _mm_and_ps(__m128 a, __m128 b) { return (__m128)vandq_s32((__m128i)a, (__m128i)b); }

// r := (~a) & b
static FORCE_INLINE __m128i _mm_andnot_si128(__m128i a, __m128i b) { return vbicq_s32(b, a); }
static FORCE_INLINE __m128 _mm_andnot_ps(__m128 a, __m128 b) { return vbicq_s32(b, a); }

// a[i]>b[i]?0xFF:0
static FORCE_INLINE __m128i _mm_cmpgt_epi8(__m128i a, __m128i b) { return vcgtq_s8(a, b); }
static FORCE_INLINE __m128i _mm_cmpgt_epu8(__m128i a, __m128i b) { return vcgtq_u8(a, b); }
static FORCE_INLINE __m128i _mm_cmpgt_epi16(__m128i a, __m128i b) { return vcgtq_s16(a, b); }
static FORCE_INLINE __m128i _mm_cmpgt_epi32(__m128i a, __m128i b) { return vcgtq_s32(a, b); }
static FORCE_INLINE __m128 _mm_cmpgt_ps(__m128 a, __m128 b) { return vcgtq_f32(a, b); }

// a[i]<b[i]?0xFF:0
static FORCE_INLINE __m128i _mm_cmplt_epi8(__m128i a, __m128i b) { return vcltq_s8(a, b); }
static FORCE_INLINE __m128i _mm_cmplt_epu8(__m128i a, __m128i b) { return vcltq_u8(a, b); }
static FORCE_INLINE __m128i _mm_cmplt_epi16(__m128i a, __m128i b) { return vcltq_s16(a, b); }
static FORCE_INLINE __m128i _mm_cmplt_epi32(__m128i a, __m128i b) { return vcltq_s32(a, b); }
static FORCE_INLINE __m128 _mm_cmplt_ps(__m128 a, __m128 b) { return vcltq_f32(a, b); }

static FORCE_INLINE __m128 _mm_cmpge_ps(__m128 a, __m128 b) { return (__m128)vcgeq_f32(a, b); }
static FORCE_INLINE __m128 _mm_cmple_ps(__m128 a, __m128 b) { return (__m128)vcleq_f32(a, b); }

/***************************************************************************
*                load and store
***************************************************************************/
static FORCE_INLINE __m128i _mm_load_si128(const __m128i *p) { return vld1q_u8((uint8_t *)p); }
static FORCE_INLINE __m128i _mm_loadu_si128(const __m128i *p) { return vld1q_u8((uint8_t *)p); }
static FORCE_INLINE void _mm_store_si128(__m128i *p, __m128i a) { vst1q_u8((uint8_t*)p, a); }
static FORCE_INLINE void _mm_storeu_si128(__m128i *p, __m128i a) { vst1q_u8((uint8_t*)p, a); }

static FORCE_INLINE __m128 _mm_load_ps(const float * p) { return vld1q_f32(p); }
static FORCE_INLINE __m128 _mm_loadu_ps(const float * p) { return vld1q_f32(p); }
static FORCE_INLINE void _mm_store_ps(float *p, __m128 a) { vst1q_f32(p, a); }
static FORCE_INLINE void _mm_storeu_ps(float *p, __m128 a) { vst1q_f32(p, a); }

// Load the lower 64 bits of the value pointed to by p into the lower 64 bits of the result, zeroing the upper 64 bits of the result.
static FORCE_INLINE __m128i _mm_loadl_epi64(__m128i const*p) { return vcombine_u8(vld1_u8((uint8_t const *)p), vcreate_u8(0)); }
static FORCE_INLINE void _mm_store_i64(void* pData, __m64i x) { vst1_u8((uint8_t*)pData, (uint8x8_t)(x)); }
static FORCE_INLINE void _mm_storel_epi64(__m128i* pData, __m128i b) { vst1_u8((uint8_t *)pData, vget_low_u8((uint8x16_t)b)); }

// Loads an single-precision, floating-point value into the low word and clears the upper three words.
static FORCE_INLINE __m128 _mm_load_ss(const float * p) { return vsetq_lane_f32(*p, vdupq_n_f32(0), 0); }

// Stores the lower single-precision, floating-point value.
static FORCE_INLINE void _mm_store_ss(float *p, __m128 a) { vst1q_lane_f32(p, a, 0); }
static FORCE_INLINE __m64i _mm64_load_i64(void* pData) { return (__m64i)vld1_u8((uint8_t const *)pData); }
static FORCE_INLINE __m128ix2 _mm_load_i32x8(int* pData) { __m128ix2 x={vld1q_u8((uint8_t *)pData), vld1q_u8((uint8_t *)(pData+4))}; return x; }

static FORCE_INLINE uint8x8_t _mm_load_i32(void* pData)
{
    uint8_t __attribute__((aligned(16))) data[8] ={((uint8_t*)pData)[0], ((uint8_t*)pData)[1], ((uint8_t*)pData)[2], ((uint8_t*)pData)[3], 0, 0, 0, 0};
    return vld1_u8((uint8_t*)data);
    //return vld1_u8((uint8_t*)pData);
}
static FORCE_INLINE void _mm_store_i32(Byte* pData, uint8x8_t x)
{
    Byte* pX=(Byte*)&x;
    pData[0]=pX[0];pData[1]=pX[1];pData[2]=pX[2];pData[3]=pX[3];
    //vst1_u8(pData, x);
}
static FORCE_INLINE void _mm_store_i16(Byte* pData, uint8x8_t x)
{
    Byte* pX=(Byte*)&x;
    pData[0]=pX[0]; pData[1]=pX[1];
    //vst1_u8(pData, x);
}
// load as byte
static FORCE_INLINE __m128i _mm_load_i8x16(int8* pData){ return _mm_loadu_si128((__m128i*)pData); }
static FORCE_INLINE __m128i _mm_load_u8x16(Byte* pData){ return _mm_loadu_si128((__m128i*)pData); }
static FORCE_INLINE __m128i _mm_load_i8x8(int8* pData){ return _mm_loadl_epi64((__m128i*)pData); }
static FORCE_INLINE __m128i _mm_load_u8x8(Byte* pData){ return _mm_loadl_epi64((__m128i*)pData); }
// load as int16
static FORCE_INLINE __m128i _mm_load_i16x8(int16* pData){ return _mm_loadu_si128((__m128i*)pData); }
static FORCE_INLINE __m128i _mm_load_i16x8(int8* pData){ return _mm_cvt_i8x8_i16x8(_mm64_load_i64(pData)); }//vmovl_s8(_mm_load_u64(pData)); }//_mm_cvtepi8_epi16(_mm_loadl_epi64((__m128i*)pData)); }
static FORCE_INLINE __m128i _mm_load_i16x8(Byte* pData){ return _mm_cvt_u8x8_i16x8(_mm64_load_i64(pData)); }//vmovl_u8(_mm_load_u64(pData)); }//_mm_cvtepu8_epi16(_mm_loadl_epi64((__m128i*)pData)); }
static FORCE_INLINE __m128i _mm_load_i16x4(int16* pData){ return _mm_loadl_epi64((__m128i*)pData); }
static FORCE_INLINE __m128i _mm_load_i16x4(int8* pData){ int32x2_t x=_mm_load_i32(pData); return _mm_cvt_i8x8_i16x8(x); }
static FORCE_INLINE __m128i _mm_load_i16x4(Byte* pData){ int32x2_t x=_mm_load_i32(pData); return _mm_cvt_u8x8_i16x8(x); }
// load as int32
static FORCE_INLINE __m128i _mm_load_i32x4(int8* pData){ return _mm_cvt_i8x8_i32x4(_mm_load_i32(pData)); }//_mm_cvtepi16_epi32(vmovl_s8(_mm_load_u64(pData))); }//_mm_cvtepi8_epi32(_mm_loadl_epi64((__m128i*)pData)); }
static FORCE_INLINE __m128i _mm_load_i32x4(Byte* pData){ return _mm_cvt_u8x8_i32x4(_mm_load_i32(pData)); }//_mm_cvtepi16_epi32(vmovl_u8(_mm_load_u64(pData))); }//_mm_cvtepu8_epi32(_mm_loadl_epi64((__m128i*)pData)); }
static FORCE_INLINE __m128i _mm_load_i32x4(int16* pData){ return _mm_cvt_i16x4_i32x4(_mm64_load_i64(pData)); }//vmovl_s16(_mm_load_u64(pData)); }//_mm_cvtepi16_epi32(_mm_loadl_epi64((__m128i*)pData)); }
static FORCE_INLINE __m128i _mm_load_i32x4(uint16* pData){ return _mm_cvt_u16x4_i32x4(_mm64_load_i64(pData)); }//vmovl_u16(_mm_load_u64(pData)); }//_mm_cvtepu16_epi32(_mm_loadl_epi64((__m128i*)pData)); }
static FORCE_INLINE __m128i _mm_load_i32x4(int32* pData){ return _mm_loadu_si128((__m128i*)pData); }
// load as float
static FORCE_INLINE __m128 _mm_load_f32x4(float* pData){ return _mm_loadu_ps(pData); }
static FORCE_INLINE __m128 _mm_load_f32x4(Byte* pData){ return _mm_cvtepi32_ps(_mm_load_i32x4(pData)); }//_mm_cvtepu8_ps(_mm_loadl_epi64((__m128i*)pData)); }
static FORCE_INLINE __m128 _mm_load_f32x4(int16* pData){ return _mm_cvtepi32_ps(_mm_load_i32x4(pData)); }//_mm_cvtepi16_ps(_mm_loadl_epi64((__m128i*)pData)); }
static FORCE_INLINE __m128 _mm_load_f32x4(int32* pData){ return _mm_cvtepi32_ps(_mm_loadu_si128((__m128i*)pData)); }
// load duplicate
static FORCE_INLINE __m128i _mm_load_dup4_i16x8(int16* pData)
{
    int16x4x2_t x = vld2_dup_s16(pData);
    return (__m128i)vcombine_s16(x.val[0], x.val[1]);
}
// store as byte
static FORCE_INLINE void _mm_store_u8x8(Byte* pData, __m128i x){ _mm_store_i64(pData, vget_low_u8(x)); }
static FORCE_INLINE void _mm_store_u8x16(Byte* pData, __m128i x){ _mm_storeu_si128((__m128i*)pData, x); }
static FORCE_INLINE void _mm_store_i16x8(Byte* pData, __m128i x){ _mm_store_i64(pData, _mm_cvt_i16x8_u8x8(x)); }//_mm_store_u64(pData, vqmovun_s16(x)); }//_mm_storel_epi64((__m128i*)pData, _mm_cvtepi16_epu8(x)); }
static FORCE_INLINE void _mm_store_i16x4(Byte* pData, __m128i x) { _mm_store_i32(pData, _mm_cvt_i16x8_u8x8(x)); }
//static FORCE_INLINE void _mm_store_i16x4(int8* pData, __m128i x) { _mm_store_i32(pData, _mm_cvt_i16x8_i8x8(x)); }
static FORCE_INLINE void _mm_store_i16x2(Byte* pData, __m128i x) { _mm_store_i16(pData, _mm_cvt_i16x8_u8x8(x)); }
static FORCE_INLINE void _mm_store_i32x4(Byte* pData, __m128i x){ _mm_store_i32(pData, _mm_cvt_i32x4_u8x8(x)); }//_mm_store_u64(pData, vqmovun_s16(_mm_cvtepi32_epi16(x))); }//_mm_storel_epi64((__m128i*)pData, _mm_cvtepi32_epu8(x)); }
//static FORCE_INLINE void _mm_store_i32x4(int8* pData, __m128i x) { _mm_store_i32(pData, _mm_cvt_i32x4_i8x8(x)); }
static FORCE_INLINE void _mm_store_f32x4(Byte* pData, __m128 x){ _mm_store_i32(pData, _mm_cvt_f32x4_u8x8(x)); }//_mm_store_u64(pData, vqmovun_s16(_mm_cvtps_epi16(x))); }//_mm_storel_epi64((__m128i*)pData, _mm_cvtps_epu8(x)); }
// store as int16
static FORCE_INLINE void _mm_store_i16x4(int16* pData, __m128i x){ _mm_store_i64(pData, vget_low_u8(x)); }
static FORCE_INLINE void _mm_store_i16x8(int16* pData, __m128i x){ _mm_storeu_si128((__m128i*)pData, x); }
static FORCE_INLINE void _mm_store_i32x4(int16* pData, __m128i x){ _mm_store_i64(pData, _mm_cvt_i32x4_i16x4(x)); }//_mm_store_u64(pData, vqmovn_s32(x)); }//_mm_storel_epi64((__m128i*)pData, _mm_cvtepi32_epi16(x)); }
static FORCE_INLINE void _mm_store_f32x4(int16* pData, __m128 x){ _mm_store_i64(pData, _mm_cvt_f32x4_i16x4(x)); }//_mm_store_u64(pData, vqmovn_s32(_mm_cvttps_epi32(x))); }//_mm_storel_epi64((__m128i*)pData, _mm_cvtps_epi16(x)); }
// store as int32
static FORCE_INLINE void _mm_store_i32x4(int32* pData, __m128i x){ _mm_storeu_si128((__m128i*)pData, x); }
static FORCE_INLINE void _mm_store_f32x4(int32* pData, __m128 x){ _mm_storeu_si128((__m128i*)pData, _mm_cvtf32x4_i32x4(x)); }
// store as float32
static FORCE_INLINE void _mm_store_f32x4(float* pData, __m128 x){ _mm_storeu_ps(pData, x); }
static FORCE_INLINE void _mm_store_i32x4(float* pData, __m128i x){ _mm_storeu_ps(pData, _mm_cvtepi32_ps(x)); }

static FORCE_INLINE __m64i _mm64_cvt_i16_u8(__m128i x) { return vqmovun_s16(x); }
static FORCE_INLINE __m128i _mm64_cvt_u8_i16(__m64i x) { return vmovl_u8(x); }
static FORCE_INLINE __m128i _mm64_cross_u8x8(__m64i x, __m64i y) { uint8x8x2_t xy=vzip_u8(x, y); return vcombine_u8(xy.val[0], xy.val[1]); }
static FORCE_INLINE __m128ix2 _mm_cross_u8x16(__m128i x, __m128i y) { uint8x16x2_t uv=vzipq_u8(x, y); return *(__m128ix2*)&uv; }
// store cross: a0 b0 a1 b1 a2 b2 a3 b3 a4 b4 a5 b5 a6 b6 a7 b7 a8 b8 a9 b9 a10 b10 a11 b11 a12 b12 a13 b13 a14 b14 a15 b15
static FORCE_INLINE void _mm_store_cross_u8x16x2(uint8* pData, __m128i a, __m128i b) { uint8x16x2_t uv={a,b}; vst2q_u8(pData, uv); }
static FORCE_INLINE void _mm_store_cross_i16x8x2(uint8* pUV, __m128i u, __m128i v) { uint8x8x2_t uv={vqmovun_s16(u),vqmovun_s16(v)}; vst2_u8(pUV, uv); }
static FORCE_INLINE void _mm64_store_cross_u8x8x2(uint8* pUV, __m64i u, __m64i v) { uint8x8x2_t uv={u,v}; vst2_u8(pUV, uv); }
//static FORCE_INLINE void _mm_store_cross_u8x8_i16x8(uint8* pData, __m64i a, __m128i b) { uint8x8x2_t uv={a,vqmovun_s16(b)}; vst2_u8(pData, uv); }
static FORCE_INLINE __m64ix2 _mm64_load_split_u8x8x2(uint8* pUV) { uint8x8x2_t uv=vld2_u8(pUV); return *(__m64ix2*)&uv; }
static FORCE_INLINE __m128ix2 _mm_load_split_i16x8x2(uint8* pUV) { uint8x8x2_t uv=vld2_u8(pUV); uint16x8x2_t uv2={vmovl_u8(uv.val[0]), vmovl_u8(uv.val[1])}; return *(__m128ix2*)&uv2; }

//static FORCE_INLINE __m128i _mm_insert_epi8(__m128i x, int a, const int i) { return vld1q_lane_u8((uint8_t*)&a, x, i); }
//static FORCE_INLINE __m128i _mm_insert_epi16(__m128i x, int a, const int i) { return vld1q_lane_u16((uint16_t*)&a, x, i); }
//static FORCE_INLINE __m128i _mm_insert_epi32(__m128i x, int a, const int i) { return vld1q_lane_u32((uint32_t*)&a, x, i); }
/***************************************************************************
*                shift
***************************************************************************/
#define _mm_srai_epi64(a,count)  vshrq_n_s64(a,count)
#define _mm_srli_epi64(a,count)  vshrq_n_u64(a,count)
#define _mm_slli_epi64(a,count)  vshlq_n_s64(a,count)

#define _mm_srai_epi32(a,count)  vshrq_n_s32(a,count)
#define _mm_srli_epi32(a,count)  vshrq_n_u32(a,count)
#define _mm_slli_epi32(a,count)  vshlq_n_s32(a,count)

#define _mm_srai_epi16(a,count)  vshrq_n_s16(a,count)
#define _mm_srli_epi16(a,count)  vshrq_n_u16(a,count)
#define _mm_slli_epi16(a,count)  vshlq_n_s16(a,count)

#define _mm_slli_epi8(x, n) vshlq_n_u8(x, n)
#define _mm_srli_epi8(x, n) vshrq_n_u8(x, n)
#define _mm_srai_epi8(x, n) vshrq_n_s8(x, n)

#define _mm_srli_si128(a, imm) (__m128i)vextq_s8((int8x16_t)a, vdupq_n_s8(0), (imm))
#define _mm_slli_si128(a, imm) (__m128i)vextq_s8(vdupq_n_s8(0), (int8x16_t)a, 16-(imm))

//////////////////////////////////////////////////////////////////////////////
//////////////  For some SSE4.1
/////////////////////////////////////////////////////////////////////////////
// static FORCE_INLINE __m128i _mm_blendv_epi8(__m128i a, __m128i b, __m128i mask)
// {
//     return _mm_or_si128(_mm_andnot_si128(mask, a), _mm_and_si128(mask, b));
// }
#define _mm_blendv_ps(x, y, mask) _mm_or_ps(_mm_and_ps(mask, y), _mm_andnot_ps(mask, x))
#define _mm_blendv_epi8(x, y, mask) _mm_or_si128(_mm_and_si128(mask, y), _mm_andnot_si128(mask, x))
#define _mm_roundn_ps(a) vrndnq_f32(a)

#endif // ENABLE_ARM_NEON

#endif



