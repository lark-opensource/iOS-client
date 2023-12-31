// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKITY_SKITY_MATRIX_H_
#define ANIMAX_RENDER_SKITY_SKITY_MATRIX_H_

#include "animax/render/include/matrix.h"
#include "skity/skity.hpp"

namespace lynx {
namespace animax {

class SkityMatrix : public Matrix {
 public:
  SkityMatrix() : matrix_() {}
  explicit SkityMatrix(skity::Matrix const &m) : matrix_(m) {}
  ~SkityMatrix() override = default;

  bool IsIdentity() const override;

  void Invert(Matrix &matrix) override;

  void MapRect(RectF &rect) const override;

  void MapPoints(float *points, int32_t size) const override;

  void Reset() override;

  void Set(Matrix &matrix) override;

  void SetValues(float *values) override;

  void PreConcat(Matrix &matrix) override;

  void PreRotate(float degress) override;

  void PreRotate(float degress, float px, float py) override;

  void PreScale(float x, float y) override;

  void PreTranslate(float x, float y) override;

  float GetScale() const override;

  skity::Matrix const &GetMatrix() const { return matrix_; }

 private:
  skity::Matrix matrix_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKITY_SKITY_MATRIX_H_
