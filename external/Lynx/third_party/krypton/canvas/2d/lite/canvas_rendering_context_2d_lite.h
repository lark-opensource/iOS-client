// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_2D_LITE_CANVAS_RENDERING_CONTEXT_2D_LITE_H_
#define CANVAS_2D_LITE_CANVAS_RENDERING_CONTEXT_2D_LITE_H_

#include "canvas/2d/canvas_rendering_context_2d.h"
#include "canvas/2d/lite/canvas_rendering_context_2d_lite_state.h"
#include "canvas/2d/lite/canvas_resource_provider_2d_lite.h"
#include "canvas/text/font_collection.h"

namespace lynx {
namespace canvas {
class CanvasRenderingContext2DLite : public CanvasRenderingContext2D,
                                     public FontCollection::TypefaceObserver {
 public:
  CanvasRenderingContext2DLite(CanvasElement* element);
  ~CanvasRenderingContext2DLite() override;

  Napi::Value GetStrokeStyle() override;
  void SetStrokeStyle(const std::string& color) override;
  void SetStrokeStyle(CanvasGradient* gradient) override;
  void SetStrokeStyle(CanvasPattern* pattern) override;

  Napi::Value GetFillStyle() override;
  void SetFillStyle(const std::string& color) override;
  void SetFillStyle(CanvasGradient* gradient) override;
  void SetFillStyle(CanvasPattern* pattern) override;

  void Fill(const std::string& winding = "nonzero") override;

  void Stroke() override;

  // path
  const std::vector<double>& GetLineDash() const override;

  void SetLineDash(std::vector<double> line_dash) override;

  double GetShadowBlur() const override;
  void SetShadowBlur(double blur) override;
  std::string GetShadowColor() const override;
  void SetShadowColor(const std::string& color) override;
  double GetShadowOffsetX() const override;
  void SetShadowOffsetX(double offset_x) override;
  double GetShadowOffsetY() const override;
  void SetShadowOffsetY(double offset_y) override;

  void BeginPath() override;
  void ClosePath() override;
  void MoveTo(double double_x, double double_y) override;
  void LineTo(double double_x, double double_y) override;
  void QuadraticCurveTo(double double_cpx, double double_cpy, double double_x,
                        double double_y) override;
  void BezierCurveTo(double double_cp1x, double double_cp1y, double double_cp2x,
                     double double_cp2y, double double_x,
                     double double_y) override;
  void ArcTo(ExceptionState& exception_state, double double_x1,
             double double_y1, double double_x2, double double_y2,
             double double_radius) override;
  void Arc(ExceptionState& exception_state, double double_x, double double_y,
           double double_radius, double double_start_angle,
           double double_end_angle, bool anticlockwise = false) override;
  void Ellipse(ExceptionState& exception_state, double double_x,
               double double_y, double double_radius_x, double double_radius_y,
               double double_rotation, double double_start_angle,
               double double_end_angle, bool anticlockwise = false) override;
  void Rect(double double_x, double double_y, double double_width,
            double double_height) override;

  double GetLineWidth() const override;

  void SetLineWidth(double line_width) override;

  string GetLineCap() const override;

  void SetLineCap(const string& cap) override;

  double GetMiterLimit() const override;

  void SetMiterLimit(double limit) override;

  double GetLineDashOffset() const override;
  void SetLineDashOffset(double offset) override;

  std::string GetLineJoin() const override;

  void SetLineJoin(const std::string& join) override;

  bool IsPointInPath(const double x, const double y,
                     const string& winding) override;

  bool IsPointInPath(Path2D* path, const double x, const double y,
                     const string& winding) override;

  bool IsPointInStroke(const double x, const double y) override;

  bool IsPointInStroke(Path2D* path, const double x, const double y) override;

  void DrawImage(ExceptionState& exception_state, CanvasImageSource* source,
                 double x, double y) override;
  void DrawImage(ExceptionState& exception_state, CanvasImageSource* source,
                 double x, double y, double width, double height) override;
  void DrawImage(ExceptionState& exception_state, CanvasImageSource* source,
                 double sx, double sy, double sw, double sh, double dx,
                 double dy, double dw, double dh) override;

  CanvasGradient* CreateLinearGradient(double x0, double y0, double x1,
                                       double y1) override;
  CanvasGradient* CreateRadialGradient(ExceptionState& exception_state,
                                       double x0, double y0, double r0,
                                       double x1, double y1,
                                       double r1) override;

  CanvasPattern* CreatePattern(ExceptionState& exception_state,
                               CanvasImageSource* image_source,
                               const std::string& repetition_type) override;

  std::unique_ptr<ImageData> CreateImageData(ExceptionState& exception_state,
                                             ImageData* image_data) override;
  std::unique_ptr<ImageData> CreateImageData(ExceptionState& exception_state,
                                             int32_t width,
                                             int32_t height) override;
  ImageData* GetImageData(ExceptionState& exception_state, int32_t sx,
                          int32_t sy, int32_t sw, int32_t sh) override;
  void PutImageData(ImageData* image_data, int dx, int dy) override;
  void PutImageData(ImageData* image_data, int dx, int dy, int dirty_x,
                    int dirty_y, int dirty_width, int dirty_height) override;

  void FillText(const std::u16string& text, double x, double y) override;
  void FillText(const std::u16string& text, double x, double y,
                double max_width) override;
  void StrokeText(const std::u16string& text, double x, double y) override;
  void StrokeText(const std::u16string& text, double x, double y,
                  double max_width) override;
  TextMetrics* MeasureText(const std::u16string& text) override;

  void Clip(const string& winding) override;

  void Scale(double sx, double sy) override;

  void Rotate(double angle_in_radians) override;

  void Translate(double tx, double ty) override;

  void Transform(double m11, double m12, double m21, double m22, double dx,
                 double dy) override;

  void SetTransform(double m11, double m12, double m21, double m22, double dx,
                    double dy) override;

  void SetTransform(std::unique_ptr<DOMMatrix2DInit> init) override;

  std::unique_ptr<DOMMatrix> GetTransform() override;

  void ResetTransform() override;
  std::string GetFont() const override;
  void SetFont(const std::string& font_str) override;

  std::string GetTextAlign() const override;
  void SetTextAlign(const std::string& text_align) override;

  std::string GetTextBaseline() const override;
  void SetTextBaseline(const std::string& baseline) override;

  void ClearRect(double x, double y, double width, double height) override;
  void FillRect(double x, double y, double width, double height) override;
  void StrokeRect(double x, double y, double width, double height) override;

  void Save() override;
  void Restore() override;

  bool GetImageSmoothingEnabled() const override;
  void SetImageSmoothingEnabled(bool) override;
  std::string GetImageSmoothingQuality() const override;
  void SetImageSmoothingQuality(const std::string& quality) override;

  double GetGlobalAlpha() const override;
  void SetGlobalAlpha(double alpha) override;

  std::string GetGlobalCompositeOperation() const override;
  void SetGlobalCompositeOperation(const std::string& operation) override;

  void Reset();

  void OnTypeFaceAdded(Typeface* typeface) override;

 private:
  class ScopedTypefaceObserver {
   public:
    ScopedTypefaceObserver(FontCollection* font_collection,
                           FontCollection::TypefaceObserver* observer)
        : font_collection_(font_collection), observer_((observer)) {
      font_collection_->AddTypefaceObserver(observer_);
    }

    ~ScopedTypefaceObserver() {
      font_collection_->RemoveTypefaceObserver(observer_);
    }

   private:
    FontCollection* font_collection_;
    FontCollection::TypefaceObserver* observer_;
  };
  enum PaintType { kStrokePaintType, kFillPaintType };

  nanovg::NVGcontext* Context() const {
    DCHECK(nvg_context_);
    return nvg_context_;
  }

  CanvasRenderingContext2DLiteState& ExtraState() const {
    return state_vector_.back();
  }

  std::shared_ptr<CanvasResourceProvider2DLite> ResourceProvider() const {
    return std::static_pointer_cast<CanvasResourceProvider2DLite>(
        element_->ResourceProvider());
  }

  void DrawTextInternal(const std::u16string& text, double x, double y,
                        PaintType paint_type,
                        const double* max_width = nullptr);

  void UnwindStateStack();
  void DidDraw() const;
  void Draw(std::function<void(nanovg::NVGcontext*)> proc) const {
    proc(Context());
    DidDraw();
  }

  CanvasRenderingContext2DLiteState& GetState() { return state_vector_.back(); }

  std::string intToHexString(int i) {
    std::stringstream sstream;
    sstream << std::hex << i;
    std::string result = sstream.str();
    return result;
  }

  void DrawImageInternal(int image, double sx, double sy, double sw, double sh,
                         double dx, double dy, double dw, double dh);

  nanovg::NVGcontext* nvg_context_;
  mutable std::vector<CanvasRenderingContext2DLiteState> state_vector_;
  std::vector<double> line_dash_;
  CSSFontParser font_parser_;
  std::unique_ptr<ScopedTypefaceObserver> scoped_typeface_observer_;
  bool enable_image_smoothing_{false};
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_2D_LITE_CANVAS_RENDERING_CONTEXT_2D_LITE_H_
