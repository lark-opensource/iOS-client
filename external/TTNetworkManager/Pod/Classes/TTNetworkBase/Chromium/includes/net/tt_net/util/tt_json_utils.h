// Copyright (c) 2020 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_UTIL_TT_JSON_UTILS_H_
#define NET_TT_NET_UTIL_TT_JSON_UTILS_H_

#include <string>
#include "base/logging.h"
#include "base/strings/string_number_conversions.h"
#include "base/values.h"
#include "net/tt_net/util/tt_json_utils_internal.h"

namespace base {
class DictionaryValue;
}

namespace net {

namespace ttutils {

template <typename T>
bool GetJsonNodeValueWithName(const base::DictionaryValue* parent_node,
                              const std::string& child_name,
                              T* child_value) {
  if (!parent_node) {
    DLOG(WARNING) << "No parent node when resolving child node " << child_name;
    return false;
  }
  const auto* child_node = parent_node->FindPath(child_name);
  if (!child_node) {
    DLOG(WARNING) << "Find no child node for name " << child_name;
    return false;
  }
  return GetJsonNodeValueWithNameInner(child_name, child_node, child_value);
}

template <typename T>
bool GetJsonNodeValueWithNameWithDefault(
    const base::DictionaryValue* parent_node,
    const std::string& child_name,
    T* child_value,
    T default_value) {
  if (!parent_node) {
    DLOG(WARNING) << "No parent node when resolving child node " << child_name;
    *child_value = default_value;
    return false;
  }
  const auto* child_node = parent_node->FindPath(child_name);
  if (!child_node) {
    DLOG(WARNING) << "Find no child node for name " << child_name;
    *child_value = default_value;
    return false;
  }
  bool inner =
      GetJsonNodeValueWithNameInner(child_name, child_node, child_value);
  if (!inner) {
    *child_value = default_value;
  }
  return inner;
}

void GetJsonNodeAsSize_t(const base::DictionaryValue* json_dict,
                         const std::string& name,
                         size_t* aim_constant,
                         size_t default_value);

void GetJsonStringNodeAsInt64_t(const base::DictionaryValue* json_dict,
                                std::string name,
                                int64_t* aim_constant,
                                int64_t default_value);

void GetJsonNodeAsUint8_t(const base::DictionaryValue* json_dict,
                          std::string name,
                          uint8_t* aim_constant,
                          uint8_t default_value);

}  // namespace ttutils

}  // namespace net

#endif  // NET_TT_NET_UTIL_TT_JSON_UTILS_H_
