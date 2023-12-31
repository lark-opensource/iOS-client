#ifndef MALLOC_DEBUG_CHECK_H
#define MALLOC_DEBUG_CHECK_H
#include <stddef.h>
#include <stdint.h>
#if defined(ANDROID) || defined(__ANDROID__)
#include <android/log.h>
#define PRINRF(...) \
  __android_log_print(ANDROID_LOG_ERROR, "LYNX malloc_leak_check", __VA_ARGS__);
#else
#define PRINRF(...) printf(__VA_ARGS__);
#endif

#define Malloc(function) dl##function
#define BACKTRACE_SIZE 32

// This must match the alignment used by the malloc implementation.
#ifndef MALLOC_ALIGNMENT
#define MALLOC_ALIGNMENT ((size_t)(2 * sizeof(void*)))
#endif

#define error_log(format, ...) PRINRF(format, __VA_ARGS__);

void malloc_debug_initialize(int);
void* chk_malloc(struct malloc_state*, size_t bytes);
void* chk_malloc_protect(struct malloc_state* state, size_t bytes);
void chk_free(struct malloc_state*, void* ptr);
void chk_free_protect(struct malloc_state* state, void* ptr);
void* chk_realloc(struct malloc_state*, void* ptr, size_t bytes);

void* chk_realloc_protect(struct malloc_state* state, void* ptr, size_t bytes);
void malloc_debug_finalize(struct malloc_state* state);
#define MAX_BACKTRACE_DEPTH 16
#define FRONT_GUARD_LEN (1 << 5)
#define REAR_GUARD_LEN (1 << 5)
typedef struct ftr_t {
  uint8_t rear_guard[REAR_GUARD_LEN];
} ftr_t;
typedef struct hdr_t {
  uint32_t tag;
  void* base;  // Always points to the memory allocated using malloc.
               // For memory allocated in chk_memalign, this value will
               // not be the same as the location of the start of this
               // structure.
  struct hdr_t* prev;
  struct hdr_t* next;
  uintptr_t bt[MAX_BACKTRACE_DEPTH];
  int bt_depth;
  uintptr_t freed_bt[MAX_BACKTRACE_DEPTH];
  int freed_bt_depth;
  size_t size;
  size_t obj_size;  // used for malloc_debug_protect
  uint8_t front_guard[FRONT_GUARD_LEN];
} hdr_t __attribute__((aligned(MALLOC_ALIGNMENT)));
#endif
