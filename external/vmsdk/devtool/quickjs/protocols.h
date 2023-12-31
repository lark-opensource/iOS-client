// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef QUICKJS_PROTOCOLS_H
#define QUICKJS_PROTOCOLS_H

#ifdef __cplusplus
extern "C" {
#endif

#include "quickjs/include/quickjs.h"

#ifdef __cplusplus
}
#endif

#include <string>
#include <unordered_map>
typedef struct DebuggerParams DebuggerParams;

typedef enum ProtocolType {
  DEBUGGER_ENABLE,
  DEBUGGER_DISABLE,
  RUNTIME_ENABLE,
  RUNTIME_DISABLE,
  PROFILER_ENABLE,
  PROFILER_DISABLE,
  OTHER,
} ProtocolType;

// compare function and hash function for const char*
unsigned int DEKHash(const char *str, unsigned int length);
struct cmp {
  bool operator()(const char *s1, const char *s2) const {
    return !strcmp(s1, s2);
  }
};

struct hash_func {
  size_t operator()(const char *arg) const { return DEKHash(arg, strlen(arg)); }
};

// send protocol response to fontend
void SendResponse(LEPUSContext *ctx, LEPUSValue message, LEPUSValue result);

// send protocol notification to frontend
void SendNotification(LEPUSContext *ctx, const char *method, LEPUSValue params,
                      int32_t view_id = -1);

// check if the xxx.enable is already processing
bool CheckEnable(LEPUSContext *ctx, LEPUSValue message, ProtocolType protocol);

#endif
