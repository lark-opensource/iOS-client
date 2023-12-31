// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skity/skity_matrix.h"

#include <cstring>
#include <vector>

#include "animax/render/skity/skity_util.h"

namespace lynx {
namespace animax {

bool SkityMatrix::IsIdentity() const { return matrix_.IsIdentity(); }

void SkityMatrix::Invert(Matrix &matrix) {
  auto skity_matrix = static_cast<SkityMatrix *>(&matrix);

  matrix_.Invert(&skity_matrix->matrix_);
}

void SkityMatrix::MapRect(RectF &rect) const {
  skity::Rect dst{};
  skity::Rect src = SkityUtil::MakeSkityRect(rect);

  matrix_.MapRect(&dst, src);

  rect.Set(dst.Left(), dst.Top(), dst.Right(), dst.Bottom());
}

void SkityMatrix::MapPoints(float *points, int32_t size) const {
  std::vector<skity::Vec2> skity_points;
  std::vector<skity::Vec2> skity_out{static_cast<size_t>(size)};

  for (int32_t i = 0; i < size; i++) {
    skity_points.emplace_back(skity::Vec2(points[i * 2], points[i * 2 + 1]));
  }

  matrix_.MapPoints(skity_out.data(), skity_points.data(), skity_points.size());

  std::memcpy(points, skity_out.data(), size * sizeof(skity::Vec2));
}

void SkityMatrix::Reset() { matrix_.Reset(); }

void SkityMatrix::Set(Matrix &matrix) {
  auto skity_matrix = static_cast<SkityMatrix *>(&matrix);

  matrix_ = skity_matrix->matrix_;
}

void SkityMatrix::SetValues(float *values) { matrix_.Set9(values); }

void SkityMatrix::PreConcat(Matrix &matrix) {
  auto skity_matrix = static_cast<SkityMatrix *>(&matrix);

  matrix_.PreConcat(skity_matrix->matrix_);
}

void SkityMatrix::PreRotate(float degress) { matrix_.PreRotate(degress); }

void SkityMatrix::PreRotate(float degress, float px, float py) {
  matrix_.PreRotate(degress, px, py);
}

void SkityMatrix::PreScale(float x, float y) { matrix_.PreScale(x, y); }

void SkityMatrix::PreTranslate(float x, float y) { matrix_.PreTranslate(x, y); }

float SkityMatrix::GetScale() const {
  float inv_sqrt_2 = std::sqrt(2) / 2.0;
  float points[4];
  points[0] = 0;
  points[1] = 0;
  points[2] = inv_sqrt_2;
  points[3] = inv_sqrt_2;
  MapPoints(points, 2);

  float dx = points[2] - points[0];
  float dy = points[3] - points[1];

  return std::hypot(dx, dy);
}
}  // namespace animax
}  // namespace lynx
