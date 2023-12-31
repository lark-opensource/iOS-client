// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skity/skity_path.h"

#include "animax/render/skity/skity_matrix.h"
#include "animax/render/skity/skity_util.h"

namespace lynx {
namespace animax {

static skity::PathOp::Op convert_to_skity(PathOp op) {
  switch (op) {
    case PathOp::kDifference:
      return skity::PathOp::Op::kDifference;
    case PathOp::kUnion:
      return skity::PathOp::Op::kUnion;
    case PathOp::kIntersect:
      return skity::PathOp::Op::kIntersect;
    case PathOp::kXor:
      return skity::PathOp::Op::kXor;
    default:
      return skity::PathOp::Op::kDifference;
  }
}

void SkityPath::Set(Path &path) {
  auto skity_path = static_cast<SkityPath *>(&path);

  path_.Reset();
  path_.AddPath(skity_path->path_);
  path_.SetFillType(skity_path->path_.GetFillType());
}

void SkityPath::SetFillType(PathFillType type) {
  if (type == PathFillType::kWinding) {
    path_.SetFillType(skity::Path::PathFillType::kWinding);
  } else {
    path_.SetFillType(skity::Path::PathFillType::kEvenOdd);
  }
}

void SkityPath::MoveTo(float x, float y) { path_.MoveTo(x, y); }

void SkityPath::CubicTo(float x1, float y1, float x2, float y2, float x3,
                        float y3) {
  path_.CubicTo(x1, y1, x2, y2, x3, y3);
}

void SkityPath::LineTo(float x, float y) { path_.LineTo(x, y); }

void SkityPath::Reset() { path_.Reset(); }

void SkityPath::AddPath(Path &path, Matrix &matrix) {
  auto skity_path = static_cast<SkityPath *>(&path);
  auto skity_matrix = static_cast<SkityMatrix *>(&matrix);

  if (path_.IsEmpty()) {
    // FIXME: FillType is changed when first path is added
    path_.SetFillType(skity_path->path_.GetFillType());
  }

  if (skity_matrix->IsIdentity()) {
    path_.AddPath(skity_path->path_);
  } else {
    path_.AddPath(skity_path->path_, skity_matrix->GetMatrix());
  }
}

void SkityPath::AddPath(Path &path) {
  auto skity_path = static_cast<SkityPath *>(&path);
  path_.AddPath(skity_path->path_);
}

void SkityPath::ComputeBounds(RectF &out_bounds, bool exact) const {
  auto rect = path_.GetBounds();

  out_bounds.Set(rect.Left(), rect.Top(), rect.Right(), rect.Bottom());
}

void SkityPath::Transform(Matrix &matrix) {
  auto skity_matrix = static_cast<SkityMatrix *>(&matrix);

  auto skity_path = path_.CopyWithMatrix(skity_matrix->GetMatrix());

  path_ = skity_path;
}

void SkityPath::Offset(float x, float y) {
  auto matrix = skity::Matrix::Translate(x, y);

  auto skity_path = path_.CopyWithMatrix(matrix);

  path_ = skity_path;
}

void SkityPath::ArcTo(const RectF &oval, float start_angle, float sweep_angle,
                      bool force_move_to) {
  auto rect = SkityUtil::MakeSkityRect(oval);

  path_.ArcTo(rect, start_angle, sweep_angle, force_move_to);
}

void SkityPath::Op(Path &path1, Path &path2, PathOp op) {
  path_.Reset();

  auto skity_path1 = static_cast<SkityPath *>(&path1);
  auto skity_path2 = static_cast<SkityPath *>(&path2);

  if (op == PathOp::kReverseDifference) {
    skity::PathOp::Execute(skity_path2->GetPath(), skity_path1->GetPath(),
                           skity::PathOp::Op::kDifference, &path_);
  } else {
    skity::PathOp::Execute(skity_path1->GetPath(), skity_path2->GetPath(),
                           convert_to_skity(op), &path_);
  }
}

void SkityPath::Close() { path_.Close(); }

void SkityPath::AddOval(const RectF &oval, PathDirection dir) {
  auto rect = SkityUtil::MakeSkityRect(oval);

  path_.AddOval(rect, dir == PathDirection::kCW ? skity::Path::Direction::kCW
                                                : skity::Path::Direction::kCCW);
}

bool SkityPath::IsEmpty() const { return path_.IsEmpty(); }

}  // namespace animax
}  // namespace lynx
