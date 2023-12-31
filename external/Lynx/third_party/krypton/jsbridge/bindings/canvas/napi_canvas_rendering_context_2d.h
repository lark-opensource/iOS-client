// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_CANVAS_RENDERING_CONTEXT_2D_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_CANVAS_RENDERING_CONTEXT_2D_H_

#include <memory>

#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class CanvasRenderingContext2D;

class NapiCanvasRenderingContext2D : public BridgeBase {
 public:
  NapiCanvasRenderingContext2D(const Napi::CallbackInfo&, bool skip_init_as_base = false);

  CanvasRenderingContext2D* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<CanvasRenderingContext2D>, Napi::Env);

  void Init(std::unique_ptr<CanvasRenderingContext2D>);

  // Attributes
  Napi::Value CanvasAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value GlobalAlphaAttributeGetter(const Napi::CallbackInfo&);
  void GlobalAlphaAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value GlobalCompositeOperationAttributeGetter(const Napi::CallbackInfo&);
  void GlobalCompositeOperationAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value ImageSmoothingEnabledAttributeGetter(const Napi::CallbackInfo&);
  void ImageSmoothingEnabledAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value ImageSmoothingQualityAttributeGetter(const Napi::CallbackInfo&);
  void ImageSmoothingQualityAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value StrokeStyleAttributeGetter(const Napi::CallbackInfo&);
  void StrokeStyleAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value FillStyleAttributeGetter(const Napi::CallbackInfo&);
  void FillStyleAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value ShadowOffsetXAttributeGetter(const Napi::CallbackInfo&);
  void ShadowOffsetXAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value ShadowOffsetYAttributeGetter(const Napi::CallbackInfo&);
  void ShadowOffsetYAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value ShadowBlurAttributeGetter(const Napi::CallbackInfo&);
  void ShadowBlurAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value ShadowColorAttributeGetter(const Napi::CallbackInfo&);
  void ShadowColorAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value LineWidthAttributeGetter(const Napi::CallbackInfo&);
  void LineWidthAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value LineCapAttributeGetter(const Napi::CallbackInfo&);
  void LineCapAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value LineJoinAttributeGetter(const Napi::CallbackInfo&);
  void LineJoinAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value MiterLimitAttributeGetter(const Napi::CallbackInfo&);
  void MiterLimitAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value LineDashOffsetAttributeGetter(const Napi::CallbackInfo&);
  void LineDashOffsetAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value FontAttributeGetter(const Napi::CallbackInfo&);
  void FontAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value TextAlignAttributeGetter(const Napi::CallbackInfo&);
  void TextAlignAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value TextBaselineAttributeGetter(const Napi::CallbackInfo&);
  void TextBaselineAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);

  // Methods
  Napi::Value SaveMethod(const Napi::CallbackInfo&);
  Napi::Value RestoreMethod(const Napi::CallbackInfo&);
  Napi::Value ScaleMethod(const Napi::CallbackInfo&);
  Napi::Value RotateMethod(const Napi::CallbackInfo&);
  Napi::Value TranslateMethod(const Napi::CallbackInfo&);
  Napi::Value TransformMethod(const Napi::CallbackInfo&);
  Napi::Value GetTransformMethod(const Napi::CallbackInfo&);
  Napi::Value ResetTransformMethod(const Napi::CallbackInfo&);
  Napi::Value CreateLinearGradientMethod(const Napi::CallbackInfo&);
  Napi::Value CreateRadialGradientMethod(const Napi::CallbackInfo&);
  Napi::Value CreatePatternMethod(const Napi::CallbackInfo&);
  Napi::Value ClearRectMethod(const Napi::CallbackInfo&);
  Napi::Value FillRectMethod(const Napi::CallbackInfo&);
  Napi::Value StrokeRectMethod(const Napi::CallbackInfo&);
  Napi::Value BeginPathMethod(const Napi::CallbackInfo&);
  Napi::Value FillMethod(const Napi::CallbackInfo&);
  Napi::Value StrokeMethod(const Napi::CallbackInfo&);
  Napi::Value ClipMethod(const Napi::CallbackInfo&);
  Napi::Value IsPointInPathMethod(const Napi::CallbackInfo&);
  Napi::Value IsPointInStrokeMethod(const Napi::CallbackInfo&);
  Napi::Value FillTextMethod(const Napi::CallbackInfo&);
  Napi::Value StrokeTextMethod(const Napi::CallbackInfo&);
  Napi::Value MeasureTextMethod(const Napi::CallbackInfo&);
  Napi::Value GetImageDataMethod(const Napi::CallbackInfo&);
  Napi::Value SetLineDashMethod(const Napi::CallbackInfo&);
  Napi::Value GetLineDashMethod(const Napi::CallbackInfo&);
  Napi::Value ClosePathMethod(const Napi::CallbackInfo&);
  Napi::Value MoveToMethod(const Napi::CallbackInfo&);
  Napi::Value LineToMethod(const Napi::CallbackInfo&);
  Napi::Value QuadraticCurveToMethod(const Napi::CallbackInfo&);
  Napi::Value BezierCurveToMethod(const Napi::CallbackInfo&);
  Napi::Value ArcToMethod(const Napi::CallbackInfo&);
  Napi::Value RectMethod(const Napi::CallbackInfo&);
  Napi::Value ArcMethod(const Napi::CallbackInfo&);
  Napi::Value EllipseMethod(const Napi::CallbackInfo&);

  // Overload Hubs
  Napi::Value SetTransformMethod(const Napi::CallbackInfo&);
  Napi::Value DrawImageMethod(const Napi::CallbackInfo&);
  Napi::Value CreateImageDataMethod(const Napi::CallbackInfo&);
  Napi::Value PutImageDataMethod(const Napi::CallbackInfo&);

  // Overloads
  Napi::Value SetTransformMethodOverload1(const Napi::CallbackInfo&);
  Napi::Value SetTransformMethodOverload2(const Napi::CallbackInfo&);
  Napi::Value DrawImageMethodOverload1(const Napi::CallbackInfo&);
  Napi::Value DrawImageMethodOverload2(const Napi::CallbackInfo&);
  Napi::Value DrawImageMethodOverload3(const Napi::CallbackInfo&);
  Napi::Value CreateImageDataMethodOverload1(const Napi::CallbackInfo&);
  Napi::Value CreateImageDataMethodOverload2(const Napi::CallbackInfo&);
  Napi::Value PutImageDataMethodOverload1(const Napi::CallbackInfo&);
  Napi::Value PutImageDataMethodOverload2(const Napi::CallbackInfo&);

  // Injection hook
  static void Install(Napi::Env, Napi::Object&);

  static Napi::Function Constructor(Napi::Env);
  static Napi::Class* Class(Napi::Env);

  // Interface name
  static constexpr const char* InterfaceName() {
    return "CanvasRenderingContext2D";
  }

 private:
  std::unique_ptr<CanvasRenderingContext2D> impl_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_CANVAS_RENDERING_CONTEXT_2D_H_
