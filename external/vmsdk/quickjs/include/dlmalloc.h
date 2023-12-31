#ifndef DLMALLOC_H
#define DLMALLOC_H
#include <errno.h>
#include <stddef.h>
#include <stdint.h>

typedef unsigned int binmap_t; /* Described below */
typedef unsigned int bindex_t; /* Described below */
typedef unsigned int flag_t;   /* The type of various bit flag sets */
struct malloc_tree_chunk {
  /* The first four fields must be compatible with malloc_chunk */
  size_t prev_foot;
  size_t head;
  struct malloc_tree_chunk* fd;
  struct malloc_tree_chunk* bk;

  struct malloc_tree_chunk* child[2];
  struct malloc_tree_chunk* parent;
  bindex_t index;
};
typedef struct malloc_tree_chunk* tbinptr; /* The type of bins of trees */
struct malloc_segment {
  char* base;                  /* base address */
  size_t size;                 /* allocated size */
  struct malloc_segment* next; /* ptr to next segment */
  flag_t sflags;               /* mmap and extern flag */
};
typedef struct malloc_segment msegment;
typedef struct malloc_segment* msegmentptr;
struct malloc_chunk {
  size_t prev_foot;        /* Size of previous chunk (if free).  */
  size_t head;             /* Size and inuse bits. */
  struct malloc_chunk* fd; /* double links -- used only if free. */
  struct malloc_chunk* bk;
};

typedef struct malloc_chunk mchunk;
typedef struct malloc_chunk* mchunkptr;

#ifndef USE_LOCKS /* ensure true if spin or recursive locks set */
#define USE_LOCKS 0
#endif /* USE_LOCKS */
#define NSMALLBINS (32U)
#define NTREEBINS (32U)
struct malloc_state {
  binmap_t smallmap;
  binmap_t treemap;
  size_t dvsize;
  size_t topsize;
  char* least_addr;
  mchunkptr dv;
  mchunkptr top;
  size_t trim_check;
  char* mmap_cache;
  size_t mmap_cache_size;
  size_t release_checks;
  size_t magic;
  mchunkptr smallbins[(NSMALLBINS + 1) * 2];
  tbinptr treebins[NTREEBINS];
  size_t footprint;
  size_t max_footprint;
  size_t footprint_limit; /* zero means no limit */
  flag_t mflags;
#if USE_LOCKS
  MLOCK_T mutex; /* locate lock among fields that rarely change */
#endif           /* USE_LOCKS */
  msegment seg;
  int tid; /* Unused but available for extensions */
  size_t exts;
#ifdef MALLOC_DEBUG
  bool enable_malloc_debug;
  bool enable_malloc_debug_protect;
#endif
};
typedef struct malloc_state* mstate;
void* dlmalloc(mstate m, size_t bytes);
void dlfree(mstate m, void* mem);
void* dlrealloc(mstate m, void* oldmem, size_t bytes);
size_t dlmalloc_usable_size(void* mem);

size_t dlmalloc_usable_size_debug(void* mem);
size_t dlmalloc_usable_size_debug_protect(void* mem);
void destroy_dlmalloc_instance(mstate m);

#endif  // DLMALLOC_H