// Copyright 2022 The Lynx Authors. All rights reserved.
// Copyright 2013 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LYNX_TRANSFORMS_TRANSFORM_OPERATION_H_
#define LYNX_TRANSFORMS_TRANSFORM_OPERATION_H_

#include <optional>

#include "starlight/style/css_type.h"
#include "starlight/types/nlength.h"
#include "transforms/matrix44.h"

namespace lynx {
namespace tasm {
class Element;
}
namespace transforms {

struct TransformOperation {
  enum LengthType {
    kLengthUnit,
    kLengthPercentage,
  };
  enum Type {
    kIdentity = 0,
    kTranslate = 1,
    kRotateX = 1 << 2,
    kRotateY = 1 << 3,
    kRotateZ = 1 << 4,
    kScale = 1 << 5,
    kSkew = 1 << 6,
  };
  const Matrix44& GetMatrix(tasm::Element* element);

  bool NotifyElementSizeUpdated();

  // If you change the union value of TransformOperation, you should call Bake()
  // directly to make a new matrix!
  void Bake(tasm::Element* element);

  bool IsIdentity() const;
  static TransformOperation BlendTransformOperations(
      const TransformOperation* from, const TransformOperation* to,
      float progress, tasm::Element* element);

  union {
    struct {
      float x, y;  // degree
    } skew;

    struct {
      float x, y;
    } scale;

    struct {
      struct {
        LengthType x, y, z;
      } type;
      struct {
        float x, y, z;
      } value;
    } translate;

    struct {
      float degree;
    } rotate;
  };
  Type type = kIdentity;

 private:
  std::optional<Matrix44> matrix44;
};
}  // namespace transforms
}  // namespace lynx

#endif  // LYNX_TRANSFORMS_TRANSFORM_OPERATION_H_
