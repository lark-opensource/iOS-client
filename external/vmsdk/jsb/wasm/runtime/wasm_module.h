// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_RUNTIME_WASM_MODULE_H_
#define JSB_WASM_RUNTIME_WASM_MODULE_H_
#if WASM_ENGINE_WAMR
#include "wamr/wasm_module.h"
#else  // WASM_ENGINE_WASM3
#include "wasm3/wasm_module.h"
#endif  // WASM_ENGINE_WAMR

#endif  // JSB_WASM_RUNTIME_WASM_MODULE_H_