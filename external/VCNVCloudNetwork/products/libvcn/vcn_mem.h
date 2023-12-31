//
//  vcn_mem.h
//  network-1
//
//  Created by thq on 17/2/17.
//  Copyright © 2017年 thq. All rights reserved.
//

#ifndef vcn_mem_h
#define vcn_mem_h
#include <stdint.h>
#include <limits.h>
#include "attributes.h"
#include "vcn_error.h"

//from macros.h
#define AV_GLUE(a, b) a ## b
#define AV_JOIN(a, b) AV_GLUE(a, b)
//from mem.c
#ifdef MALLOC_PREFIX

#define malloc         AV_JOIN(MALLOC_PREFIX, malloc)
#define memalign       AV_JOIN(MALLOC_PREFIX, memalign)
#define posix_memalign AV_JOIN(MALLOC_PREFIX, posix_memalign)
#define realloc        AV_JOIN(MALLOC_PREFIX, realloc)
#define free           AV_JOIN(MALLOC_PREFIX, free)
void *malloc(size_t size);
void *memalign(size_t align, size_t size);
int   posix_memalign(void **ptr, size_t align, size_t size);
void *realloc(void *ptr, size_t size);
void  free(void *ptr);

#endif /* MALLOC_PREFIX */
/**
 * @defgroup lavu_mem_attrs Function Attributes
 * Function attributes applicable to memory handling functions.
 *
 * These function attributes can help compilers emit more useful warnings, or
 * generate better code.
 * @{
 */

/**
 * @def av_malloc_attrib
 * Function attribute denoting a malloc-like function.
 *
 * @see <a href="https://gcc.gnu.org/onlinedocs/gcc/Common-Function-Attributes.html#index-g_t_0040code_007bmalloc_007d-function-attribute-3251">Function attribute `malloc` in GCC's documentation</a>
 */

#if AV_GCC_VERSION_AT_LEAST(3,1)
#define av_malloc_attrib __attribute__((__malloc__))
#else
#define av_malloc_attrib
#endif
/**
 * @def av_alloc_size(...)
 * Function attribute used on a function that allocates memory, whose size is
 * given by the specified parameter(s).
 *
 * @code{.c}
 * void *vcn_av_malloc(size_t size) av_alloc_size(1);
 * void *av_calloc(size_t nmemb, size_t size) av_alloc_size(1, 2);
 * @endcode
 *
 * @param ... One or two parameter indexes, separated by a comma
 *
 * @see <a href="https://gcc.gnu.org/onlinedocs/gcc/Common-Function-Attributes.html#index-g_t_0040code_007balloc_005fsize_007d-function-attribute-3220">Function attribute `alloc_size` in GCC's documentation</a>
 */

#if AV_GCC_VERSION_AT_LEAST(4,3)
#define av_alloc_size(...) __attribute__((alloc_size(__VA_ARGS__)))
#else
#define av_alloc_size(...)
#endif
/**
 * Allocate a memory block with alignment suitable for all memory accesses
 * (including vectors if available on the CPU).
 *
 * @param size Size in bytes for the memory block to be allocated
 * @return Pointer to the allocated block, or `NULL` if the block cannot
 *         be allocated
 * @see vcn_av_mallocz()
 */
__attribute__((visibility ("default"))) void *vcn_av_malloc(size_t size);
/**
 * Allocate a memory block with alignment suitable for all memory accesses
 * (including vectors if available on the CPU) and zero all the bytes of the
 * block.
 *
 * @param size Size in bytes for the memory block to be allocated
 * @return Pointer to the allocated block, or `NULL` if it cannot be allocated
 * @see vcn_av_malloc()
 */
__attribute__((visibility ("default"))) void *vcn_av_mallocz(size_t size) av_malloc_attrib av_alloc_size(1);

/**
 * @}
 */

/**
 * @defgroup lavu_mem_funcs Heap Management
 * Functions responsible for allocating, freeing, and copying memory.
 *
 * All memory allocation functions have a built-in upper limit of `INT_MAX`
 * bytes. This may be changed with av_max_alloc(), although exercise extreme
 * caution when doing so.
 *
 * @{
 */

/**
 * Allocate a memory block with alignment suitable for all memory accesses
 * (including vectors if available on the CPU).
 *
 * @param size Size in bytes for the memory block to be allocated
 * @return Pointer to the allocated block, or `NULL` if the block cannot
 *         be allocated
 * @see vcn_av_mallocz()
 */
void *vcn_av_malloc(size_t size) av_malloc_attrib av_alloc_size(1);

/**
 * Allocate a memory block with alignment suitable for all memory accesses
 * (including vectors if available on the CPU) and zero all the bytes of the
 * block.
 *
 * @param size Size in bytes for the memory block to be allocated
 * @return Pointer to the allocated block, or `NULL` if it cannot be allocated
 * @see vcn_av_malloc()
 */
void *vcn_av_mallocz(size_t size) av_malloc_attrib av_alloc_size(1);

/**
 * Allocate a memory block for an array with vcn_av_malloc().
 *
 * The allocated memory will have size `size * nmemb` bytes.
 *
 * @param nmemb Number of element
 * @param size  Size of a single element
 * @return Pointer to the allocated block, or `NULL` if the block cannot
 *         be allocated
 * @see vcn_av_malloc()
 */
av_alloc_size(1, 2) static inline void *av_malloc_array(size_t nmemb, size_t size)
{
    if (!size || nmemb >= INT_MAX / size)
        return NULL;
    return vcn_av_malloc(nmemb * size);
}

/**
 * Allocate a memory block for an array with vcn_av_mallocz().
 *
 * The allocated memory will have size `size * nmemb` bytes.
 *
 * @param nmemb Number of elements
 * @param size  Size of the single element
 * @return Pointer to the allocated block, or `NULL` if the block cannot
 *         be allocated
 *
 * @see vcn_av_mallocz()
 * @see av_malloc_array()
 */
av_alloc_size(1, 2) static inline void *vcn_av_mallocz_array(size_t nmemb, size_t size)
{
    if (!size || nmemb >= INT_MAX / size)
        return NULL;
    return vcn_av_mallocz(nmemb * size);
}

/**
 * Allocate, reallocate, or free a block of memory.
 *
 * If `ptr` is `NULL` and `size` > 0, allocate a new block. If `size` is
 * zero, free the memory block pointed to by `ptr`. Otherwise, expand or
 * shrink that block of memory according to `size`.
 *
 * @param ptr  Pointer to a memory block already allocated with
 *             av_realloc() or `NULL`
 * @param size Size in bytes of the memory block to be allocated or
 *             reallocated
 *
 * @return Pointer to a newly-reallocated block or `NULL` if the block
 *         cannot be reallocated or the function is used to free the memory block
 *
 * @warning Unlike vcn_av_malloc(), the returned pointer is not guaranteed to be
 *          correctly aligned.
 * @see av_fast_realloc()
 * @see vcn_av_reallocp()
 */
void *av_realloc(void *ptr, size_t size) av_alloc_size(2);
/**
 * Allocate, reallocate, or free a block of memory through a pointer to a
 * pointer.
 *
 * If `*ptr` is `NULL` and `size` > 0, allocate a new block. If `size` is
 * zero, free the memory block pointed to by `*ptr`. Otherwise, expand or
 * shrink that block of memory according to `size`.
 *
 * @param[in,out] ptr  Pointer to a pointer to a memory block already allocated
 *                     with av_realloc(), or a pointer to `NULL`. The pointer
 *                     is updated on success, or freed on failure.
 * @param[in]     size Size in bytes for the memory block to be allocated or
 *                     reallocated
 *
 * @return Zero on success, an AVERROR error code on failure
 *
 * @warning Unlike vcn_av_malloc(), the allocated memory is not guaranteed to be
 *          correctly aligned.
 */
av_warn_unused_result
__attribute__((visibility ("default"))) int vcn_av_reallocp(void *ptr, size_t size);
/**
 * Allocate, reallocate, or free a block of memory.
 *
 * This function does the same thing as av_realloc(), except:
 * - It takes two size arguments and allocates `nelem * elsize` bytes,
 *   after checking the result of the multiplication for integer overflow.
 * - It frees the input block in case of failure, thus avoiding the memory
 *   leak with the classic
 *   @code{.c}
 *   buf = realloc(buf);
 *   if (!buf)
 *       return -1;
 *   @endcode
 *   pattern.
 */
void *av_realloc_f(void *ptr, size_t nelem, size_t elsize);
/**
 * Free a memory block which has been allocated with a function of vcn_av_malloc()
 * or av_realloc() family, and set the pointer pointing to it to `NULL`.
 *
 * @code{.c}
 * uint8_t *buf = vcn_av_malloc(16);
 * vcn_av_free(buf);
 * // buf now contains a dangling pointer to freed memory, and accidental
 * // dereference of buf will result in a use-after-free, which may be a
 * // security risk.
 *
 * uint8_t *buf = vcn_av_malloc(16);
 * vcn_av_freep(&buf);
 * // buf is now NULL, and accidental dereference will only result in a
 * // NULL-pointer dereference.
 * @endcode
 *
 * @param ptr Pointer to the pointer to the memory block which should be freed
 * @note `*ptr = NULL` is safe and leads to no action.
 * @see vcn_av_free()
 */
__attribute__((visibility ("default"))) void vcn_av_freep(void *ptr);
__attribute__((visibility ("default"))) void vcn_av_free(void *ptr);
/**
 * Duplicate a string.
 *
 * @param s String to be duplicated
 * @return Pointer to a newly-allocated string containing a
 *         copy of `s` or `NULL` if the string cannot be allocated
 * @see vcn_av_strndup()
 */
__attribute__((visibility ("default"))) char *vcn_av_strdup(const char *s) av_malloc_attrib;
/**
 * Duplicate a substring of a string.
 *
 * @param s   String to be duplicated
 * @param len Maximum length of the resulting string (not counting the
 *            terminating byte)
 * @return Pointer to a newly-allocated string containing a
 *         substring of `s` or `NULL` if the string cannot be allocated
 */
__attribute__((visibility ("default"))) char *vcn_av_strndup(const char *s, size_t len) av_malloc_attrib;
/**
 * Duplicate a buffer with vcn_av_malloc().
 *
 * @param p    Buffer to be duplicated
 * @param size Size in bytes of the buffer copied
 * @return Pointer to a newly allocated buffer containing a
 *         copy of `p` or `NULL` if the buffer cannot be allocated
 */
void *av_memdup(const void *p, size_t size);
/**
 * Multiply two `size_t` values checking for overflow.
 *
 * @param[in]  a,b Operands of multiplication
 * @param[out] r   Pointer to the result of the operation
 * @return 0 on success, AVERROR(EINVAL) on overflow
 */
static inline int av_size_mult(size_t a, size_t b, size_t *r)
{
    size_t t = a * b;
    /* Hack inspired from glibc: don't try the division if nelem and elsize
     * are both less than sqrt(SIZE_MAX). */
    if ((a | b) >= ((size_t)1 << (sizeof(size_t) * 4)) && a && t / a != b)
        return AVERROR(EINVAL);
    *r = t;
    return 0;
}

#endif /* vcn_mem_h */
