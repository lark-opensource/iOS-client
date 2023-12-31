// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_RUNTIME_WASM_TABLE_H_
#define JSB_WASM_RUNTIME_WASM_TABLE_H_

#if WASM_ENGINE_WAMR
#include "wamr/wasm_table.h"
#else  // WASM_ENGINE_WASM3
#include "wasm3/wasm_table.h"
#endif  // WASM_ENGINE_WAMR

#endif  // JSB_WASM_RUNTIME_WASM_TABLE_H_