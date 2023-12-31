// Copyright 2022 The Lynx Authors. All rights reserved.

#include "font_collection.h"

#include "canvas/util/string_utils.h"

namespace lynx {
namespace canvas {

void FontCollection::AddNormalTypeface(std::string name,
                                       std::unique_ptr<DataHolder> font_data) {
  if (name.empty() || !font_data->Size()) {
    return;
  }

  auto lowercase_name = canvas::StringToLowerASCII(name);

  auto typeface =
      std::make_unique<Typeface>(lowercase_name, std::move(font_data));

  for (auto observer : observer_) {
    observer->OnTypeFaceAdded(typeface.get());
  }

  typeface_map_[lowercase_name] = std::move(typeface);
}

Typeface *FontCollection::GetTypeface(const std::string &name) const {
  auto iter = typeface_map_.find(name);
  if (iter != typeface_map_.end()) {
    return iter->second.get();
  }
  return nullptr;
}

void FontCollection::AddTypefaceObserver(
    FontCollection::TypefaceObserver *typeface_observer) {
  observer_.emplace_back(typeface_observer);

  // make sure observer see all typeface
  for (auto &pair : typeface_map_) {
    typeface_observer->OnTypeFaceAdded(pair.second.get());
  }
}

void FontCollection::RemoveTypefaceObserver(
    FontCollection::TypefaceObserver *typeface_observer) {
  observer_.erase(
      std::remove(observer_.begin(), observer_.end(), typeface_observer),
      observer_.end());
}
}  // namespace canvas
}  // namespace lynx
