// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKIA_SKIA_CANVAS_H_
#define ANIMAX_RENDER_SKIA_SKIA_CANVAS_H_

#include "animax/render/include/canvas.h"
#include "animax/render/skia/skia_real_context.h"
#include "animax/render/skia/skia_util.h"

namespace lynx {
namespace animax {

class SkiaCanvas : public Canvas {
 public:
  SkiaCanvas(SkCanvas* canvas, int32_t width, int32_t height);

  ~SkiaCanvas() override = default;

  void SaveLayer(const RectF& rect, Paint& paint) override;

  void DrawPath(Path& path, Paint& paint) override;

  void DrawImageRect(Image& image, const RectF& src, const RectF& dst,
                     Paint& paint) override;

  void DrawRect(const RectF& rect, Paint& paint) override;

  void DrawText(const std::string& text, float x, float y, Font& font,
                Paint& paint) override;

  void Save() override;

  void ResetMatrix() override;

  void Concat(Matrix& matrix) override;

  void Restore() override;

  bool ClipRect(const RectF& rect) override;

  void Scale(float x, float y) override;

  void Translate(float x, float y) override;

  std::unique_ptr<Matrix> GetMatrix() const override;

  RealContext* GetRealContext() const override;

 private:
  SkCanvas* skia_canvas_;
  std::unique_ptr<SkiaRealContext> real_context_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKIA_SKIA_CANVAS_H_
