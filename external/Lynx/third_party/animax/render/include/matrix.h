// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_INCLUDE_MATRIX_H_
#define ANIMAX_RENDER_INCLUDE_MATRIX_H_

#include <memory>
#include <vector>

#include "animax/model/basic_model.h"

namespace lynx {
namespace animax {

class Matrix {
 public:
  virtual ~Matrix() = default;

  virtual bool IsIdentity() const = 0;
  virtual void Invert(Matrix& matrix) = 0;
  virtual void MapRect(RectF& rect) const = 0;
  virtual void MapPoints(float points[], int32_t size) const = 0;

  virtual void Reset() = 0;
  virtual void Set(Matrix& matrix) = 0;
  virtual void SetValues(float* values) = 0;

  virtual void PreConcat(Matrix& matrix) = 0;
  virtual void PreRotate(float degress) = 0;
  virtual void PreRotate(float degress, float px, float py) = 0;
  virtual void PreScale(float x, float y) = 0;
  virtual void PreTranslate(float x, float y) = 0;

  virtual float GetScale() const = 0;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_INCLUDE_MATRIX_H_
