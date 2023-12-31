// Copyright 2021 The Lynx Authors. All rights reserved.
// this file is used to be included by renderer.cc / renderer_ng.cc
// do not used it as normal include file

#ifndef LYNX_TASM_RENDERER_TEMPLATE_H_
#define LYNX_TASM_RENDERER_TEMPLATE_H_

#include "tasm/lynx_trace_event.h"
#include "tasm/renderer_functions_def.h"

#if defined(OS_WIN)
#ifdef SetProp
#define REDEF_SETPROP SetProp
#undef SetProp
#endif  // SetProp
#endif  // OS_WIN

#ifndef BUILD_LEPUS
#define NORMAL_FUNCTION_DEF(name)  \
  RENDERER_FUNCTION(name) {        \
    PREPARE_ARGS(name);            \
    CALL_RUNTIME_AND_RETURN(name); \
  }
NORMAL_RENDERER_FUNCTIONS(NORMAL_FUNCTION_DEF)

#undef NORMAL_FUNCTION_DEF
#else
NORMAL_RENDERER_FUNCTIONS(CREATE_FUNCTION)
#endif

#if defined(OS_WIN)
#ifdef REDEF_SETPROP
#define SetProp REDEF_SETPROP
#endif  // REDEF_SETPROP
#endif

#endif  // LYNX_TASM_RENDERER_TEMPLATE_H_
