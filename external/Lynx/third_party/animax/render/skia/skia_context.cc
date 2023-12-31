// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/include/context.h"
#include "animax/render/skia/skia_font.h"
#include "animax/render/skia/skia_image.h"
#include "animax/render/skia/skia_mask_filter.h"
#include "animax/render/skia/skia_matrix.h"
#include "animax/render/skia/skia_paint.h"
#include "animax/render/skia/skia_path.h"
#include "animax/render/skia/skia_path_effect.h"
#include "animax/render/skia/skia_path_measure.h"
#include "animax/render/skia/skia_shader.h"
#include "animax/render/skia/skia_surface.h"

namespace lynx {
namespace animax {

std::unique_ptr<Path> Context::MakePath() {
  return std::make_unique<SkiaPath>();
}

std::unique_ptr<Matrix> Context::MakeMatrix() {
  return std::make_unique<SkiaMatrix>();
}

std::unique_ptr<Paint> Context::MakePaint() {
  return std::make_unique<SkiaPaint>();
}

std::unique_ptr<MaskFilter> Context::MakeBlurFilter(float radius) {
  return SkiaMaskFilter::MakeSkiaBlur(radius);
}

std::shared_ptr<PathMeasure> Context::MakePathMeasure() {
  return std::make_shared<SkiaPathMeasure>();
}

std::unique_ptr<Shader> Context::MakeLinear(const PointF &sp, const PointF &ep,
                                            int32_t size, int32_t *colors,
                                            float *pos, ShaderTileMode mode,
                                            Matrix &matrix) {
  return SkiaShader::MakeSkiaLinear(sp, ep, size, colors, pos, mode, matrix);
}

std::unique_ptr<Shader> Context::MakeRadial(const PointF &sp, float r,
                                            int32_t size, int32_t *colors,
                                            float *pos, ShaderTileMode mode,
                                            Matrix &matrix) {
  return SkiaShader::MakeSkiaRadial(sp, r, size, colors, pos, mode, matrix);
}

std::shared_ptr<Image> Context::MakeImage(canvas::Bitmap &bitmap,
                                          RealContext *real_context) {
  return SkiaImage::MakeSkiaImage(bitmap, real_context);
}

std::shared_ptr<Font> Context::MakeFont(const void *bytes, size_t len) {
  return SkiaFont::MakeSkiaFont(bytes, len);
}

std::shared_ptr<Font> Context::MakeDefaultFont() {
  return SkiaFont::MakeSkiaDefaultFont();
}

std::shared_ptr<DashPathEffect> Context::MakeDashPathEffect(const float *values,
                                                            size_t size,
                                                            float offset) {
  return SkiaDashPathEffect::Make(values, size, offset);
}

std::unique_ptr<Surface> Context::MakeSurface(AnimaXOnScreenSurface *surface,
                                              int32_t width, int32_t height) {
  return std::make_unique<SkiaSurface>(surface, width, height);
}

}  // namespace animax
}  // namespace lynx
