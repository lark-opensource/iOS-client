// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skity/skity_path_measure.h"

#include "animax/render/skity/skity_path.h"

namespace lynx {
namespace animax {

void SkityPathMeasure::SetPath(Path& path, bool force_close) {
  auto skity_path = static_cast<SkityPath*>(&path);

  pm_.SetPath(&skity_path->GetPath(), force_close);
}

bool SkityPathMeasure::NextContour() { return pm_.NextContour(); }

float SkityPathMeasure::GetLength() { return pm_.GetLength(); }

void SkityPathMeasure::GetPosTan(float distance, PointF* out_pos) {
  skity::Point pos{};

  pm_.GetPosTan(distance, &pos, nullptr);

  out_pos->Set(pos.x, pos.y);
}

bool SkityPathMeasure::GetSegment(float start, float stop, Path& dst,
                                  bool start_with_move_to) {
  auto skity_path = static_cast<SkityPath*>(&dst);

  return pm_.GetSegment(start, stop, &skity_path->GetPath(),
                        start_with_move_to);
}

}  // namespace animax
}  // namespace lynx
