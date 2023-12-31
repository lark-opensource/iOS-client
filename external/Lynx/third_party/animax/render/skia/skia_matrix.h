// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKIA_SKIA_MATRIX_H_
#define ANIMAX_RENDER_SKIA_SKIA_MATRIX_H_

#include "animax/render/include/matrix.h"
#include "animax/render/skia/skia_util.h"

namespace lynx {
namespace animax {

class SkiaMatrix : public Matrix {
 public:
  SkiaMatrix() = default;
  SkiaMatrix(SkMatrix sk_matrix) : skia_matrix_(std::move(sk_matrix)) {}
  ~SkiaMatrix() override = default;

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

  const SkMatrix &GetSkMatrix() const { return skia_matrix_; }

 private:
  SkMatrix skia_matrix_ = {};
};
}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKIA_SKIA_MATRIX_H_
