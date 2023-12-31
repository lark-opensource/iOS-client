// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skia/skia_path_measure.h"

#include "animax/render/skia/skia_path.h"

namespace lynx {
namespace animax {

void SkiaPathMeasure::SetPath(Path& path, bool force_close) {
  auto sk_path = static_cast<SkiaPath*>(&path);

  skia_pm_.setPath(&sk_path->GetSkPath(), force_close);
}

float SkiaPathMeasure::GetLength() { return skia_pm_.getLength(); }

void SkiaPathMeasure::GetPosTan(float distance, PointF* out_pos) {
  SkPoint out{};

  skia_pm_.getPosTan(distance, &out, nullptr);

  out_pos->Set(out.x(), out.y());
}

bool SkiaPathMeasure::NextContour() { return skia_pm_.nextContour(); }

bool SkiaPathMeasure::GetSegment(float start, float stop, Path& dst,
                                 bool start_with_move_to) {
  auto sk_path = static_cast<SkiaPath*>(&dst);
  return skia_pm_.getSegment(start, stop, &sk_path->GetSkPath(),
                             start_with_move_to);
}

}  // namespace animax
}  // namespace lynx
