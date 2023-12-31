// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_TEXT_TYPEFACE_H_
#define CANVAS_TEXT_TYPEFACE_H_

#include <string>

#include "canvas/2d/lite/nanovg/include/nanovg.h"
#include "canvas/base/data_holder.h"

namespace lynx {
namespace canvas {
class Typeface {
 public:
  Typeface(std::string name, std::unique_ptr<DataHolder> font_data);

  std::string Name() const { return font_name_; }

  const void *Data() const { return font_data_->Data(); }

  size_t Size() const { return font_data_->Size(); }

  size_t Id() const { return id_; }

 private:
  static size_t GenerateUniqueId() {
    static size_t next_id = 0;
    return next_id++;
  }

  std::string font_name_;
  std::unique_ptr<DataHolder> font_data_;
  size_t id_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_TEXT_TYPEFACE_H_
