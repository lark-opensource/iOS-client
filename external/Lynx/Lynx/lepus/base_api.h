// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_BASE_API_H_
#define LYNX_LEPUS_BASE_API_H_

#include <string>

#include "config/config.h"

#if !ENABLE_JUST_LEPUSNG

#include <cassert>
#include <iomanip>
#include <iostream>

#include "lepus/builtin.h"
#include "lepus/exception.h"
#include "lepus/table.h"
#include "lepus/vm_context.h"

namespace lynx {
namespace lepus {

std::string GetPrintStr(Context* context) {
  long params_count = context->GetParamsSize();
  std::ostringstream s;
  s << "lepus-console: ";
  for (long i = 0; i < params_count; i++) {
    Value* v = context->GetParam(i);
    v->PrintValue(s);
    s << " ";
  }
  return s.str();
}

Value Console_Log(Context* context) {
  std::string msg = GetPrintStr(context);
#ifdef LEPUS_PC
  LOGE(msg);
#endif
  reinterpret_cast<VMContext*>(context)->PrintMsgToJS("log", msg);
  return Value();
}

Value Console_Warn(Context* context) {
  std::string msg = GetPrintStr(context);
  reinterpret_cast<VMContext*>(context)->PrintMsgToJS("warn", msg);
  return Value();
}

Value Console_Error(Context* context) {
  std::string msg = GetPrintStr(context);
  reinterpret_cast<VMContext*>(context)->PrintMsgToJS("error", msg);
  return Value();
}

Value Console_Info(Context* context) {
  std::string msg = GetPrintStr(context);
  reinterpret_cast<VMContext*>(context)->PrintMsgToJS("info", msg);
  return Value();
}

Value Console_Debug(Context* context) {
  std::string msg = GetPrintStr(context);
  reinterpret_cast<VMContext*>(context)->PrintMsgToJS("debug", msg);
  return Value();
}

Value Console_Report(Context* context) {
  std::string msg = GetPrintStr(context);
  reinterpret_cast<VMContext*>(context)->PrintMsgToJS("report", msg);
  return Value();
}

Value Console_Alog(Context* context) {
  std::string msg = GetPrintStr(context);
  reinterpret_cast<VMContext*>(context)->PrintMsgToJS("alog", msg);
  return Value();
}

Value Assert(Context* context) {
  UNUSED_LOG_VARIABLE Value* condition = context->GetParam(1);
  Value* msg = context->GetParam(2);
  std::string s = "Assertion failed:" + msg->String()->str();
  assert(condition->IsTrue() && s.c_str());
  return Value();
}

void RegisterBaseAPI(Context* ctx) {
  lynx::base::scoped_refptr<Dictionary> table = Dictionary::Create();
  RegisterTableFunction(ctx, table, "log", &Console_Log);
  RegisterTableFunction(ctx, table, "warn", &Console_Warn);
  RegisterTableFunction(ctx, table, "error", &Console_Error);
  RegisterTableFunction(ctx, table, "info", &Console_Info);
  RegisterTableFunction(ctx, table, "debug", &Console_Debug);
  RegisterTableFunction(ctx, table, "report", &Console_Report);
  RegisterTableFunction(ctx, table, "alog", &Console_Alog);
  RegisterTableFunction(ctx, table, "assert", &Assert);
  RegisterFunctionTable(ctx, "console", table);
}

static Value toFixed(Context* context) {
  long params_count = context->GetParamsSize();
  DCHECK(params_count == 1 || params_count == 2);
  Value n;                          // for precision
  Value* v = context->GetParam(1);  // for value
  if (params_count == 1) {
    n = Value(0);
    v = context->GetParam(0);
  } else {
    n = *context->GetParam(0);
    v = context->GetParam(1);
  }
  DCHECK(n.IsNumber());
  DCHECK(v->IsNumber());
  std::stringstream os;

  os << std::setiosflags(std::ios::fixed)
     << std::setprecision(static_cast<int>(n.Number())) << v->Number();
  base::scoped_refptr<StringImpl> ret =
      lepus::StringImpl::Create(os.str().c_str());
  return Value(ret);
}

void RegisterNumberAPI(Context* ctx) {
  lynx::base::scoped_refptr<Dictionary> table = Dictionary::Create();
  RegisterTableFunction(ctx, table, "toFixed", &toFixed);
  reinterpret_cast<VMContext*>(ctx)->SetNumberPrototype(Value(table));
}

}  // namespace lepus
}  // namespace lynx

#endif  // ENABLE_JUST_LEPUSNG
#endif  // LYNX_LEPUS_BASE_API_H_
