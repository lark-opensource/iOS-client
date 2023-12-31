// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_INCLUDE_CONTEXT_H_
#define ANIMAX_RENDER_INCLUDE_CONTEXT_H_

#include <memory>

#include "animax/model/basic_model.h"
#include "canvas/bitmap.h"

namespace lynx {
namespace animax {

class Path;
class Matrix;
class Paint;
class Shader;
enum class ShaderTileMode : uint8_t;
class MaskFilter;
class PathMeasure;
class Image;
class Font;
class DashPathEffect;
class Canvas;
class Surface;
class RealContext;
class AnimaXOnScreenSurface;

class Context final {
 public:
  Context() = delete;
  ~Context() = delete;

  static std::unique_ptr<Path> MakePath();
  static std::unique_ptr<Matrix> MakeMatrix();
  static std::unique_ptr<Paint> MakePaint();
  static std::unique_ptr<MaskFilter> MakeBlurFilter(float radius);
  static std::shared_ptr<PathMeasure> MakePathMeasure();
  static std::unique_ptr<Shader> MakeLinear(PointF const& sp, PointF const& ep,
                                            int32_t size, int32_t* colors,
                                            float* positions,
                                            ShaderTileMode mode,
                                            Matrix& matrix);
  static std::unique_ptr<Shader> MakeRadial(PointF const& sp, float r,
                                            int32_t size, int32_t* colors,
                                            float* positions,
                                            ShaderTileMode mode,
                                            Matrix& matrix);
  static std::shared_ptr<Image> MakeImage(canvas::Bitmap& bitmap,
                                          RealContext* real_context);
  static std::shared_ptr<Font> MakeFont(const void* bytes, size_t len);
  static std::shared_ptr<Font> MakeDefaultFont();
  static std::shared_ptr<DashPathEffect> MakeDashPathEffect(const float* values,
                                                            size_t size,
                                                            float offset);
  static std::unique_ptr<Surface> MakeSurface(AnimaXOnScreenSurface* surface,
                                              int32_t width, int32_t height);
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_INCLUDE_CONTEXT_H_
