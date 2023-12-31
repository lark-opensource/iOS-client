// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_VALUE_UTILS_H_
#define LYNX_TASM_VALUE_UTILS_H_
#include <functional>
#include <string>
#include <utility>

#include "base/compiler_specific.h"
#include "lepus/array.h"
#include "lepus/table.h"
#include "lepus/value-inl.h"

namespace lynx {
namespace tasm {

// shadow equal check for table value
bool CheckTableValueNotEqual(const lepus::Value& target_item_value,
                             const lepus::Value& update_item_value);
#if ENABLE_INSPECTOR && LYNX_ENABLE_TRACING
bool CheckTableDeepUpdated(const lepus::Value& target,
                           const lepus::Value& update, bool first_layer);
#endif
// shadow equal for table
bool CheckTableShadowUpdated(const lepus::Value& target,
                             const lepus::Value& update);

void ForEachLepusValue(const lepus::Value& value,
                       lepus::LepusValueIterator func);

std::string GetTimingFlag(const lepus_value& table);

lepus::Value ConvertJSValueToLepusValue(const lepus::Value& value);

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_VALUE_UTILS_H_
