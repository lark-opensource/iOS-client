// Copyright 2022 The Lynx Authors. All rights reserved.
// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifdef OS_WIN
#define _USE_MATH_DEFINES
#endif

#include "transforms/transform_operations.h"

#include <algorithm>
#include <cmath>
#include <utility>

#include "animation/css_keyframe_manager.h"
#include "starlight/style/css_style_utils.h"
#include "tasm/react/element_manager.h"
#include "transforms/decomposed_transform.h"
#include "transforms/matrix44.h"
#include "transforms/transform_operation.h"

namespace lynx {
namespace transforms {
static inline constexpr float RadToDeg(float rad) {
  return rad * 180.0f / M_PI;
}

// A standalone function using for initialize a transform operations with
// transform raw data. It will traverse each item in the raw data and append
// different transform operation to transform operations according to the item
// type.
void TransformOperations::InitializeTransformOperations(
    TransformOperations& transform_operations,
    std::vector<lynx::starlight::TransformRawData>& transform_raw_data) {
  for (auto& item : transform_raw_data) {
    switch (item.type) {
      case starlight::TransformType::kTranslate: {
        transform_operations.AppendTranslate(
            item.p0.GetRawValue(),
            item.p0.IsPercent()
                ? TransformOperation::LengthType::kLengthPercentage
                : TransformOperation::LengthType::kLengthUnit,
            item.p1.GetRawValue(),
            item.p1.IsPercent()
                ? TransformOperation::LengthType::kLengthPercentage
                : TransformOperation::LengthType::kLengthUnit,
            0.0f, TransformOperation::LengthType::kLengthUnit);
        break;
      }
      case starlight::TransformType::kTranslateX: {
        transform_operations.AppendTranslate(
            item.p0.GetRawValue(),
            item.p0.IsPercent()
                ? TransformOperation::LengthType::kLengthPercentage
                : TransformOperation::LengthType::kLengthUnit,
            0.0f, TransformOperation::LengthType::kLengthUnit, 0.0f,
            TransformOperation::LengthType::kLengthUnit);
        break;
      }
      case starlight::TransformType::kTranslateY: {
        transform_operations.AppendTranslate(
            0.0f, TransformOperation::LengthType::kLengthUnit,
            item.p0.GetRawValue(),
            item.p0.IsPercent()
                ? TransformOperation::LengthType::kLengthPercentage
                : TransformOperation::LengthType::kLengthUnit,
            0.0f, TransformOperation::LengthType::kLengthUnit);
        break;
      }
      case starlight::TransformType::kTranslateZ: {
        transform_operations.AppendTranslate(
            0.0f, TransformOperation::LengthType::kLengthUnit, 0.0f,
            TransformOperation::LengthType::kLengthUnit, item.p0.GetRawValue(),
            item.p0.IsPercent()
                ? TransformOperation::LengthType::kLengthPercentage
                : TransformOperation::LengthType::kLengthUnit);
        break;
      }
      case starlight::TransformType::kTranslate3d: {
        transform_operations.AppendTranslate(
            item.p0.GetRawValue(),
            item.p0.IsPercent()
                ? TransformOperation::LengthType::kLengthPercentage
                : TransformOperation::LengthType::kLengthUnit,
            item.p1.GetRawValue(),
            item.p1.IsPercent()
                ? TransformOperation::LengthType::kLengthPercentage
                : TransformOperation::LengthType::kLengthUnit,
            item.p2.GetRawValue(),
            item.p2.IsPercent()
                ? TransformOperation::LengthType::kLengthPercentage
                : TransformOperation::LengthType::kLengthUnit);
        break;
      }
      case starlight::TransformType::kRotateX: {
        transform_operations.AppendRotate(TransformOperation::Type::kRotateX,
                                          item.p0.GetRawValue());
        break;
      }
      case starlight::TransformType::kRotateY: {
        transform_operations.AppendRotate(TransformOperation::Type::kRotateY,
                                          item.p0.GetRawValue());
        break;
      }
      case starlight::TransformType::kRotate:
      case starlight::TransformType::kRotateZ: {
        transform_operations.AppendRotate(TransformOperation::Type::kRotateZ,
                                          item.p0.GetRawValue());
        break;
      }
      case starlight::TransformType::kScale: {
        transform_operations.AppendScale(item.p0.GetRawValue(),
                                         item.p1.GetRawValue());
        break;
      }
      case starlight::TransformType::kScaleX: {
        transform_operations.AppendScale(item.p0.GetRawValue(), 1.0f);
        break;
      }
      case starlight::TransformType::kScaleY: {
        transform_operations.AppendScale(1.0f, item.p0.GetRawValue());
        break;
      }
      case starlight::TransformType::kSkew: {
        transform_operations.AppendSkew(item.p0.GetRawValue(),
                                        item.p1.GetRawValue());
        break;
      }
      case starlight::TransformType::kSkewX: {
        transform_operations.AppendSkew(item.p0.GetRawValue(), 0.0f);
        break;
      }
      case starlight::TransformType::kSkewY: {
        transform_operations.AppendSkew(0.0f, item.p0.GetRawValue());
        break;
      }
      default: {
        break;
      }
    }
  }
}

TransformOperations::TransformOperations(tasm::Element* element)
    : element_(element) {}

// Construct a transform operations with transform data whose type is
// tasm::CSSValue. The transform data should be parsed by
// starlight::CSSStyleUtils::ComputeTransform before using it to initialize a
// transform operations.
TransformOperations::TransformOperations(tasm::Element* element,
                                         const tasm::CSSValue& raw_data)
    : element_(element) {
  std::optional<std::vector<starlight::TransformRawData>> transform_data =
      std::make_optional<std::vector<starlight::TransformRawData>>();
  if (!starlight::CSSStyleUtils::ComputeTransform(
          raw_data, false, transform_data,
          animation::CSSKeyframeManager::GetLengthContext(element),
          element->element_manager()->GetCSSParserConfigs())) {
    return;
  }
  InitializeTransformOperations(*this, *transform_data);
}

TransformOperations::TransformOperations(const TransformOperations& other) {
  operations_ = other.operations_;
  element_ = other.element_;
}

TransformOperations::~TransformOperations() = default;

TransformOperations& TransformOperations::operator=(
    const TransformOperations& other) {
  operations_ = other.operations_;
  return *this;
}

Matrix44 TransformOperations::ApplyRemaining(size_t start) {
  Matrix44 to_return;
  for (size_t i = start; i < operations_.size(); i++) {
    to_return.preConcat(operations_[i].GetMatrix(element_));
  }
  return to_return;
}

TransformOperations TransformOperations::Blend(TransformOperations& from,
                                               float progress) {
  TransformOperations to_return(this->element_);
  if (!BlendInternal(from, progress, &to_return)) {
    // If the matrices cannot be blended, fallback to discrete animation logic.
    // See https://drafts.csswg.org/css-transforms/#matrix-interpolation
    to_return = progress < 0.5 ? from : *this;
  }
  return to_return;
}

size_t TransformOperations::MatchingPrefixLength(
    const TransformOperations& other) const {
  size_t num_operations =
      std::min(operations_.size(), other.operations_.size());
  for (size_t i = 0; i < num_operations; ++i) {
    if (operations_[i].type != other.operations_[i].type) {
      // Remaining operations in each operations list require matrix/matrix3d
      // interpolation.
      return i;
    }
  }
  // If the operations match to the length of the shorter list, then pad its
  // length with the matching identity operations.
  // https://drafts.csswg.org/css-transforms/#transform-function-lists
  return std::max(operations_.size(), other.operations_.size());
}

bool TransformOperations::IsIdentity() const {
  for (auto& operation : operations_) {
    if (!operation.IsIdentity()) return false;
  }
  return true;
}

void TransformOperations::Append(const TransformOperation& operation) {
  operations_.push_back(operation);
  decomposed_transforms_.clear();
}

void TransformOperations::AppendTranslate(
    float x_value, TransformOperation::LengthType x_type, float y_value,
    TransformOperation::LengthType y_type, float z_value,
    TransformOperation::LengthType z_type) {
  TransformOperation op;
  op.type = TransformOperation::Type::kTranslate;
  op.translate.type.x = x_type;
  op.translate.type.y = y_type;
  op.translate.type.z = z_type;
  op.translate.value.x = x_value;
  op.translate.value.y = y_value;
  op.translate.value.z = z_value;
  Append(op);
}
void TransformOperations::AppendRotate(TransformOperation::Type type,
                                       float degree) {
  TransformOperation op;
  op.type = type;
  op.rotate.degree = degree;
  Append(op);
}
void TransformOperations::AppendScale(float x, float y) {
  TransformOperation op;
  op.type = TransformOperation::Type::kScale;
  op.scale.x = x;
  op.scale.y = y;
  Append(op);
}
void TransformOperations::AppendSkew(float x, float y) {
  TransformOperation op;
  op.type = TransformOperation::Type::kSkew;
  op.skew.x = x;
  op.skew.y = y;
  Append(op);
}

void TransformOperations::AppendDecomposedTransform(
    const DecomposedTransform& decomposed) {
  AppendTranslate(
      decomposed.translate[0], TransformOperation::LengthType::kLengthUnit,
      decomposed.translate[1], TransformOperation::LengthType::kLengthUnit,
      decomposed.translate[2], TransformOperation::LengthType::kLengthUnit);

  Euler euler = decomposed.quaternion.ConvertToEuler();
  AppendRotate(TransformOperation::Type::kRotateX, RadToDeg(euler.x));
  AppendRotate(TransformOperation::Type::kRotateY, RadToDeg(euler.y));
  AppendRotate(TransformOperation::Type::kRotateZ, RadToDeg(euler.z));

  AppendSkew(RadToDeg(atan(decomposed.skew[0])), 0);

  AppendScale(decomposed.scale[0], decomposed.scale[1]);
}

bool TransformOperations::BlendInternal(TransformOperations& from,
                                        float progress,
                                        TransformOperations* result) {
  bool from_identity = from.IsIdentity();
  bool to_identity = IsIdentity();
  if (from_identity && to_identity) return true;

  size_t matching_prefix_length = MatchingPrefixLength(from);
  size_t from_size = from_identity ? 0 : from.operations_.size();
  size_t to_size = to_identity ? 0 : operations_.size();
  size_t num_operations = std::max(from_size, to_size);

  for (size_t i = 0; i < matching_prefix_length; ++i) {
    TransformOperation blended = TransformOperation::BlendTransformOperations(
        i >= from_size ? nullptr : &from.operations_[i],
        i >= to_size ? nullptr : &operations_[i], progress, element_);
    result->Append(blended);
  }

  if (matching_prefix_length < num_operations) {
    if (!ComputeDecomposedTransform(matching_prefix_length) ||
        !from.ComputeDecomposedTransform(matching_prefix_length)) {
      return false;
    }
    DecomposedTransform matrix_transform = BlendDecomposedTransforms(
        *decomposed_transforms_[matching_prefix_length],
        *from.decomposed_transforms_[matching_prefix_length], progress);
    result->AppendDecomposedTransform(matrix_transform);
  }
  return true;
}

bool TransformOperations::ComputeDecomposedTransform(size_t start_offset) {
  auto it = decomposed_transforms_.find(start_offset);
  if (it == decomposed_transforms_.end()) {
    std::unique_ptr<DecomposedTransform> decomposed_transform =
        std::make_unique<DecomposedTransform>();
    Matrix44 transform = ApplyRemaining(start_offset);
    if (!DecomposeTransform(decomposed_transform.get(), transform)) {
      return false;
    }
    decomposed_transforms_[start_offset] = std::move(decomposed_transform);
  }
  return true;
}

void TransformOperations::NotifyElementSizeUpdated() {
  bool need_update = false;
  for (auto& op : operations_) {
    need_update = need_update || op.NotifyElementSizeUpdated();
  }
  if (need_update) {
    decomposed_transforms_.clear();
  }
}

// A method using for converting transform operations to transform raw data.
// Transform operations will be used for animation calculations. After the
// calculation is over, use this method to convert operations to raw data and
// update it on element.
tasm::CSSValue TransformOperations::ToTransformRawValue() {
  auto items = lepus::CArray::Create();
  for (auto& op : operations_) {
    switch (op.type) {
      case TransformOperation::Type::kTranslate: {
        auto item = lepus::CArray::Create();
        item->push_back(lepus::Value(
            static_cast<int>(starlight::TransformType::kTranslate3d)));
        item->push_back(lepus::Value(op.translate.value.x));
        item->push_back(lepus::Value(static_cast<int>(
            op.translate.type.x ==
                    TransformOperation::LengthType::kLengthPercentage
                ? tasm::CSSValuePattern::PERCENT
                : tasm::CSSValuePattern::NUMBER)));
        item->push_back(lepus::Value(op.translate.value.y));
        item->push_back(lepus::Value(static_cast<int>(
            op.translate.type.y ==
                    TransformOperation::LengthType::kLengthPercentage
                ? tasm::CSSValuePattern::PERCENT
                : tasm::CSSValuePattern::NUMBER)));
        item->push_back(lepus::Value(op.translate.value.z));
        item->push_back(lepus::Value(static_cast<int>(
            op.translate.type.z ==
                    TransformOperation::LengthType::kLengthPercentage
                ? tasm::CSSValuePattern::PERCENT
                : tasm::CSSValuePattern::NUMBER)));
        items->push_back(lepus::Value(item));
        break;
      }
      case TransformOperation::Type::kRotateX: {
        auto item = lepus::CArray::Create();
        item->push_back(
            lepus::Value(static_cast<int>(starlight::TransformType::kRotateX)));
        item->push_back(lepus::Value(op.rotate.degree));
        items->push_back(lepus::Value(item));
        break;
      }
      case TransformOperation::Type::kRotateY: {
        auto item = lepus::CArray::Create();
        item->push_back(
            lepus::Value(static_cast<int>(starlight::TransformType::kRotateY)));
        item->push_back(lepus::Value(op.rotate.degree));
        items->push_back(lepus::Value(item));
        break;
      }
      case TransformOperation::Type::kRotateZ: {
        auto item = lepus::CArray::Create();
        item->push_back(
            lepus::Value(static_cast<int>(starlight::TransformType::kRotateZ)));
        item->push_back(lepus::Value(op.rotate.degree));
        items->push_back(lepus::Value(item));
        break;
      }
      case TransformOperation::Type::kScale: {
        auto item = lepus::CArray::Create();
        item->push_back(
            lepus::Value(static_cast<int>(starlight::TransformType::kScale)));
        item->push_back(lepus::Value(op.scale.x));
        item->push_back(lepus::Value(op.scale.y));
        items->push_back(lepus::Value(item));
        break;
      }
      case TransformOperation::Type::kSkew: {
        auto item = lepus::CArray::Create();
        item->push_back(
            lepus::Value(static_cast<int>(starlight::TransformType::kSkew)));
        item->push_back(lepus::Value(op.skew.x));
        item->push_back(lepus::Value(op.skew.y));
        items->push_back(lepus::Value(item));
        break;
      }
      default: {
        break;
      }
    }
  }
  return tasm::CSSValue(lepus::Value(items), tasm::CSSValuePattern::ARRAY);
}

}  // namespace transforms
}  // namespace lynx
