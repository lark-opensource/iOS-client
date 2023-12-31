// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_LEPUS_BYTECODE_PRINT_H_
#define LYNX_LEPUS_BYTECODE_PRINT_H_

#include <base/log/logging.h>

#include <chrono>
#include <vector>

#include "lepus/value.h"
#include "lepus/vm_context.h"
namespace lynx {
namespace lepus {
enum OffsetScope {
  Normal = 0,
  Global = 1,
  Constant,
  Clo  // represents Closure type
};

class Dumper {
 public:
  Dumper(Function* r) : root(r) {}
  void Dump();
  void DumpFunction();

 private:
  Function* root;
  void PrintOpCode(Instruction ins, Function* func_ptr, int i);
  void PrintDetail(const char* oper, int nums, long offsets[],
                   OffsetScope scopeId[]);
  std::vector<Function*> functions_;
};
}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_BYTECODE_PRINT_H_
