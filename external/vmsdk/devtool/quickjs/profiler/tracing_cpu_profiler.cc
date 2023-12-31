// Copyright 2019 The Lynx Authors. All rights reserved.

#include "devtool/quickjs/profiler/tracing_cpu_profiler.h"

#include "devtool/quickjs/debugger/debugger.h"
#include "devtool/quickjs/interface.h"
#include "devtool/quickjs/profiler/profile_generator.h"
#include "devtool/quickjs/protocols.h"

void HandleProfilerEnable(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  if (ctx) {
    LEPUSValue message = debugger_options->message;
    LEPUSValue view_id_val = LEPUS_GetPropertyStr(ctx, message, "view_id");
    int32_t view_id = -1;
    if (!LEPUS_IsUndefined(view_id_val)) {
      LEPUS_ToInt32(ctx, &view_id, view_id_val);
      LEPUS_FreeValue(ctx, view_id_val);
    }

    if (view_id != -1) {
      // set session enable state
      SetSessionEnableState(ctx, view_id, PROFILER_ENABLE);
    }

    LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
    info->cpu_profiler = nullptr;
    info->is_profiling_enabled += 1;
    LEPUSValue result = LEPUS_NewObject(ctx);
    if (!LEPUS_IsException(result)) {
      SendResponse(ctx, message, result);
    }
  }
}

void HandleProfilerDisable(DebuggerParams *profiler_options) {
  LEPUSContext *ctx = profiler_options->ctx;
  if (ctx) {
    LEPUSValue message = profiler_options->message;
    if (!CheckEnable(ctx, message, PROFILER_ENABLE)) return;
    LEPUSValue view_id_val = LEPUS_GetPropertyStr(ctx, message, "view_id");
    int32_t view_id = -1;
    if (!LEPUS_IsUndefined(view_id_val)) {
      LEPUS_ToInt32(ctx, &view_id, view_id_val);
    }

    if (view_id != -1) {
      // set session enable state
      SetSessionEnableState(ctx, view_id, PROFILER_DISABLE);
    }

    LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
    info->is_profiling_enabled -= 1;
    LEPUSValue result = LEPUS_NewObject(ctx);
    if (!LEPUS_IsException(result)) {
      SendResponse(ctx, message, result);
    }
  }
}

void HandleSetSamplingInterval(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  if (ctx) {
    LEPUSValue message = debugger_options->message;
    if (!CheckEnable(ctx, message, PROFILER_ENABLE)) return;
    LEPUSValue params = LEPUS_GetPropertyStr(ctx, message, "params");
    LEPUSValue params_interval = LEPUS_GetPropertyStr(ctx, params, "interval");
    uint32_t interval = 0;
    LEPUS_ToUint32(ctx, &interval, params_interval);
    LEPUS_FreeValue(ctx, params);
    auto *info = GetDebuggerInfo(ctx);
    if (info) {
      info->profiler_interval = interval;
    }
    LEPUSValue result = LEPUS_NewObject(ctx);
    if (!LEPUS_IsException(result)) {
      SendResponse(ctx, message, result);
    }
  }
}

void HandleProfilerStart(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  LEPUSValue message = debugger_options->message;
  if (!CheckEnable(ctx, message, PROFILER_ENABLE)) return;
  auto *info = GetDebuggerInfo(ctx);
  if (!info) return;
  auto cpu_profiler = std::make_shared<VMSDK::CpuProfiler::CpuProfiler>(ctx);
  info->cpu_profiler = cpu_profiler;
  uint32_t interval = info ? info->profiler_interval : 100;
  cpu_profiler->set_sampling_interval(interval);
  cpu_profiler->StartProfiling("");

  LEPUSValue result = LEPUS_NewObject(ctx);
  if (!LEPUS_IsException(result)) {
    SendResponse(ctx, message, result);
  }
}

void HandleProfilerStop(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  if (ctx) {
    LEPUSValue message = debugger_options->message;
    if (!CheckEnable(ctx, message, PROFILER_ENABLE)) {
      SendResponse(ctx, message, LEPUS_NewObject(ctx));
      return;
    }
    auto *info = GetDebuggerInfo(ctx);
    if (!info) return;
    auto profiler = info->cpu_profiler->StopProfiling("");
    if (profiler) {
      std::string profiler_result = profiler->GetCpuProfileContent();
      printf("Profiler Result: %s\n", profiler_result.c_str());
      LEPUSValue profiler_result_obj = LEPUS_ParseJSON(
          ctx, profiler_result.c_str(), profiler_result.size(), "");
      if (LEPUS_IsException(profiler_result_obj)) {
        info->cpu_profiler = nullptr;
        printf("Profiler Result Serialize Fail!\n");
        return;
      }
      if (!LEPUS_IsException(profiler_result_obj)) {
        SendResponse(ctx, message, profiler_result_obj);
      }
    }
    info->cpu_profiler = nullptr;
  }
}