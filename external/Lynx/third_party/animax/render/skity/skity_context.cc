// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/include/context.h"
#include "animax/render/skity/skity_font.h"
#include "animax/render/skity/skity_image.h"
#include "animax/render/skity/skity_mask_filter.h"
#include "animax/render/skity/skity_matrix.h"
#include "animax/render/skity/skity_paint.h"
#include "animax/render/skity/skity_path.h"
#include "animax/render/skity/skity_path_effect.h"
#include "animax/render/skity/skity_path_measure.h"
#include "animax/render/skity/skity_shader.h"
#include "animax/render/skity/skity_surface.h"

namespace lynx {
namespace animax {

std::unique_ptr<Path> Context::MakePath() {
  return std::make_unique<SkityPath>();
}

std::unique_ptr<Matrix> Context::MakeMatrix() {
  return std::make_unique<SkityMatrix>();
}

std::unique_ptr<Paint> Context::MakePaint() {
  return std::make_unique<SkityPaint>();
}

std::unique_ptr<MaskFilter> Context::MakeBlurFilter(float radius) {
  return SkityMaskFilter::MakeBlur(radius);
}

std::shared_ptr<PathMeasure> Context::MakePathMeasure() {
  return std::make_shared<SkityPathMeasure>();
}

std::unique_ptr<Shader> Context::MakeLinear(const PointF &sp, const PointF &ep,
                                            int32_t size, int32_t *colors,
                                            float *pos, ShaderTileMode mode,
                                            Matrix &matrix) {
  return SkityShader::MakeLinear(sp, ep, size, colors, pos, mode, matrix);
}

std::unique_ptr<Shader> Context::MakeRadial(const PointF &sp, float r,
                                            int32_t size, int32_t *colors,
                                            float *pos, ShaderTileMode mode,
                                            Matrix &matrix) {
  return SkityShader::MakeRadial(sp, r, size, colors, pos, mode, matrix);
}

std::shared_ptr<Image> Context::MakeImage(canvas::Bitmap &bitmap,
                                          RealContext *real_context) {
  return SkityImage::MakeImage(bitmap, real_context);
}

std::shared_ptr<Font> Context::MakeFont(const void *bytes, size_t len) {
  return SkityFont::MakeFont(bytes, len);
}

std::shared_ptr<Font> Context::MakeDefaultFont() {
  return SkityFont::MakeDefaultFont();
}

std::shared_ptr<DashPathEffect> Context::MakeDashPathEffect(const float *values,
                                                            size_t size,
                                                            float offset) {
  return SkityDashPathEffect::Make(values, size, offset);
}

std::unique_ptr<Surface> Context::MakeSurface(AnimaXOnScreenSurface *surface,
                                              int32_t width, int32_t height) {
  return std::make_unique<SkitySurface>(surface, width, height);
}

}  // namespace animax
}  // namespace lynx
