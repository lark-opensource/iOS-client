// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_CONTENT_DATA_H_
#define LYNX_STARLIGHT_STYLE_CONTENT_DATA_H_

#include <tuple>

#include "lepus/value.h"
#include "starlight/style/css_type.h"

namespace lynx {
namespace starlight {
struct ContentData {
  ContentData() : type(ContentType::kInvalid), content_data("") {}

  ContentType type;
  lepus::String content_data;

  bool operator==(const Content& rhs) const {
    return std::tie(type, content_data) == std::tie(rhs.type, rhs.content_data);
  }
};
}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_CONTENT_DATA_H_
