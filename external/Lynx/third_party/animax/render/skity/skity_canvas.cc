// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skity/skity_canvas.h"

#include "animax/render/skity/skity_font.h"
#include "animax/render/skity/skity_image.h"
#include "animax/render/skity/skity_mask_filter.h"
#include "animax/render/skity/skity_matrix.h"
#include "animax/render/skity/skity_paint.h"
#include "animax/render/skity/skity_path.h"
#include "animax/render/skity/skity_util.h"

namespace lynx {
namespace animax {

SkityCanvas::SkityCanvas(skity::Canvas *canvas, int32_t width, int32_t height,
                         skity::RenderContext *context)
    : Canvas(width, height), canvas_(canvas) {
  if (context) {
    real_context_ = std::make_unique<SkityRealContext>(context);
  }
}

void SkityCanvas::SaveLayer(const RectF &rect, Paint &paint) {
  auto skity_paint = static_cast<SkityPaint *>(&paint);

  skity_paint->SetAntiAlias(true);
  canvas_->SaveLayer(SkityUtil::MakeSkityRect(rect), skity_paint->GetPaint());
}

void SkityCanvas::DrawPath(Path &path, Paint &paint) {
  auto skity_paint = static_cast<SkityPaint *>(&paint);
  auto skity_path = static_cast<SkityPath *>(&path);

  auto &shadow_layer = skity_paint->GetShadowLayer();

  if (shadow_layer) {
    skity::Paint wp{skity_paint->GetPaint()};
    // clear gradient
    wp.SetShader(nullptr);

    wp.SetMaskFilter(skity::MaskFilter::MakeBlur(skity::BlurStyle::kNormal,
                                                 shadow_layer->radius));
    Color color(shadow_layer->color);
    wp.SetColor(skity::ColorSetARGB(color.GetA(), color.GetR(), color.GetG(),
                                    color.GetB()));
    canvas_->Save();
    canvas_->Translate(shadow_layer->off_x, shadow_layer->off_y);
    canvas_->DrawPath(skity_path->GetPath(), wp);
    canvas_->Restore();
  }

  canvas_->DrawPath(skity_path->GetPath(), skity_paint->GetPaint());
}

void SkityCanvas::DrawImageRect(Image &image, const RectF &src,
                                const RectF &dst, Paint &paint) {
  auto skity_image = static_cast<SkityImage *>(&image);
  auto skity_paint = static_cast<SkityPaint *>(&paint);

  canvas_->DrawImage(skity_image->GetImage(), SkityUtil::MakeSkityRect(dst),
                     skity_paint ? &skity_paint->GetPaint() : nullptr);
}

void SkityCanvas::DrawRect(const RectF &rect, Paint &paint) {
  auto skity_paint = static_cast<SkityPaint *>(&paint);

  auto &shadow_layer = skity_paint->GetShadowLayer();

  auto skity_rect = SkityUtil::MakeSkityRect(rect);

  if (shadow_layer) {
    skity::Paint wp{skity_paint->GetPaint()};

    wp.SetMaskFilter(skity::MaskFilter::MakeBlur(skity::BlurStyle::kNormal,
                                                 shadow_layer->radius));

    Color color(shadow_layer->color);
    wp.SetColor(skity::ColorSetARGB(color.GetA(), color.GetR(), color.GetG(),
                                    color.GetB()));
    canvas_->Save();
    canvas_->Translate(shadow_layer->off_x, shadow_layer->off_y);
    canvas_->DrawRect(skity_rect, wp);
    canvas_->Restore();
  }

  canvas_->DrawRect(skity_rect, skity_paint->GetPaint());
}

void SkityCanvas::DrawText(const std::string &text, float x, float y,
                           Font &font, Paint &paint) {
  auto skity_paint = static_cast<SkityPaint *>(&paint)->GetPaint();
  auto skity_font = static_cast<SkityFont *>(&font)->GetFont();

  FallbackTypefaceDelegate delegate{};

  skity::TextBlobBuilder builder;

  skity_paint.SetTextSize(skity_font.GetSize());
  skity_paint.SetTypeface(skity_font.GetTypeface());

  auto blob = builder.BuildTextBlob(text.c_str(), skity_paint, &delegate);

  canvas_->DrawTextBlob(blob, x, y, skity_paint);
}

void SkityCanvas::Save() { canvas_->Save(); }

void SkityCanvas::ResetMatrix() { canvas_->ResetMatrix(); }

void SkityCanvas::Concat(Matrix &matrix) {
  auto skity_matrix = static_cast<SkityMatrix *>(&matrix);

  canvas_->Concat(skity_matrix->GetMatrix());
}

void SkityCanvas::Restore() { canvas_->Restore(); }

bool SkityCanvas::ClipRect(const RectF &rect) {
  // some clip may cause content not rendered
  // and most animax content does not need to be clip
  canvas_->ClipRect(SkityUtil::MakeSkityRect(rect));
  return true;
}

void SkityCanvas::Scale(float x, float y) { canvas_->Scale(x, y); }

void SkityCanvas::Translate(float x, float y) { canvas_->Translate(x, y); }

std::unique_ptr<Matrix> SkityCanvas::GetMatrix() const {
  return std::make_unique<SkityMatrix>(canvas_->GetTotalMatrix());
}

RealContext *SkityCanvas::GetRealContext() const {
  return real_context_ ? real_context_.get() : nullptr;
}

}  // namespace animax
}  // namespace lynx
