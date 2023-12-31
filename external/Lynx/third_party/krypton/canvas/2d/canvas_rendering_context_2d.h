// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_2D_CANVAS_RENDERING_CONTEXT_2D_H_
#define CANVAS_2D_CANVAS_RENDERING_CONTEXT_2D_H_

#include <functional>
#include <memory>
#include <vector>

#include "canvas/2d/text_metrics.h"
#include "canvas/canvas_context.h"
#include "canvas/image_data.h"
#include "jsbridge/napi/exception_state.h"

namespace lynx {
namespace canvas {

class CanvasElement;
class CanvasGradient;
class CanvasPattern;
class DOMMatrix2DInit;
class Path2D;
class DOMMatrix;
class TextMetrics;

using piper::ExceptionState;

class CanvasRenderingContext2D : public CanvasContext {
 public:
  CanvasRenderingContext2D(CanvasElement* element) : CanvasContext(element) {}
  CanvasRenderingContext2D(const CanvasRenderingContext2D&) = delete;
  ~CanvasRenderingContext2D() override = default;

  CanvasRenderingContext2D& operator=(const CanvasRenderingContext2D&) = delete;

  virtual Napi::Value GetStrokeStyle() = 0;
  virtual void SetStrokeStyle(const std::string& color) = 0;
  virtual void SetStrokeStyle(CanvasGradient* gradient) = 0;
  virtual void SetStrokeStyle(CanvasPattern* pattern) = 0;

  virtual Napi::Value GetFillStyle() = 0;
  virtual void SetFillStyle(const std::string& color) = 0;
  virtual void SetFillStyle(CanvasGradient* gradient) = 0;
  virtual void SetFillStyle(CanvasPattern* pattern) = 0;

  virtual double GetLineWidth() const = 0;
  virtual void SetLineWidth(double line_width) = 0;

  virtual std::string GetLineCap() const = 0;
  virtual void SetLineCap(const std::string& cap) = 0;

  virtual std::string GetLineJoin() const = 0;
  virtual void SetLineJoin(const std::string& join) = 0;

  virtual double GetMiterLimit() const = 0;
  virtual void SetMiterLimit(double limit) = 0;

  virtual const std::vector<double>& GetLineDash() const = 0;
  virtual void SetLineDash(std::vector<double> line_dash) = 0;

  virtual double GetLineDashOffset() const = 0;
  virtual void SetLineDashOffset(double offset) = 0;

  virtual double GetShadowOffsetX() const = 0;
  virtual void SetShadowOffsetX(double offset_x) = 0;

  virtual double GetShadowOffsetY() const = 0;
  virtual void SetShadowOffsetY(double offset_y) = 0;

  virtual double GetShadowBlur() const = 0;
  virtual void SetShadowBlur(double blur) = 0;

  virtual std::string GetShadowColor() const = 0;
  virtual void SetShadowColor(const std::string& color) = 0;

  virtual double GetGlobalAlpha() const = 0;
  virtual void SetGlobalAlpha(double alpha) = 0;

  virtual std::string GetGlobalCompositeOperation() const = 0;
  virtual void SetGlobalCompositeOperation(const std::string& operation) = 0;

  virtual void Save() = 0;
  virtual void Restore() = 0;

  virtual void Scale(double sx, double sy) = 0;
  virtual void Rotate(double angle_in_radians) = 0;
  virtual void Translate(double tx, double ty) = 0;
  virtual void Transform(double m11, double m12, double m21, double m22,
                         double dx, double dy) = 0;
  virtual void SetTransform(double m11, double m12, double m21, double m22,
                            double dx, double dy) = 0;
  virtual void SetTransform(
      std::unique_ptr<DOMMatrix2DInit> init = nullptr) = 0;
  virtual std::unique_ptr<DOMMatrix> GetTransform() = 0;
  virtual void ResetTransform() = 0;
  //
  virtual void BeginPath() = 0;
  virtual void Fill(const std::string& winding = "nonzero") = 0;
  //  virtual void Fill(Path2D* path, const std::string& winding = "nonzero") =
  //  0;
  virtual void Stroke() = 0;
  //  virtual void Stroke(Path2D* path) = 0;
  virtual void Clip(const std::string& winding = "nonzero") = 0;
  //  virtual void Clip(Path2D* path, const std::string& winding = "nonzero") =
  //  0;
  //
  virtual bool IsPointInPath(const double x, const double y,
                             const std::string& winding = "nonzero") = 0;
  virtual bool IsPointInPath(Path2D* path, const double x, const double y,
                             const std::string& winding = "nonzero") = 0;
  virtual bool IsPointInStroke(const double x, const double y) = 0;
  virtual bool IsPointInStroke(Path2D* path, const double x,
                               const double y) = 0;

  virtual void ClearRect(double x, double y, double width, double height) = 0;
  virtual void FillRect(double x, double y, double width, double height) = 0;
  virtual void StrokeRect(double x, double y, double width, double height) = 0;

  virtual void DrawImage(ExceptionState& exception_state,
                         CanvasImageSource* source, double x, double y) = 0;
  virtual void DrawImage(ExceptionState& exception_state,
                         CanvasImageSource* source, double x, double y,
                         double width, double height) = 0;
  virtual void DrawImage(ExceptionState& exception_state,
                         CanvasImageSource* source, double sx, double sy,
                         double sw, double sh, double dx, double dy, double dw,
                         double dh) = 0;

  virtual CanvasGradient* CreateLinearGradient(double x0, double y0, double x1,
                                               double y1) = 0;
  virtual CanvasGradient* CreateRadialGradient(ExceptionState& exception_state,
                                               double x0, double y0, double r0,
                                               double x1, double y1,
                                               double r1) = 0;
  //    CanvasGradient* createConicGradient(double startAngle,
  //                                        double centerX,
  //                                        double centerY) = 0;

  virtual CanvasPattern* CreatePattern(ExceptionState& exception_state,
                                       CanvasImageSource* image_source,
                                       const std::string& repetition_type) = 0;

  virtual std::unique_ptr<ImageData> CreateImageData(
      ExceptionState& exception_state, ImageData* image_data) = 0;
  virtual std::unique_ptr<ImageData> CreateImageData(
      ExceptionState& exception_state, int32_t width, int32_t height) = 0;
  // For deferred canvases this will have the side effect of drawing recorded
  // commands in order to finalize the frame
  virtual ImageData* GetImageData(ExceptionState& exception_state, int32_t sx,
                                  int32_t sy, int32_t sw, int32_t sh) = 0;
  virtual void PutImageData(ImageData* image_data, int dx, int dy) = 0;
  virtual void PutImageData(ImageData* image_data, int dx, int dy, int dirty_x,
                            int dirty_y, int dirty_width, int dirty_height) = 0;

  virtual bool GetImageSmoothingEnabled() const = 0;
  virtual void SetImageSmoothingEnabled(bool) = 0;
  virtual std::string GetImageSmoothingQuality() const = 0;
  virtual void SetImageSmoothingQuality(const std::string& quality) = 0;

  //  virtual void RestoreMatrixClipStack() const = 0;

  virtual std::string GetFont() const = 0;
  virtual void SetFont(const std::string& font_str) = 0;

  //  virtual std::string GetDirection() const = 0;
  //  virtual void SetDirection(const std::string& direction) = 0;

  virtual std::string GetTextAlign() const = 0;
  virtual void SetTextAlign(const std::string& text_align) = 0;

  virtual std::string GetTextBaseline() const = 0;
  virtual void SetTextBaseline(const std::string& baseline) = 0;
  //
  virtual void FillText(const std::u16string& text, double x, double y) = 0;
  virtual void FillText(const std::u16string& text, double x, double y,
                        double max_width) = 0;
  virtual void StrokeText(const std::u16string& text, double x, double y) = 0;
  virtual void StrokeText(const std::u16string& text, double x, double y,
                          double max_width) = 0;
  virtual TextMetrics* MeasureText(const std::u16string& text) = 0;

  //    double textLetterSpacing() const = 0;
  //    double textWordSpacing() const = 0;
  //    String textRendering() const = 0;
  //
  //    String fontKerning() const = 0;
  //    String fontStretch() const = 0;
  //    String fontVariantCaps() const = 0;

  // Path2D
  virtual void ClosePath() = 0;
  virtual void MoveTo(double double_x, double double_y) = 0;
  virtual void LineTo(double double_x, double double_y) = 0;
  virtual void QuadraticCurveTo(double double_cpx, double double_cpy,
                                double double_x, double double_y) = 0;
  virtual void BezierCurveTo(double double_cp1x, double double_cp1y,
                             double double_cp2x, double double_cp2y,
                             double double_x, double double_y) = 0;
  virtual void ArcTo(ExceptionState& exception_state, double double_x1,
                     double double_y1, double double_x2, double double_y2,
                     double double_radius) = 0;
  virtual void Arc(ExceptionState& exception_state, double double_x,
                   double double_y, double double_radius,
                   double double_start_angle, double double_end_angle,
                   bool anticlockwise = false) = 0;
  virtual void Ellipse(ExceptionState& exception_state, double double_x,
                       double double_y, double double_radius_x,
                       double double_radius_y, double double_rotation,
                       double double_start_angle, double double_end_angle,
                       bool anticlockwise = false) = 0;
  virtual void Rect(double double_x, double double_y, double double_width,
                    double double_height) = 0;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_2D_CANVAS_RENDERING_CONTEXT_2D_H_
