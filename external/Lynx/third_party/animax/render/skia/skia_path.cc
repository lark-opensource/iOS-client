// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skia/skia_path.h"

#include "animax/render/skia/skia_matrix.h"
#include "animax/render/skia/skia_util.h"

namespace lynx {
namespace animax {

void SkiaPath::Set(Path &path) {
  auto sk_path = static_cast<SkiaPath *>(&path);

  skia_path_.reset();
  skia_path_.addPath(sk_path->skia_path_);
  skia_path_.setFillType(sk_path->skia_path_.getFillType());
}

void SkiaPath::MoveTo(float x, float y) { skia_path_.moveTo(x, y); }

void SkiaPath::CubicTo(float x1, float y1, float x2, float y2, float x3,
                       float y3) {
  skia_path_.cubicTo(x1, y1, x2, y2, x3, y3);
}

void SkiaPath::LineTo(float x, float y) { skia_path_.lineTo(x, y); }

void SkiaPath::Reset() { skia_path_.reset(); }

void SkiaPath::Offset(float x, float y) { skia_path_.offset(x, y); }

void SkiaPath::ArcTo(const RectF &oval, float start_angle, float sweep_angle,
                     bool force_move_to) {
  skia_path_.arcTo(SkRect::MakeLTRB(oval.GetLeft(), oval.GetTop(),
                                    oval.GetRight(), oval.GetBottom()),
                   start_angle, sweep_angle, force_move_to);
}

void SkiaPath::AddPath(Path &path, Matrix &matrix) {
  auto sk_matrix = static_cast<SkiaMatrix *>(&matrix);
  auto sk_path = static_cast<SkiaPath *>(&path);

  if (skia_path_.isEmpty()) {
    // FIXME: FillType is changed when first path is added
    skia_path_.setFillType(sk_path->skia_path_.getFillType());
  }
  skia_path_.addPath(sk_path->skia_path_, sk_matrix->GetSkMatrix());
}

void SkiaPath::AddPath(Path &path) {
  auto sk_path = static_cast<SkiaPath *>(&path);

  skia_path_.addPath(sk_path->skia_path_);
}

void SkiaPath::SetFillType(PathFillType type) {
  auto sk_type = type == PathFillType::kEvenOdd ? SkPathFillType::kEvenOdd
                                                : SkPathFillType::kWinding;
  skia_path_.setFillType(sk_type);
}

void SkiaPath::ComputeBounds(RectF &out_bounds, bool exact) const {
  auto bounds = skia_path_.computeTightBounds();
  out_bounds.Set(bounds.left(), bounds.top(), bounds.right(), bounds.bottom());
}

void SkiaPath::Close() { skia_path_.close(); }

void SkiaPath::AddOval(const RectF &oval, PathDirection dir) {
  skia_path_.addOval(
      SkRect::MakeXYWH(oval.GetLeft(), oval.GetTop(), oval.GetWidth(),
                       oval.GetHeight()),
      dir == PathDirection::kCW ? SkPathDirection::kCW : SkPathDirection::kCCW);
}

bool SkiaPath::IsEmpty() const { return skia_path_.isEmpty(); }

void SkiaPath::Transform(Matrix &matrix) {
  auto sk_matrix = static_cast<SkiaMatrix *>(&matrix);
  skia_path_.transform(sk_matrix->GetSkMatrix());
}

void SkiaPath::Op(Path &path1, Path &path2, PathOp op) {
  skia_path_.reset();

  auto skia_path1 = static_cast<SkiaPath *>(&path1);
  auto skia_path2 = static_cast<SkiaPath *>(&path2);

  // TODO(aiyongbiao): fix this on skia
  SkPathOp sk_path_op;
  if (op == PathOp::kDifference) {
    sk_path_op = SkPathOp::kDifference_SkPathOp;
  } else if (op == PathOp::kIntersect) {
    sk_path_op = SkPathOp::kIntersect_SkPathOp;
  } else if (op == PathOp::kReverseDifference) {
    sk_path_op = SkPathOp::kReverseDifference_SkPathOp;
  } else if (op == PathOp::kUnion) {
    sk_path_op = SkPathOp::kUnion_SkPathOp;
  } else if (op == PathOp::kXor) {
    sk_path_op = SkPathOp::kXOR_SkPathOp;
  } else {
    sk_path_op = SkPathOp::kUnion_SkPathOp;
  }

  ::Op(skia_path1->GetSkPath(), skia_path2->GetSkPath(), sk_path_op,
       &skia_path_);
}

}  // namespace animax
}  // namespace lynx
