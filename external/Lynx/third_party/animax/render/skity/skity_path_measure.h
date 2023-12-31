// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKITY_SKITY_PATH_MEASURE_H_
#define ANIMAX_RENDER_SKITY_SKITY_PATH_MEASURE_H_

#include "animax/render/include/path_measure.h"
#include "skity/skity.hpp"

namespace lynx {
namespace animax {

class SkityPathMeasure : public PathMeasure {
 public:
  SkityPathMeasure() = default;
  ~SkityPathMeasure() override = default;

  void SetPath(Path& path, bool force_close) override;

  bool NextContour() override;

  float GetLength() override;

  void GetPosTan(float distance, PointF* out_pos) override;

  bool GetSegment(float start, float stop, Path& dst,
                  bool start_with_move_to) override;

 private:
  skity::PathMeasure pm_ = {};
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKITY_SKITY_PATH_MEASURE_H_
