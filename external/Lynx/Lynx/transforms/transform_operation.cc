// Copyright 2022 The Lynx Authors. All rights reserved.

#include "transforms/transform_operation.h"

#include <base/log/logging.h>

#include "tasm/react/element.h"
#include "transforms/matrix44.h"

namespace lynx {
namespace transforms {

namespace {
bool IsOperationIdentity(const TransformOperation* operation) {
  return !operation || operation->IsIdentity();
}

float GetDefaultValue(TransformOperation::Type type) {
  switch (type) {
    case TransformOperation::Type::kScale: {
      return 1.0;
    }
    default: {
      return 0.0;
    }
  }
}

// get the final length type of translateX and translateY
std::array<TransformOperation::LengthType, 2> GetTranslateLengthType(
    const TransformOperation* from, const TransformOperation* to) {
  DCHECK(from || to);
  TransformOperation::LengthType final_type_x =
      TransformOperation::LengthType::kLengthUnit;
  TransformOperation::LengthType final_type_y =
      TransformOperation::LengthType::kLengthUnit;
  if (IsOperationIdentity(from) && !IsOperationIdentity(to)) {
    final_type_x = to->translate.type.x;
    final_type_y = to->translate.type.y;
  } else if (!IsOperationIdentity(from) && IsOperationIdentity(to)) {
    final_type_x = from->translate.type.x;
    final_type_y = from->translate.type.y;
  } else if (!IsOperationIdentity(from) && !IsOperationIdentity(to)) {
    if (from->translate.type.x == to->translate.type.x) {
      final_type_x = from->translate.type.x;
    }
    if (from->translate.type.y == to->translate.type.y) {
      final_type_y = from->translate.type.y;
    }
  }
  return std::array<TransformOperation::LengthType, 2>{final_type_x,
                                                       final_type_y};
}

// Convert possible percentage values to unit values
std::array<float, 3> GetPercentTranslateValue(
    const TransformOperation* translate, tasm::Element* element) {
  DCHECK(element);
  if (IsOperationIdentity(translate)) {
    return std::array<float, 3>{0.0f, 0.0f, 0.0f};
  }
  float x = translate->translate.value.x;
  float y = translate->translate.value.y;
  float z = translate->translate.value.z;
  if (translate->translate.type.x ==
      TransformOperation::LengthType::kLengthPercentage) {
    x = element->width() * x / 100.0f;
  }
  if (translate->translate.type.y ==
      TransformOperation::LengthType::kLengthPercentage) {
    y = element->height() * y / 100.0f;
  }
  return std::array<float, 3>{x, y, z};
};

static float BlendValue(float from, float to, float progress) {
  return from * (1 - progress) + to * progress;
}

}  // namespace
bool TransformOperation::IsIdentity() const {
  switch (type) {
    case TransformOperation::Type::kTranslate: {
      float default_value = GetDefaultValue(type);
      return translate.value.x == default_value &&
             translate.value.y == default_value &&
             translate.value.z == default_value;
    }
    case TransformOperation::Type::kRotateX:
    case TransformOperation::Type::kRotateY:
    case TransformOperation::Type::kRotateZ: {
      return rotate.degree == GetDefaultValue(type);
    }
    case TransformOperation::Type::kScale: {
      return scale.x == GetDefaultValue(type) &&
             scale.y == GetDefaultValue(type);
    }
    case TransformOperation::Type::kSkew: {
      return skew.x == GetDefaultValue(type) && skew.y == GetDefaultValue(type);
    }
    default: {
      return true;
    }
  }
}

// Lazy bake matrix till we need matrix, to avoid getting invalid size of
// element if layout is not ready.
const Matrix44& TransformOperation::GetMatrix(tasm::Element* element) {
  if (matrix44) {
    return *matrix44;
  }
  Bake(element);
  return *matrix44;
}

void TransformOperation::Bake(tasm::Element* element) {
  matrix44 = std::make_optional<Matrix44>();
  switch (type) {
    case TransformOperation::Type::kTranslate: {
      std::array<float, 3> arr = GetPercentTranslateValue(this, element);
      matrix44->preTranslate(arr[0], arr[1], arr[2]);
      break;
    }
    case TransformOperation::Type::kRotateX: {
      matrix44->setRotateAboutXAxis(rotate.degree);
      break;
    }
    case TransformOperation::Type::kRotateY: {
      matrix44->setRotateAboutYAxis(rotate.degree);
      break;
    }
    case TransformOperation::Type::kRotateZ: {
      matrix44->setRotateAboutZAxis(rotate.degree);
      break;
    }
    case TransformOperation::Type::kScale: {
      matrix44->preScale(scale.x, scale.y, 1);
      break;
    }
    case TransformOperation::Type::kSkew: {
      matrix44->Skew(skew.x, skew.y);
      break;
    }
    default: {
      break;
    }
  }
}

TransformOperation TransformOperation::BlendTransformOperations(
    const TransformOperation* from, const TransformOperation* to,
    float progress, tasm::Element* element) {
  DCHECK(from != nullptr || to != nullptr);
  DCHECK(element);
  if (IsOperationIdentity(from) && IsOperationIdentity(to)) {
    return TransformOperation();
  }
  TransformOperation operation;
  TransformOperation::Type transform_type =
      IsOperationIdentity(from) ? to->type : from->type;
  operation.type = transform_type;
  switch (transform_type) {
    case TransformOperation::Type::kTranslate: {
      float from_x = IsOperationIdentity(from) ? 0.0f : from->translate.value.x;
      float from_y = IsOperationIdentity(from) ? 0.0f : from->translate.value.y;
      float from_z = IsOperationIdentity(from) ? 0.0f : from->translate.value.z;
      float to_x = IsOperationIdentity(to) ? 0.0f : to->translate.value.x;
      float to_y = IsOperationIdentity(to) ? 0.0f : to->translate.value.y;
      float to_z = IsOperationIdentity(to) ? 0.0f : to->translate.value.z;
      std::array<TransformOperation::LengthType, 2> result_type_arr =
          GetTranslateLengthType(from, to);
      std::array<float, 3> from_value_arr =
          GetPercentTranslateValue(from, element);
      std::array<float, 3> to_value_arr = GetPercentTranslateValue(to, element);
      if (result_type_arr[0] !=
          TransformOperation::LengthType::kLengthPercentage) {
        from_x = from_value_arr[0];
        to_x = to_value_arr[0];
      }
      if (result_type_arr[1] !=
          TransformOperation::LengthType::kLengthPercentage) {
        from_y = from_value_arr[1];
        to_y = to_value_arr[1];
      }
      operation.translate.value.x = BlendValue(from_x, to_x, progress);
      operation.translate.value.y = BlendValue(from_y, to_y, progress);
      operation.translate.value.z = BlendValue(from_z, to_z, progress);
      operation.translate.type.x = result_type_arr[0];
      operation.translate.type.y = result_type_arr[1];
      operation.translate.type.z = TransformOperation::LengthType::kLengthUnit;
      return operation;
    }
    case TransformOperation::Type::kRotateX:
    case TransformOperation::Type::kRotateY:
    case TransformOperation::Type::kRotateZ: {
      float from_angle = IsOperationIdentity(from) ? 0.0f : from->rotate.degree;
      float to_angle = IsOperationIdentity(to) ? 0.0f : to->rotate.degree;
      operation.rotate.degree = BlendValue(from_angle, to_angle, progress);
      return operation;
    }
    case TransformOperation::Type::kScale: {
      float from_x = IsOperationIdentity(from) ? 1.0f : from->scale.x;
      float from_y = IsOperationIdentity(from) ? 1.0f : from->scale.y;
      float to_x = IsOperationIdentity(to) ? 1.0f : to->scale.x;
      float to_y = IsOperationIdentity(to) ? 1.0f : to->scale.y;
      operation.scale.x = BlendValue(from_x, to_x, progress);
      operation.scale.y = BlendValue(from_y, to_y, progress);
      return operation;
    }
    case TransformOperation::Type::kSkew: {
      float from_x = IsOperationIdentity(from) ? 0.0f : from->skew.x;
      float from_y = IsOperationIdentity(from) ? 0.0f : from->skew.y;
      float to_x = IsOperationIdentity(to) ? 0.0f : to->skew.x;
      float to_y = IsOperationIdentity(to) ? 0.0f : to->skew.y;
      operation.skew.x = BlendValue(from_x, to_x, progress);
      operation.skew.y = BlendValue(from_y, to_y, progress);
      return operation;
    }
    default: {
      return operation;
    }
  }
}

bool TransformOperation::NotifyElementSizeUpdated() {
  if (type == TransformOperation::Type::kTranslate &&
      (translate.type.x == TransformOperation::LengthType::kLengthPercentage ||
       translate.type.y == TransformOperation::LengthType::kLengthPercentage ||
       translate.type.z == TransformOperation::LengthType::kLengthPercentage)) {
    matrix44 = std::optional<Matrix44>();
    return true;
  }
  return false;
}

}  // namespace transforms
}  // namespace lynx
