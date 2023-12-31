// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_COMMON_WASM_UTILS_H_
#define JSB_WASM_COMMON_WASM_UTILS_H_

#if defined(__GNUC__) || defined(__clang__)
#define wasm_likely(x) __builtin_expect(!!(x), 1)
#define wasm_unlikely(x) __builtin_expect(!!(x), 0)
#else
#define wasm_likely(x) (x)
#define wasm_unlikely(x) (x)
#endif

#endif  // JSB_WASM_COMMON_WASM_UTILS_H_