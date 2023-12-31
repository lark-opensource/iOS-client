// Copyright 2023 The Lynx Authors. All rights reserved.
// Copyright 2018 Airbnb, Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef ANIMAX_MODEL_TEXT_DOCUMENT_DATA_MODEL_H_
#define ANIMAX_MODEL_TEXT_DOCUMENT_DATA_MODEL_H_

#include <memory>

#include "animax/model/basic_model.h"

namespace lynx {
namespace animax {

enum class DocumentJustification : uint8_t {
  kLeftAlign = 0,
  kRightAlign,
  kCenter
};

class DocumentDataModel {
 public:
  static DocumentDataModel MakeEmpty() {
    auto model = DocumentDataModel();
    model.size_ = NAN;
    return model;
  }

  DocumentDataModel() = default;
  DocumentDataModel(std::string text, std::string font_name, float size,
                    DocumentJustification justification, uint32_t tracking,
                    float line_height, float baseline_shift, int32_t color,
                    int32_t stroke_color, float stroke_width,
                    bool stroke_overfill, PointF box_position, PointF box_size)
      : text_(std::move(text)),
        font_name_(std::move(font_name)),
        size_(size),
        justification_(justification),
        tracking_(tracking),
        line_height_(line_height),
        baseline_shift_(baseline_shift),
        color_(color),
        stroke_color_(stroke_color),
        stroke_width_(stroke_width),
        stroke_overfill_(stroke_overfill),
        box_position_(std::move(box_position)),
        box_size_(std::move(box_size)) {}

  bool IsEmpty() const { return std::isnan(size_); }

 private:
  friend class TextLayer;

  std::string text_;
  std::string font_name_;
  float size_ = 0;
  DocumentJustification justification_;
  int32_t tracking_ = 0;
  float line_height_ = 0;
  float baseline_shift_ = 0;
  int32_t color_ = 0;
  int32_t stroke_color_ = 0;
  float stroke_width_ = 0;
  bool stroke_overfill_ = false;
  PointF box_position_;
  PointF box_size_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_TEXT_DOCUMENT_DATA_MODEL_H_
