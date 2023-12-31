// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_INCLUDE_CANVAS_H_
#define ANIMAX_RENDER_INCLUDE_CANVAS_H_

#include <memory>

#include "animax/base/performance_record.h"
#include "animax/render/include/font.h"
#include "animax/render/include/image.h"
#include "animax/render/include/matrix.h"
#include "animax/render/include/paint.h"
#include "animax/render/include/path.h"

namespace lynx {
namespace animax {
class RealContext;
class Canvas {
 public:
  Canvas(int32_t width, int32_t height) : width_(width), height_(height) {}
  virtual ~Canvas() = default;

  virtual void SaveLayer(const RectF& rect, Paint& paint) = 0;
  virtual void DrawPath(Path& path, Paint& paint) = 0;
  virtual void DrawImageRect(Image& image, const RectF& src, const RectF& dst,
                             Paint& paint) = 0;
  virtual void DrawRect(const RectF& rect, Paint& paint) = 0;
  virtual void DrawText(const std::string& text, float x, float y, Font& font,
                        Paint& paint) = 0;
  virtual void Save() = 0;
  virtual void ResetMatrix() = 0;
  virtual void Concat(Matrix& matrix) = 0;
  virtual void Restore() = 0;
  virtual bool ClipRect(const RectF& rect) = 0;
  virtual void Scale(float x, float y) = 0;
  virtual void Translate(float x, float y) = 0;
  virtual std::unique_ptr<Matrix> GetMatrix() const = 0;
  virtual RealContext* GetRealContext() const = 0;

  void DrawRect(float left, float top, float right, float bottom,
                Paint& paint) {
    RectF rect{left, top, right, bottom};
    this->DrawRect(rect, paint);
  }

  int32_t GetWidth() const { return width_; }
  int32_t GetHeight() const { return height_; }

 private:
  int32_t width_ = 0;
  int32_t height_ = 0;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_INCLUDE_CANVAS_H_
