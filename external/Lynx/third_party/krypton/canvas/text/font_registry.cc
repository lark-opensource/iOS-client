// Copyright 2022 The Lynx Authors. All rights reserved.

#include "canvas/text/font_registry.h"

namespace lynx {
namespace canvas {

#ifndef OS_ANDROID
FontRegistry& FontRegistry::Instance() {
  static FontRegistry instance;
  return instance;
}
#endif

bool FontRegistry::Add(const char* name, const char* url, int weight,
                       int style) {
  if (name == nullptr || *name == 0 || url == nullptr || *url == 0 ||
      weight < 0 || style < 0) {
    KRYPTON_LOGE("add font param error");
    return false;
  }

  std::string normalized_name = StringToLowerASCII(name);
  std::lock_guard<std::mutex> lock(mutex_);
  auto& item_list = items_[normalized_name];
  for (auto it = item_list.begin(); it != item_list.end(); ++it) {
    if (it->Diff(weight, style) == 0) {
      it->url = url;
      KRYPTON_LOGI("replace font ") << normalized_name << ", " << url;
      return true;
    }
  }

  item_list.push_front(
      {.name = normalized_name, .url = url, .weight = weight, .style = style});
  KRYPTON_LOGI("add font ") << normalized_name << ", " << url;
  return true;
}

std::string FontRegistry::GetFontUrl(const std::string& name, int weight,
                                     int style) {
  std::lock_guard<std::mutex> lock(mutex_);

  std::string normalized_name = StringToLowerASCII(name);
  auto it_list = items_.find(normalized_name);
  if (it_list == items_.end() || it_list->second.empty()) {
    return "";
  }

  auto& item_list = it_list->second;
  auto result = item_list.begin();
  int diff = result->Diff(weight, style);
  auto it = result;
  for (++it; it != item_list.end(); ++it) {
    int new_diff = it->Diff(weight, style);
    if (new_diff < diff) {
      diff = new_diff;
      result = it;
    }
  }
  return result->url;
}

bool FontRegistry::GetAssetData(const std::string& path, uint8_t*& out,
                                size_t& out_size) {
  // default no implement
  return false;
}

}  // namespace canvas
}  // namespace lynx
