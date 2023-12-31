// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKIA_SKIA_PATH_MEASURE_H_
#define ANIMAX_RENDER_SKIA_SKIA_PATH_MEASURE_H_

#include "animax/render/include/path_measure.h"
#include "animax/render/skia/skia_util.h"

namespace lynx {
namespace animax {

class SkiaPathMeasure : public PathMeasure {
 public:
  SkiaPathMeasure() = default;
  ~SkiaPathMeasure() override = default;

  void SetPath(Path& path, bool force_close) override;

  bool NextContour() override;

  float GetLength() override;

  void GetPosTan(float distance, PointF* out_pos) override;

  bool GetSegment(float start, float stop, Path& dst,
                  bool start_with_move_to) override;

 private:
  SkPathMeasure skia_pm_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKIA_SKIA_PATH_MEASURE_H_
