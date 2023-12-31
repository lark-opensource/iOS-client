// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_AIR_TESTING_AIR_LEPUS_CONTEXT_MOCK_H_
#define LYNX_TASM_AIR_TESTING_AIR_LEPUS_CONTEXT_MOCK_H_

#include <vector>

#include "gmock/gmock.h"
#include "lepus/quick_context.h"

namespace lynx {
namespace air {
namespace testing {
class AirMockLepusContext : public lepus::QuickContext {
 public:
  lepus::Value CallWithClosure(const lepus::Value& closure,
                               const std::vector<lepus::Value>& args) override {
    return lepus::Value(1);
  }
};

}  // namespace testing
}  // namespace air
}  // namespace lynx

#endif  // LYNX_TASM_AIR_TESTING_AIR_LEPUS_CONTEXT_MOCK_H_
