// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_LYNX_VIEW_DATA_MANAGER_H_
#define LYNX_TASM_LYNX_VIEW_DATA_MANAGER_H_

#include "third_party/rapidjson/document.h"

namespace lynx {
namespace lepus {
class Value;
}

namespace tasm {
class LynxViewDataManager {
 public:
  static lepus::Value* ParseData(const char* data);
  static lepus::Value* ParseData(rapidjson::Value&& data);
  static void ReleaseData(lepus::Value* obj);
  static bool UpdateData(lepus::Value* target, lepus::Value* value);
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_LYNX_VIEW_DATA_MANAGER_H_
