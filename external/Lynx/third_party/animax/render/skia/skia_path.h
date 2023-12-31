// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKIA_SKIA_PATH_H_
#define ANIMAX_RENDER_SKIA_SKIA_PATH_H_

#include "animax/render/include/path.h"
#include "animax/render/skia/skia_util.h"

namespace lynx {
namespace animax {

class SkiaPath : public Path {
 public:
  SkiaPath() = default;
  explicit SkiaPath(SkPath const& sp) : skia_path_(sp) {}

  ~SkiaPath() override = default;

  void Set(Path& path) override;
  void SetFillType(PathFillType type) override;
  void MoveTo(float x, float y) override;
  void CubicTo(float x1, float y1, float x2, float y2, float x3,
               float y3) override;
  void LineTo(float x, float y) override;
  void Reset() override;
  void AddPath(Path& path, Matrix& matrix) override;
  void AddPath(Path& path) override;
  void ComputeBounds(RectF& out_bounds, bool exact) const override;
  void Transform(Matrix& matrix) override;
  void Offset(float x, float y) override;
  void ArcTo(const RectF& oval, float start_angle, float sweep_angle,
             bool force_move_to) override;
  void Op(Path& path1, Path& path2, PathOp op) override;
  void Close() override;
  void AddOval(const RectF& oval,
               PathDirection dir = PathDirection::kCW) override;

  bool IsEmpty() const override;

  SkPath const& GetSkPath() const { return skia_path_; }
  SkPath& GetSkPath() { return skia_path_; }

 private:
  SkPath skia_path_ = {};
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKIA_SKIA_PATH_H_
