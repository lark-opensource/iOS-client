// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/canvas/napi_canvas_rendering_context_2d.h"

#include <vector>
#include <utility>

#include "canvas/image_element.h"
#include "canvas/media/video_element.h"
#include "canvas/2d/canvas_gradient.h"
#include "canvas/2d/canvas_pattern.h"
#include "canvas/2d/canvas_rendering_context_2d.h"
#include "canvas/2d/dom_matrix.h"
#include "jsbridge/bindings/canvas/napi_canvas_element.h"
#include "jsbridge/bindings/canvas/napi_canvas_gradient.h"
#include "jsbridge/bindings/canvas/napi_canvas_pattern.h"
#include "jsbridge/bindings/canvas/napi_dom_matrix.h"
#include "jsbridge/bindings/canvas/napi_dom_matrix_2d_init.h"
#include "jsbridge/bindings/canvas/napi_image_element.h"
#include "jsbridge/bindings/canvas/napi_image_data.h"
#include "jsbridge/bindings/canvas/napi_text_metrics.h"
#include "jsbridge/bindings/canvas/napi_video_element.h"
#include "jsbridge/napi/exception_state.h"
#include "jsbridge/napi/exception_message.h"
#include "jsbridge/napi/napi_base_wrap.h"

using Napi::Array;
using Napi::CallbackInfo;
using Napi::Error;
using Napi::Function;
using Napi::FunctionReference;
using Napi::Number;
using Napi::Object;
using Napi::ObjectWrap;
using Napi::String;
using Napi::TypeError;
using Napi::Value;

using Napi::ArrayBuffer;
using Napi::Int8Array;
using Napi::Uint8Array;
using Napi::Int16Array;
using Napi::Uint16Array;
using Napi::Int32Array;
using Napi::Uint32Array;
using Napi::Float32Array;
using Napi::Float64Array;
using Napi::DataView;

using lynx::piper::IDLBoolean;
using lynx::piper::IDLDouble;
using lynx::piper::IDLFloat;
using lynx::piper::IDLFunction;
using lynx::piper::IDLNumber;
using lynx::piper::IDLString;
using lynx::piper::IDLUnrestrictedFloat;
using lynx::piper::IDLUnrestrictedDouble;
using lynx::piper::IDLNullable;
using lynx::piper::IDLObject;
using lynx::piper::IDLInt8Array;
using lynx::piper::IDLInt16Array;
using lynx::piper::IDLInt32Array;
using lynx::piper::IDLUint8ClampedArray;
using lynx::piper::IDLUint8Array;
using lynx::piper::IDLUint16Array;
using lynx::piper::IDLUint32Array;
using lynx::piper::IDLFloat32Array;
using lynx::piper::IDLFloat64Array;
using lynx::piper::IDLArrayBuffer;
using lynx::piper::IDLArrayBufferView;
using lynx::piper::IDLDictionary;
using lynx::piper::IDLSequence;
using lynx::piper::NativeValueTraits;

using lynx::piper::ExceptionMessage;

namespace lynx {
namespace canvas {

namespace {
const uint64_t kCanvasRenderingContext2DClassID = reinterpret_cast<uint64_t>(&kCanvasRenderingContext2DClassID);
const uint64_t kCanvasRenderingContext2DConstructorID = reinterpret_cast<uint64_t>(&kCanvasRenderingContext2DConstructorID);

using Wrapped = piper::NapiBaseWrapped<NapiCanvasRenderingContext2D>;
typedef Value (NapiCanvasRenderingContext2D::*InstanceCallback)(const CallbackInfo& info);
typedef void (NapiCanvasRenderingContext2D::*InstanceSetterCallback)(const CallbackInfo& info, const Value& value);

__attribute__((unused))
void AddAttribute(std::vector<Wrapped::PropertyDescriptor>& props,
                  const char* name,
                  InstanceCallback getter,
                  InstanceSetterCallback setter) {
  props.push_back(
      Wrapped::InstanceAccessor(name, getter, setter, napi_default_jsproperty));
}

__attribute__((unused))
void AddInstanceMethod(std::vector<Wrapped::PropertyDescriptor>& props,
                       const char* name,
                       InstanceCallback method) {
  props.push_back(
      Wrapped::InstanceMethod(name, method, napi_default_jsproperty));
}
}  // namespace

NapiCanvasRenderingContext2D::NapiCanvasRenderingContext2D(const CallbackInfo& info, bool skip_init_as_base)
    : BridgeBase(info) {
  // If this is a base class or created by native, skip initialization since
  // impl side needs to have control over the construction of the impl object.
  if (skip_init_as_base || (info.Length() == 1 && info[0].IsExternal())) {
    return;
  }
  ExceptionMessage::IllegalConstructor(info.Env(), InterfaceName());
  return;
}

CanvasRenderingContext2D* NapiCanvasRenderingContext2D::ToImplUnsafe() {
  return impl_.get();
}

// static
Object NapiCanvasRenderingContext2D::Wrap(std::unique_ptr<CanvasRenderingContext2D> impl, Napi::Env env) {
  DCHECK(impl);
  auto obj = Constructor(env).New({Napi::External::New(env, nullptr, nullptr, nullptr)});
  ObjectWrap<NapiCanvasRenderingContext2D>::Unwrap(obj)->Init(std::move(impl));
  return obj;
}

void NapiCanvasRenderingContext2D::Init(std::unique_ptr<CanvasRenderingContext2D> impl) {
  DCHECK(impl);
  DCHECK(!impl_);

  impl_ = std::move(impl);
  // We only associate and call OnWrapped() once, when we init the root base.
  impl_->AssociateWithWrapper(this);

  uintptr_t ptr = reinterpret_cast<uintptr_t>(&*impl_);
  uint32_t ptr_high = static_cast<uint32_t>((uint64_t)ptr >> 32);
  uint32_t ptr_low = static_cast<uint32_t>(ptr & 0xffffffff);
  JsObject().Set("_ptr_high", ptr_high);
  JsObject().Set("_ptr_low", ptr_low);
}

Value NapiCanvasRenderingContext2D::CanvasAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  auto* wrapped = impl_->GetCanvas();

  // Impl needs to take care of object ownership.
  DCHECK(wrapped->IsWrapped());
  return wrapped->JsObject();
}

Value NapiCanvasRenderingContext2D::GlobalAlphaAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetGlobalAlpha());
}

void NapiCanvasRenderingContext2D::GlobalAlphaAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetGlobalAlpha(NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(value));
}

Value NapiCanvasRenderingContext2D::GlobalCompositeOperationAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return String::New(info.Env(), impl_->GetGlobalCompositeOperation());
}

void NapiCanvasRenderingContext2D::GlobalCompositeOperationAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetGlobalCompositeOperation(NativeValueTraits<IDLString>::NativeValue(value));
}

Value NapiCanvasRenderingContext2D::ImageSmoothingEnabledAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Napi::Boolean::New(info.Env(), impl_->GetImageSmoothingEnabled());
}

void NapiCanvasRenderingContext2D::ImageSmoothingEnabledAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetImageSmoothingEnabled(NativeValueTraits<IDLBoolean>::NativeValue(value));
}

Value NapiCanvasRenderingContext2D::ImageSmoothingQualityAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return String::New(info.Env(), impl_->GetImageSmoothingQuality());
}

void NapiCanvasRenderingContext2D::ImageSmoothingQualityAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  do {
    if (value.IsString()) {
      if (value.As<String>().Utf8Value() == "low") break;
      if (value.As<String>().Utf8Value() == "medium") break;
      if (value.As<String>().Utf8Value() == "high") break;
    }
    ExceptionMessage::InvalidType(info.Env(), "ImageSmoothingQuality setter", "ImageSmoothingQuality");
    return;
  } while (false);
  impl_->SetImageSmoothingQuality(value.As<String>().Utf8Value());
}

Value NapiCanvasRenderingContext2D::StrokeStyleAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return impl_->GetStrokeStyle();
}

void NapiCanvasRenderingContext2D::StrokeStyleAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  if (value.IsObject() && value.As<Object>().InstanceOf(NapiCanvasGradient::Constructor(info.Env()))) {
    impl_->SetStrokeStyle(ObjectWrap<NapiCanvasGradient>::Unwrap(info[0].As<Object>())->ToImplUnsafe());
    return;
  }
  if (value.IsObject() && value.As<Object>().InstanceOf(NapiCanvasPattern::Constructor(info.Env()))) {
    impl_->SetStrokeStyle(ObjectWrap<NapiCanvasPattern>::Unwrap(info[0].As<Object>())->ToImplUnsafe());
    return;
  }
  if (true/* converting to string */) {
    impl_->SetStrokeStyle(info[0].ToString());
    return;
  }
}

Value NapiCanvasRenderingContext2D::FillStyleAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return impl_->GetFillStyle();
}

void NapiCanvasRenderingContext2D::FillStyleAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  if (value.IsObject() && value.As<Object>().InstanceOf(NapiCanvasGradient::Constructor(info.Env()))) {
    impl_->SetFillStyle(ObjectWrap<NapiCanvasGradient>::Unwrap(info[0].As<Object>())->ToImplUnsafe());
    return;
  }
  if (value.IsObject() && value.As<Object>().InstanceOf(NapiCanvasPattern::Constructor(info.Env()))) {
    impl_->SetFillStyle(ObjectWrap<NapiCanvasPattern>::Unwrap(info[0].As<Object>())->ToImplUnsafe());
    return;
  }
  if (true/* converting to string */) {
    impl_->SetFillStyle(info[0].ToString());
    return;
  }
}

Value NapiCanvasRenderingContext2D::ShadowOffsetXAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetShadowOffsetX());
}

void NapiCanvasRenderingContext2D::ShadowOffsetXAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetShadowOffsetX(NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(value));
}

Value NapiCanvasRenderingContext2D::ShadowOffsetYAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetShadowOffsetY());
}

void NapiCanvasRenderingContext2D::ShadowOffsetYAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetShadowOffsetY(NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(value));
}

Value NapiCanvasRenderingContext2D::ShadowBlurAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetShadowBlur());
}

void NapiCanvasRenderingContext2D::ShadowBlurAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetShadowBlur(NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(value));
}

Value NapiCanvasRenderingContext2D::ShadowColorAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return String::New(info.Env(), impl_->GetShadowColor());
}

void NapiCanvasRenderingContext2D::ShadowColorAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetShadowColor(NativeValueTraits<IDLString>::NativeValue(value));
}

Value NapiCanvasRenderingContext2D::LineWidthAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetLineWidth());
}

void NapiCanvasRenderingContext2D::LineWidthAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetLineWidth(NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(value));
}

Value NapiCanvasRenderingContext2D::LineCapAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return String::New(info.Env(), impl_->GetLineCap());
}

void NapiCanvasRenderingContext2D::LineCapAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetLineCap(NativeValueTraits<IDLString>::NativeValue(value));
}

Value NapiCanvasRenderingContext2D::LineJoinAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return String::New(info.Env(), impl_->GetLineJoin());
}

void NapiCanvasRenderingContext2D::LineJoinAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetLineJoin(NativeValueTraits<IDLString>::NativeValue(value));
}

Value NapiCanvasRenderingContext2D::MiterLimitAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetMiterLimit());
}

void NapiCanvasRenderingContext2D::MiterLimitAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetMiterLimit(NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(value));
}

Value NapiCanvasRenderingContext2D::LineDashOffsetAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetLineDashOffset());
}

void NapiCanvasRenderingContext2D::LineDashOffsetAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetLineDashOffset(NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(value));
}

Value NapiCanvasRenderingContext2D::FontAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return String::New(info.Env(), impl_->GetFont());
}

void NapiCanvasRenderingContext2D::FontAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetFont(NativeValueTraits<IDLString>::NativeValue(value));
}

Value NapiCanvasRenderingContext2D::TextAlignAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return String::New(info.Env(), impl_->GetTextAlign());
}

void NapiCanvasRenderingContext2D::TextAlignAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetTextAlign(NativeValueTraits<IDLString>::NativeValue(value));
}

Value NapiCanvasRenderingContext2D::TextBaselineAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return String::New(info.Env(), impl_->GetTextBaseline());
}

void NapiCanvasRenderingContext2D::TextBaselineAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetTextBaseline(NativeValueTraits<IDLString>::NativeValue(value));
}

Value NapiCanvasRenderingContext2D::SaveMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  impl_->Save();
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::RestoreMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  impl_->Restore();
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::ScaleMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "Scale", "2");
    return Value();
  }

  auto arg0_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  auto arg1_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  impl_->Scale(arg0_x, arg1_y);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::RotateMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "Rotate", "1");
    return Value();
  }

  auto arg0_angle = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  impl_->Rotate(arg0_angle);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::TranslateMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "Translate", "2");
    return Value();
  }

  auto arg0_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  auto arg1_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  impl_->Translate(arg0_x, arg1_y);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::TransformMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 6) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "Transform", "6");
    return Value();
  }

  auto arg0_a = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  auto arg1_b = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  auto arg2_c = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 2);

  auto arg3_d = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 3);

  auto arg4_e = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 4);

  auto arg5_f = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 5);

  impl_->Transform(arg0_a, arg1_b, arg2_c, arg3_d, arg4_e, arg5_f);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::SetTransformMethodOverload1(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 6) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "SetTransform", "6");
    return Value();
  }

  auto arg0_a = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  auto arg1_b = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  auto arg2_c = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 2);

  auto arg3_d = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 3);

  auto arg4_e = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 4);

  auto arg5_f = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 5);

  impl_->SetTransform(arg0_a, arg1_b, arg2_c, arg3_d, arg4_e, arg5_f);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::SetTransformMethodOverload2(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() <= 0) {
    impl_->SetTransform();
    return info.Env().Undefined();
  }

  auto arg0_transform = NativeValueTraits<IDLDictionary<DOMMatrix2DInit>>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->SetTransform(std::move(arg0_transform));
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::GetTransformMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  auto&& result = impl_->GetTransform();
  return result ? (result->IsWrapped() ? result->JsObject() : NapiDOMMatrix::Wrap(std::unique_ptr<DOMMatrix>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiCanvasRenderingContext2D::ResetTransformMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  impl_->ResetTransform();
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::CreateLinearGradientMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 4) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "CreateLinearGradient", "4");
    return Value();
  }

  auto arg0_x0 = NativeValueTraits<IDLDouble>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto arg1_y0 = NativeValueTraits<IDLDouble>::NativeValue(info, 1);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto arg2_x1 = NativeValueTraits<IDLDouble>::NativeValue(info, 2);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto arg3_y1 = NativeValueTraits<IDLDouble>::NativeValue(info, 3);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto&& result = impl_->CreateLinearGradient(arg0_x0, arg1_y0, arg2_x1, arg3_y1);
  return result ? (result->IsWrapped() ? result->JsObject() : NapiCanvasGradient::Wrap(std::unique_ptr<CanvasGradient>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiCanvasRenderingContext2D::CreateRadialGradientMethod(const CallbackInfo& info) {
  DCHECK(impl_);
  piper::ExceptionState exception_state(info.Env());

  if (info.Length() < 6) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "CreateRadialGradient", "6");
    return Value();
  }

  auto arg0_x0 = NativeValueTraits<IDLDouble>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto arg1_y0 = NativeValueTraits<IDLDouble>::NativeValue(info, 1);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto arg2_r0 = NativeValueTraits<IDLDouble>::NativeValue(info, 2);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto arg3_x1 = NativeValueTraits<IDLDouble>::NativeValue(info, 3);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto arg4_y1 = NativeValueTraits<IDLDouble>::NativeValue(info, 4);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto arg5_r1 = NativeValueTraits<IDLDouble>::NativeValue(info, 5);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto&& result = impl_->CreateRadialGradient(exception_state, arg0_x0, arg1_y0, arg2_r0, arg3_x1, arg4_y1, arg5_r1);
  if (exception_state.HadException()) {
    return Value();
  }
  return result ? (result->IsWrapped() ? result->JsObject() : NapiCanvasGradient::Wrap(std::unique_ptr<CanvasGradient>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiCanvasRenderingContext2D::CreatePatternMethod(const CallbackInfo& info) {
  DCHECK(impl_);
  piper::ExceptionState exception_state(info.Env());

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "CreatePattern", "2");
    return Value();
  }

  do {
    if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiCanvasElement::Constructor(info.Env()))) break;
    if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiImageElement::Constructor(info.Env()))) break;
    if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiVideoElement::Constructor(info.Env()))) break;
    ExceptionMessage::InvalidType(info.Env(), "argument 0", "['CanvasElement*', 'ImageElement*', 'VideoElement*']");
    return Value();
  } while (false);
  size_t union_branch = 0;
  CanvasElement* arg0_image_CanvasElement = nullptr;
  if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiCanvasElement::Constructor(info.Env()))) {
    arg0_image_CanvasElement = ObjectWrap<NapiCanvasElement>::Unwrap(info[0].As<Object>())->ToImplUnsafe();
    union_branch = 1;
  }
  ImageElement* arg0_image_ImageElement = nullptr;
  if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiImageElement::Constructor(info.Env()))) {
    arg0_image_ImageElement = ObjectWrap<NapiImageElement>::Unwrap(info[0].As<Object>())->ToImplUnsafe();
    union_branch = 2;
  }
  VideoElement* arg0_image_VideoElement = nullptr;
  if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiVideoElement::Constructor(info.Env()))) {
    arg0_image_VideoElement = ObjectWrap<NapiVideoElement>::Unwrap(info[0].As<Object>())->ToImplUnsafe();
    union_branch = 3;
  }

  auto arg1_repetitionType = NativeValueTraits<IDLString>::NativeValue(info, 1);

  switch (union_branch) {
    case 1: {
      auto&& result = impl_->CreatePattern(exception_state, arg0_image_CanvasElement, std::move(arg1_repetitionType));
      if (exception_state.HadException()) {
        return Value();
      }
      if (!result) return info.Env().Null();
      return result ? (result->IsWrapped() ? result->JsObject() : NapiCanvasPattern::Wrap(std::unique_ptr<CanvasPattern>(std::move(result)), info.Env())) : info.Env().Null();
    }
    case 2: {
      auto&& result = impl_->CreatePattern(exception_state, arg0_image_ImageElement, std::move(arg1_repetitionType));
      if (exception_state.HadException()) {
        return Value();
      }
      if (!result) return info.Env().Null();
      return result ? (result->IsWrapped() ? result->JsObject() : NapiCanvasPattern::Wrap(std::unique_ptr<CanvasPattern>(std::move(result)), info.Env())) : info.Env().Null();
    }
    case 3: {
      auto&& result = impl_->CreatePattern(exception_state, arg0_image_VideoElement, std::move(arg1_repetitionType));
      if (exception_state.HadException()) {
        return Value();
      }
      if (!result) return info.Env().Null();
      return result ? (result->IsWrapped() ? result->JsObject() : NapiCanvasPattern::Wrap(std::unique_ptr<CanvasPattern>(std::move(result)), info.Env())) : info.Env().Null();
    }
    default: {
      ExceptionMessage::FailedToCallOverloadExpecting(info.Env(), "CreatePattern()", "['CanvasElement*', 'ImageElement*', 'VideoElement*']");
      return Value();
    }
  }
}

Value NapiCanvasRenderingContext2D::ClearRectMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 4) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "ClearRect", "4");
    return Value();
  }

  auto arg0_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  auto arg1_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  auto arg2_width = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 2);

  auto arg3_height = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 3);

  impl_->ClearRect(arg0_x, arg1_y, arg2_width, arg3_height);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::FillRectMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 4) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "FillRect", "4");
    return Value();
  }

  auto arg0_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  auto arg1_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  auto arg2_width = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 2);

  auto arg3_height = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 3);

  impl_->FillRect(arg0_x, arg1_y, arg2_width, arg3_height);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::StrokeRectMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 4) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "StrokeRect", "4");
    return Value();
  }

  auto arg0_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  auto arg1_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  auto arg2_width = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 2);

  auto arg3_height = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 3);

  impl_->StrokeRect(arg0_x, arg1_y, arg2_width, arg3_height);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::BeginPathMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  impl_->BeginPath();
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::FillMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() <= 0) {
    impl_->Fill();
    return info.Env().Undefined();
  }

  do {
    if (info[0].IsString()) {
      if (info[0].As<String>().Utf8Value() == "nonzero") break;
      if (info[0].As<String>().Utf8Value() == "evenodd") break;
    }
    ExceptionMessage::InvalidType(info.Env(), "argument 0", "CanvasFillRule");
    return info.Env().Undefined();
  } while (false);
  std::string arg0_winding;
  arg0_winding = info[0].As<String>().Utf8Value();

  impl_->Fill(arg0_winding);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::StrokeMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  impl_->Stroke();
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::ClipMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() <= 0) {
    impl_->Clip();
    return info.Env().Undefined();
  }

  do {
    if (info[0].IsString()) {
      if (info[0].As<String>().Utf8Value() == "nonzero") break;
      if (info[0].As<String>().Utf8Value() == "evenodd") break;
    }
    ExceptionMessage::InvalidType(info.Env(), "argument 0", "CanvasFillRule");
    return info.Env().Undefined();
  } while (false);
  std::string arg0_winding;
  arg0_winding = info[0].As<String>().Utf8Value();

  impl_->Clip(arg0_winding);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::IsPointInPathMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "IsPointInPath", "2");
    return Value();
  }

  auto arg0_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  auto arg1_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  if (info.Length() <= 2) {
    auto&& result = impl_->IsPointInPath(arg0_x, arg1_y);
    return Napi::Boolean::New(info.Env(), result);
  }

  do {
    if (info[2].IsString()) {
      if (info[2].As<String>().Utf8Value() == "nonzero") break;
      if (info[2].As<String>().Utf8Value() == "evenodd") break;
    }
    ExceptionMessage::InvalidType(info.Env(), "argument 2", "CanvasFillRule");
    return Value();
  } while (false);
  std::string arg2_winding;
  arg2_winding = info[2].As<String>().Utf8Value();

  auto&& result = impl_->IsPointInPath(arg0_x, arg1_y, arg2_winding);
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiCanvasRenderingContext2D::IsPointInStrokeMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "IsPointInStroke", "2");
    return Value();
  }

  auto arg0_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  auto arg1_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  auto&& result = impl_->IsPointInStroke(arg0_x, arg1_y);
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiCanvasRenderingContext2D::FillTextMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 3) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "FillText", "3");
    return Value();
  }

  auto arg0_text = NativeValueTraits<IDLString>::NativeValue(info, 0);

  auto arg1_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  auto arg2_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 2);

  if (info.Length() <= 3) {
    impl_->FillText(std::move(arg0_text), arg1_x, arg2_y);
    return info.Env().Undefined();
  }

  auto arg3_maxWidth = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 3);

  impl_->FillText(std::move(arg0_text), arg1_x, arg2_y, arg3_maxWidth);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::StrokeTextMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 3) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "StrokeText", "3");
    return Value();
  }

  auto arg0_text = NativeValueTraits<IDLString>::NativeValue(info, 0);

  auto arg1_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  auto arg2_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 2);

  if (info.Length() <= 3) {
    impl_->StrokeText(std::move(arg0_text), arg1_x, arg2_y);
    return info.Env().Undefined();
  }

  auto arg3_maxWidth = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 3);

  impl_->StrokeText(std::move(arg0_text), arg1_x, arg2_y, arg3_maxWidth);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::MeasureTextMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "MeasureText", "1");
    return Value();
  }

  auto arg0_text = NativeValueTraits<IDLString>::NativeValue(info, 0);

  auto&& result = impl_->MeasureText(std::move(arg0_text));
  return result ? (result->IsWrapped() ? result->JsObject() : NapiTextMetrics::Wrap(std::unique_ptr<TextMetrics>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiCanvasRenderingContext2D::DrawImageMethodOverload1(const CallbackInfo& info) {
  DCHECK(impl_);
  piper::ExceptionState exception_state(info.Env());

  if (info.Length() < 3) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "DrawImage", "3");
    return Value();
  }

  do {
    if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiCanvasElement::Constructor(info.Env()))) break;
    if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiImageElement::Constructor(info.Env()))) break;
    if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiVideoElement::Constructor(info.Env()))) break;
    ExceptionMessage::InvalidType(info.Env(), "argument 0", "['CanvasElement*', 'ImageElement*', 'VideoElement*']");
    return info.Env().Undefined();
  } while (false);
  size_t union_branch = 0;
  CanvasElement* arg0_image_CanvasElement = nullptr;
  if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiCanvasElement::Constructor(info.Env()))) {
    arg0_image_CanvasElement = ObjectWrap<NapiCanvasElement>::Unwrap(info[0].As<Object>())->ToImplUnsafe();
    union_branch = 1;
  }
  ImageElement* arg0_image_ImageElement = nullptr;
  if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiImageElement::Constructor(info.Env()))) {
    arg0_image_ImageElement = ObjectWrap<NapiImageElement>::Unwrap(info[0].As<Object>())->ToImplUnsafe();
    union_branch = 2;
  }
  VideoElement* arg0_image_VideoElement = nullptr;
  if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiVideoElement::Constructor(info.Env()))) {
    arg0_image_VideoElement = ObjectWrap<NapiVideoElement>::Unwrap(info[0].As<Object>())->ToImplUnsafe();
    union_branch = 3;
  }

  auto arg1_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  auto arg2_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 2);

  switch (union_branch) {
    case 1: {
      impl_->DrawImage(exception_state, arg0_image_CanvasElement, arg1_x, arg2_y);
      return info.Env().Undefined();
    }
    case 2: {
      impl_->DrawImage(exception_state, arg0_image_ImageElement, arg1_x, arg2_y);
      return info.Env().Undefined();
    }
    case 3: {
      impl_->DrawImage(exception_state, arg0_image_VideoElement, arg1_x, arg2_y);
      return info.Env().Undefined();
    }
    default: {
      ExceptionMessage::FailedToCallOverloadExpecting(info.Env(), "DrawImage()", "['CanvasElement*', 'ImageElement*', 'VideoElement*']");
      return Value();
    }
  }
}

Value NapiCanvasRenderingContext2D::DrawImageMethodOverload2(const CallbackInfo& info) {
  DCHECK(impl_);
  piper::ExceptionState exception_state(info.Env());

  if (info.Length() < 5) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "DrawImage", "5");
    return Value();
  }

  do {
    if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiCanvasElement::Constructor(info.Env()))) break;
    if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiImageElement::Constructor(info.Env()))) break;
    if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiVideoElement::Constructor(info.Env()))) break;
    ExceptionMessage::InvalidType(info.Env(), "argument 0", "['CanvasElement*', 'ImageElement*', 'VideoElement*']");
    return info.Env().Undefined();
  } while (false);
  size_t union_branch = 0;
  CanvasElement* arg0_image_CanvasElement = nullptr;
  if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiCanvasElement::Constructor(info.Env()))) {
    arg0_image_CanvasElement = ObjectWrap<NapiCanvasElement>::Unwrap(info[0].As<Object>())->ToImplUnsafe();
    union_branch = 1;
  }
  ImageElement* arg0_image_ImageElement = nullptr;
  if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiImageElement::Constructor(info.Env()))) {
    arg0_image_ImageElement = ObjectWrap<NapiImageElement>::Unwrap(info[0].As<Object>())->ToImplUnsafe();
    union_branch = 2;
  }
  VideoElement* arg0_image_VideoElement = nullptr;
  if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiVideoElement::Constructor(info.Env()))) {
    arg0_image_VideoElement = ObjectWrap<NapiVideoElement>::Unwrap(info[0].As<Object>())->ToImplUnsafe();
    union_branch = 3;
  }

  auto arg1_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  auto arg2_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 2);

  auto arg3_width = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 3);

  auto arg4_height = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 4);

  switch (union_branch) {
    case 1: {
      impl_->DrawImage(exception_state, arg0_image_CanvasElement, arg1_x, arg2_y, arg3_width, arg4_height);
      return info.Env().Undefined();
    }
    case 2: {
      impl_->DrawImage(exception_state, arg0_image_ImageElement, arg1_x, arg2_y, arg3_width, arg4_height);
      return info.Env().Undefined();
    }
    case 3: {
      impl_->DrawImage(exception_state, arg0_image_VideoElement, arg1_x, arg2_y, arg3_width, arg4_height);
      return info.Env().Undefined();
    }
    default: {
      ExceptionMessage::FailedToCallOverloadExpecting(info.Env(), "DrawImage()", "['CanvasElement*', 'ImageElement*', 'VideoElement*']");
      return Value();
    }
  }
}

Value NapiCanvasRenderingContext2D::DrawImageMethodOverload3(const CallbackInfo& info) {
  DCHECK(impl_);
  piper::ExceptionState exception_state(info.Env());

  if (info.Length() < 9) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "DrawImage", "9");
    return Value();
  }

  do {
    if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiCanvasElement::Constructor(info.Env()))) break;
    if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiImageElement::Constructor(info.Env()))) break;
    if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiVideoElement::Constructor(info.Env()))) break;
    ExceptionMessage::InvalidType(info.Env(), "argument 0", "['CanvasElement*', 'ImageElement*', 'VideoElement*']");
    return info.Env().Undefined();
  } while (false);
  size_t union_branch = 0;
  CanvasElement* arg0_image_CanvasElement = nullptr;
  if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiCanvasElement::Constructor(info.Env()))) {
    arg0_image_CanvasElement = ObjectWrap<NapiCanvasElement>::Unwrap(info[0].As<Object>())->ToImplUnsafe();
    union_branch = 1;
  }
  ImageElement* arg0_image_ImageElement = nullptr;
  if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiImageElement::Constructor(info.Env()))) {
    arg0_image_ImageElement = ObjectWrap<NapiImageElement>::Unwrap(info[0].As<Object>())->ToImplUnsafe();
    union_branch = 2;
  }
  VideoElement* arg0_image_VideoElement = nullptr;
  if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiVideoElement::Constructor(info.Env()))) {
    arg0_image_VideoElement = ObjectWrap<NapiVideoElement>::Unwrap(info[0].As<Object>())->ToImplUnsafe();
    union_branch = 3;
  }

  auto arg1_sx = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  auto arg2_sy = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 2);

  auto arg3_sw = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 3);

  auto arg4_sh = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 4);

  auto arg5_dx = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 5);

  auto arg6_dy = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 6);

  auto arg7_dw = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 7);

  auto arg8_dh = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 8);

  switch (union_branch) {
    case 1: {
      impl_->DrawImage(exception_state, arg0_image_CanvasElement, arg1_sx, arg2_sy, arg3_sw, arg4_sh, arg5_dx, arg6_dy, arg7_dw, arg8_dh);
      return info.Env().Undefined();
    }
    case 2: {
      impl_->DrawImage(exception_state, arg0_image_ImageElement, arg1_sx, arg2_sy, arg3_sw, arg4_sh, arg5_dx, arg6_dy, arg7_dw, arg8_dh);
      return info.Env().Undefined();
    }
    case 3: {
      impl_->DrawImage(exception_state, arg0_image_VideoElement, arg1_sx, arg2_sy, arg3_sw, arg4_sh, arg5_dx, arg6_dy, arg7_dw, arg8_dh);
      return info.Env().Undefined();
    }
    default: {
      ExceptionMessage::FailedToCallOverloadExpecting(info.Env(), "DrawImage()", "['CanvasElement*', 'ImageElement*', 'VideoElement*']");
      return Value();
    }
  }
}

Value NapiCanvasRenderingContext2D::CreateImageDataMethodOverload1(const CallbackInfo& info) {
  DCHECK(impl_);
  piper::ExceptionState exception_state(info.Env());

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "CreateImageData", "1");
    return Value();
  }

  auto arg0_imagedata = NativeValueTraits<NapiImageData>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto&& result = impl_->CreateImageData(exception_state, arg0_imagedata);
  if (exception_state.HadException()) {
    return Value();
  }
  return result ? (result->IsWrapped() ? result->JsObject() : NapiImageData::Wrap(std::unique_ptr<ImageData>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiCanvasRenderingContext2D::CreateImageDataMethodOverload2(const CallbackInfo& info) {
  DCHECK(impl_);
  piper::ExceptionState exception_state(info.Env());

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "CreateImageData", "2");
    return Value();
  }

  auto arg0_sw = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_sh = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto&& result = impl_->CreateImageData(exception_state, arg0_sw, arg1_sh);
  if (exception_state.HadException()) {
    return Value();
  }
  return result ? (result->IsWrapped() ? result->JsObject() : NapiImageData::Wrap(std::unique_ptr<ImageData>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiCanvasRenderingContext2D::GetImageDataMethod(const CallbackInfo& info) {
  DCHECK(impl_);
  piper::ExceptionState exception_state(info.Env());

  if (info.Length() < 4) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetImageData", "4");
    return Value();
  }

  auto arg0_sx = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_sy = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_sw = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto arg3_sh = NativeValueTraits<IDLNumber>::NativeValue(info, 3);

  auto&& result = impl_->GetImageData(exception_state, arg0_sx, arg1_sy, arg2_sw, arg3_sh);
  if (exception_state.HadException()) {
    return Value();
  }
  return result ? (result->IsWrapped() ? result->JsObject() : NapiImageData::Wrap(std::unique_ptr<ImageData>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiCanvasRenderingContext2D::PutImageDataMethodOverload1(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 3) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "PutImageData", "3");
    return Value();
  }

  auto arg0_imagedata = NativeValueTraits<NapiImageData>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  auto arg1_dx = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_dy = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  impl_->PutImageData(arg0_imagedata, arg1_dx, arg2_dy);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::PutImageDataMethodOverload2(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 7) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "PutImageData", "7");
    return Value();
  }

  auto arg0_imagedata = NativeValueTraits<NapiImageData>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  auto arg1_dx = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_dy = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto arg3_dirtyX = NativeValueTraits<IDLNumber>::NativeValue(info, 3);

  auto arg4_dirtyY = NativeValueTraits<IDLNumber>::NativeValue(info, 4);

  auto arg5_dirtyWidth = NativeValueTraits<IDLNumber>::NativeValue(info, 5);

  auto arg6_dirtyHeight = NativeValueTraits<IDLNumber>::NativeValue(info, 6);

  impl_->PutImageData(arg0_imagedata, arg1_dx, arg2_dy, arg3_dirtyX, arg4_dirtyY, arg5_dirtyWidth, arg6_dirtyHeight);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::SetLineDashMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "SetLineDash", "1");
    return Value();
  }

  auto arg0_dash = NativeValueTraits<IDLSequence<IDLUnrestrictedDouble>>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->SetLineDash(std::move(arg0_dash));
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::GetLineDashMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  const auto& vector_result = impl_->GetLineDash();
  auto result = Array::New(info.Env(), vector_result.size());
  for (size_t i = 0; i < vector_result.size(); ++i) {
    result[i] = Number::New(info.Env(), vector_result[i]);
  }
  return result;
}

Value NapiCanvasRenderingContext2D::ClosePathMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  impl_->ClosePath();
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::MoveToMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "MoveTo", "2");
    return Value();
  }

  auto arg0_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  auto arg1_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  impl_->MoveTo(arg0_x, arg1_y);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::LineToMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "LineTo", "2");
    return Value();
  }

  auto arg0_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  auto arg1_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  impl_->LineTo(arg0_x, arg1_y);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::QuadraticCurveToMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 4) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "QuadraticCurveTo", "4");
    return Value();
  }

  auto arg0_cpx = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  auto arg1_cpy = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  auto arg2_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 2);

  auto arg3_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 3);

  impl_->QuadraticCurveTo(arg0_cpx, arg1_cpy, arg2_x, arg3_y);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::BezierCurveToMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 6) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "BezierCurveTo", "6");
    return Value();
  }

  auto arg0_cp1x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  auto arg1_cp1y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  auto arg2_cp2x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 2);

  auto arg3_cp2y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 3);

  auto arg4_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 4);

  auto arg5_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 5);

  impl_->BezierCurveTo(arg0_cp1x, arg1_cp1y, arg2_cp2x, arg3_cp2y, arg4_x, arg5_y);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::ArcToMethod(const CallbackInfo& info) {
  DCHECK(impl_);
  piper::ExceptionState exception_state(info.Env());

  if (info.Length() < 5) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "ArcTo", "5");
    return Value();
  }

  auto arg0_x1 = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  auto arg1_y1 = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  auto arg2_x2 = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 2);

  auto arg3_y2 = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 3);

  auto arg4_radius = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 4);

  impl_->ArcTo(exception_state, arg0_x1, arg1_y1, arg2_x2, arg3_y2, arg4_radius);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::RectMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 4) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "Rect", "4");
    return Value();
  }

  auto arg0_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  auto arg1_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  auto arg2_width = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 2);

  auto arg3_height = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 3);

  impl_->Rect(arg0_x, arg1_y, arg2_width, arg3_height);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::ArcMethod(const CallbackInfo& info) {
  DCHECK(impl_);
  piper::ExceptionState exception_state(info.Env());

  if (info.Length() < 5) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "Arc", "5");
    return Value();
  }

  auto arg0_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  auto arg1_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  auto arg2_radius = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 2);

  auto arg3_startAngle = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 3);

  auto arg4_endAngle = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 4);

  if (info.Length() <= 5) {
    impl_->Arc(exception_state, arg0_x, arg1_y, arg2_radius, arg3_startAngle, arg4_endAngle);
    return info.Env().Undefined();
  }

  auto arg5_anticlockwise = NativeValueTraits<IDLBoolean>::NativeValue(info, 5);

  impl_->Arc(exception_state, arg0_x, arg1_y, arg2_radius, arg3_startAngle, arg4_endAngle, arg5_anticlockwise);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::EllipseMethod(const CallbackInfo& info) {
  DCHECK(impl_);
  piper::ExceptionState exception_state(info.Env());

  if (info.Length() < 7) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "Ellipse", "7");
    return Value();
  }

  auto arg0_x = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 0);

  auto arg1_y = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 1);

  auto arg2_radiusX = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 2);

  auto arg3_radiusY = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 3);

  auto arg4_rotation = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 4);

  auto arg5_startAngle = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 5);

  auto arg6_endAngle = NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(info, 6);

  if (info.Length() <= 7) {
    impl_->Ellipse(exception_state, arg0_x, arg1_y, arg2_radiusX, arg3_radiusY, arg4_rotation, arg5_startAngle, arg6_endAngle);
    return info.Env().Undefined();
  }

  auto arg7_anticlockwise = NativeValueTraits<IDLBoolean>::NativeValue(info, 7);

  impl_->Ellipse(exception_state, arg0_x, arg1_y, arg2_radiusX, arg3_radiusY, arg4_rotation, arg5_startAngle, arg6_endAngle, arg7_anticlockwise);
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::SetTransformMethod(const CallbackInfo& info) {
  const size_t arg_count = std::min<size_t>(info.Length(), 6u);
  if (arg_count == 0) {
    return SetTransformMethodOverload2(info);
  }
  if (arg_count == 1) {
    return SetTransformMethodOverload2(info);
  }
  if (arg_count == 6) {
    return SetTransformMethodOverload1(info);
  }
  ExceptionMessage::FailedToCallOverload(info.Env(), "SetTransform()");
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::DrawImageMethod(const CallbackInfo& info) {
  const size_t arg_count = std::min<size_t>(info.Length(), 9u);
  if (arg_count == 3) {
    return DrawImageMethodOverload1(info);
  }
  if (arg_count == 5) {
    return DrawImageMethodOverload2(info);
  }
  if (arg_count == 9) {
    return DrawImageMethodOverload3(info);
  }
  ExceptionMessage::FailedToCallOverload(info.Env(), "DrawImage()");
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::CreateImageDataMethod(const CallbackInfo& info) {
  const size_t arg_count = std::min<size_t>(info.Length(), 2u);
  if (arg_count == 1) {
    return CreateImageDataMethodOverload1(info);
  }
  if (arg_count == 2) {
    return CreateImageDataMethodOverload2(info);
  }
  ExceptionMessage::FailedToCallOverload(info.Env(), "CreateImageData()");
  return info.Env().Undefined();
}

Value NapiCanvasRenderingContext2D::PutImageDataMethod(const CallbackInfo& info) {
  const size_t arg_count = std::min<size_t>(info.Length(), 7u);
  if (arg_count == 3) {
    return PutImageDataMethodOverload1(info);
  }
  if (arg_count == 7) {
    return PutImageDataMethodOverload2(info);
  }
  ExceptionMessage::FailedToCallOverload(info.Env(), "PutImageData()");
  return info.Env().Undefined();
}

// static
Napi::Class* NapiCanvasRenderingContext2D::Class(Napi::Env env) {
  auto* clazz = env.GetInstanceData<Napi::Class>(kCanvasRenderingContext2DClassID);
  if (clazz) {
    return clazz;
  }

  std::vector<Wrapped::PropertyDescriptor> props;

  // Attributes
  AddAttribute(props, "canvas",
               &NapiCanvasRenderingContext2D::CanvasAttributeGetter,
               nullptr
               );
  AddAttribute(props, "globalAlpha",
               &NapiCanvasRenderingContext2D::GlobalAlphaAttributeGetter,
               &NapiCanvasRenderingContext2D::GlobalAlphaAttributeSetter
               );
  AddAttribute(props, "globalCompositeOperation",
               &NapiCanvasRenderingContext2D::GlobalCompositeOperationAttributeGetter,
               &NapiCanvasRenderingContext2D::GlobalCompositeOperationAttributeSetter
               );
  AddAttribute(props, "imageSmoothingEnabled",
               &NapiCanvasRenderingContext2D::ImageSmoothingEnabledAttributeGetter,
               &NapiCanvasRenderingContext2D::ImageSmoothingEnabledAttributeSetter
               );
  AddAttribute(props, "imageSmoothingQuality",
               &NapiCanvasRenderingContext2D::ImageSmoothingQualityAttributeGetter,
               &NapiCanvasRenderingContext2D::ImageSmoothingQualityAttributeSetter
               );
  AddAttribute(props, "strokeStyle",
               &NapiCanvasRenderingContext2D::StrokeStyleAttributeGetter,
               &NapiCanvasRenderingContext2D::StrokeStyleAttributeSetter
               );
  AddAttribute(props, "fillStyle",
               &NapiCanvasRenderingContext2D::FillStyleAttributeGetter,
               &NapiCanvasRenderingContext2D::FillStyleAttributeSetter
               );
  AddAttribute(props, "shadowOffsetX",
               &NapiCanvasRenderingContext2D::ShadowOffsetXAttributeGetter,
               &NapiCanvasRenderingContext2D::ShadowOffsetXAttributeSetter
               );
  AddAttribute(props, "shadowOffsetY",
               &NapiCanvasRenderingContext2D::ShadowOffsetYAttributeGetter,
               &NapiCanvasRenderingContext2D::ShadowOffsetYAttributeSetter
               );
  AddAttribute(props, "shadowBlur",
               &NapiCanvasRenderingContext2D::ShadowBlurAttributeGetter,
               &NapiCanvasRenderingContext2D::ShadowBlurAttributeSetter
               );
  AddAttribute(props, "shadowColor",
               &NapiCanvasRenderingContext2D::ShadowColorAttributeGetter,
               &NapiCanvasRenderingContext2D::ShadowColorAttributeSetter
               );
  AddAttribute(props, "lineWidth",
               &NapiCanvasRenderingContext2D::LineWidthAttributeGetter,
               &NapiCanvasRenderingContext2D::LineWidthAttributeSetter
               );
  AddAttribute(props, "lineCap",
               &NapiCanvasRenderingContext2D::LineCapAttributeGetter,
               &NapiCanvasRenderingContext2D::LineCapAttributeSetter
               );
  AddAttribute(props, "lineJoin",
               &NapiCanvasRenderingContext2D::LineJoinAttributeGetter,
               &NapiCanvasRenderingContext2D::LineJoinAttributeSetter
               );
  AddAttribute(props, "miterLimit",
               &NapiCanvasRenderingContext2D::MiterLimitAttributeGetter,
               &NapiCanvasRenderingContext2D::MiterLimitAttributeSetter
               );
  AddAttribute(props, "lineDashOffset",
               &NapiCanvasRenderingContext2D::LineDashOffsetAttributeGetter,
               &NapiCanvasRenderingContext2D::LineDashOffsetAttributeSetter
               );
  AddAttribute(props, "font",
               &NapiCanvasRenderingContext2D::FontAttributeGetter,
               &NapiCanvasRenderingContext2D::FontAttributeSetter
               );
  AddAttribute(props, "textAlign",
               &NapiCanvasRenderingContext2D::TextAlignAttributeGetter,
               &NapiCanvasRenderingContext2D::TextAlignAttributeSetter
               );
  AddAttribute(props, "textBaseline",
               &NapiCanvasRenderingContext2D::TextBaselineAttributeGetter,
               &NapiCanvasRenderingContext2D::TextBaselineAttributeSetter
               );

  // Methods
  AddInstanceMethod(props, "save", &NapiCanvasRenderingContext2D::SaveMethod);
  AddInstanceMethod(props, "restore", &NapiCanvasRenderingContext2D::RestoreMethod);
  AddInstanceMethod(props, "scale", &NapiCanvasRenderingContext2D::ScaleMethod);
  AddInstanceMethod(props, "rotate", &NapiCanvasRenderingContext2D::RotateMethod);
  AddInstanceMethod(props, "translate", &NapiCanvasRenderingContext2D::TranslateMethod);
  AddInstanceMethod(props, "transform", &NapiCanvasRenderingContext2D::TransformMethod);
  AddInstanceMethod(props, "setTransform", &NapiCanvasRenderingContext2D::SetTransformMethod);
  AddInstanceMethod(props, "getTransform", &NapiCanvasRenderingContext2D::GetTransformMethod);
  AddInstanceMethod(props, "resetTransform", &NapiCanvasRenderingContext2D::ResetTransformMethod);
  AddInstanceMethod(props, "createLinearGradient", &NapiCanvasRenderingContext2D::CreateLinearGradientMethod);
  AddInstanceMethod(props, "createRadialGradient", &NapiCanvasRenderingContext2D::CreateRadialGradientMethod);
  AddInstanceMethod(props, "createPattern", &NapiCanvasRenderingContext2D::CreatePatternMethod);
  AddInstanceMethod(props, "clearRect", &NapiCanvasRenderingContext2D::ClearRectMethod);
  AddInstanceMethod(props, "fillRect", &NapiCanvasRenderingContext2D::FillRectMethod);
  AddInstanceMethod(props, "strokeRect", &NapiCanvasRenderingContext2D::StrokeRectMethod);
  AddInstanceMethod(props, "beginPath", &NapiCanvasRenderingContext2D::BeginPathMethod);
  AddInstanceMethod(props, "fill", &NapiCanvasRenderingContext2D::FillMethod);
  AddInstanceMethod(props, "stroke", &NapiCanvasRenderingContext2D::StrokeMethod);
  AddInstanceMethod(props, "clip", &NapiCanvasRenderingContext2D::ClipMethod);
  AddInstanceMethod(props, "isPointInPath", &NapiCanvasRenderingContext2D::IsPointInPathMethod);
  AddInstanceMethod(props, "isPointInStroke", &NapiCanvasRenderingContext2D::IsPointInStrokeMethod);
  AddInstanceMethod(props, "fillText", &NapiCanvasRenderingContext2D::FillTextMethod);
  AddInstanceMethod(props, "strokeText", &NapiCanvasRenderingContext2D::StrokeTextMethod);
  AddInstanceMethod(props, "measureText", &NapiCanvasRenderingContext2D::MeasureTextMethod);
  AddInstanceMethod(props, "drawImage", &NapiCanvasRenderingContext2D::DrawImageMethod);
  AddInstanceMethod(props, "createImageData", &NapiCanvasRenderingContext2D::CreateImageDataMethod);
  AddInstanceMethod(props, "getImageData", &NapiCanvasRenderingContext2D::GetImageDataMethod);
  AddInstanceMethod(props, "putImageData", &NapiCanvasRenderingContext2D::PutImageDataMethod);
  AddInstanceMethod(props, "setLineDash", &NapiCanvasRenderingContext2D::SetLineDashMethod);
  AddInstanceMethod(props, "getLineDash", &NapiCanvasRenderingContext2D::GetLineDashMethod);
  AddInstanceMethod(props, "closePath", &NapiCanvasRenderingContext2D::ClosePathMethod);
  AddInstanceMethod(props, "moveTo", &NapiCanvasRenderingContext2D::MoveToMethod);
  AddInstanceMethod(props, "lineTo", &NapiCanvasRenderingContext2D::LineToMethod);
  AddInstanceMethod(props, "quadraticCurveTo", &NapiCanvasRenderingContext2D::QuadraticCurveToMethod);
  AddInstanceMethod(props, "bezierCurveTo", &NapiCanvasRenderingContext2D::BezierCurveToMethod);
  AddInstanceMethod(props, "arcTo", &NapiCanvasRenderingContext2D::ArcToMethod);
  AddInstanceMethod(props, "rect", &NapiCanvasRenderingContext2D::RectMethod);
  AddInstanceMethod(props, "arc", &NapiCanvasRenderingContext2D::ArcMethod);
  AddInstanceMethod(props, "ellipse", &NapiCanvasRenderingContext2D::EllipseMethod);

  // Cache the class
  clazz = new Napi::Class(Wrapped::DefineClass(env, "CanvasRenderingContext2D", props));
  env.SetInstanceData<Napi::Class>(kCanvasRenderingContext2DClassID, clazz);
  return clazz;
}

// static
Function NapiCanvasRenderingContext2D::Constructor(Napi::Env env) {
  FunctionReference* ref = env.GetInstanceData<FunctionReference>(kCanvasRenderingContext2DConstructorID);
  if (ref) {
    return ref->Value();
  }

  // Cache the constructor for future use
  ref = new FunctionReference();
  ref->Reset(Class(env)->Get(env), 1);
  env.SetInstanceData<FunctionReference>(kCanvasRenderingContext2DConstructorID, ref);
  return ref->Value();
}

// static
void NapiCanvasRenderingContext2D::Install(Napi::Env env, Object& target) {
  if (target.Has("CanvasRenderingContext2D")) {
    return;
  }
  target.Set("CanvasRenderingContext2D", Constructor(env));
}

}  // namespace canvas
}  // namespace lynx
