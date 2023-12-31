// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_INCLUDE_PATH_H_
#define ANIMAX_RENDER_INCLUDE_PATH_H_

#include <memory>

#include "animax/model/basic_model.h"
#include "animax/render/include/matrix.h"

namespace lynx {
namespace animax {

enum class PathOp : uint8_t {
  kDifference = 0,
  kIntersect,
  kUnion,
  kXor,
  kReverseDifference
};

enum class PathFillType : uint8_t { kWinding = 0, kEvenOdd };

enum class PathDirection : uint8_t {
  kCW = 0,
  kCCW,
};

class Path {
 public:
  virtual ~Path() = default;

  virtual void Set(Path& path) = 0;
  virtual void SetFillType(PathFillType type) = 0;
  virtual void MoveTo(float x, float y) = 0;
  virtual void CubicTo(float x1, float y1, float x2, float y2, float x3,
                       float y3) = 0;
  virtual void LineTo(float x, float y) = 0;
  virtual void Reset() = 0;
  virtual void AddPath(Path& path, Matrix& matrix) = 0;
  virtual void AddPath(Path& path) = 0;
  virtual void ComputeBounds(RectF& out_bounds, bool exact) const = 0;
  virtual void Transform(Matrix& matrix) = 0;
  virtual void Offset(float x, float y) = 0;
  virtual void ArcTo(const RectF& oval, float start_angle, float sweep_angle,
                     bool force_move_to) = 0;
  virtual void Op(Path& path1, Path& path2, PathOp op) = 0;
  virtual void Close() = 0;
  virtual void AddOval(const RectF& oval,
                       PathDirection dir = PathDirection::kCW) = 0;
  virtual bool IsEmpty() const = 0;

  void Set(Path* path) {
    if (!path) {
      return;
    }
    Set(*path);
  }

  void AddPath(Path* path, Matrix& matrix) {
    if (!path) {
      return;
    }
    AddPath(*path, matrix);
  }

  void AddPath(Path* path) {
    if (!path) {
      return;
    }
    AddPath(*path);
  }
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_INCLUDE_PATH_H_
