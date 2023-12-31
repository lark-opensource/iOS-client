// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_RUNTIME_WASM_FUNC_PACK_H_
#define JSB_WASM_RUNTIME_WASM_FUNC_PACK_H_

#if WASM_ENGINE_WAMR
#include "wamr/wasm_func_pack.h"
#else  // WASM_ENGINE_WASM3
#include "wasm3/wasm_func_pack.h"
#endif  // WASM_ENGINE_WAMR

#endif  // JSB_WASM_RUNTIME_WASM_FUNC_PACK_H_