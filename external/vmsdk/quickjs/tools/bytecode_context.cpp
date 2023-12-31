#include "quickjs/tools/bytecode_context.h"

#include <iostream>

#include "quickjs/tools/value.h"

using namespace quickjs::bytecode;

std::string DataBuffer::EMPTY_STR = "";

Status BytecodeContext::compile() {
  // 1. set shuffle mode
  // todo:
  (void)config;

  // 2. compile
  LEPUSValue obj =
      LEPUS_Eval(getContext(), jsStr.data(), jsStr.length(), "",
                 LEPUS_EVAL_FLAG_COMPILE_ONLY | LEPUS_EVAL_TYPE_GLOBAL);
  if (LEPUS_IsException(obj))
    return Status(ERR_FAILED_TO_COMPILE, getExceptionMessage());

  setTopLevelFunction(obj);
  complete = true;
  return Status::OK();
}

Status BytecodeContext::call(const std::string &name,
                             const std::vector<Value> &args, Value &result) {
  Status status = Status::OK();
  std::vector<LEPUSValue> jsArgs;
  jsArgs.reserve(args.size());
  for (Value v : args) jsArgs.emplace_back(v.getJSValue());

  LEPUSValue ret = LEPUS_UNDEFINED;
  status = getAndCall(name, jsArgs, ret);
  // ret has been add reference by Value
  if (status.ok()) {
    auto sharedThis = sharedFromThis();
    result = Value(sharedThis, ret);
  }
  // free current reference
  LEPUS_FreeValue(getContext(), ret);

  for (LEPUSValue v : jsArgs) LEPUS_FreeValue(getContext(), v);

  return status;
}

// void BytecodeContext::execute() {
//   if (LEPUS_IsUndefined(getTopLevelFunc())) {
//     std::cout << "no compiled function object\n";
//     return;
//   }

//   LEPUSValue global = LEPUS_GetGlobalObject(getContext());
//   LEPUSValue ret = LEPUS_EvalFunction(getContext(), getTopLevelFunc(),
//   global);
//   // LEPUS_FreeValue(getContext(), global);
//   if (LEPUS_IsException(ret)) {
//     std::string log = getExceptionMessage();
//     std::cout << log << std::endl;
//   }
//   LEPUS_FreeValue(getContext(), ret);
// }

LEPUSValue BytecodeContext::getProprety(const std::string &name,
                                        LEPUSValue thisObj) {
  LEPUSAtom atom = LEPUS_NewAtom(getContext(), name.c_str());
  LEPUSValue ret = LEPUS_GetProperty(getContext(), thisObj, atom);
  LEPUS_FreeAtom(getContext(), atom);
  return ret;
}

Status BytecodeContext::internalCall(LEPUSValue caller,
                                     const std::vector<LEPUSValue> &args,
                                     LEPUSValue &result) noexcept {
  Status status = Status::OK();
  LEPUSValue global = LEPUS_GetGlobalObject(getContext());
  LEPUSValue ret = LEPUS_Call(getContext(), caller, global, args.size(),
                              const_cast<LEPUSValue *>(args.data()));
  LEPUS_FreeValue(getContext(), global);
  if (LEPUS_IsException(ret))
    status = Status(ERR_GET_EXCEPTION_FOR_CALLING, getExceptionMessage());
  result = ret;
  return status;
}

Status BytecodeContext::getAndCall(const std::string &name,
                                   const std::vector<LEPUSValue> &args,
                                   LEPUSValue &result) noexcept {
  LEPUSAtom atom = LEPUS_NewAtom(getContext(), name.c_str());
  LEPUSValue caller = LEPUS_GetGlobalVar(getContext(), atom, 0);
  LEPUS_FreeAtom(getContext(), atom);

  Status status = Status::OK();
  if (!LEPUS_IsFunction(getContext(), caller))
    status = Status(ERR_OBJ_IS_NOT_FUNC, "caller should be function");
  else
    status = internalCall(caller, args, result);
  LEPUS_FreeValue(getContext(), caller);
  return status;
}

std::string BytecodeContext::getExceptionMessage() {
  LEPUSValue exception_val = LEPUS_GetException(getContext());
  LEPUSValue val;
  const char *stack;
  const char *message = LEPUS_ToCString(getContext(), exception_val);
  std::string ret = "";
  if (message) {
    ret += message;
    LEPUS_FreeCString(getContext(), message);
  }

  bool is_error = LEPUS_IsError(getContext(), exception_val);
  if (is_error) {
    val = LEPUS_GetPropertyStr(getContext(), exception_val, "stack");
    if (!LEPUS_IsUndefined(val)) {
      stack = LEPUS_ToCString(getContext(), val);
      ret += stack;
      LEPUS_FreeCString(getContext(), stack);
    }
    LEPUS_FreeValue(getContext(), val);
  }
  LEPUS_FreeValue(getContext(), exception_val);
  return ret;
}
