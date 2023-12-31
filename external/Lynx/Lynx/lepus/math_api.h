// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_MATH_API_H_
#define LYNX_LEPUS_MATH_API_H_

#include "config/config.h"

#if !ENABLE_JUST_LEPUSNG
#include <math.h>
#include <time.h>

namespace lynx {
namespace lepus {

Value Sin(Context* context) {
  Value* arg = context->GetParam(0);
  if (!arg->IsNumber()) {
    return Value();
  }
  return Value(sin(arg->Number()));
}
Value Acos(Context* context) {
  Value* arg = context->GetParam(0);
  if (!arg->IsNumber()) {
    return Value();
  }
  return Value(acos(arg->Number()));
}

Value Asin(Context* context) {
  Value* arg = context->GetParam(0);
  if (!arg->IsNumber()) {
    return Value();
  }
  return Value(asin(arg->Number()));
}

Value Abs(Context* context) {
  Value* arg = context->GetParam(0);
  if (!arg->IsNumber()) {
    return Value();
  }
  return Value(fabs(arg->Number()));
}

Value Atan(Context* context) {
  Value* arg = context->GetParam(0);
  if (!arg->IsNumber()) {
    return Value();
  }
  return Value(atan(arg->Number()));
}
Value Ceil(Context* context) {
  Value* arg = context->GetParam(0);
  if (!arg->IsNumber()) {
    return Value();
  }
  return Value(ceil(arg->Number()));
}
Value Cos(Context* context) {
  Value* arg = context->GetParam(0);
  if (!arg->IsNumber()) {
    return Value();
  }
  return Value(cos(arg->Number()));
}
Value Exp(Context* context) {
  Value* arg = context->GetParam(0);
  if (!arg->IsNumber()) {
    return Value();
  }
  return Value(exp(arg->Number()));
}
Value Floor(Context* context) {
  Value* arg = context->GetParam(0);
  if (!arg->IsNumber()) {
    return Value();
  }
  return Value(floor(arg->Number()));
}
Value Log(Context* context) {
  Value* arg = context->GetParam(0);
  if (!arg->IsNumber()) {
    return Value();
  }
  return Value(log(arg->Number()));
}
Value Max(Context* context) {
  Value* arg1 = context->GetParam(0);
  Value* arg2 = context->GetParam(1);
  if (!arg1->IsNumber() || !arg2->IsNumber()) {
    return Value();
  }
  return Value(fmax(arg1->Number(), arg2->Number()));
}
Value Min(Context* context) {
  Value* arg1 = context->GetParam(0);
  Value* arg2 = context->GetParam(1);
  if (!arg1->IsNumber() || !arg2->IsNumber()) {
    return Value();
  }
  return Value(fmin(arg1->Number(), arg2->Number()));
}
Value Pow(Context* context) {
  Value* arg1 = context->GetParam(0);
  Value* arg2 = context->GetParam(1);
  if (!arg1->IsNumber() || !arg2->IsNumber()) {
    return Value();
  }
  return Value(pow(arg1->Number(), arg2->Number()));
}
Value Random(Context* context) {
  static bool seeded = false;
  if (!seeded) {
    seeded = true;
    srand(static_cast<unsigned int>(time(NULL)));
  }
  return Value(static_cast<float>(rand()) / static_cast<float>(RAND_MAX));
}
Value Round(Context* context) {
  Value* arg = context->GetParam(0);
  if (!arg->IsNumber()) {
    return Value();
  }
  return Value((int32_t)round(arg->Number()));
}
Value Sqrt(Context* context) {
  Value* arg = context->GetParam(0);
  if (!arg->IsNumber()) {
    return Value();
  }
  return Value(sqrt(arg->Number()));
}
Value Tan(Context* context) {
  Value* arg = context->GetParam(0);
  if (!arg->IsNumber()) {
    return Value();
  }
  return Value(tan(arg->Number()));
}

void RegisterMathAPI(Context* ctx) {
  lynx::base::scoped_refptr<Dictionary> table = Dictionary::Create();
  RegisterTableFunction(ctx, table, "sin", &Sin);
  RegisterTableFunction(ctx, table, "abs", &Abs);
  RegisterTableFunction(ctx, table, "acos", &Acos);
  RegisterTableFunction(ctx, table, "atan", &Atan);
  RegisterTableFunction(ctx, table, "asin", &Asin);
  RegisterTableFunction(ctx, table, "ceil", &Ceil);
  RegisterTableFunction(ctx, table, "cos", &Cos);
  RegisterTableFunction(ctx, table, "exp", &Exp);
  RegisterTableFunction(ctx, table, "floor", &Floor);
  RegisterTableFunction(ctx, table, "log", &Log);
  RegisterTableFunction(ctx, table, "max", &Max);
  RegisterTableFunction(ctx, table, "min", &Min);
  RegisterTableFunction(ctx, table, "pow", &Pow);
  RegisterTableFunction(ctx, table, "random", &Random);
  RegisterTableFunction(ctx, table, "round", &Round);
  RegisterTableFunction(ctx, table, "sqrt", &Sqrt);
  RegisterTableFunction(ctx, table, "tan", &Tan);
  RegisterFunctionTable(ctx, "Math", table);
}
}  // namespace lepus
}  // namespace lynx
#endif  // ENABLE_JUST_LEPUSNG
#endif  // LYNX_LEPUS_MATH_API_H_
