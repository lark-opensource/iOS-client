// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_INCLUDE_PATH_MEASURE_H_
#define ANIMAX_RENDER_INCLUDE_PATH_MEASURE_H_

#include <memory>

#include "animax/render/include/path.h"

namespace lynx {
namespace animax {

class PathMeasure {
 public:
  virtual ~PathMeasure() = default;

  virtual void SetPath(Path& path, bool force_close) = 0;
  virtual bool NextContour() = 0;

  virtual float GetLength() = 0;
  virtual void GetPosTan(float distance, PointF* out_pos) = 0;
  virtual bool GetSegment(float start, float stop, Path& dst,
                          bool start_with_move_to) = 0;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_INCLUDE_PATH_MEASURE_H_
