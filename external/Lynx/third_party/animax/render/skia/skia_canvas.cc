// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skia/skia_canvas.h"

#include <memory>

#include "animax/render/skia/skia_font.h"
#include "animax/render/skia/skia_image.h"
#include "animax/render/skia/skia_matrix.h"
#include "animax/render/skia/skia_paint.h"
#include "animax/render/skia/skia_path.h"
#include "animax/render/skia/skia_util.h"
#include "third_party/skia_includes/include/core/SkSamplingOptions.h"

namespace lynx {
namespace animax {

SkiaCanvas::SkiaCanvas(SkCanvas *canvas, int32_t width, int32_t height)
    : Canvas(width, height), skia_canvas_(std::move(canvas)) {
  GrRecordingContext *recording_context = skia_canvas_->recordingContext();
  GrDirectContext *direct_context =
      recording_context ? recording_context->asDirectContext() : nullptr;
  if (direct_context) {
    real_context_ = std::make_unique<SkiaRealContext>(direct_context);
  }
}

void SkiaCanvas::SaveLayer(const RectF &rect, Paint &paint) {
  auto sk_paint = static_cast<SkiaPaint *>(&paint);

  skia_canvas_->saveLayer(SkRect::MakeLTRB(rect.GetLeft(), rect.GetTop(),
                                           rect.GetRight(), rect.GetBottom()),
                          &sk_paint->GetSkPaint());
}

void SkiaCanvas::DrawPath(Path &path, Paint &paint) {
  auto sk_path = static_cast<SkiaPath *>(&path);
  auto sk_paint = static_cast<SkiaPaint *>(&paint);
  skia_canvas_->drawPath(sk_path->GetSkPath(), sk_paint->GetSkPaint());
}

void SkiaCanvas::DrawImageRect(Image &image, const RectF &src, const RectF &dst,
                               Paint &paint) {
  auto sk_image = static_cast<SkiaImage *>(&image);
  auto sk_paint = static_cast<SkiaPaint *>(&paint);

  skia_canvas_->drawImageRect(
      sk_image->GetSkImage(), MakeRect(src), MakeRect(dst), SkSamplingOptions(),
      &sk_paint->GetSkPaint(),
      SkCanvas::SrcRectConstraint::kStrict_SrcRectConstraint);
}

void SkiaCanvas::DrawRect(const RectF &rect, Paint &paint) {
  auto sk_paint = static_cast<SkiaPaint *>(&paint);
  skia_canvas_->drawRect(MakeRect(rect), sk_paint->GetSkPaint());
}

void SkiaCanvas::DrawText(const std::string &text, float x, float y, Font &font,
                          Paint &paint) {
  auto sk_paint = static_cast<SkiaPaint *>(&paint);
  auto sk_font = static_cast<SkiaFont *>(&font);
  skia_canvas_->drawString(SkString(text), x, y, sk_font->GetSkFont(),
                           sk_paint->GetSkPaint());
}

void SkiaCanvas::Save() { skia_canvas_->save(); }

void SkiaCanvas::ResetMatrix() { skia_canvas_->resetMatrix(); }

void SkiaCanvas::Concat(Matrix &matrix) {
  auto sk_matrix = static_cast<SkiaMatrix *>(&matrix);
  skia_canvas_->concat(sk_matrix->GetSkMatrix());
}

void SkiaCanvas::Restore() { skia_canvas_->restore(); }

bool SkiaCanvas::ClipRect(const RectF &rect) {
  skia_canvas_->clipRect(MakeRect(rect));
  return true;
}

void SkiaCanvas::Scale(float x, float y) { skia_canvas_->scale(x, y); }

void SkiaCanvas::Translate(float x, float y) { skia_canvas_->translate(x, y); }

std::unique_ptr<Matrix> SkiaCanvas::GetMatrix() const {
  auto sk_matrix = skia_canvas_->getTotalMatrix();

  return std::make_unique<SkiaMatrix>(sk_matrix);
}

RealContext *SkiaCanvas::GetRealContext() const {
  return real_context_ ? real_context_.get() : nullptr;
}

}  // namespace animax
}  // namespace lynx
