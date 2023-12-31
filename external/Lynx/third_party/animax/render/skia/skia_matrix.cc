// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skia/skia_matrix.h"

#include <vector>

#include "animax/model/basic_model.h"
#include "animax/render/skia/skia_util.h"

namespace lynx {
namespace animax {

void SkiaMatrix::PreTranslate(float x, float y) {
  skia_matrix_.preTranslate(x, y);
}

void SkiaMatrix::Reset() { skia_matrix_.reset(); }

void SkiaMatrix::PreConcat(Matrix& matrix) {
  auto sk_matrix = static_cast<SkiaMatrix*>(&matrix);
  skia_matrix_.preConcat(sk_matrix->skia_matrix_);
}

void SkiaMatrix::Set(Matrix& matrix) {
  auto sk_matrix = static_cast<SkiaMatrix*>(&matrix);
  skia_matrix_ = sk_matrix->skia_matrix_;
}

void SkiaMatrix::SetValues(float* values) { skia_matrix_.set9(values); }

void SkiaMatrix::PreRotate(float degress) { skia_matrix_.preRotate(degress); }

void SkiaMatrix::PreRotate(float degress, float px, float py) {
  skia_matrix_.preRotate(degress, px, py);
}

void SkiaMatrix::PreScale(float x, float y) { skia_matrix_.preScale(x, y); }

bool SkiaMatrix::IsIdentity() const { return skia_matrix_.isIdentity(); }

void SkiaMatrix::Invert(Matrix& matrix) {
  skia_matrix_.invert(&static_cast<SkiaMatrix*>(&matrix)->skia_matrix_);
}

void SkiaMatrix::MapRect(RectF& rect) const {
  auto sk_rect = MakeRect(rect);

  SkRect sk_out;

  skia_matrix_.mapRect(&sk_out, sk_rect);

  rect.Set(sk_out.left(), sk_out.top(), sk_out.right(), sk_out.bottom());
}

void SkiaMatrix::MapPoints(float points[], int32_t size) const {
  std::vector<SkPoint> map_points{};

  for (int32_t i = 0; i < size; i++) {
    map_points.emplace_back(SkPoint::Make(points[i * 2], points[i * 2 + 1]));
  }

  skia_matrix_.mapPoints(map_points.data(), size);

  for (auto i = 0; i < size; i++) {
    points[i * 2] = map_points[i].x();
    points[i * 2 + 1] = map_points[i].y();
  }
}

float SkiaMatrix::GetScale() const {
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
