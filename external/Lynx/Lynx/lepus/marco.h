#ifndef LYNX_LEPUS_MARCO_H_
#define LYNX_LEPUS_MARCO_H_
#define unlikely(x) __builtin_expect(!!(x), 0)
#define likely(x) __builtin_expect(!!(x), 1)
#endif  // LYNX_LEPUS_MARCO_H_
