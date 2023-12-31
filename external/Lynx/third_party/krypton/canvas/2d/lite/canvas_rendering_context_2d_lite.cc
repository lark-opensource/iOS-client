// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/2d/lite/canvas_rendering_context_2d_lite.h"

#include <codecvt>
#include <memory>

#include "canvas/2d/dom_matrix.h"
#include "canvas/2d/lite/canvas_gradient_lite.h"
#include "canvas/2d/lite/canvas_pattern_lite.h"
#include "canvas/2d/lite/nanovg/include/fontstash.h"
#include "canvas/2d/lite/nanovg/include/nanovg_gl.h"
#include "canvas/base/log.h"
#include "canvas/gpu/gl/scoped_gl_reset_restore.h"
#include "canvas/image_data.h"
#include "canvas/image_element.h"
#include "canvas/text/font_collection.h"
#include "canvas/text/typeface.h"
#include "canvas/util/math_utils.h"
#include "canvas/util/nanovg_util.h"
#include "canvas/util/string_utils.h"
#include "canvas/util/utils.h"
#include "css/css_color.h"
#include "jsbridge/bindings/canvas/napi_dom_matrix_2d_init.h"
#include "jsbridge/napi/napi_environment.h"

namespace lynx {
namespace canvas {
namespace {
const char *kDefaultFont = "10px sans-serif";
const char *kDefaultFontFamily = "sans-serif";
const int kDefaultFontSize = 10;

const char *kLineCapButt = "butt";
const char *kLineCapRound = "round";
const char *kLineCapSquare = "square";
const char *kLineCapBevel = "bevel";
const char *kLineCapMiter = "miter";

const char *kPathWindingEvenodd = "evenodd";

enum RotationDirection {
  kAntiClockwiseRotationDirection = 1,
  kClockwiseRotationDirection
};
enum PointCheckOpt {
  kEvenoddPointCheck = 0x01,
  kStrokePointCheck = 0x02,
};

std::string ValidUtf8(const std::u16string &text) {
  std::u16string valid_substr =
      text.substr(0, string_util::GetLongestValidSubStringLength(text));
  std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t> conversion;
  return conversion.to_bytes(valid_substr);
}
}  // namespace

CanvasRenderingContext2DLite::CanvasRenderingContext2DLite(
    CanvasElement *element)
    : CanvasRenderingContext2D(element),
      nvg_context_(ResourceProvider()->GetNVGContext()) {
  KRYPTON_CONSTRUCTOR_LOG(CanvasRenderingContext2DLite);
  Reset();
}

CanvasRenderingContext2DLite::~CanvasRenderingContext2DLite() {
  KRYPTON_DESTRUCTOR_LOG(CanvasRenderingContext2DLite);
};

Napi::Value CanvasRenderingContext2DLite::GetStrokeStyle() {
  return GetState().StrokeStyle().GetJsValue(Env());
}

void CanvasRenderingContext2DLite::SetStrokeStyle(const std::string &color) {
  CanvasStyle style(color);
  if (style.Valid()) {
    GetState().SetStrokeStyle(style);
    nanovg::nvgStrokeColor(Context(), GetState().StrokeStyle().PaintColor());
  }
}

void CanvasRenderingContext2DLite::SetStrokeStyle(CanvasGradient *gradient) {
  if (gradient) {
    GetState().SetStrokeStyle(CanvasStyle(gradient));
    CanvasGradientLite *lite = static_cast<CanvasGradientLite *>(gradient);
    nanovg::nvgStrokePaint(Context(), lite->GetGradient(Context()));
  }
}

void CanvasRenderingContext2DLite::SetStrokeStyle(CanvasPattern *pattern) {
  if (pattern) {
    GetState().SetStrokeStyle(CanvasStyle(pattern));
    CanvasPatternLite *lite = static_cast<CanvasPatternLite *>(pattern);
    nanovg::nvgStrokePaint(Context(), lite->GetPattern(Context()));
  }
}

Napi::Value CanvasRenderingContext2DLite::GetFillStyle() {
  return GetState().FillStyle().GetJsValue(Env());
}

void CanvasRenderingContext2DLite::SetFillStyle(const std::string &color) {
  CanvasStyle style(color);
  if (style.Valid()) {
    GetState().SetFillStyle(style);
    nanovg::nvgFillColor(Context(), GetState().FillStyle().PaintColor());
  }
}

void CanvasRenderingContext2DLite::SetFillStyle(CanvasGradient *gradient) {
  if (gradient) {
    GetState().SetFillStyle(CanvasStyle(gradient));
    CanvasGradientLite *lite = static_cast<CanvasGradientLite *>(gradient);
    nanovg::nvgFillPaint(Context(), lite->GetGradient(Context()));
  }
}

void CanvasRenderingContext2DLite::SetFillStyle(CanvasPattern *pattern) {
  if (pattern) {
    GetState().SetFillStyle(CanvasStyle(pattern));
    CanvasPatternLite *lite = static_cast<CanvasPatternLite *>(pattern);
    nanovg::nvgFillPaint(Context(), lite->GetPattern(Context()));
  }
}

void CanvasRenderingContext2DLite::Fill(const std::string &winding) {
  Draw([winding](auto *context) {
    nanovg::nvgFillEx(context, winding == kPathWindingEvenodd);
  });
}

void CanvasRenderingContext2DLite::Stroke() {
  Draw([](auto *context) { nanovg::nvgStroke(context); });
}

void CanvasRenderingContext2DLite::BeginPath() {
  nanovg::nvgBeginPath(Context());
}

void CanvasRenderingContext2DLite::ClosePath() {
  nanovg::nvgClosePath(Context());
}

void CanvasRenderingContext2DLite::MoveTo(double double_x, double double_y) {
  nanovg::nvgMoveTo(Context(), double_x, double_y);
}

void CanvasRenderingContext2DLite::LineTo(double double_x, double double_y) {
  nanovg::nvgLineTo(Context(), double_x, double_y);
}

void CanvasRenderingContext2DLite::QuadraticCurveTo(double double_cpx,
                                                    double double_cpy,
                                                    double double_x,
                                                    double double_y) {
  nanovg::nvgQuadTo(Context(), double_cpx, double_cpy, double_x, double_y);
}

void CanvasRenderingContext2DLite::BezierCurveTo(
    double double_cp1x, double double_cp1y, double double_cp2x,
    double double_cp2y, double double_x, double double_y) {
  nanovg::nvgBezierTo(Context(), double_cp1x, double_cp1y, double_cp2x,
                      double_cp2y, double_x, double_y);
}

void CanvasRenderingContext2DLite::ArcTo(ExceptionState &exception_state,
                                         double double_x1, double double_y1,
                                         double double_x2, double double_y2,
                                         double double_radius) {
  nanovg::nvgArcTo(Context(), double_x1, double_y1, double_x2, double_y2,
                   double_radius);
}

void CanvasRenderingContext2DLite::Arc(ExceptionState &exception_state,
                                       double double_x, double double_y,
                                       double double_radius,
                                       double double_start_angle,
                                       double double_end_angle,
                                       bool anticlockwise) {
  auto dir = anticlockwise ? RotationDirection::kAntiClockwiseRotationDirection
                           : RotationDirection::kClockwiseRotationDirection;
  nanovg::nvgArc(Context(), double_x, double_y, double_radius,
                 double_start_angle, double_end_angle, dir);
}

void CanvasRenderingContext2DLite::Ellipse(
    ExceptionState &exception_state, double double_x, double double_y,
    double double_radius_x, double double_radius_y, double double_rotation,
    double double_start_angle, double double_end_angle, bool anticlockwise) {
  auto vg = Context();
  nvgSave(vg);
  nvgTranslate(vg, double_x, double_y);
  nvgRotate(vg, double_rotation);
  nvgScale(vg, 1.0, double_radius_y / double_radius_x);
  auto dir = anticlockwise ? RotationDirection::kAntiClockwiseRotationDirection
                           : RotationDirection::kClockwiseRotationDirection;
  nvgArc(vg, 0, 0, double_radius_x, double_start_angle, double_end_angle, dir);
  nvgRestore(vg);
  // nanovg::nvgEllipse(Context(), double_x, double_y, double_radius_x,
  // double_radius_y, double_rotation, double_start_angle, double_end_angle,
  // anticlockwise);
}

void CanvasRenderingContext2DLite::Rect(double double_x, double double_y,
                                        double double_width,
                                        double double_height) {
  nanovg::nvgRect(Context(), double_x, double_y, double_width, double_height);
}

void CanvasRenderingContext2DLite::Reset() {
  UnwindStateStack();
  state_vector_.clear();
  state_vector_.emplace_back();

  nanovg::nvgReset(Context());
}

void CanvasRenderingContext2DLite::UnwindStateStack() {
  if (size_t stack_size = state_vector_.size()) {
    while (--stack_size) {
      nanovg::nvgRestore(Context());
    }
  }
}

void CanvasRenderingContext2DLite::DidDraw() const {
  ResourceProvider()->SetNeedRedraw();
}

TextMetrics *CanvasRenderingContext2DLite::MeasureText(
    const std::u16string &t) {
  std::string text = ValidUtf8(t);

  if (!ExtraState().HasRealizedFont()) {
    nanovg::nvgFontFace(Context(), kDefaultFontFamily);
    nanovg::nvgFontSize(Context(), kDefaultFontSize);
    nanovg::nvgFontWSV(Context(), nanovg::FONS_WSV_NORMAL);
  }

  nanovg::NVGtextMetricsInfo text_metrics_info;
  float width = nanovg::nvgTextMetricsInfo(Context(), 0, 0, text.c_str(),
                                           nullptr, &text_metrics_info);
  return new TextMetrics(
      width, text_metrics_info.textBounds[0], text_metrics_info.textBounds[2],
      text_metrics_info.fontAscent, text_metrics_info.fontDescent,
      -text_metrics_info.textBounds[1], text_metrics_info.textBounds[3],
      text_metrics_info.missingGlyphCount);
}

void CanvasRenderingContext2DLite::FillText(const std::u16string &text,
                                            double x, double y) {
  DrawTextInternal(text, x, y, kFillPaintType, nullptr);
}

void CanvasRenderingContext2DLite::FillText(const std::u16string &text,
                                            double x, double y,
                                            double max_width) {
  DrawTextInternal(text, x, y, kFillPaintType, &max_width);
}

void CanvasRenderingContext2DLite::StrokeText(const std::u16string &text,
                                              double x, double y) {
  DrawTextInternal(text, x, y, kStrokePaintType, nullptr);
}

void CanvasRenderingContext2DLite::StrokeText(const std::u16string &text,
                                              double x, double y,
                                              double max_width) {
  DrawTextInternal(text, x, y, kStrokePaintType, &max_width);
}

void CanvasRenderingContext2DLite::DrawTextInternal(
    const std::u16string &t, double x, double y,
    CanvasRenderingContext2DLite::PaintType paint_type,
    const double *max_width) {
  if (!std::isfinite(x) || !std::isfinite(y)) return;
  if (max_width && (!std::isfinite(*max_width) || *max_width <= 0)) return;

  std::string text = ValidUtf8(t);

  if (!ExtraState().HasRealizedFont()) {
    KRYPTON_LOGI("DrawText but no font set, fallback to default.");
    nanovg::nvgFontFace(Context(), kDefaultFontFamily);
    nanovg::nvgFontSize(Context(), kDefaultFontSize);
    nanovg::nvgFontWSV(Context(), nanovg::FONS_WSV_NORMAL);
  }

  int bitmap_option =
      paint_type == kFillPaintType ? nanovg::NVG_FILL : nanovg::NVG_STROKE;

  bool need_restore = false;
  if (max_width) {
    float width =
        nanovg::nvgTextBounds(Context(), x, y, text.c_str(), nullptr, nullptr);
    if (width > *max_width) {
      nanovg::nvgSave(Context());
      need_restore = true;

      float scale = *max_width / width;
      nanovg::nvgScale(Context(), scale, 1.0);
      x = x / scale;
    }
  }

  Draw([x, y, bitmap_option, text_start = text.c_str()](auto *context) {
    nanovg::NVGShadow *shadow = nanovg::nvgGetShadow(context);
    if (shadow->color.a != 0) {
      nanovg::nvgSave(context);
      nanovg::nvgFillColor(context, shadow->color);
      nanovg::nvgFontBlur(context, shadow->blur);
      nanovg::nvgText(context, x + shadow->offsetX, y + shadow->offsetY,
                      text_start, nullptr, bitmap_option);
      nanovg::nvgRestore(context);
    }

    nanovg::nvgText(context, x, y, text_start, nullptr, bitmap_option);
  });

  if (need_restore) {
    nanovg::nvgRestore(Context());
  }
}

void CanvasRenderingContext2DLite::DrawImage(ExceptionState &exception_state,
                                             CanvasImageSource *source,
                                             double x, double y) {
  int image = source->CreateNVGImage(Context(), enable_image_smoothing_);
  if (!image) {
    exception_state.SetException("Canvas Image Source not complete.");
    return;
  }
  int iw, ih;
  nanovg::nvgImageSize(Context(), image, &iw, &ih);
  DrawImageInternal(image, 0, 0, iw, ih, x, y, iw, ih);
}

void CanvasRenderingContext2DLite::DrawImage(ExceptionState &exception_state,
                                             CanvasImageSource *source,
                                             double x, double y, double width,
                                             double height) {
  int image = source->CreateNVGImage(Context(), enable_image_smoothing_);
  if (!image) {
    exception_state.SetException("Canvas Image Source not complete.");
    return;
  }
  int iw, ih;
  nanovg::nvgImageSize(Context(), image, &iw, &ih);
  DrawImageInternal(image, 0, 0, iw, ih, x, y, width, height);
}

void CanvasRenderingContext2DLite::DrawImage(ExceptionState &exception_state,
                                             CanvasImageSource *source,
                                             double sx, double sy, double sw,
                                             double sh, double dx, double dy,
                                             double dw, double dh) {
  int image = source->CreateNVGImage(Context(), enable_image_smoothing_);
  if (!image) {
    exception_state.SetException("Canvas Image Source not complete.");
    return;
  }
  DrawImageInternal(image, sx, sy, sw, sh, dx, dy, dw, dh);
}

void CanvasRenderingContext2DLite::DrawImageInternal(int image, double sx,
                                                     double sy, double sw,
                                                     double sh, double dx,
                                                     double dy, double dw,
                                                     double dh) {
  if (sw == 0 || sh == 0) return;
  if (sw < 0) {
    sx = sx + sw;
    sw = -sw;
  }
  if (sh < 0) {
    sy = sy + sh;
    sh = -sh;
  }
  if (dw < 0) {
    dx = dx + dw;
    dw = -dw;
  }
  if (dh < 0) {
    dy = dy + dh;
    dh = -dh;
  }

  int iw, ih;
  nanovg::NVGpaint img;
  nanovg::nvgImageSize(Context(), image, &iw, &ih);

  // Aspect ration of pixel in x an y dimensions. This allows us to scale
  // the sprite to fill the whole rectangle.
  float ax = dw / sw;
  float ay = dh / sh;

  img = nanovg::nvgImagePattern(Context(), dx - sx * ax, dy - sy * ay,
                                static_cast<float>(iw) * ax,
                                static_cast<float>(ih) * ay, 0, image, 0);
  nanovg::nvgSave(Context());
  nanovg::nvgBackupPath(Context());
  nanovg::nvgBeginPath(Context());
  nanovg::nvgRect(Context(), dx, dy, dw, dh);
  nanovg::nvgFillPaint(Context(), img);
  nanovg::nvgFill(Context());
  nanovg::nvgClosePath(Context());
  nanovg::nvgRestore(Context());
  nanovg::nvgFlush(Context());
  nanovg::nvgRestorePath(Context());
  DidDraw();

  nanovg::nvgDeleteImage(Context(), image);

  // flush gl command buffer to avoid tex updated by mistake i.e. another canvas
  // draw same image / canvas
  element_->WillDraw();
}

std::string CanvasRenderingContext2DLite::GetFont() const {
  if (!ExtraState().HasRealizedFont()) {
    return kDefaultFont;
  }

  CSSFont css_font = ExtraState().Font();

  std::ostringstream string_stream;
  if (css_font.style == kItalicStyle || css_font.style == kObliqueStyle) {
    // treat oblique as italic now
    string_stream << "italic ";
  }
  if (css_font.weight == kBoldWeight ||
      (css_font.weight == kNumberWeight && css_font.weight_value == 700)) {
    string_stream << "bold ";
  }
  if (css_font.variant == kSmallCapsVariant) {
    string_stream << "small-caps ";
  }

  string_stream << css_font.size << "px";
  for (auto iter = css_font.family_vector.begin();
       iter < css_font.family_vector.end(); iter++) {
    if (iter != css_font.family_vector.begin()) {
      string_stream << ",";
    }
    string_stream << " ";
    bool need_quote = false;
    if (iter->find(' ') != std::string::npos) {
      string_stream << '"';
      need_quote = true;
    }
    string_stream << *iter;
    if (need_quote) {
      string_stream << '"';
    }
  }
  return string_stream.str();
}

static nanovg::FONSWSV GetMatchedWeightFromValue(double weight_value) {
  // based on https://developer.mozilla.org/zh-CN/docs/Web/CSS/font-weight
  // fallback logic
  if (weight_value < 1 || weight_value > 1000) {
    return nanovg::FONS_WSV_NORMAL;
  } else if (weight_value < 200) {
    return nanovg::FONS_WEIGHT_100;
  } else if (weight_value < 300) {
    return nanovg::FONS_WEIGHT_200;
  } else if (weight_value < 400) {
    return nanovg::FONS_WEIGHT_300;
  } else if (weight_value == 400) {
    return nanovg::FONS_WEIGHT_400;
  } else if (weight_value < 501) {
    return nanovg::FONS_WEIGHT_500;
  } else if (weight_value < 601) {
    return nanovg::FONS_WEIGHT_600;
  } else if (weight_value < 701) {
    return nanovg::FONS_WEIGHT_700;
  } else if (weight_value < 801) {
    return nanovg::FONS_WEIGHT_800;
  } else {
    return nanovg::FONS_WEIGHT_900;
  }
}

CanvasGradient *CanvasRenderingContext2DLite::CreateLinearGradient(double x0,
                                                                   double y0,
                                                                   double x1,
                                                                   double y1) {
  return new CanvasGradientLite(x0, y0, x1, y1);
}

CanvasGradient *CanvasRenderingContext2DLite::CreateRadialGradient(
    ExceptionState &exception_state, double x0, double y0, double r0, double x1,
    double y1, double r1) {
  if (r0 < 0 || r1 < 0) {
    exception_state.SetException("The radius provided is less than 0.",
                                 piper::ExceptionState::kRangeError);
    return nullptr;
  }

  return new CanvasGradientLite(x0, y0, r0, x1, y1, r1);
}

CanvasPattern *CanvasRenderingContext2DLite::CreatePattern(
    ExceptionState &exception_state, CanvasImageSource *image_source,
    const std::string &repetition_type) {
  return new CanvasPatternLite(exception_state, Context(), image_source,
                               repetition_type);
}

std::unique_ptr<ImageData> CanvasRenderingContext2DLite::CreateImageData(
    ExceptionState &exception_state, ImageData *image_data) {
  return ImageData::Create(image_data);
}

std::unique_ptr<ImageData> CanvasRenderingContext2DLite::CreateImageData(
    ExceptionState &exception_state, int32_t width, int32_t height) {
  return ImageData::Create(exception_state, abs(width), abs(height));
}

ImageData *CanvasRenderingContext2DLite::GetImageData(
    ExceptionState &exception_state, int32_t sx, int32_t sy, int32_t sw,
    int32_t sh) {
  if (static_cast<int64_t>(sw) * static_cast<int64_t>(sh) >
      std::numeric_limits<int32_t>::max()) {
    exception_state.SetException("Out of memory at ImageData creation",
                                 piper::ExceptionState::kRangeError);
    return nullptr;
  }

  if (sw < 0) {
    if (static_cast<int64_t>(sx) + static_cast<int64_t>(sw) >
        std::numeric_limits<int32_t>::max()) {
      exception_state.SetException("Out of memory at ImageData creation",
                                   piper::ExceptionState::kRangeError);
      return nullptr;
    }
    sx += sw;
    sw = -sw;
  }

  if (sh < 0) {
    if (static_cast<int64_t>(sy) + static_cast<int64_t>(sh) >
        std::numeric_limits<int32_t>::max()) {
      exception_state.SetException("Out of memory at ImageData creation",
                                   piper::ExceptionState::kRangeError);
      return nullptr;
    }
    sy += sh;
    sh = -sh;
  }

  if (static_cast<int64_t>(sx) + static_cast<int64_t>(sw) >
          std::numeric_limits<int32_t>::max() ||
      static_cast<int64_t>(sy) + static_cast<int64_t>(sh) >
          std::numeric_limits<int32_t>::max()) {
    exception_state.SetException("Out of memory at ImageData creation",
                                 piper::ExceptionState::kRangeError);
    return nullptr;
  }

  ImageData *image_data = new ImageData(exception_state, sw, sh);
  auto raw_data = image_data->GetRawData();
  if (exception_state.HadException() || !raw_data) {
    KRYPTON_LOGE("getImageData throw error: ") << raw_data;
    return nullptr;
  }

  element_->ReadPixels(sx, sy, sw, sh, const_cast<void *>(raw_data));

  return image_data;
}

void CanvasRenderingContext2DLite::PutImageData(ImageData *image_data, int dx,
                                                int dy) {
  PutImageData(image_data, dx, dy, 0, 0,
               static_cast<int>(image_data->GetWidth()),
               static_cast<int>(image_data->GetHeight()));
}

void CanvasRenderingContext2DLite::PutImageData(ImageData *image_data, int dx,
                                                int dy, int dirty_x,
                                                int dirty_y, int dirty_width,
                                                int dirty_height) {
  if (dirty_width < 0) {
    if (dirty_x < 0) {
      dirty_x = dirty_width = 0;
    } else {
      dirty_x += dirty_width;
      dirty_width = std::abs(dirty_width);
    }

    if (dirty_height < 0) {
      if (dirty_y < 0) {
        dirty_y = dirty_height = 0;
      } else {
        dirty_y += dirty_height;
        dirty_height = std::abs(dirty_height);
      }
    }
  }

  auto raw_data = image_data->GetRawData();
  if (!raw_data) {
    KRYPTON_LOGE("putImageData throw error: ") << raw_data;
    return;
  }

  element_->PutPixels(const_cast<void *>(raw_data),
                      static_cast<int>(image_data->GetWidth()),
                      static_cast<int>(image_data->GetHeight()), dx, dy,
                      dirty_x, dirty_y, dirty_width, dirty_height);
}

bool CanvasRenderingContext2DLite::IsPointInPath(const double x, const double y,
                                                 const string &winding) {
  short pots = 0;
  if (winding == kPathWindingEvenodd) pots |= PointCheckOpt::kEvenoddPointCheck;
  return nanovg::nvgIsPointInConvexPolygon(Context(), x, y, pots);
}

bool CanvasRenderingContext2DLite::IsPointInPath(Path2D *path, const double x,
                                                 const double y,
                                                 const string &winding) {
  // todo
  return false;
}

bool CanvasRenderingContext2DLite::IsPointInStroke(const double x,
                                                   const double y) {
  return nanovg::nvgIsPointInConvexPolygon(Context(), x, y,
                                           PointCheckOpt::kStrokePointCheck);
}

bool CanvasRenderingContext2DLite::IsPointInStroke(Path2D *path, const double x,
                                                   const double y) {
  // todo
  return false;
}

const std::vector<double> &CanvasRenderingContext2DLite::GetLineDash() const {
  return line_dash_;
}

void CanvasRenderingContext2DLite::SetLineDash(std::vector<double> line_dash) {
  // helium didnot record line_dash into line_dash_, currently we use the same
  // way.. line_dash_.assign(line_dash.begin(), line_dash.end());
  if (!std::all_of(line_dash.begin(), line_dash.end(),
                   [](double d) { return isfinite(d) && d >= 0; })) {
    return;
  }
  if (std::all_of(line_dash.begin(), line_dash.end(),
                  [](double d) { return d == 0; })) {
    std::vector<double>().swap(line_dash);
  }
  auto dst = std::vector<float>(line_dash.begin(), line_dash.end());
  nanovg::nvgLineDash(Context(), dst.data(), static_cast<uint32_t>(dst.size()));
}

double CanvasRenderingContext2DLite::GetShadowBlur() const {
  return nanovg::nvgGetShadow(Context())->blur;
}

void CanvasRenderingContext2DLite::SetShadowBlur(double blur) {
  if (!std::isfinite(blur) || blur < 0) return;
  nanovg::NVGShadow *shadow = nvgGetShadow(Context());
  if (shadow->blur == blur) return;
  shadow->blur = blur;
}

std::string CanvasRenderingContext2DLite::GetShadowColor() const {
  nanovg::NVGShadow *shadow = nvgGetShadow(Context());
  std::string colorString = SerializeNVGcolor(shadow->color);
  return colorString;
}

void CanvasRenderingContext2DLite::SetShadowColor(const std::string &color) {
  nanovg::NVGcolor nvgColor;
  if (ParseColorString(color, nvgColor)) {
    nanovg::NVGShadow *shadow = nvgGetShadow(Context());
    shadow->color = nvgColor;
  }
}

double CanvasRenderingContext2DLite::GetShadowOffsetX() const {
  nanovg::NVGShadow *shadow = nvgGetShadow(Context());
  return shadow->offsetX;
}

void CanvasRenderingContext2DLite::SetShadowOffsetX(double offset_x) {
  nanovg::NVGShadow *shadow = nvgGetShadow(Context());
  shadow->offsetX = offset_x;
}

double CanvasRenderingContext2DLite::GetShadowOffsetY() const {
  nanovg::NVGShadow *shadow = nvgGetShadow(Context());
  return shadow->offsetY;
}

void CanvasRenderingContext2DLite::SetShadowOffsetY(double offset_y) {
  nanovg::NVGShadow *shadow = nvgGetShadow(Context());
  shadow->offsetY = offset_y;
}

double CanvasRenderingContext2DLite::GetLineWidth() const {
  return nanovg::nvgGetStrokeWidth(Context());
}

void CanvasRenderingContext2DLite::SetLineWidth(double line_width) {
  if (!std::isfinite(line_width) || line_width <= 0) {
    return;
  }
  nanovg::nvgStrokeWidth(Context(), line_width);
}

double CanvasRenderingContext2DLite::GetLineDashOffset() const {
  return nanovg::nvgGetLineDashOffset(Context());
}
void CanvasRenderingContext2DLite::SetLineDashOffset(double offset) {
  if (!std::isfinite(offset)) {
    return;
  }
  nanovg::nvgLineDashOffset(Context(), offset);
}

string CanvasRenderingContext2DLite::GetLineCap() const {
  auto cap = nanovg::nvgGetLineCap(Context());
  switch (cap) {
    case nanovg::NVGlineCap::NVG_ROUND:
      return kLineCapRound;
    case nanovg::NVGlineCap::NVG_SQUARE:
      return kLineCapSquare;
    default:
      return kLineCapButt;
  }
}

void CanvasRenderingContext2DLite::SetLineCap(const string &cap) {
  auto opt = nanovg::NVGlineCap::NVG_BUTT;
  if (cap == kLineCapButt) {
    opt = nanovg::NVGlineCap::NVG_BUTT;
  } else if (cap == kLineCapRound) {
    opt = nanovg::NVGlineCap::NVG_ROUND;
  } else if (cap == kLineCapSquare) {
    opt = nanovg::NVGlineCap::NVG_SQUARE;
  } else {
    return;
  }

  nanovg::nvgLineCap(Context(), opt);
}

double CanvasRenderingContext2DLite::GetMiterLimit() const {
  return nanovg::nvgGetMiterLimit(Context());
}

void CanvasRenderingContext2DLite::SetMiterLimit(double limit) {
  if (!std::isfinite(limit) || limit <= 0) {
    return;
  }
  nanovg::nvgMiterLimit(Context(), limit);
}

std::string CanvasRenderingContext2DLite::GetLineJoin() const {
  auto join = nanovg::nvgGetLineJoin(Context());
  switch (join) {
    case nanovg::NVGlineCap::NVG_ROUND:
      return kLineCapRound;
    case nanovg::NVGlineCap::NVG_BEVEL:
      return kLineCapBevel;
    default:
      return kLineCapMiter;
  }
}

void CanvasRenderingContext2DLite::SetLineJoin(const std::string &join) {
  auto opt = nanovg::NVGlineCap::NVG_MITER;
  if (join == kLineCapMiter) {
    opt = nanovg::NVGlineCap::NVG_MITER;
  } else if (join == kLineCapRound) {
    opt = nanovg::NVGlineCap::NVG_ROUND;
  } else if (join == kLineCapBevel) {
    opt = nanovg::NVGlineCap::NVG_BEVEL;
  } else {
    return;
  }

  nanovg::nvgLineJoin(Context(), opt);
}

void CanvasRenderingContext2DLite::Scale(double sx, double sy) {
  nanovg::nvgScale(Context(), sx, sy);
}

void CanvasRenderingContext2DLite::Rotate(double angle_in_radians) {
  nanovg::nvgRotate(Context(), angle_in_radians);
}

void CanvasRenderingContext2DLite::Translate(double tx, double ty) {
  nanovg::nvgTranslate(Context(), tx, ty);
}

void CanvasRenderingContext2DLite::Transform(double m11, double m12, double m21,
                                             double m22, double dx, double dy) {
  nanovg::nvgTransform(Context(), m11, m12, m21, m22, dx, dy);
}

void CanvasRenderingContext2DLite::SetTransform(double m11, double m12,
                                                double m21, double m22,
                                                double dx, double dy) {
  float matrix[6] = {static_cast<float>(m11), static_cast<float>(m12),
                     static_cast<float>(m21), static_cast<float>(m22),
                     static_cast<float>(dx),  static_cast<float>(dy)};
  nanovg::nvgSetTransform(Context(), matrix);
}

void CanvasRenderingContext2DLite::SetTransform(
    std::unique_ptr<DOMMatrix2DInit> init) {
  if (init == nullptr) {
    SetTransform(1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f);
    return;
  }
  SetTransform(init->a(), init->b(), init->c(), init->d(), init->e(),
               init->f());
}

std::unique_ptr<DOMMatrix> CanvasRenderingContext2DLite::GetTransform() {
  float matrix[6];
  nanovg::nvgCurrentTransform(Context(), matrix);
  return std::make_unique<DOMMatrix>(matrix);
}

void CanvasRenderingContext2DLite::ResetTransform() {
  nanovg::nvgResetTransform(Context());
}

void CanvasRenderingContext2DLite::ClearRect(double x, double y, double width,
                                             double height) {
  if (x == 0 && y == 0 && width == GetCanvas()->GetWidth() &&
      height == GetCanvas()->GetHeight() && !nanovg::nvgHasClip(Context())) {
    float xform[6];
    const float i[] = {
        1, 0, 0, 1, 0, 0,
    };
    nanovg::nvgCurrentTransform(Context(), xform);
    if (!__builtin_memcmp(xform, i, sizeof(xform))) {
      nanovg::nvgClear(Context());
      GetCanvas()->Clear();
      return;
    }
  }
  // Refer to helium implementation
  nanovg::nvgSave(Context());
  nanovg::nvgFillColor(Context(), nanovg::nvgRGBAf(0.0, 0.0, 0.0, 0.0));
  nanovg::nvgGlobalCompositeOperation(Context(),
                                      nanovg::NVGcompositeOperation::NVG_COPY);
  nanovg::nvgBackupPath(Context());
  nanovg::nvgBeginPath(Context());
  nanovg::nvgRect(Context(), x, y, width, height);
  nanovg::nvgClosePath(Context());
  nanovg::nvgFill(Context());
  nanovg::nvgRestorePath(Context());
  nanovg::nvgRestore(Context());
  DidDraw();
}

void CanvasRenderingContext2DLite::FillRect(double x, double y, double width,
                                            double height) {
  nanovg::NVGShadow *shadow = nanovg::nvgGetShadow(Context());
  if (shadow->color.a != 0) {
    nanovg::nvgSave(Context());
    const float &blur = shadow->blur;

    nanovg::nvgFillPaint(
        Context(), nanovg::nvgBoxGradient(Context(), x + shadow->offsetX,
                                          y + shadow->offsetY, width, height,
                                          blur / 2, blur, shadow->color,
                                          nanovg::nvgRGBAf(0, 0, 0, 0)));
    nanovg::nvgBackupPath(Context());
    nanovg::nvgBeginPath(Context());
    nanovg::nvgRect(Context(), x + shadow->offsetX - blur,
                    y + shadow->offsetY - blur, width + blur * 2,
                    height + blur * 2);
    nanovg::nvgClosePath(Context());
    nanovg::nvgFill(Context());
    nanovg::nvgRestorePath(Context());
    nanovg::nvgRestore(Context());
  }
  nanovg::nvgBackupPath(Context());
  nanovg::nvgBeginPath(Context());
  nanovg::nvgRect(Context(), x, y, width, height);
  nanovg::nvgClosePath(Context());
  nanovg::nvgFill(Context());
  nanovg::nvgRestorePath(Context());
  DidDraw();
}

void CanvasRenderingContext2DLite::StrokeRect(double x, double y, double width,
                                              double height) {
  nanovg::nvgBackupPath(Context());
  nanovg::nvgBeginPath(Context());
  nanovg::nvgRect(Context(), x, y, width, height);
  nanovg::nvgClosePath(Context());
  nanovg::nvgStroke(Context());
  nanovg::nvgRestorePath(Context());
  DidDraw();
}

void CanvasRenderingContext2DLite::Clip(const string &winding) {
  nanovg::nvgClip(Context(), winding == kPathWindingEvenodd);
}

static unsigned short GetWSVFromCSSFontStyle(const CSSFont &css_font) {
  nanovg::FONSWSV weight;
  nanovg::FONSWSV style;
  nanovg::FONSWSV variant;

  switch (css_font.weight) {
    case kNormalWeight:
      weight = nanovg::FONS_WSV_NORMAL;
      break;
    case kBoldWeight:
      weight = nanovg::FONS_WEIGHT_BOLD;
      break;
    case kBolderWeight:
      weight = nanovg::FONS_WEIGHT_BOLDER;
      break;
    case kLighterWeight:
      weight = nanovg::FONS_WEIGHT_LIGHTER;
      break;
    case kNumberWeight:
      weight = GetMatchedWeightFromValue(css_font.weight_value);
      break;
  }

  switch (css_font.style) {
    case kNormalStyle:
      style = nanovg::FONS_WSV_NORMAL;
      break;
    case kItalicStyle:
      style = nanovg::FONS_STYLE_ITALIC;
      break;
    case kObliqueStyle:
      style = nanovg::FONS_STYLE_OBLIQUE;
      break;
  }

  switch (css_font.variant) {
    case kNormalVariant:
      variant = nanovg::FONS_WSV_NORMAL;
      break;
    case kSmallCapsVariant:
      variant = nanovg::FONS_VARIANT_SMALL_CAPS;
      break;
  }

  return weight | style | variant;
}

namespace {
int GetDefaultFontFamilyId(nanovg::NVGcontext *context) {
  auto font_id = nanovg::nvgFindFont(context, kDefaultFontFamily);
  if (font_id == FONS_INVALID) {
    KRYPTON_LOGE(
        "can not find default font family id, may load failed. retry.");
    font_id = nanovg::nvgAutoLoadSystemFont(context, kDefaultFontFamily);
  }
  DCHECK(font_id != FONS_INVALID);
  return font_id;
}

int FindFont(nanovg::NVGcontext *context, const std::string &family_name) {
  auto font_id = nanovg::nvgFindFont(context, family_name.c_str());

  if (font_id == FONS_INVALID) {
    font_id = nanovg::nvgAutoLoadSystemFont(context, family_name.c_str());
  }

  return font_id;
}

int LoadFont(nanovg::NVGcontext *context, const std::string &family_name,
             Typeface *typeface) {
  DCHECK(typeface);
  auto font_id = FONS_INVALID;

  auto added_id = nanovg::nvgCreateFontMem(
      context, family_name.c_str(),
      reinterpret_cast<u_char *>(const_cast<void *>(typeface->Data())),
      static_cast<int>(typeface->Size()), 0);
  if (added_id != FONS_INVALID) {
    font_id = added_id;
    auto fallback_id = GetDefaultFontFamilyId(context);
    nanovg::nvgAddFallbackFontId(context, added_id, fallback_id);
  }

  return font_id;
}
}  // namespace

void CanvasRenderingContext2DLite::OnTypeFaceAdded(Typeface *typeface) {
  KRYPTON_LOGI("OnTypefaceAdded with ")
      << typeface << " name: " << typeface->Name() << " id: " << typeface->Id();
  auto font_id = LoadFont(Context(), typeface->Name(), typeface);
  if (font_id == FONS_INVALID) {
    KRYPTON_LOGE("OnTypefaceAdded failed with ") << typeface;
  }
}

void CanvasRenderingContext2DLite::SetFont(const string &font_str) {
  if (ExtraState().HasRealizedFont() &&
      ExtraState().UnparsedFont() == font_str) {
    return;
  }

  auto font_collection = element_->GetFontCollection();
  // start observe font changed
  if (!scoped_typeface_observer_) {
    scoped_typeface_observer_ =
        std::make_unique<ScopedTypefaceObserver>(font_collection, this);
  }

  CSSFont css_font;
  if (font_parser_.ParseFont(font_str, css_font)) {
    int fons_id_found = FONS_INVALID;
    for (auto family : css_font.family_vector) {
      std::string normalized_font_str = StringToLowerASCII(family);

      auto font_id = FindFont(Context(), normalized_font_str);
      if (font_id != FONS_INVALID) {
        fons_id_found = font_id;
        break;
      }
    }

    ExtraState().SetFont(css_font);
    ExtraState().SetUnparsedFont(font_str);

    if (fons_id_found == FONS_INVALID) {
      fons_id_found = GetDefaultFontFamilyId(Context());
    }

    DCHECK(fons_id_found != FONS_INVALID);
    nanovg::nvgFontFaceId(Context(), fons_id_found);
    nanovg::nvgFontSize(Context(), css_font.size);
    nanovg::nvgFontWSV(Context(), GetWSVFromCSSFontStyle(css_font));
  }
}

static bool ParseTextAlign(const std::string &s, nanovg::NVGalign &align) {
  if (s == "start") {
    align = nanovg::NVG_ALIGN_LEFT;
    return true;
  }
  if (s == "end") {
    align = nanovg::NVG_ALIGN_RIGHT;
    return true;
  }
  if (s == "left") {
    align = nanovg::NVG_ALIGN_LEFT;
    return true;
  }
  if (s == "center") {
    align = nanovg::NVG_ALIGN_CENTER;
    return true;
  }
  if (s == "right") {
    align = nanovg::NVG_ALIGN_RIGHT;
    return true;
  }
  return false;
}

std::string CanvasRenderingContext2DLite::GetTextAlign() const {
  return ExtraState().TextAlign();
}

void CanvasRenderingContext2DLite::SetTextAlign(const string &text_align) {
  nanovg::NVGalign align;
  if (!ParseTextAlign(text_align, align)) {
    return;
  }
  ExtraState().SetTextAlign(text_align);
  nanovg::nvgTextAlign(
      Context(),
      align | (nanovg::nvgGetTextAlign(Context()) &
               (nanovg::NVG_ALIGN_TOP | nanovg::NVG_ALIGN_MIDDLE |
                nanovg::NVG_ALIGN_BOTTOM | nanovg::NVG_ALIGN_BASELINE)));
}

static bool ParseTextBaseline(const std::string &s,
                              nanovg::NVGalign &baseline) {
  if (s == "alphabetic") {
    baseline = nanovg::NVG_ALIGN_BASELINE;
    return true;
  }
  if (s == "top") {
    baseline = nanovg::NVG_ALIGN_TOP;
    return true;
  }
  if (s == "middle") {
    baseline = nanovg::NVG_ALIGN_MIDDLE;
    return true;
  }
  if (s == "bottom") {
    baseline = nanovg::NVG_ALIGN_BOTTOM;
    return true;
  }
  if (s == "ideographic") {
    baseline = nanovg::NVG_ALIGN_BOTTOM;
    return true;
  }
  if (s == "hanging") {
    baseline = nanovg::NVG_ALIGN_TOP;
    return true;
  }
  return false;
}

std::string CanvasRenderingContext2DLite::GetTextBaseline() const {
  return ExtraState().TextBaseline();
}

void CanvasRenderingContext2DLite::SetTextBaseline(const string &baseline) {
  nanovg::NVGalign align;
  if (!ParseTextBaseline(baseline, align)) {
    return;
  }
  ExtraState().SetTextBaseline(baseline);
  nanovg::nvgTextAlign(
      Context(), align | (nanovg::nvgGetTextAlign(Context()) &
                          (nanovg::NVG_ALIGN_LEFT | nanovg::NVG_ALIGN_CENTER |
                           nanovg::NVG_ALIGN_RIGHT)));
}

void CanvasRenderingContext2DLite::Save() {
  nanovg::nvgSave(Context());

  state_vector_.emplace_back(ExtraState());
}

void CanvasRenderingContext2DLite::Restore() {
  if (state_vector_.size() <= 1) {
    return;
  }

  nanovg::nvgRestore(Context());

  state_vector_.pop_back();
}

bool CanvasRenderingContext2DLite::GetImageSmoothingEnabled() const {
  return enable_image_smoothing_;
}

void CanvasRenderingContext2DLite::SetImageSmoothingEnabled(bool e) {
  enable_image_smoothing_ = e;
}

std::string CanvasRenderingContext2DLite::GetImageSmoothingQuality() const {
  KRYPTON_LOGI("do not support image smoothing now.");
  return std::string();
}

void CanvasRenderingContext2DLite::SetImageSmoothingQuality(
    const string &quality) {
  KRYPTON_LOGI("do not support image smoothing now.");
}

double CanvasRenderingContext2DLite::GetGlobalAlpha() const {
  return nanovg::nvgGetGlobalAlpha(Context());
}

void CanvasRenderingContext2DLite::SetGlobalAlpha(double alpha) {
  nanovg::nvgGlobalAlpha(Context(), ClampDoubleToFloat(alpha));
}

const char *const kCompositeOperationName[] = {
    "source-over",
    "source-in",
    "source-out",
    "source-atop",
    "destination-over",
    "destination-in",
    "destination-out",
    "destination-atop",
    "lighter",
    "copy",
    "xor",
};

template <typename T, size_t N>
constexpr size_t Size(const T (&array)[N]) noexcept {
  return N;
}

static const size_t kCompositeOperationNameSize = Size(kCompositeOperationName);

static const char *const kBlendModeNames[] = {
    "normal",     "multiply",   "screen",      "overlay",
    "darken",     "lighten",    "color-dodge", "color-burn",
    "hard-light", "soft-light", "difference",  "exclusion",
    "hue",        "saturation", "color",       "luminosity"};

const nanovg::NVGcompositeOperation kNVGCompositeOperation[] = {
    nanovg::NVG_SOURCE_OVER,
    nanovg::NVG_SOURCE_IN,
    nanovg::NVG_SOURCE_OUT,
    nanovg::NVG_ATOP,
    nanovg::NVG_DESTINATION_OVER,
    nanovg::NVG_DESTINATION_IN,
    nanovg::NVG_DESTINATION_OUT,
    nanovg::NVG_DESTINATION_ATOP,
    nanovg::NVG_LIGHTER,
    nanovg::NVG_COPY,
    nanovg::NVG_XOR,
};

static nanovg::NVGcompositeOperation ParseCompositeOperation(
    const std::string &operation) {
  for (auto i = 0; i < kCompositeOperationNameSize; i++) {
    if (kCompositeOperationName[i] == operation) {
      return kNVGCompositeOperation[i];
    }
  }

  for (auto kBlendModeName : kBlendModeNames) {
    if (kBlendModeName == operation) {
      KRYPTON_LOGI(
          "composite mode set to blend mode, but wo do not support now.");
      break;
    }
  }

  return nanovg::NVG_SOURCE_OVER;
}

static std::string CompositeOperatorName(
    nanovg::NVGcompositeOperation composite_operation) {
  for (int i = 0; i < kCompositeOperationNameSize; ++i) {
    if (composite_operation == kNVGCompositeOperation[i]) {
      return kCompositeOperationName[i];
    }
  }

  return kCompositeOperationName[0];
}

std::string CanvasRenderingContext2DLite::GetGlobalCompositeOperation() const {
  return CompositeOperatorName(ExtraState().CompositeOperation());
}

void CanvasRenderingContext2DLite::SetGlobalCompositeOperation(
    const string &operation) {
  auto composite_operation = ParseCompositeOperation(operation);
  nanovg::nvgGlobalCompositeOperation(Context(), composite_operation);
  ExtraState().SetCompositeMode(composite_operation);
}
}  // namespace canvas
}  // namespace lynx
