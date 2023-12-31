/*
 * Copyright (C) 2012 The Android Open Source Project
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
#ifdef MALLOC_DEBUG
#ifdef __cplusplus
extern "C" {
#include "malloc_debug_check.h"

#include <dlfcn.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unwind.h>

#include "dlmalloc.h"
}
#endif

#define ALLOCATION_TAG 0x1ee7d00d
#define BACKLOG_TAG 0xbabecafe
#define FREE_POISON 0xa5
#define FRONT_GUARD 0xaa
#define REAR_GUARD 0xbb

#define PAGESIZE 4096

static void log_message(const char* format, ...) {
  va_list args;
  va_start(args, format);
  error_log(format, args);
  va_end(args);
}

static inline ftr_t* to_ftr(hdr_t* hdr) {
  return (ftr_t*)((char*)(hdr + 1) + hdr->size);
}

static inline void* user(hdr_t* hdr) { return hdr + 1; }

static inline hdr_t* meta(void* user) { return (hdr_t*)(user)-1; }

#if defined(ANDROID) || defined(__ANDROID__)
#ifdef __cplusplus
extern "C" {
#include <dlfcn.h>
#include <unwind.h>
}
#endif
struct BacktraceState {
  void** current;
  void** end;
};

static _Unwind_Reason_Code unwindCallback(struct _Unwind_Context* context,
                                          void* arg) {
  struct BacktraceState* state = (struct BacktraceState*)(arg);
  uintptr_t pc = _Unwind_GetIP(context);
  if (pc) {
    if (state->current == state->end) {
      return _URC_END_OF_STACK;
    } else {
      *state->current++ = (void*)(pc);
    }
  }
  return _URC_NO_REASON;
}
int get_backtrace_debug(uintptr_t* frames, size_t max_depth) {
  struct BacktraceState state;
  state.current = (void**)frames;
  state.end = (void**)frames + max_depth;
  _Unwind_Backtrace(unwindCallback, &state);

  return state.current - (void**)frames;
}
void log_backtrace(uintptr_t* frames, size_t frame_count) {
  uintptr_t self_bt[16];
  if (frames == NULL) {
    frame_count = get_backtrace_debug(self_bt, 16);
    frames = self_bt;
  }

  for (size_t idx = 0; idx < frame_count; ++idx) {
    const void* addr = (void*)(frames[idx]);
    const char* symbol = "";

    Dl_info info;
    if (dladdr(addr, &info) && info.dli_sname) {
      symbol = info.dli_sname;
    }
    PRINRF("idx:%zu, addr: %p, symbol:%s \n", idx, addr, symbol);
  }
}
#else
#ifdef __cplusplus
extern "C" {
#include <execinfo.h>
#include <stdlib.h>
#include <unistd.h>
}
#endif
int get_backtrace_debug(uintptr_t* frames, size_t max_depth) {
  return backtrace((void**)frames, max_depth);
}
void log_backtrace(uintptr_t* frames, size_t frame_count) {
  uintptr_t self_bt[16];
  if (frames == NULL) {
    frame_count = get_backtrace_debug(self_bt, 16);
    frames = self_bt;
  }

  char** strings = backtrace_symbols((void* const*)frames, frame_count);
  if (strings == NULL) {
    *(int*)(0xdead) = 0;
  }
  for (int j = 0; j < frame_count; j++) printf("%s\n", strings[j]);
  free(strings);
}
#endif

// TODO: introduce a struct for this global state.
// There are basically two lists here, the regular list and the backlog list.
// We should be able to remove the duplication.
static unsigned g_allocated_block_count;
static hdr_t* tail;
static hdr_t* head;

static unsigned backlog_num;
static hdr_t* backlog_tail;
static hdr_t* backlog_head;

// This variable is set to the value of property libc.debug.malloc.backlog.
// It determines the size of the backlog we use to detect multiple frees.
static unsigned g_malloc_debug_backlog = 100;

// This variable is set to false if the property libc.debug.malloc.nobacktrace
// is set to non-zero.
#define TRUE 1
#define FALSE 0
uint8_t g_backtrace_enabled = TRUE;

static inline void init_front_guard(hdr_t* hdr) {
  memset(hdr->front_guard, FRONT_GUARD, FRONT_GUARD_LEN);
}

static inline uint8_t is_front_guard_valid(hdr_t* hdr) {
  for (size_t i = 0; i < FRONT_GUARD_LEN; i++) {
    if (hdr->front_guard[i] != FRONT_GUARD) {
      return FALSE;
    }
  }
  return TRUE;
}

static inline void init_rear_guard(hdr_t* hdr) {
  // todo remove
  ftr_t* ftr = to_ftr(hdr);
  memset(ftr->rear_guard, REAR_GUARD, REAR_GUARD_LEN);
}

static inline uint8_t is_rear_guard_valid(hdr_t* hdr) {
  unsigned i;
  uint8_t valid = TRUE;
  int first_mismatch = -1;
  ftr_t* ftr = to_ftr(hdr);
  for (i = 0; i < REAR_GUARD_LEN; i++) {
    if (ftr->rear_guard[i] != REAR_GUARD) {
      if (first_mismatch < 0) first_mismatch = i;
      valid = FALSE;
    } else if (first_mismatch >= 0) {
      log_message("+++ REAR GUARD MISMATCH [%d, %d)\n", first_mismatch, i);
      first_mismatch = -1;
    }
  }

  if (first_mismatch >= 0)
    log_message("+++ REAR GUARD MISMATCH [%d, %d)\n", first_mismatch, i);
  return valid;
}

static inline void add_locked(hdr_t* hdr, hdr_t** tail, hdr_t** head) {
  hdr->prev = NULL;
  hdr->next = *head;
  if (*head)
    (*head)->prev = hdr;
  else
    *tail = hdr;
  *head = hdr;
}

static inline int del_locked(hdr_t* hdr, hdr_t** tail, hdr_t** head) {
  if (hdr->prev) {
    hdr->prev->next = hdr->next;
  } else {
    *head = hdr->next;
  }
  if (hdr->next) {
    hdr->next->prev = hdr->prev;
  } else {
    *tail = hdr->prev;
  }
  return 0;
}

static inline void add(hdr_t* hdr, size_t size) {
  hdr->tag = ALLOCATION_TAG;
  hdr->size = size;
  init_front_guard(hdr);
  init_rear_guard(hdr);
  ++g_allocated_block_count;
  add_locked(hdr, &tail, &head);
}

static inline int del(hdr_t* hdr) {
  if (hdr->tag != ALLOCATION_TAG) {
    return -1;
  }

  del_locked(hdr, &tail, &head);
  --g_allocated_block_count;
  return 0;
}

static inline void poison(hdr_t* hdr) {
  memset(user(hdr), FREE_POISON, hdr->size);
}

static uint8_t was_used_after_free(hdr_t* hdr) {
  const uint8_t* data = (const uint8_t*)(user(hdr));
  for (size_t i = 0; i < hdr->size; i++) {
    if (data[i] != FREE_POISON) {
      return TRUE;
    }
  }
  return FALSE;
}

/* returns 1 if valid, *safe == 1 if safe to dump stack */
static inline int check_guards(hdr_t* hdr, int* safe) {
  *safe = 1;
  if (!is_front_guard_valid(hdr)) {
    if (hdr->front_guard[0] == FRONT_GUARD) {
      log_message("+++ ALLOCATION %p SIZE %d HAS A CORRUPTED FRONT GUARD\n",
                  user(hdr), hdr->size);
    } else {
      log_message(
          "+++ ALLOCATION %p HAS A CORRUPTED FRONT GUARD "
          "(NOT DUMPING STACKTRACE)\n",
          user(hdr));
      /* Allocation header is probably corrupt, do not print stack trace */
      *safe = 0;
    }
    return 0;
  }

  if (!is_rear_guard_valid(hdr)) {
    log_message("+++ ALLOCATION %p SIZE %d HAS A CORRUPTED REAR GUARD\n",
                user(hdr), hdr->size);
    return 0;
  }

  return 1;
}

/* returns 1 if valid, *safe == 1 if safe to dump stack */
static inline int check_allocation_locked(hdr_t* hdr, int* safe) {
  int valid = 1;
  *safe = 1;

  if (hdr->tag != ALLOCATION_TAG && hdr->tag != BACKLOG_TAG) {
    log_message(
        "+++ ALLOCATION %p HAS INVALID TAG %08x (NOT DUMPING STACKTRACE)\n",
        user(hdr), hdr->tag);
    // Allocation header is probably corrupt, do not dequeue or dump stack
    // trace.
    *safe = 0;
    return 0;
  }

  if (hdr->tag == BACKLOG_TAG && was_used_after_free(hdr)) {
    log_message("+++ ALLOCATION %p SIZE %d WAS USED AFTER BEING FREED\n",
                user(hdr), hdr->size);
    valid = 0;
    /* check the guards to see if it's safe to dump a stack trace */
    check_guards(hdr, safe);
  } else {
    valid = check_guards(hdr, safe);
  }

  if (!valid && *safe && g_backtrace_enabled) {
    log_message("+++ ALLOCATION %p SIZE %d ALLOCATED HERE:\n", user(hdr),
                hdr->size);
    log_backtrace(hdr->bt, hdr->bt_depth);
    if (hdr->tag == BACKLOG_TAG) {
      log_message("+++ ALLOCATION %p SIZE %d FREED HERE:\n", user(hdr),
                  hdr->size);
      log_backtrace(hdr->freed_bt, hdr->freed_bt_depth);
    }
  }

  return valid;
}

static inline int del_and_check_locked(hdr_t* hdr, hdr_t** tail, hdr_t** head,
                                       unsigned* cnt, int* safe) {
  int valid = check_allocation_locked(hdr, safe);
  if (safe) {
    (*cnt)--;
    del_locked(hdr, tail, head);
  }
  return valid;
}

static inline void del_from_backlog_locked(hdr_t* hdr) {
  int safe;
  del_and_check_locked(hdr, &backlog_tail, &backlog_head, &backlog_num, &safe);
  hdr->tag = 0; /* clear the tag */
}

static inline void del_from_backlog(hdr_t* hdr) {
  del_from_backlog_locked(hdr);
}

#include <sys/mman.h>

#define SIZE_T_ONE ((size_t)1)
#define page_align(S) \
  (((S) + (PAGESIZE - SIZE_T_ONE)) & ~(PAGESIZE - SIZE_T_ONE))

static inline void add_to_backlog(hdr_t* hdr, struct malloc_state* state) {
  hdr->tag = BACKLOG_TAG;
  backlog_num++;
  add_locked(hdr, &backlog_tail, &backlog_head);
  poison(hdr);
  /* If we've exceeded the maximum backlog, clear it up */
  while (backlog_num > g_malloc_debug_backlog) {
    hdr_t* gone = backlog_tail;
    del_from_backlog_locked(gone);
    dlfree(state, gone->base);
  }
}
static const size_t mask = PAGESIZE - 1;

// 8bytes(can protect),  8bytes(size), 8bytes(realsize), 8bytes(start)
#define PROTECT_HEADER_SIZE 32
static int PROTECT_GRANULARITY = 32;
void malloc_debug_initialize(int number) { PROTECT_GRANULARITY = number; }
void* chk_malloc(struct malloc_state* state, size_t bytes) {
  size_t size = sizeof(hdr_t) + bytes + sizeof(ftr_t);
  if (size < bytes) {  // Overflow
    errno = ENOMEM;
    return NULL;
  }
  hdr_t* hdr = (hdr_t*)(dlmalloc(state, size));
  if (hdr) {
    hdr->base = hdr;
    static int cnt = 0;
    if (cnt++ % PROTECT_GRANULARITY == 0)
      hdr->bt_depth = get_backtrace_debug(hdr->bt, MAX_BACKTRACE_DEPTH);
    add(hdr, bytes);
    return user(hdr);
  }
  return NULL;
}

uint64_t get_canprotect(void* hdr) { return *(uint64_t*)hdr; }

void init_protect_info(void* hdr, uint8_t enable_protect, size_t size,
                       size_t real_size, void* start) {
  *(uint64_t*)hdr = (uint64_t)enable_protect;
  *(uint64_t*)((uint8_t*)hdr + 8) = size;
  *(uint64_t*)((uint8_t*)hdr + 16) = real_size;
  *(uint64_t*)((uint8_t*)hdr + 24) = (uint64_t)start;
}

size_t get_size(void* hdr) { return *(uint64_t*)((uint8_t*)hdr + 8); }
size_t get_realsize(void* hdr) { return *(uint64_t*)((uint8_t*)hdr + 16); }
void* get_start(void* hdr) { return (void*)*(uint64_t*)((uint8_t*)hdr + 24); }

void* chk_malloc_protect(struct malloc_state* state, size_t bytes) {
  uint8_t enable_protect;
  static int cnt = 0;
  size_t size;
  if (cnt++ % PROTECT_GRANULARITY == 0) {
    size = page_align(bytes + PROTECT_HEADER_SIZE);
    enable_protect = 1;
  } else {
    size = bytes + PROTECT_HEADER_SIZE;
    enable_protect = 0;
  }

  if (size < bytes) {  // Overflow
    errno = ENOMEM;
    return NULL;
  }
  uintptr_t mem;
  uint8_t* hdr;
  if (enable_protect) {
    mem = (uintptr_t)dlmalloc(state, size + PAGESIZE);
    hdr = (uint8_t*)((mem + mask) & ~mask);
  } else {
    hdr = (uint8_t*)dlmalloc(state, size);
    mem = (uintptr_t)hdr;
  }
  if (mem) {
    init_protect_info(hdr, enable_protect, size, bytes, (void*)mem);
    return hdr + PROTECT_HEADER_SIZE;
  }
  return NULL;
}
#include <unistd.h>
void* get_header(void* ptr) { return (uint8_t*)ptr - PROTECT_HEADER_SIZE; }
static uintptr_t* buf = NULL;
static size_t* size_buf = NULL;
#define BUFSIZE 1000
static int idx = 0;
void chk_free_protect(struct malloc_state* state, void* ptr) {
  if (!ptr) return;
  {
    // todo settings config
    static int cnt = 0;
    void* hdr = get_header(ptr);
    if (cnt++ % PROTECT_GRANULARITY == 0) {
      if (buf == NULL) {
        buf = (uintptr_t*)calloc(BUFSIZE, sizeof(uintptr_t));
        size_buf = (size_t*)calloc(BUFSIZE, sizeof(size_t));
      }
      if (get_canprotect(hdr)) {
        size_t current_idx = idx % BUFSIZE;
        if (buf[current_idx] != 0) {
          void* free_hdr = (void*)(buf[current_idx]);
          if (mprotect(free_hdr, size_buf[current_idx],
                       PROT_WRITE | PROT_READ) != 0)
            abort();
          dlfree(state, (void*)get_start((void*)buf[current_idx]));
        }
        buf[current_idx] = (uintptr_t)(hdr);
        size_buf[idx++ % BUFSIZE] = get_realsize(hdr);
        if (mprotect(hdr, get_realsize(hdr), PROT_NONE) != 0) {
          abort();
        }
      } else {
        dlfree(state, get_start(hdr));
      }
    } else {
      dlfree(state, get_start(hdr));
    }
  }
}
void chk_free(struct malloc_state* state, void* ptr) {
  if (!ptr) return;

  hdr_t* hdr = meta(ptr);

  if (del(hdr) < 0) {
    uintptr_t bt[MAX_BACKTRACE_DEPTH];
    int depth = get_backtrace_debug(bt, MAX_BACKTRACE_DEPTH);
    if (hdr->tag == BACKLOG_TAG) {
      log_message("+++ ALLOCATION %p SIZE %d BYTES MULTIPLY FREED!\n",
                  user(hdr), hdr->size);
      if (g_backtrace_enabled) {
        log_message("+++ ALLOCATION %p SIZE %d ALLOCATED HERE:\n", user(hdr),
                    hdr->size);
        log_backtrace(hdr->bt, hdr->bt_depth);
        /* hdr->freed_bt_depth should be nonzero here */
        log_message("+++ ALLOCATION %p SIZE %d FIRST FREED HERE:\n", user(hdr),
                    hdr->size);
        log_backtrace(hdr->freed_bt, hdr->freed_bt_depth);
        log_message("+++ ALLOCATION %p SIZE %d NOW BEING FREED HERE:\n",
                    user(hdr), hdr->size);
        log_backtrace(bt, depth);
      }
    } else {
      log_message(
          "+++ ALLOCATION %p IS CORRUPTED OR NOT ALLOCATED VIA TRACKER2!\n",
          user(hdr));
      if (g_backtrace_enabled) {
        log_backtrace(bt, depth);
      }
    }
  } else {
    static int cnt = 0;
    if (cnt++ % PROTECT_GRANULARITY == 0) {
      hdr->freed_bt_depth =
          get_backtrace_debug(hdr->freed_bt, MAX_BACKTRACE_DEPTH);
      add_to_backlog(hdr, state);
    } else {
      dlfree(state, hdr->base);
    }
  }
}

void* chk_realloc(struct malloc_state* state, void* ptr, size_t bytes) {
  if (!ptr) {
    return chk_malloc(state, bytes);
  }

  hdr_t* hdr = meta(ptr);

  if (del(hdr) < 0) {
    uintptr_t bt[MAX_BACKTRACE_DEPTH];
    int depth = get_backtrace_debug(bt, MAX_BACKTRACE_DEPTH);
    if (hdr->tag == BACKLOG_TAG) {
      log_message("+++ REALLOCATION %p SIZE %d OF FREED MEMORY!\n", user(hdr),
                  bytes, hdr->size);
      if (g_backtrace_enabled) {
        log_message("+++ ALLOCATION %p SIZE %d ALLOCATED HERE:\n", user(hdr),
                    hdr->size);
        log_backtrace(hdr->bt, hdr->bt_depth);
        /* hdr->freed_bt_depth should be nonzero here */
        log_message("+++ ALLOCATION %p SIZE %d FIRST FREED HERE:\n", user(hdr),
                    hdr->size);
        log_backtrace(hdr->freed_bt, hdr->freed_bt_depth);
        log_message("+++ ALLOCATION %p SIZE %d NOW BEING REALLOCATED HERE:\n",
                    user(hdr), hdr->size);
        log_backtrace(bt, depth);
      }

      /* We take the memory out of the backlog and fall through so the
       * reallocation below succeeds.  Since we didn't really free it, we
       * can default to this behavior.
       */
      del_from_backlog(hdr);
    } else {
      log_message(
          "+++ REALLOCATION %p SIZE %d IS CORRUPTED OR NOT ALLOCATED VIA "
          "TRACKER3!\n",
          user(hdr), bytes);
      if (g_backtrace_enabled) {
        log_backtrace(bt, depth);
      }
      // just get a whole new allocation and leak the old one
      return dlrealloc(state, 0, bytes);
      // return realloc(user(hdr), bytes); // assuming it was allocated
      // externally
    }
  }

  size_t size = sizeof(hdr_t) + bytes + sizeof(ftr_t);
  if (size < bytes) {  // Overflow
    errno = ENOMEM;
    return NULL;
  }
  if (hdr->base != hdr) {
    // An allocation from memalign, so create another allocation and
    // copy the data out.
    void* newMem = dlmalloc(state, size);
    if (newMem == NULL) {
      return NULL;
    }

    dlfree(state, hdr->base);
    hdr = (hdr_t*)(newMem)-1;
    memcpy(newMem, hdr, sizeof(hdr_t) + hdr->size);
  } else {
    hdr = (hdr_t*)(dlrealloc(state, hdr, size));
  }
  if (hdr) {
    hdr->base = hdr;
    hdr->bt_depth = get_backtrace_debug(hdr->bt, MAX_BACKTRACE_DEPTH);
    add(hdr, bytes);
    return user(hdr);
  }
  return NULL;
}
void* chk_realloc_protect(struct malloc_state* state, void* ptr, size_t bytes) {
  if (!ptr) {
    return chk_malloc_protect(state, bytes);
  }

  uint8_t* hdr = (uint8_t*)get_header(ptr);
  static int cnt = 0;
  size_t size;
  uint8_t enable_protect = 0;
  if (cnt++ % PROTECT_GRANULARITY == 0) {
    enable_protect = 1;
    size = page_align(bytes + PROTECT_HEADER_SIZE);
  } else {
    size = bytes + PROTECT_HEADER_SIZE;
    enable_protect = 0;
  }

  if (size < bytes) {  // Overflow
    errno = ENOMEM;
    return NULL;
  }

  uintptr_t newMem;
  if (enable_protect)
    newMem = (uintptr_t)dlmalloc(state, size + PAGESIZE);
  else
    newMem = (uintptr_t)dlmalloc(state, size);
  if (newMem == 0) {
    return NULL;
  }
  uint8_t* new_hdr;
  if (enable_protect)
    new_hdr = (uint8_t*)((newMem + mask) & ~mask);
  else
    new_hdr = (uint8_t*)(newMem);
  size_t old_size = get_realsize(hdr);
  size_t min_size = old_size > bytes ? bytes : old_size;
  memcpy(new_hdr + PROTECT_HEADER_SIZE, ptr, min_size);

  dlfree(state, get_start(hdr));
  init_protect_info(new_hdr, enable_protect, size, bytes, (void*)newMem);
  return new_hdr + PROTECT_HEADER_SIZE;
}

void malloc_debug_finalize(struct malloc_state* state) {
  if (state->enable_malloc_debug_protect == 1) {
    for (int i = 0; i < BUFSIZE; i++) {
      if (buf[i] != 0) {
        void* free_hdr = (void*)(buf[i]);
        if (mprotect(free_hdr, size_buf[i], PROT_WRITE | PROT_READ) != 0)
          abort();
        dlfree(state, (void*)get_start((void*)buf[i]));
        buf[i] = (uintptr_t)0;
      }
    }
  } else if (state->enable_malloc_debug == 1) {
    while (backlog_num > 0) {
      hdr_t* gone = backlog_tail;
      del_from_backlog_locked(gone);
      dlfree(state, gone->base);
    }
  } else {
    abort();
  }
  tail = NULL;
  head = NULL;
  /*if (g_allocated_block_count != 0 || tail != NULL || head != NULL)
   *(int*)(0xdead) = 0;*/
}

#endif