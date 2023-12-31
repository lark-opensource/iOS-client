// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKITY_SKITY_CANVAS_H_
#define ANIMAX_RENDER_SKITY_SKITY_CANVAS_H_

#include "animax/render/include/canvas.h"
#include "animax/render/skity/skity_real_context.h"
#include "skity/skity.hpp"

namespace lynx {
namespace animax {

class SkityCanvas : public Canvas {
 public:
  SkityCanvas(skity::Canvas* canvas, int32_t width, int32_t height,
              skity::RenderContext* context);

  ~SkityCanvas() override = default;

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
  skity::Canvas* canvas_;
  std::unique_ptr<SkityRealContext> real_context_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKITY_SKITY_CANVAS_H_
