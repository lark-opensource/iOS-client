// Copyright 2021 The Lynx Authors. All rights reserved.

#include "typeface.h"

namespace lynx {
namespace canvas {
Typeface::Typeface(std::string name, std::unique_ptr<DataHolder> font_data)
    : font_name_(std::move(name)),
      font_data_(std::move(font_data)),
      id_(GenerateUniqueId()) {}

}  // namespace canvas
}  // namespace lynx
