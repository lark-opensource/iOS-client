// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/canvas/napi_webgl_rendering_context.h"

#include <vector>
#include <utility>

#include "canvas/webgl/webgl_rendering_context.h"
#include "jsbridge/bindings/canvas/napi_canvas_element.h"
#include "jsbridge/bindings/canvas/napi_image_element.h"
#include "jsbridge/bindings/canvas/napi_image_data.h"
#include "jsbridge/bindings/canvas/napi_video_element.h"
#include "jsbridge/bindings/canvas/napi_webgl_program.h"
#include "jsbridge/bindings/canvas/napi_webgl_shader.h"
#include "jsbridge/bindings/canvas/napi_webgl_buffer.h"
#include "jsbridge/bindings/canvas/napi_webgl_framebuffer.h"
#include "jsbridge/bindings/canvas/napi_webgl_renderbuffer.h"
#include "jsbridge/bindings/canvas/napi_webgl_texture.h"
#include "jsbridge/bindings/canvas/napi_webgl_active_info.h"
#include "jsbridge/bindings/canvas/napi_webgl_context_attributes.h"
#include "jsbridge/bindings/canvas/napi_webgl_uniform_location.h"
#include "jsbridge/bindings/canvas/napi_webgl_shader_precision_format.h"
#include "jsbridge/napi/array_buffer_view.h"
#include "jsbridge/bindings/canvas/napi_webgl_vertex_array_object_oes.h"
#include "jsbridge/napi/exception_message.h"
#include "jsbridge/napi/napi_base_wrap.h"

#include "third_party/fml/make_copyable.h"
#include "canvas/base/shared_vector.h"

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
const uint64_t kWebGLRenderingContextClassID = reinterpret_cast<uint64_t>(&kWebGLRenderingContextClassID);
const uint64_t kWebGLRenderingContextConstructorID = reinterpret_cast<uint64_t>(&kWebGLRenderingContextConstructorID);
const uint64_t kWebGLRenderingContextCommandBufferID = reinterpret_cast<uint64_t>(&kWebGLRenderingContextCommandBufferID);

using Wrapped = piper::NapiBaseWrapped<NapiWebGLRenderingContext>;
typedef Value (NapiWebGLRenderingContext::*InstanceCallback)(const CallbackInfo& info);
typedef void (NapiWebGLRenderingContext::*InstanceSetterCallback)(const CallbackInfo& info, const Value& value);

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

NapiWebGLRenderingContext::NapiWebGLRenderingContext(const CallbackInfo& info, bool skip_init_as_base)
    : BridgeBase(info) {
  // If this is a base class or created by native, skip initialization since
  // impl side needs to have control over the construction of the impl object.
  if (skip_init_as_base || (info.Length() == 1 && info[0].IsExternal())) {
    return;
  }
  ExceptionMessage::IllegalConstructor(info.Env(), InterfaceName());
  return;
}

NapiWebGLRenderingContext::~NapiWebGLRenderingContext() {
  LOGI("NapiWebGLRenderingContext Destrutor ") << this << (" WebGLRenderingContext ") << ToImplUnsafe();
  // If context is being teared down, skip flushing as the destruction order is
  // not guaranteed to align with ref (gl objects might go first although they
  // are referenced by command buffer).
  if (static_cast<napi_env>(Env())->rt) {
    FlushCommandBuffer(Env());
  }
}

WebGLRenderingContext* NapiWebGLRenderingContext::ToImplUnsafe() {
  return impl_.get();
}

// static
Object NapiWebGLRenderingContext::Wrap(std::unique_ptr<WebGLRenderingContext> impl, Napi::Env env) {
  DCHECK(impl);
  auto obj = Constructor(env).New({Napi::External::New(env, nullptr, nullptr, nullptr)});
  ObjectWrap<NapiWebGLRenderingContext>::Unwrap(obj)->Init(std::move(impl));
  return obj;
}

void NapiWebGLRenderingContext::Init(std::unique_ptr<WebGLRenderingContext> impl) {
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
  impl_->SetClientOnFrameCallback(fml::MakeCopyable([ref = Napi::Weak(JsObject())] () { OnFrame(ref); }));
}

Value NapiWebGLRenderingContext::CanvasAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  auto* wrapped = impl_->GetCanvas();

  // Impl needs to take care of object ownership.
  DCHECK(wrapped->IsWrapped());
  return wrapped->JsObject();
}

Value NapiWebGLRenderingContext::DrawingBufferWidthAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  return Number::New(info.Env(), impl_->GetDrawingBufferWidth());
}

Value NapiWebGLRenderingContext::DrawingBufferHeightAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  return Number::New(info.Env(), impl_->GetDrawingBufferHeight());
}

Value NapiWebGLRenderingContext::BindAttribLocationMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 3) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "BindAttribLocation", "3");
    return Value();
  }

  auto arg0_program = NativeValueTraits<NapiWebGLProgram>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  auto arg1_index = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_name = NativeValueTraits<IDLString>::NativeValue(info, 2);

  impl_->BindAttribLocation(arg0_program, arg1_index, std::move(arg2_name));
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::BufferDataMethodOverload1(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 3) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "BufferData", "3");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_size = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_usage = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  impl_->BufferData(arg0_target, arg1_size, arg2_usage);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::BufferDataMethodOverload2(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 3) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "BufferData", "3");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_data = NativeValueTraits<IDLArrayBufferView>::NativeValue(info, 1);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  auto arg2_usage = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  impl_->BufferData(arg0_target, arg1_data, arg2_usage);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::BufferDataMethodOverload3(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 3) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "BufferData", "3");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_data = NativeValueTraits<IDLNullable<IDLArrayBuffer>>::NativeValue(info, 1);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  auto arg2_usage = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  impl_->BufferData(arg0_target, arg1_data, arg2_usage);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::BufferSubDataMethodOverload1(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 3) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "BufferSubData", "3");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_offset = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_data = NativeValueTraits<IDLArrayBufferView>::NativeValue(info, 2);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->BufferSubData(arg0_target, arg1_offset, arg2_data);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::BufferSubDataMethodOverload2(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 3) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "BufferSubData", "3");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_offset = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_data = NativeValueTraits<IDLArrayBuffer>::NativeValue(info, 2);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->BufferSubData(arg0_target, arg1_offset, arg2_data);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::CheckFramebufferStatusMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "CheckFramebufferStatus", "1");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto&& result = impl_->CheckFramebufferStatus(arg0_target);
  return Number::New(info.Env(), result);
}

Value NapiWebGLRenderingContext::CompressedTexImage2DMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 7) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "CompressedTexImage2D", "7");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_level = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_internalformat = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto arg3_width = NativeValueTraits<IDLNumber>::NativeValue(info, 3);

  auto arg4_height = NativeValueTraits<IDLNumber>::NativeValue(info, 4);

  auto arg5_border = NativeValueTraits<IDLNumber>::NativeValue(info, 5);

  auto arg6_data = NativeValueTraits<IDLArrayBufferView>::NativeValue(info, 6);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->CompressedTexImage2D(arg0_target, arg1_level, arg2_internalformat, arg3_width, arg4_height, arg5_border, arg6_data);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::CompressedTexSubImage2DMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 8) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "CompressedTexSubImage2D", "8");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_level = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_xoffset = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto arg3_yoffset = NativeValueTraits<IDLNumber>::NativeValue(info, 3);

  auto arg4_width = NativeValueTraits<IDLNumber>::NativeValue(info, 4);

  auto arg5_height = NativeValueTraits<IDLNumber>::NativeValue(info, 5);

  auto arg6_format = NativeValueTraits<IDLNumber>::NativeValue(info, 6);

  auto arg7_data = NativeValueTraits<IDLArrayBufferView>::NativeValue(info, 7);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->CompressedTexSubImage2D(arg0_target, arg1_level, arg2_xoffset, arg3_yoffset, arg4_width, arg5_height, arg6_format, arg7_data);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::CreateBufferMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  auto&& result = impl_->CreateBuffer();
  return result ? (result->IsWrapped() ? result->JsObject() : NapiWebGLBuffer::Wrap(std::unique_ptr<WebGLBuffer>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiWebGLRenderingContext::CreateFramebufferMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  auto&& result = impl_->CreateFramebuffer();
  return result ? (result->IsWrapped() ? result->JsObject() : NapiWebGLFramebuffer::Wrap(std::unique_ptr<WebGLFramebuffer>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiWebGLRenderingContext::CreateProgramMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  auto&& result = impl_->CreateProgram();
  return result ? (result->IsWrapped() ? result->JsObject() : NapiWebGLProgram::Wrap(std::unique_ptr<WebGLProgram>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiWebGLRenderingContext::CreateRenderbufferMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  auto&& result = impl_->CreateRenderbuffer();
  return result ? (result->IsWrapped() ? result->JsObject() : NapiWebGLRenderbuffer::Wrap(std::unique_ptr<WebGLRenderbuffer>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiWebGLRenderingContext::CreateShaderMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "CreateShader", "1");
    return Value();
  }

  auto arg0_type = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto&& result = impl_->CreateShader(arg0_type);
  return result ? (result->IsWrapped() ? result->JsObject() : NapiWebGLShader::Wrap(std::unique_ptr<WebGLShader>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiWebGLRenderingContext::CreateTextureMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  auto&& result = impl_->CreateTexture();
  return result ? (result->IsWrapped() ? result->JsObject() : NapiWebGLTexture::Wrap(std::unique_ptr<WebGLTexture>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiWebGLRenderingContext::FinishMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  impl_->Finish();
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::GetActiveAttribMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetActiveAttrib", "2");
    return Value();
  }

  auto arg0_program = NativeValueTraits<NapiWebGLProgram>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto arg1_index = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto&& result = impl_->GetActiveAttrib(arg0_program, arg1_index);
  return result ? (result->IsWrapped() ? result->JsObject() : NapiWebGLActiveInfo::Wrap(std::unique_ptr<WebGLActiveInfo>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiWebGLRenderingContext::GetActiveUniformMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetActiveUniform", "2");
    return Value();
  }

  auto arg0_program = NativeValueTraits<NapiWebGLProgram>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto arg1_index = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto&& result = impl_->GetActiveUniform(arg0_program, arg1_index);
  return result ? (result->IsWrapped() ? result->JsObject() : NapiWebGLActiveInfo::Wrap(std::unique_ptr<WebGLActiveInfo>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiWebGLRenderingContext::GetAttachedShadersMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetAttachedShaders", "1");
    return Value();
  }

  auto arg0_program = NativeValueTraits<NapiWebGLProgram>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  const auto& vector_result = impl_->GetAttachedShaders(arg0_program);
  auto result = Array::New(info.Env(), vector_result.size());
  for (size_t i = 0; i < vector_result.size(); ++i) {
    result[static_cast<uint32_t>(i)] = (vector_result[i]->IsWrapped() ? vector_result[i]->JsObject() : NapiWebGLShader::Wrap(std::unique_ptr<WebGLShader>(std::move(vector_result[i])), info.Env()));
  }
  // TODO(yuyifei): This is actually not reached. Consider implementing Optional if necessary.
  if (result.IsEmpty()) return info.Env().Null();
  return result;
}

Value NapiWebGLRenderingContext::GetAttribLocationMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetAttribLocation", "2");
    return Value();
  }

  auto arg0_program = NativeValueTraits<NapiWebGLProgram>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto arg1_name = NativeValueTraits<IDLString>::NativeValue(info, 1);

  auto&& result = impl_->GetAttribLocation(arg0_program, std::move(arg1_name));
  return Number::New(info.Env(), result);
}

Value NapiWebGLRenderingContext::GetBufferParameterMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetBufferParameter", "2");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_pname = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto&& result = impl_->GetBufferParameter(arg0_target, arg1_pname);
  return result;
}

Value NapiWebGLRenderingContext::GetContextAttributesMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  auto&& result = impl_->GetContextAttributes();
  if (!result) return info.Env().Null();
  return result->ToJsObject(info.Env());
}

Value NapiWebGLRenderingContext::GetErrorMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  auto&& result = impl_->GetError();
  return Number::New(info.Env(), result);
}

Value NapiWebGLRenderingContext::GetExtensionMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetExtension", "1");
    return Value();
  }

  auto arg0_name = NativeValueTraits<IDLString>::NativeValue(info, 0);

  auto&& result = impl_->GetExtension(std::move(arg0_name));
  if (result.IsEmpty()) return info.Env().Null();
  return result;
}

Value NapiWebGLRenderingContext::GetFramebufferAttachmentParameterMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 3) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetFramebufferAttachmentParameter", "3");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_attachment = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_pname = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto&& result = impl_->GetFramebufferAttachmentParameter(arg0_target, arg1_attachment, arg2_pname);
  return result;
}

Value NapiWebGLRenderingContext::GetParameterMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetParameter", "1");
    return Value();
  }

  auto arg0_pname = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto&& result = impl_->GetParameter(arg0_pname);
  return result;
}

Value NapiWebGLRenderingContext::GetProgramParameterMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetProgramParameter", "2");
    return Value();
  }

  auto arg0_program = NativeValueTraits<NapiWebGLProgram>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto arg1_pname = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto&& result = impl_->GetProgramParameter(arg0_program, arg1_pname);
  return result;
}

Value NapiWebGLRenderingContext::GetProgramInfoLogMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetProgramInfoLog", "1");
    return Value();
  }

  auto arg0_program = NativeValueTraits<NapiWebGLProgram>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto&& result = impl_->GetProgramInfoLog(arg0_program);
  return String::New(info.Env(), result);
}

Value NapiWebGLRenderingContext::GetRenderbufferParameterMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetRenderbufferParameter", "2");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_pname = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto&& result = impl_->GetRenderbufferParameter(arg0_target, arg1_pname);
  return result;
}

Value NapiWebGLRenderingContext::GetShaderParameterMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetShaderParameter", "2");
    return Value();
  }

  auto arg0_shader = NativeValueTraits<NapiWebGLShader>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto arg1_pname = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto&& result = impl_->GetShaderParameter(arg0_shader, arg1_pname);
  return result;
}

Value NapiWebGLRenderingContext::GetShaderInfoLogMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetShaderInfoLog", "1");
    return Value();
  }

  auto arg0_shader = NativeValueTraits<NapiWebGLShader>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto&& result = impl_->GetShaderInfoLog(arg0_shader);
  return String::New(info.Env(), result);
}

Value NapiWebGLRenderingContext::GetShaderPrecisionFormatMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetShaderPrecisionFormat", "2");
    return Value();
  }

  auto arg0_shadertype = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_precisiontype = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto&& result = impl_->GetShaderPrecisionFormat(arg0_shadertype, arg1_precisiontype);
  return result ? (result->IsWrapped() ? result->JsObject() : NapiWebGLShaderPrecisionFormat::Wrap(std::unique_ptr<WebGLShaderPrecisionFormat>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiWebGLRenderingContext::GetShaderSourceMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetShaderSource", "1");
    return Value();
  }

  auto arg0_shader = NativeValueTraits<NapiWebGLShader>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto&& result = impl_->GetShaderSource(arg0_shader);
  return String::New(info.Env(), result);
}

Value NapiWebGLRenderingContext::GetSupportedExtensionsMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  const auto& vector_result = impl_->GetSupportedExtensions();
  auto result = Array::New(info.Env(), vector_result.size());
  for (size_t i = 0; i < vector_result.size(); ++i) {
    result[i] = String::New(info.Env(), vector_result[i]);
  }
  // TODO(yuyifei): This is actually not reached. Consider implementing Optional if necessary.
  if (result.IsEmpty()) return info.Env().Null();
  return result;
}

Value NapiWebGLRenderingContext::GetTexParameterMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetTexParameter", "2");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_pname = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto&& result = impl_->GetTexParameter(arg0_target, arg1_pname);
  return result;
}

Value NapiWebGLRenderingContext::GetUniformMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetUniform", "2");
    return Value();
  }

  auto arg0_program = NativeValueTraits<NapiWebGLProgram>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto arg1_location = NativeValueTraits<NapiWebGLUniformLocation>::NativeValue(info, 1);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto&& result = impl_->GetUniform(arg0_program, arg1_location);
  return result;
}

Value NapiWebGLRenderingContext::GetUniformLocationMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetUniformLocation", "2");
    return Value();
  }

  auto arg0_program = NativeValueTraits<NapiWebGLProgram>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto arg1_name = NativeValueTraits<IDLString>::NativeValue(info, 1);

  auto&& result = impl_->GetUniformLocation(arg0_program, std::move(arg1_name));
  return result ? (result->IsWrapped() ? result->JsObject() : NapiWebGLUniformLocation::Wrap(std::unique_ptr<WebGLUniformLocation>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiWebGLRenderingContext::GetVertexAttribMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetVertexAttrib", "2");
    return Value();
  }

  auto arg0_index = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_pname = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto&& result = impl_->GetVertexAttrib(arg0_index, arg1_pname);
  return result;
}

Value NapiWebGLRenderingContext::GetVertexAttribOffsetMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetVertexAttribOffset", "2");
    return Value();
  }

  auto arg0_index = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_pname = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto&& result = impl_->GetVertexAttribOffset(arg0_index, arg1_pname);
  return Number::New(info.Env(), result);
}

Value NapiWebGLRenderingContext::IsBufferMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "IsBuffer", "1");
    return Value();
  }

  auto arg0_buffer = NativeValueTraits<IDLNullable<NapiWebGLBuffer>>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto&& result = impl_->IsBuffer(arg0_buffer);
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiWebGLRenderingContext::IsContextLostMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  auto&& result = impl_->IsContextLost();
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiWebGLRenderingContext::IsEnabledMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "IsEnabled", "1");
    return Value();
  }

  auto arg0_cap = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto&& result = impl_->IsEnabled(arg0_cap);
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiWebGLRenderingContext::IsFramebufferMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "IsFramebuffer", "1");
    return Value();
  }

  auto arg0_framebuffer = NativeValueTraits<IDLNullable<NapiWebGLFramebuffer>>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto&& result = impl_->IsFramebuffer(arg0_framebuffer);
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiWebGLRenderingContext::IsProgramMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "IsProgram", "1");
    return Value();
  }

  auto arg0_program = NativeValueTraits<IDLNullable<NapiWebGLProgram>>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto&& result = impl_->IsProgram(arg0_program);
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiWebGLRenderingContext::IsRenderbufferMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "IsRenderbuffer", "1");
    return Value();
  }

  auto arg0_renderbuffer = NativeValueTraits<IDLNullable<NapiWebGLRenderbuffer>>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto&& result = impl_->IsRenderbuffer(arg0_renderbuffer);
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiWebGLRenderingContext::IsShaderMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "IsShader", "1");
    return Value();
  }

  auto arg0_shader = NativeValueTraits<IDLNullable<NapiWebGLShader>>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto&& result = impl_->IsShader(arg0_shader);
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiWebGLRenderingContext::IsTextureMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "IsTexture", "1");
    return Value();
  }

  auto arg0_texture = NativeValueTraits<IDLNullable<NapiWebGLTexture>>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto&& result = impl_->IsTexture(arg0_texture);
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiWebGLRenderingContext::ReadPixelsMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 7) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "ReadPixels", "7");
    return Value();
  }

  auto arg0_x = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_y = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_width = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto arg3_height = NativeValueTraits<IDLNumber>::NativeValue(info, 3);

  auto arg4_format = NativeValueTraits<IDLNumber>::NativeValue(info, 4);

  auto arg5_type = NativeValueTraits<IDLNumber>::NativeValue(info, 5);

  auto arg6_pixels = NativeValueTraits<IDLNullable<IDLArrayBufferView>>::NativeValue(info, 6);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->ReadPixels(arg0_x, arg1_y, arg2_width, arg3_height, arg4_format, arg5_type, arg6_pixels);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::ShaderSourceMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "ShaderSource", "2");
    return Value();
  }

  auto arg0_shader = NativeValueTraits<NapiWebGLShader>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  auto arg1_string = NativeValueTraits<IDLString>::NativeValue(info, 1);

  impl_->ShaderSource(arg0_shader, std::move(arg1_string));
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::TexImage2DMethodOverload1(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 9) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "TexImage2D", "9");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_level = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_internalformat = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto arg3_width = NativeValueTraits<IDLNumber>::NativeValue(info, 3);

  auto arg4_height = NativeValueTraits<IDLNumber>::NativeValue(info, 4);

  auto arg5_border = NativeValueTraits<IDLNumber>::NativeValue(info, 5);

  auto arg6_format = NativeValueTraits<IDLNumber>::NativeValue(info, 6);

  auto arg7_type = NativeValueTraits<IDLNumber>::NativeValue(info, 7);

  auto arg8_pixels = NativeValueTraits<IDLNullable<IDLArrayBufferView>>::NativeValue(info, 8);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->TexImage2D(arg0_target, arg1_level, arg2_internalformat, arg3_width, arg4_height, arg5_border, arg6_format, arg7_type, arg8_pixels);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::TexImage2DMethodOverload2(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 6) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "TexImage2D", "6");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_level = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_internalformat = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto arg3_format = NativeValueTraits<IDLNumber>::NativeValue(info, 3);

  auto arg4_type = NativeValueTraits<IDLNumber>::NativeValue(info, 4);

  auto arg5_pixels = NativeValueTraits<NapiImageData>::NativeValue(info, 5);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->TexImage2D(arg0_target, arg1_level, arg2_internalformat, arg3_format, arg4_type, arg5_pixels);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::TexImage2DMethodOverload3(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 6) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "TexImage2D", "6");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_level = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_internalformat = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto arg3_format = NativeValueTraits<IDLNumber>::NativeValue(info, 3);

  auto arg4_type = NativeValueTraits<IDLNumber>::NativeValue(info, 4);

  auto arg5_image = NativeValueTraits<NapiImageElement>::NativeValue(info, 5);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->TexImage2D(arg0_target, arg1_level, arg2_internalformat, arg3_format, arg4_type, arg5_image);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::TexImage2DMethodOverload4(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 6) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "TexImage2D", "6");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_level = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_internalformat = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto arg3_format = NativeValueTraits<IDLNumber>::NativeValue(info, 3);

  auto arg4_type = NativeValueTraits<IDLNumber>::NativeValue(info, 4);

  auto arg5_canvas = NativeValueTraits<NapiCanvasElement>::NativeValue(info, 5);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->TexImage2D(arg0_target, arg1_level, arg2_internalformat, arg3_format, arg4_type, arg5_canvas);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::TexImage2DMethodOverload5(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 6) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "TexImage2D", "6");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_level = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_internalformat = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto arg3_format = NativeValueTraits<IDLNumber>::NativeValue(info, 3);

  auto arg4_type = NativeValueTraits<IDLNumber>::NativeValue(info, 4);

  auto arg5_video = NativeValueTraits<NapiVideoElement>::NativeValue(info, 5);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->TexImage2D(arg0_target, arg1_level, arg2_internalformat, arg3_format, arg4_type, arg5_video);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::TexSubImage2DMethodOverload1(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 9) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "TexSubImage2D", "9");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_level = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_xoffset = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto arg3_yoffset = NativeValueTraits<IDLNumber>::NativeValue(info, 3);

  auto arg4_width = NativeValueTraits<IDLNumber>::NativeValue(info, 4);

  auto arg5_height = NativeValueTraits<IDLNumber>::NativeValue(info, 5);

  auto arg6_format = NativeValueTraits<IDLNumber>::NativeValue(info, 6);

  auto arg7_type = NativeValueTraits<IDLNumber>::NativeValue(info, 7);

  auto arg8_pixels = NativeValueTraits<IDLNullable<IDLArrayBufferView>>::NativeValue(info, 8);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->TexSubImage2D(arg0_target, arg1_level, arg2_xoffset, arg3_yoffset, arg4_width, arg5_height, arg6_format, arg7_type, arg8_pixels);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::TexSubImage2DMethodOverload2(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 7) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "TexSubImage2D", "7");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_level = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_xoffset = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto arg3_yoffset = NativeValueTraits<IDLNumber>::NativeValue(info, 3);

  auto arg4_format = NativeValueTraits<IDLNumber>::NativeValue(info, 4);

  auto arg5_type = NativeValueTraits<IDLNumber>::NativeValue(info, 5);

  auto arg6_pixels = NativeValueTraits<NapiImageData>::NativeValue(info, 6);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->TexSubImage2D(arg0_target, arg1_level, arg2_xoffset, arg3_yoffset, arg4_format, arg5_type, arg6_pixels);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::TexSubImage2DMethodOverload3(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 7) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "TexSubImage2D", "7");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_level = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_xoffset = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto arg3_yoffset = NativeValueTraits<IDLNumber>::NativeValue(info, 3);

  auto arg4_format = NativeValueTraits<IDLNumber>::NativeValue(info, 4);

  auto arg5_type = NativeValueTraits<IDLNumber>::NativeValue(info, 5);

  auto arg6_image = NativeValueTraits<NapiImageElement>::NativeValue(info, 6);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->TexSubImage2D(arg0_target, arg1_level, arg2_xoffset, arg3_yoffset, arg4_format, arg5_type, arg6_image);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::TexSubImage2DMethodOverload4(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 7) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "TexSubImage2D", "7");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_level = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_xoffset = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto arg3_yoffset = NativeValueTraits<IDLNumber>::NativeValue(info, 3);

  auto arg4_format = NativeValueTraits<IDLNumber>::NativeValue(info, 4);

  auto arg5_type = NativeValueTraits<IDLNumber>::NativeValue(info, 5);

  auto arg6_canvas = NativeValueTraits<NapiCanvasElement>::NativeValue(info, 6);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->TexSubImage2D(arg0_target, arg1_level, arg2_xoffset, arg3_yoffset, arg4_format, arg5_type, arg6_canvas);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::TexSubImage2DMethodOverload5(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 7) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "TexSubImage2D", "7");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_level = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_xoffset = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto arg3_yoffset = NativeValueTraits<IDLNumber>::NativeValue(info, 3);

  auto arg4_format = NativeValueTraits<IDLNumber>::NativeValue(info, 4);

  auto arg5_type = NativeValueTraits<IDLNumber>::NativeValue(info, 5);

  auto arg6_video = NativeValueTraits<NapiVideoElement>::NativeValue(info, 6);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->TexSubImage2D(arg0_target, arg1_level, arg2_xoffset, arg3_yoffset, arg4_format, arg5_type, arg6_video);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::CreateVertexArrayOESMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  auto&& result = impl_->CreateVertexArrayOES();
  return result ? (result->IsWrapped() ? result->JsObject() : NapiWebGLVertexArrayObjectOES::Wrap(std::unique_ptr<WebGLVertexArrayObjectOES>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiWebGLRenderingContext::IsVertexArrayOESMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "IsVertexArrayOES", "1");
    return Value();
  }

  auto arg0_arrayObject = NativeValueTraits<IDLNullable<NapiWebGLVertexArrayObjectOES>>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto&& result = impl_->IsVertexArrayOES(arg0_arrayObject);
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiWebGLRenderingContext::GetSupportedProfilesMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  const auto& vector_result = impl_->GetSupportedProfiles();
  auto result = Array::New(info.Env(), vector_result.size());
  for (size_t i = 0; i < vector_result.size(); ++i) {
    result[i] = String::New(info.Env(), vector_result[i]);
  }
  return result;
}

Value NapiWebGLRenderingContext::TexImage3DMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  FlushCommandBuffer(info.Env());

  if (info.Length() < 10) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "TexImage3D", "10");
    return Value();
  }

  auto arg0_target = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_level = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto arg2_internalformat = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto arg3_width = NativeValueTraits<IDLNumber>::NativeValue(info, 3);

  auto arg4_height = NativeValueTraits<IDLNumber>::NativeValue(info, 4);

  auto arg5_depth = NativeValueTraits<IDLNumber>::NativeValue(info, 5);

  auto arg6_border = NativeValueTraits<IDLNumber>::NativeValue(info, 6);

  auto arg7_format = NativeValueTraits<IDLNumber>::NativeValue(info, 7);

  auto arg8_type = NativeValueTraits<IDLNumber>::NativeValue(info, 8);

  auto arg9_srcData = NativeValueTraits<IDLNullable<IDLArrayBufferView>>::NativeValue(info, 9);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->TexImage3D(arg0_target, arg1_level, arg2_internalformat, arg3_width, arg4_height, arg5_depth, arg6_border, arg7_format, arg8_type, arg9_srcData);
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::BufferDataMethod(const CallbackInfo& info) {
  const size_t arg_count = std::min<size_t>(info.Length(), 3u);
  if (arg_count == 3) {
    if (info[1].IsUndefined() || info[1].IsNull()) {
      return BufferDataMethodOverload3(info);
    }
    if (info[1].IsTypedArray() || info[1].IsDataView()) {
      return BufferDataMethodOverload2(info);
    }
    if (info[1].IsArrayBuffer()) {
      return BufferDataMethodOverload3(info);
    }
    if (info[1].IsNumber()) {
      return BufferDataMethodOverload1(info);
    }
    return BufferDataMethodOverload1(info);
  }
  ExceptionMessage::FailedToCallOverload(info.Env(), "BufferData()");
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::BufferSubDataMethod(const CallbackInfo& info) {
  const size_t arg_count = std::min<size_t>(info.Length(), 3u);
  if (arg_count == 3) {
    if (info[2].IsTypedArray() || info[2].IsDataView()) {
      return BufferSubDataMethodOverload1(info);
    }
    if (info[2].IsArrayBuffer()) {
      return BufferSubDataMethodOverload2(info);
    }
  }
  ExceptionMessage::FailedToCallOverload(info.Env(), "BufferSubData()");
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::TexImage2DMethod(const CallbackInfo& info) {
  const size_t arg_count = std::min<size_t>(info.Length(), 9u);
  if (arg_count == 6) {
    if (info[5].IsObject() && info[5].ToObject().InstanceOf(NapiImageData::Constructor(info.Env()))) {
      return TexImage2DMethodOverload2(info);
    }
    if (info[5].IsObject() && info[5].ToObject().InstanceOf(NapiImageElement::Constructor(info.Env()))) {
      return TexImage2DMethodOverload3(info);
    }
    if (info[5].IsObject() && info[5].ToObject().InstanceOf(NapiCanvasElement::Constructor(info.Env()))) {
      return TexImage2DMethodOverload4(info);
    }
    if (info[5].IsObject() && info[5].ToObject().InstanceOf(NapiVideoElement::Constructor(info.Env()))) {
      return TexImage2DMethodOverload5(info);
    }
  }
  if (arg_count == 9) {
    return TexImage2DMethodOverload1(info);
  }
  ExceptionMessage::FailedToCallOverload(info.Env(), "TexImage2D()");
  return info.Env().Undefined();
}

Value NapiWebGLRenderingContext::TexSubImage2DMethod(const CallbackInfo& info) {
  const size_t arg_count = std::min<size_t>(info.Length(), 9u);
  if (arg_count == 7) {
    if (info[6].IsObject() && info[6].ToObject().InstanceOf(NapiImageData::Constructor(info.Env()))) {
      return TexSubImage2DMethodOverload2(info);
    }
    if (info[6].IsObject() && info[6].ToObject().InstanceOf(NapiImageElement::Constructor(info.Env()))) {
      return TexSubImage2DMethodOverload3(info);
    }
    if (info[6].IsObject() && info[6].ToObject().InstanceOf(NapiCanvasElement::Constructor(info.Env()))) {
      return TexSubImage2DMethodOverload4(info);
    }
    if (info[6].IsObject() && info[6].ToObject().InstanceOf(NapiVideoElement::Constructor(info.Env()))) {
      return TexSubImage2DMethodOverload5(info);
    }
  }
  if (arg_count == 9) {
    return TexSubImage2DMethodOverload1(info);
  }
  ExceptionMessage::FailedToCallOverload(info.Env(), "TexSubImage2D()");
  return info.Env().Undefined();
}

static Value FlushCommandBufferCallback(const Napi::CallbackInfo& info) {
  NapiWebGLRenderingContext::FlushCommandBuffer(info.Env());
  return Value();
}

// static
void NapiWebGLRenderingContext::FlushCommandBuffer(Napi::Env env) {
  uint32_t* command_buffer = env.GetInstanceData<uint32_t>(kWebGLRenderingContextCommandBufferID);

  // First word stores current length.
  uint32_t buffer_len = ReadBuffer<uint32_t>(command_buffer, 0);
  uint32_t current = 1;
  while (current < buffer_len) {
    struct __attribute__ ((__packed__)) MethodHeader {
      uint32_t method;
      union WebGLRenderingContextPointer64bits {
        WebGLRenderingContext* ptr;
        uint64_t _placeholder;
      } obj;
    };
    MethodHeader& header = ReadBuffer<MethodHeader>(command_buffer, current);
    current += 3;
    switch (header.method) {
      case 1: { // activeTexture
        struct __attribute__ ((__packed__)) ActiveTextureCommand {
          uint32_t texture;
        };
        ActiveTextureCommand& command = ReadBuffer<ActiveTextureCommand>(command_buffer, current);
        current += 1;
        header.obj.ptr->ActiveTexture(command.texture);
        break;
      }
      case 2: { // attachShader
        struct __attribute__ ((__packed__)) AttachShaderCommand {
          union WebGLProgramPointer64bits {
            WebGLProgram* ptr;
            uint64_t _placeholder;
          } program;
          union WebGLShaderPointer64bits {
            WebGLShader* ptr;
            uint64_t _placeholder;
          } shader;
        };
        AttachShaderCommand& command = ReadBuffer<AttachShaderCommand>(command_buffer, current);
        current += 4;
        header.obj.ptr->AttachShader(command.program.ptr, command.shader.ptr);
        break;
      }
      case 3: { // bindBuffer
        struct __attribute__ ((__packed__)) BindBufferCommand {
          uint32_t target;
          union WebGLBufferPointer64bits {
            WebGLBuffer* ptr;
            uint64_t _placeholder;
          } buffer;
        };
        BindBufferCommand& command = ReadBuffer<BindBufferCommand>(command_buffer, current);
        current += 3;
        header.obj.ptr->BindBuffer(command.target, command.buffer.ptr);
        break;
      }
      case 4: { // bindFramebuffer
        struct __attribute__ ((__packed__)) BindFramebufferCommand {
          uint32_t target;
          union WebGLFramebufferPointer64bits {
            WebGLFramebuffer* ptr;
            uint64_t _placeholder;
          } framebuffer;
        };
        BindFramebufferCommand& command = ReadBuffer<BindFramebufferCommand>(command_buffer, current);
        current += 3;
        header.obj.ptr->BindFramebuffer(command.target, command.framebuffer.ptr);
        break;
      }
      case 5: { // bindRenderbuffer
        struct __attribute__ ((__packed__)) BindRenderbufferCommand {
          uint32_t target;
          union WebGLRenderbufferPointer64bits {
            WebGLRenderbuffer* ptr;
            uint64_t _placeholder;
          } renderbuffer;
        };
        BindRenderbufferCommand& command = ReadBuffer<BindRenderbufferCommand>(command_buffer, current);
        current += 3;
        header.obj.ptr->BindRenderbuffer(command.target, command.renderbuffer.ptr);
        break;
      }
      case 6: { // bindTexture
        struct __attribute__ ((__packed__)) BindTextureCommand {
          uint32_t target;
          union WebGLTexturePointer64bits {
            WebGLTexture* ptr;
            uint64_t _placeholder;
          } texture;
        };
        BindTextureCommand& command = ReadBuffer<BindTextureCommand>(command_buffer, current);
        current += 3;
        header.obj.ptr->BindTexture(command.target, command.texture.ptr);
        break;
      }
      case 7: { // blendColor
        struct __attribute__ ((__packed__)) BlendColorCommand {
          GLfloat red;
          GLfloat green;
          GLfloat blue;
          GLfloat alpha;
        };
        BlendColorCommand& command = ReadBuffer<BlendColorCommand>(command_buffer, current);
        current += 4;
        header.obj.ptr->BlendColor(command.red, command.green, command.blue, command.alpha);
        break;
      }
      case 8: { // blendEquation
        struct __attribute__ ((__packed__)) BlendEquationCommand {
          uint32_t mode;
        };
        BlendEquationCommand& command = ReadBuffer<BlendEquationCommand>(command_buffer, current);
        current += 1;
        header.obj.ptr->BlendEquation(command.mode);
        break;
      }
      case 9: { // blendEquationSeparate
        struct __attribute__ ((__packed__)) BlendEquationSeparateCommand {
          uint32_t modeRGB;
          uint32_t modeAlpha;
        };
        BlendEquationSeparateCommand& command = ReadBuffer<BlendEquationSeparateCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->BlendEquationSeparate(command.modeRGB, command.modeAlpha);
        break;
      }
      case 10: { // blendFunc
        struct __attribute__ ((__packed__)) BlendFuncCommand {
          uint32_t sfactor;
          uint32_t dfactor;
        };
        BlendFuncCommand& command = ReadBuffer<BlendFuncCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->BlendFunc(command.sfactor, command.dfactor);
        break;
      }
      case 11: { // blendFuncSeparate
        struct __attribute__ ((__packed__)) BlendFuncSeparateCommand {
          uint32_t srcRGB;
          uint32_t dstRGB;
          uint32_t srcAlpha;
          uint32_t dstAlpha;
        };
        BlendFuncSeparateCommand& command = ReadBuffer<BlendFuncSeparateCommand>(command_buffer, current);
        current += 4;
        header.obj.ptr->BlendFuncSeparate(command.srcRGB, command.dstRGB, command.srcAlpha, command.dstAlpha);
        break;
      }
      case 12: { // bufferData
        struct __attribute__ ((__packed__)) BufferDataCommand {
          uint32_t target;
          int32_t size;
          uint32_t usage;
        };
        BufferDataCommand& command = ReadBuffer<BufferDataCommand>(command_buffer, current);
        current += 3;
        header.obj.ptr->BufferData(command.target, command.size, command.usage);
        break;
      }
      case 13: { // bufferData
        struct __attribute__ ((__packed__)) BufferDataCommand {
          uint32_t target;
          uint32_t length;
          uint32_t usage;
        };
        BufferDataCommand& command = ReadBuffer<BufferDataCommand>(command_buffer, current);
        current += 3;
        header.obj.ptr->BufferData(command.target, (uint32_t *)command_buffer + current, command.length, command.usage);
        current += ceil((double)command.length / 4);
        break;
      }
      case 14: { // bufferData
        struct __attribute__ ((__packed__)) BufferDataCommand {
          uint32_t target;
          uint32_t length;
          uint32_t usage;
        };
        BufferDataCommand& command = ReadBuffer<BufferDataCommand>(command_buffer, current);
        current += 3;
        header.obj.ptr->BufferData(command.target, (uint32_t *)command_buffer + current, command.length, command.usage);
        current += ceil((double)command.length / 4);
        break;
      }
      case 15: { // bufferSubData
        struct __attribute__ ((__packed__)) BufferSubDataCommand {
          uint32_t target;
          int32_t offset;
          uint32_t length;
        };
        BufferSubDataCommand& command = ReadBuffer<BufferSubDataCommand>(command_buffer, current);
        current += 3;
        header.obj.ptr->BufferSubData(command.target, command.offset, (uint32_t *)command_buffer + current, command.length);
        current += ceil((double)command.length / 4);
        break;
      }
      case 16: { // bufferSubData
        struct __attribute__ ((__packed__)) BufferSubDataCommand {
          uint32_t target;
          int32_t offset;
          uint32_t length;
        };
        BufferSubDataCommand& command = ReadBuffer<BufferSubDataCommand>(command_buffer, current);
        current += 3;
        header.obj.ptr->BufferSubData(command.target, command.offset, (uint32_t *)command_buffer + current, command.length);
        current += ceil((double)command.length / 4);
        break;
      }
      case 17: { // clear
        struct __attribute__ ((__packed__)) ClearCommand {
          uint32_t mask;
        };
        ClearCommand& command = ReadBuffer<ClearCommand>(command_buffer, current);
        current += 1;
        header.obj.ptr->Clear(command.mask);
        break;
      }
      case 18: { // clearColor
        struct __attribute__ ((__packed__)) ClearColorCommand {
          GLfloat red;
          GLfloat green;
          GLfloat blue;
          GLfloat alpha;
        };
        ClearColorCommand& command = ReadBuffer<ClearColorCommand>(command_buffer, current);
        current += 4;
        header.obj.ptr->ClearColor(command.red, command.green, command.blue, command.alpha);
        break;
      }
      case 19: { // clearDepth
        struct __attribute__ ((__packed__)) ClearDepthCommand {
          GLfloat depth;
        };
        ClearDepthCommand& command = ReadBuffer<ClearDepthCommand>(command_buffer, current);
        current += 1;
        header.obj.ptr->ClearDepth(command.depth);
        break;
      }
      case 20: { // clearStencil
        struct __attribute__ ((__packed__)) ClearStencilCommand {
          int32_t s;
        };
        ClearStencilCommand& command = ReadBuffer<ClearStencilCommand>(command_buffer, current);
        current += 1;
        header.obj.ptr->ClearStencil(command.s);
        break;
      }
      case 21: { // colorMask
        struct __attribute__ ((__packed__)) ColorMaskCommand {
          uint32_t red;
          uint32_t green;
          uint32_t blue;
          uint32_t alpha;
        };
        ColorMaskCommand& command = ReadBuffer<ColorMaskCommand>(command_buffer, current);
        current += 4;
        header.obj.ptr->ColorMask(command.red, command.green, command.blue, command.alpha);
        break;
      }
      case 22: { // compileShader
        struct __attribute__ ((__packed__)) CompileShaderCommand {
          union WebGLShaderPointer64bits {
            WebGLShader* ptr;
            uint64_t _placeholder;
          } shader;
        };
        CompileShaderCommand& command = ReadBuffer<CompileShaderCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->CompileShader(command.shader.ptr);
        break;
      }
      case 23: { // copyTexImage2D
        struct __attribute__ ((__packed__)) CopyTexImage2DCommand {
          uint32_t target;
          int32_t level;
          uint32_t internalformat;
          int32_t x;
          int32_t y;
          int32_t width;
          int32_t height;
          int32_t border;
        };
        CopyTexImage2DCommand& command = ReadBuffer<CopyTexImage2DCommand>(command_buffer, current);
        current += 8;
        header.obj.ptr->CopyTexImage2D(command.target, command.level, command.internalformat, command.x, command.y, command.width, command.height, command.border);
        break;
      }
      case 24: { // copyTexSubImage2D
        struct __attribute__ ((__packed__)) CopyTexSubImage2DCommand {
          uint32_t target;
          int32_t level;
          int32_t xoffset;
          int32_t yoffset;
          int32_t x;
          int32_t y;
          int32_t width;
          int32_t height;
        };
        CopyTexSubImage2DCommand& command = ReadBuffer<CopyTexSubImage2DCommand>(command_buffer, current);
        current += 8;
        header.obj.ptr->CopyTexSubImage2D(command.target, command.level, command.xoffset, command.yoffset, command.x, command.y, command.width, command.height);
        break;
      }
      case 25: { // cullFace
        struct __attribute__ ((__packed__)) CullFaceCommand {
          uint32_t mode;
        };
        CullFaceCommand& command = ReadBuffer<CullFaceCommand>(command_buffer, current);
        current += 1;
        header.obj.ptr->CullFace(command.mode);
        break;
      }
      case 26: { // deleteBuffer
        struct __attribute__ ((__packed__)) DeleteBufferCommand {
          union WebGLBufferPointer64bits {
            WebGLBuffer* ptr;
            uint64_t _placeholder;
          } buffer;
        };
        DeleteBufferCommand& command = ReadBuffer<DeleteBufferCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->DeleteBuffer(command.buffer.ptr);
        break;
      }
      case 27: { // deleteFramebuffer
        struct __attribute__ ((__packed__)) DeleteFramebufferCommand {
          union WebGLFramebufferPointer64bits {
            WebGLFramebuffer* ptr;
            uint64_t _placeholder;
          } framebuffer;
        };
        DeleteFramebufferCommand& command = ReadBuffer<DeleteFramebufferCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->DeleteFramebuffer(command.framebuffer.ptr);
        break;
      }
      case 28: { // deleteProgram
        struct __attribute__ ((__packed__)) DeleteProgramCommand {
          union WebGLProgramPointer64bits {
            WebGLProgram* ptr;
            uint64_t _placeholder;
          } program;
        };
        DeleteProgramCommand& command = ReadBuffer<DeleteProgramCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->DeleteProgram(command.program.ptr);
        break;
      }
      case 29: { // deleteRenderbuffer
        struct __attribute__ ((__packed__)) DeleteRenderbufferCommand {
          union WebGLRenderbufferPointer64bits {
            WebGLRenderbuffer* ptr;
            uint64_t _placeholder;
          } renderbuffer;
        };
        DeleteRenderbufferCommand& command = ReadBuffer<DeleteRenderbufferCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->DeleteRenderbuffer(command.renderbuffer.ptr);
        break;
      }
      case 30: { // deleteShader
        struct __attribute__ ((__packed__)) DeleteShaderCommand {
          union WebGLShaderPointer64bits {
            WebGLShader* ptr;
            uint64_t _placeholder;
          } shader;
        };
        DeleteShaderCommand& command = ReadBuffer<DeleteShaderCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->DeleteShader(command.shader.ptr);
        break;
      }
      case 31: { // deleteTexture
        struct __attribute__ ((__packed__)) DeleteTextureCommand {
          union WebGLTexturePointer64bits {
            WebGLTexture* ptr;
            uint64_t _placeholder;
          } texture;
        };
        DeleteTextureCommand& command = ReadBuffer<DeleteTextureCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->DeleteTexture(command.texture.ptr);
        break;
      }
      case 32: { // depthFunc
        struct __attribute__ ((__packed__)) DepthFuncCommand {
          uint32_t func;
        };
        DepthFuncCommand& command = ReadBuffer<DepthFuncCommand>(command_buffer, current);
        current += 1;
        header.obj.ptr->DepthFunc(command.func);
        break;
      }
      case 33: { // depthMask
        struct __attribute__ ((__packed__)) DepthMaskCommand {
          uint32_t flag;
        };
        DepthMaskCommand& command = ReadBuffer<DepthMaskCommand>(command_buffer, current);
        current += 1;
        header.obj.ptr->DepthMask(command.flag);
        break;
      }
      case 34: { // depthRange
        struct __attribute__ ((__packed__)) DepthRangeCommand {
          GLfloat zNear;
          GLfloat zFar;
        };
        DepthRangeCommand& command = ReadBuffer<DepthRangeCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->DepthRange(command.zNear, command.zFar);
        break;
      }
      case 35: { // detachShader
        struct __attribute__ ((__packed__)) DetachShaderCommand {
          union WebGLProgramPointer64bits {
            WebGLProgram* ptr;
            uint64_t _placeholder;
          } program;
          union WebGLShaderPointer64bits {
            WebGLShader* ptr;
            uint64_t _placeholder;
          } shader;
        };
        DetachShaderCommand& command = ReadBuffer<DetachShaderCommand>(command_buffer, current);
        current += 4;
        header.obj.ptr->DetachShader(command.program.ptr, command.shader.ptr);
        break;
      }
      case 36: { // disable
        struct __attribute__ ((__packed__)) DisableCommand {
          uint32_t cap;
        };
        DisableCommand& command = ReadBuffer<DisableCommand>(command_buffer, current);
        current += 1;
        header.obj.ptr->Disable(command.cap);
        break;
      }
      case 37: { // disableVertexAttribArray
        struct __attribute__ ((__packed__)) DisableVertexAttribArrayCommand {
          uint32_t index;
        };
        DisableVertexAttribArrayCommand& command = ReadBuffer<DisableVertexAttribArrayCommand>(command_buffer, current);
        current += 1;
        header.obj.ptr->DisableVertexAttribArray(command.index);
        break;
      }
      case 38: { // drawArrays
        struct __attribute__ ((__packed__)) DrawArraysCommand {
          uint32_t mode;
          int32_t first;
          int32_t count;
        };
        DrawArraysCommand& command = ReadBuffer<DrawArraysCommand>(command_buffer, current);
        current += 3;
        header.obj.ptr->DrawArrays(command.mode, command.first, command.count);
        break;
      }
      case 39: { // drawElements
        struct __attribute__ ((__packed__)) DrawElementsCommand {
          uint32_t mode;
          int32_t count;
          uint32_t type;
          int32_t offset;
        };
        DrawElementsCommand& command = ReadBuffer<DrawElementsCommand>(command_buffer, current);
        current += 4;
        header.obj.ptr->DrawElements(command.mode, command.count, command.type, command.offset);
        break;
      }
      case 40: { // enable
        struct __attribute__ ((__packed__)) EnableCommand {
          uint32_t cap;
        };
        EnableCommand& command = ReadBuffer<EnableCommand>(command_buffer, current);
        current += 1;
        header.obj.ptr->Enable(command.cap);
        break;
      }
      case 41: { // enableVertexAttribArray
        struct __attribute__ ((__packed__)) EnableVertexAttribArrayCommand {
          uint32_t index;
        };
        EnableVertexAttribArrayCommand& command = ReadBuffer<EnableVertexAttribArrayCommand>(command_buffer, current);
        current += 1;
        header.obj.ptr->EnableVertexAttribArray(command.index);
        break;
      }
      case 42: { // flush
        struct __attribute__ ((__packed__)) FlushCommand {
        };
        header.obj.ptr->Flush();
        break;
      }
      case 43: { // framebufferRenderbuffer
        struct __attribute__ ((__packed__)) FramebufferRenderbufferCommand {
          uint32_t target;
          uint32_t attachment;
          uint32_t renderbuffertarget;
          union WebGLRenderbufferPointer64bits {
            WebGLRenderbuffer* ptr;
            uint64_t _placeholder;
          } renderbuffer;
        };
        FramebufferRenderbufferCommand& command = ReadBuffer<FramebufferRenderbufferCommand>(command_buffer, current);
        current += 5;
        header.obj.ptr->FramebufferRenderbuffer(command.target, command.attachment, command.renderbuffertarget, command.renderbuffer.ptr);
        break;
      }
      case 44: { // framebufferTexture2D
        struct __attribute__ ((__packed__)) FramebufferTexture2DCommand {
          uint32_t target;
          uint32_t attachment;
          uint32_t textarget;
          union WebGLTexturePointer64bits {
            WebGLTexture* ptr;
            uint64_t _placeholder;
          } texture;
          int32_t level;
        };
        FramebufferTexture2DCommand& command = ReadBuffer<FramebufferTexture2DCommand>(command_buffer, current);
        current += 6;
        header.obj.ptr->FramebufferTexture2D(command.target, command.attachment, command.textarget, command.texture.ptr, command.level);
        break;
      }
      case 45: { // frontFace
        struct __attribute__ ((__packed__)) FrontFaceCommand {
          uint32_t mode;
        };
        FrontFaceCommand& command = ReadBuffer<FrontFaceCommand>(command_buffer, current);
        current += 1;
        header.obj.ptr->FrontFace(command.mode);
        break;
      }
      case 46: { // generateMipmap
        struct __attribute__ ((__packed__)) GenerateMipmapCommand {
          uint32_t target;
        };
        GenerateMipmapCommand& command = ReadBuffer<GenerateMipmapCommand>(command_buffer, current);
        current += 1;
        header.obj.ptr->GenerateMipmap(command.target);
        break;
      }
      case 47: { // hint
        struct __attribute__ ((__packed__)) HintCommand {
          uint32_t target;
          uint32_t mode;
        };
        HintCommand& command = ReadBuffer<HintCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->Hint(command.target, command.mode);
        break;
      }
      case 48: { // lineWidth
        struct __attribute__ ((__packed__)) LineWidthCommand {
          GLfloat width;
        };
        LineWidthCommand& command = ReadBuffer<LineWidthCommand>(command_buffer, current);
        current += 1;
        header.obj.ptr->LineWidth(command.width);
        break;
      }
      case 49: { // linkProgram
        struct __attribute__ ((__packed__)) LinkProgramCommand {
          union WebGLProgramPointer64bits {
            WebGLProgram* ptr;
            uint64_t _placeholder;
          } program;
        };
        LinkProgramCommand& command = ReadBuffer<LinkProgramCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->LinkProgram(command.program.ptr);
        break;
      }
      case 50: { // pixelStorei
        struct __attribute__ ((__packed__)) PixelStoreiCommand {
          uint32_t pname;
          int32_t param;
        };
        PixelStoreiCommand& command = ReadBuffer<PixelStoreiCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->PixelStorei(command.pname, command.param);
        break;
      }
      case 51: { // polygonOffset
        struct __attribute__ ((__packed__)) PolygonOffsetCommand {
          GLfloat factor;
          GLfloat units;
        };
        PolygonOffsetCommand& command = ReadBuffer<PolygonOffsetCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->PolygonOffset(command.factor, command.units);
        break;
      }
      case 52: { // renderbufferStorage
        struct __attribute__ ((__packed__)) RenderbufferStorageCommand {
          uint32_t target;
          uint32_t internalformat;
          int32_t width;
          int32_t height;
        };
        RenderbufferStorageCommand& command = ReadBuffer<RenderbufferStorageCommand>(command_buffer, current);
        current += 4;
        header.obj.ptr->RenderbufferStorage(command.target, command.internalformat, command.width, command.height);
        break;
      }
      case 53: { // sampleCoverage
        struct __attribute__ ((__packed__)) SampleCoverageCommand {
          GLfloat value;
          uint32_t invert;
        };
        SampleCoverageCommand& command = ReadBuffer<SampleCoverageCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->SampleCoverage(command.value, command.invert);
        break;
      }
      case 54: { // scissor
        struct __attribute__ ((__packed__)) ScissorCommand {
          int32_t x;
          int32_t y;
          int32_t width;
          int32_t height;
        };
        ScissorCommand& command = ReadBuffer<ScissorCommand>(command_buffer, current);
        current += 4;
        header.obj.ptr->Scissor(command.x, command.y, command.width, command.height);
        break;
      }
      case 55: { // stencilFunc
        struct __attribute__ ((__packed__)) StencilFuncCommand {
          uint32_t func;
          int32_t ref;
          uint32_t mask;
        };
        StencilFuncCommand& command = ReadBuffer<StencilFuncCommand>(command_buffer, current);
        current += 3;
        header.obj.ptr->StencilFunc(command.func, command.ref, command.mask);
        break;
      }
      case 56: { // stencilFuncSeparate
        struct __attribute__ ((__packed__)) StencilFuncSeparateCommand {
          uint32_t face;
          uint32_t func;
          int32_t ref;
          uint32_t mask;
        };
        StencilFuncSeparateCommand& command = ReadBuffer<StencilFuncSeparateCommand>(command_buffer, current);
        current += 4;
        header.obj.ptr->StencilFuncSeparate(command.face, command.func, command.ref, command.mask);
        break;
      }
      case 57: { // stencilMask
        struct __attribute__ ((__packed__)) StencilMaskCommand {
          uint32_t mask;
        };
        StencilMaskCommand& command = ReadBuffer<StencilMaskCommand>(command_buffer, current);
        current += 1;
        header.obj.ptr->StencilMask(command.mask);
        break;
      }
      case 58: { // stencilMaskSeparate
        struct __attribute__ ((__packed__)) StencilMaskSeparateCommand {
          uint32_t face;
          uint32_t mask;
        };
        StencilMaskSeparateCommand& command = ReadBuffer<StencilMaskSeparateCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->StencilMaskSeparate(command.face, command.mask);
        break;
      }
      case 59: { // stencilOp
        struct __attribute__ ((__packed__)) StencilOpCommand {
          uint32_t fail;
          uint32_t zfail;
          uint32_t zpass;
        };
        StencilOpCommand& command = ReadBuffer<StencilOpCommand>(command_buffer, current);
        current += 3;
        header.obj.ptr->StencilOp(command.fail, command.zfail, command.zpass);
        break;
      }
      case 60: { // stencilOpSeparate
        struct __attribute__ ((__packed__)) StencilOpSeparateCommand {
          uint32_t face;
          uint32_t fail;
          uint32_t zfail;
          uint32_t zpass;
        };
        StencilOpSeparateCommand& command = ReadBuffer<StencilOpSeparateCommand>(command_buffer, current);
        current += 4;
        header.obj.ptr->StencilOpSeparate(command.face, command.fail, command.zfail, command.zpass);
        break;
      }
      case 61: { // texParameterf
        struct __attribute__ ((__packed__)) TexParameterfCommand {
          uint32_t target;
          uint32_t pname;
          GLfloat param;
        };
        TexParameterfCommand& command = ReadBuffer<TexParameterfCommand>(command_buffer, current);
        current += 3;
        header.obj.ptr->TexParameterf(command.target, command.pname, command.param);
        break;
      }
      case 62: { // texParameteri
        struct __attribute__ ((__packed__)) TexParameteriCommand {
          uint32_t target;
          uint32_t pname;
          int32_t param;
        };
        TexParameteriCommand& command = ReadBuffer<TexParameteriCommand>(command_buffer, current);
        current += 3;
        header.obj.ptr->TexParameteri(command.target, command.pname, command.param);
        break;
      }
      case 63: { // uniform1f
        struct __attribute__ ((__packed__)) Uniform1FCommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          GLfloat x;
        };
        Uniform1FCommand& command = ReadBuffer<Uniform1FCommand>(command_buffer, current);
        current += 3;
        header.obj.ptr->Uniform1F(command.location.ptr, command.x);
        break;
      }
      case 64: { // uniform1fv
        struct __attribute__ ((__packed__)) Uniform1FvCommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          uint32_t length;
        };
        Uniform1FvCommand& command = ReadBuffer<Uniform1FvCommand>(command_buffer, current);
        current += 3;
        SharedVector<float> v((float*)command_buffer + current, command.length);
        current += command.length;
        header.obj.ptr->Uniform1Fv(command.location.ptr, v);
        break;
      }
      case 65: { // uniform1i
        struct __attribute__ ((__packed__)) Uniform1ICommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          int32_t x;
        };
        Uniform1ICommand& command = ReadBuffer<Uniform1ICommand>(command_buffer, current);
        current += 3;
        header.obj.ptr->Uniform1I(command.location.ptr, command.x);
        break;
      }
      case 66: { // uniform1iv
        struct __attribute__ ((__packed__)) Uniform1IvCommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          uint32_t length;
        };
        Uniform1IvCommand& command = ReadBuffer<Uniform1IvCommand>(command_buffer, current);
        current += 3;
        SharedVector<int32_t> v((int32_t*)command_buffer + current, command.length);
        current += command.length;
        header.obj.ptr->Uniform1Iv(command.location.ptr, v);
        break;
      }
      case 67: { // uniform2f
        struct __attribute__ ((__packed__)) Uniform2FCommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          GLfloat x;
          GLfloat y;
        };
        Uniform2FCommand& command = ReadBuffer<Uniform2FCommand>(command_buffer, current);
        current += 4;
        header.obj.ptr->Uniform2F(command.location.ptr, command.x, command.y);
        break;
      }
      case 68: { // uniform2fv
        struct __attribute__ ((__packed__)) Uniform2FvCommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          uint32_t length;
        };
        Uniform2FvCommand& command = ReadBuffer<Uniform2FvCommand>(command_buffer, current);
        current += 3;
        SharedVector<float> v((float*)command_buffer + current, command.length);
        current += command.length;
        header.obj.ptr->Uniform2Fv(command.location.ptr, v);
        break;
      }
      case 69: { // uniform2i
        struct __attribute__ ((__packed__)) Uniform2ICommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          int32_t x;
          int32_t y;
        };
        Uniform2ICommand& command = ReadBuffer<Uniform2ICommand>(command_buffer, current);
        current += 4;
        header.obj.ptr->Uniform2I(command.location.ptr, command.x, command.y);
        break;
      }
      case 70: { // uniform2iv
        struct __attribute__ ((__packed__)) Uniform2IvCommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          uint32_t length;
        };
        Uniform2IvCommand& command = ReadBuffer<Uniform2IvCommand>(command_buffer, current);
        current += 3;
        SharedVector<int32_t> v((int32_t*)command_buffer + current, command.length);
        current += command.length;
        header.obj.ptr->Uniform2Iv(command.location.ptr, v);
        break;
      }
      case 71: { // uniform3f
        struct __attribute__ ((__packed__)) Uniform3FCommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          GLfloat x;
          GLfloat y;
          GLfloat z;
        };
        Uniform3FCommand& command = ReadBuffer<Uniform3FCommand>(command_buffer, current);
        current += 5;
        header.obj.ptr->Uniform3F(command.location.ptr, command.x, command.y, command.z);
        break;
      }
      case 72: { // uniform3fv
        struct __attribute__ ((__packed__)) Uniform3FvCommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          uint32_t length;
        };
        Uniform3FvCommand& command = ReadBuffer<Uniform3FvCommand>(command_buffer, current);
        current += 3;
        SharedVector<float> v((float*)command_buffer + current, command.length);
        current += command.length;
        header.obj.ptr->Uniform3Fv(command.location.ptr, v);
        break;
      }
      case 73: { // uniform3i
        struct __attribute__ ((__packed__)) Uniform3ICommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          int32_t x;
          int32_t y;
          int32_t z;
        };
        Uniform3ICommand& command = ReadBuffer<Uniform3ICommand>(command_buffer, current);
        current += 5;
        header.obj.ptr->Uniform3I(command.location.ptr, command.x, command.y, command.z);
        break;
      }
      case 74: { // uniform3iv
        struct __attribute__ ((__packed__)) Uniform3IvCommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          uint32_t length;
        };
        Uniform3IvCommand& command = ReadBuffer<Uniform3IvCommand>(command_buffer, current);
        current += 3;
        SharedVector<int32_t> v((int32_t*)command_buffer + current, command.length);
        current += command.length;
        header.obj.ptr->Uniform3Iv(command.location.ptr, v);
        break;
      }
      case 75: { // uniform4f
        struct __attribute__ ((__packed__)) Uniform4FCommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          GLfloat x;
          GLfloat y;
          GLfloat z;
          GLfloat w;
        };
        Uniform4FCommand& command = ReadBuffer<Uniform4FCommand>(command_buffer, current);
        current += 6;
        header.obj.ptr->Uniform4F(command.location.ptr, command.x, command.y, command.z, command.w);
        break;
      }
      case 76: { // uniform4fv
        struct __attribute__ ((__packed__)) Uniform4FvCommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          uint32_t length;
        };
        Uniform4FvCommand& command = ReadBuffer<Uniform4FvCommand>(command_buffer, current);
        current += 3;
        SharedVector<float> v((float*)command_buffer + current, command.length);
        current += command.length;
        header.obj.ptr->Uniform4Fv(command.location.ptr, v);
        break;
      }
      case 77: { // uniform4i
        struct __attribute__ ((__packed__)) Uniform4ICommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          int32_t x;
          int32_t y;
          int32_t z;
          int32_t w;
        };
        Uniform4ICommand& command = ReadBuffer<Uniform4ICommand>(command_buffer, current);
        current += 6;
        header.obj.ptr->Uniform4I(command.location.ptr, command.x, command.y, command.z, command.w);
        break;
      }
      case 78: { // uniform4iv
        struct __attribute__ ((__packed__)) Uniform4IvCommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          uint32_t length;
        };
        Uniform4IvCommand& command = ReadBuffer<Uniform4IvCommand>(command_buffer, current);
        current += 3;
        SharedVector<int32_t> v((int32_t*)command_buffer + current, command.length);
        current += command.length;
        header.obj.ptr->Uniform4Iv(command.location.ptr, v);
        break;
      }
      case 79: { // uniformMatrix2fv
        struct __attribute__ ((__packed__)) UniformMatrix2FvCommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          uint32_t transpose;
          uint32_t length;
        };
        UniformMatrix2FvCommand& command = ReadBuffer<UniformMatrix2FvCommand>(command_buffer, current);
        current += 4;
        SharedVector<float> array((float*)command_buffer + current, command.length);
        current += command.length;
        header.obj.ptr->UniformMatrix2Fv(command.location.ptr, command.transpose, array);
        break;
      }
      case 80: { // uniformMatrix3fv
        struct __attribute__ ((__packed__)) UniformMatrix3FvCommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          uint32_t transpose;
          uint32_t length;
        };
        UniformMatrix3FvCommand& command = ReadBuffer<UniformMatrix3FvCommand>(command_buffer, current);
        current += 4;
        SharedVector<float> array((float*)command_buffer + current, command.length);
        current += command.length;
        header.obj.ptr->UniformMatrix3Fv(command.location.ptr, command.transpose, array);
        break;
      }
      case 81: { // uniformMatrix4fv
        struct __attribute__ ((__packed__)) UniformMatrix4FvCommand {
          union WebGLUniformLocationPointer64bits {
            WebGLUniformLocation* ptr;
            uint64_t _placeholder;
          } location;
          uint32_t transpose;
          uint32_t length;
        };
        UniformMatrix4FvCommand& command = ReadBuffer<UniformMatrix4FvCommand>(command_buffer, current);
        current += 4;
        SharedVector<float> array((float*)command_buffer + current, command.length);
        current += command.length;
        header.obj.ptr->UniformMatrix4Fv(command.location.ptr, command.transpose, array);
        break;
      }
      case 82: { // useProgram
        struct __attribute__ ((__packed__)) UseProgramCommand {
          union WebGLProgramPointer64bits {
            WebGLProgram* ptr;
            uint64_t _placeholder;
          } program;
        };
        UseProgramCommand& command = ReadBuffer<UseProgramCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->UseProgram(command.program.ptr);
        break;
      }
      case 83: { // validateProgram
        struct __attribute__ ((__packed__)) ValidateProgramCommand {
          union WebGLProgramPointer64bits {
            WebGLProgram* ptr;
            uint64_t _placeholder;
          } program;
        };
        ValidateProgramCommand& command = ReadBuffer<ValidateProgramCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->ValidateProgram(command.program.ptr);
        break;
      }
      case 84: { // vertexAttrib1f
        struct __attribute__ ((__packed__)) VertexAttrib1FCommand {
          uint32_t indx;
          GLfloat x;
        };
        VertexAttrib1FCommand& command = ReadBuffer<VertexAttrib1FCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->VertexAttrib1F(command.indx, command.x);
        break;
      }
      case 85: { // vertexAttrib1fv
        struct __attribute__ ((__packed__)) VertexAttrib1FvCommand {
          uint32_t indx;
          uint32_t length;
        };
        VertexAttrib1FvCommand& command = ReadBuffer<VertexAttrib1FvCommand>(command_buffer, current);
        current += 2;
        SharedVector<float> values((float*)command_buffer + current, command.length);
        current += command.length;
        header.obj.ptr->VertexAttrib1Fv(command.indx, values);
        break;
      }
      case 86: { // vertexAttrib2f
        struct __attribute__ ((__packed__)) VertexAttrib2FCommand {
          uint32_t indx;
          GLfloat x;
          GLfloat y;
        };
        VertexAttrib2FCommand& command = ReadBuffer<VertexAttrib2FCommand>(command_buffer, current);
        current += 3;
        header.obj.ptr->VertexAttrib2F(command.indx, command.x, command.y);
        break;
      }
      case 87: { // vertexAttrib2fv
        struct __attribute__ ((__packed__)) VertexAttrib2FvCommand {
          uint32_t indx;
          uint32_t length;
        };
        VertexAttrib2FvCommand& command = ReadBuffer<VertexAttrib2FvCommand>(command_buffer, current);
        current += 2;
        SharedVector<float> values((float*)command_buffer + current, command.length);
        current += command.length;
        header.obj.ptr->VertexAttrib2Fv(command.indx, values);
        break;
      }
      case 88: { // vertexAttrib3f
        struct __attribute__ ((__packed__)) VertexAttrib3FCommand {
          uint32_t indx;
          GLfloat x;
          GLfloat y;
          GLfloat z;
        };
        VertexAttrib3FCommand& command = ReadBuffer<VertexAttrib3FCommand>(command_buffer, current);
        current += 4;
        header.obj.ptr->VertexAttrib3F(command.indx, command.x, command.y, command.z);
        break;
      }
      case 89: { // vertexAttrib3fv
        struct __attribute__ ((__packed__)) VertexAttrib3FvCommand {
          uint32_t indx;
          uint32_t length;
        };
        VertexAttrib3FvCommand& command = ReadBuffer<VertexAttrib3FvCommand>(command_buffer, current);
        current += 2;
        SharedVector<float> values((float*)command_buffer + current, command.length);
        current += command.length;
        header.obj.ptr->VertexAttrib3Fv(command.indx, values);
        break;
      }
      case 90: { // vertexAttrib4f
        struct __attribute__ ((__packed__)) VertexAttrib4FCommand {
          uint32_t indx;
          GLfloat x;
          GLfloat y;
          GLfloat z;
          GLfloat w;
        };
        VertexAttrib4FCommand& command = ReadBuffer<VertexAttrib4FCommand>(command_buffer, current);
        current += 5;
        header.obj.ptr->VertexAttrib4F(command.indx, command.x, command.y, command.z, command.w);
        break;
      }
      case 91: { // vertexAttrib4fv
        struct __attribute__ ((__packed__)) VertexAttrib4FvCommand {
          uint32_t indx;
          uint32_t length;
        };
        VertexAttrib4FvCommand& command = ReadBuffer<VertexAttrib4FvCommand>(command_buffer, current);
        current += 2;
        SharedVector<float> values((float*)command_buffer + current, command.length);
        current += command.length;
        header.obj.ptr->VertexAttrib4Fv(command.indx, values);
        break;
      }
      case 92: { // vertexAttribPointer
        struct __attribute__ ((__packed__)) VertexAttribPointerCommand {
          uint32_t indx;
          int32_t size;
          uint32_t type;
          uint32_t normalized;
          int32_t stride;
          int32_t offset;
        };
        VertexAttribPointerCommand& command = ReadBuffer<VertexAttribPointerCommand>(command_buffer, current);
        current += 6;
        header.obj.ptr->VertexAttribPointer(command.indx, command.size, command.type, command.normalized, command.stride, command.offset);
        break;
      }
      case 93: { // viewport
        struct __attribute__ ((__packed__)) ViewportCommand {
          int32_t x;
          int32_t y;
          int32_t width;
          int32_t height;
        };
        ViewportCommand& command = ReadBuffer<ViewportCommand>(command_buffer, current);
        current += 4;
        header.obj.ptr->Viewport(command.x, command.y, command.width, command.height);
        break;
      }
      case 94: { // drawArraysInstancedANGLE
        struct __attribute__ ((__packed__)) DrawArraysInstancedANGLECommand {
          uint32_t mode;
          int32_t first;
          int32_t count;
          int32_t primcount;
        };
        DrawArraysInstancedANGLECommand& command = ReadBuffer<DrawArraysInstancedANGLECommand>(command_buffer, current);
        current += 4;
        header.obj.ptr->DrawArraysInstancedANGLE(command.mode, command.first, command.count, command.primcount);
        break;
      }
      case 95: { // drawElementsInstancedANGLE
        struct __attribute__ ((__packed__)) DrawElementsInstancedANGLECommand {
          uint32_t mode;
          int32_t count;
          uint32_t type;
          int32_t offset;
          int32_t primcount;
        };
        DrawElementsInstancedANGLECommand& command = ReadBuffer<DrawElementsInstancedANGLECommand>(command_buffer, current);
        current += 5;
        header.obj.ptr->DrawElementsInstancedANGLE(command.mode, command.count, command.type, command.offset, command.primcount);
        break;
      }
      case 96: { // vertexAttribDivisorANGLE
        struct __attribute__ ((__packed__)) VertexAttribDivisorANGLECommand {
          uint32_t index;
          uint32_t divisor;
        };
        VertexAttribDivisorANGLECommand& command = ReadBuffer<VertexAttribDivisorANGLECommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->VertexAttribDivisorANGLE(command.index, command.divisor);
        break;
      }
      case 97: { // deleteVertexArrayOES
        struct __attribute__ ((__packed__)) DeleteVertexArrayOESCommand {
          union WebGLVertexArrayObjectOESPointer64bits {
            WebGLVertexArrayObjectOES* ptr;
            uint64_t _placeholder;
          } arrayObject;
        };
        DeleteVertexArrayOESCommand& command = ReadBuffer<DeleteVertexArrayOESCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->DeleteVertexArrayOES(command.arrayObject.ptr);
        break;
      }
      case 98: { // bindVertexArrayOES
        struct __attribute__ ((__packed__)) BindVertexArrayOESCommand {
          union WebGLVertexArrayObjectOESPointer64bits {
            WebGLVertexArrayObjectOES* ptr;
            uint64_t _placeholder;
          } arrayObject;
        };
        BindVertexArrayOESCommand& command = ReadBuffer<BindVertexArrayOESCommand>(command_buffer, current);
        current += 2;
        header.obj.ptr->BindVertexArrayOES(command.arrayObject.ptr);
        break;
      }
      default:{
        LOGE("=================== WebGLRenderingContext Error Report ===================");
        LOGE("Unexpected WebGLRenderingContext command! Current len: " << buffer_len << ", pos: " << current << ", method: " << header.method << ", ptr: " << header.obj.ptr << ", " << sizeof(int*));
        std::stringstream start_content;
        for (uint32_t i = 0; i < std::min(128u, current); ++i) {
          start_content << "[" << i << "]" << ReadBuffer<uint32_t>(command_buffer, i);
        }
        LOGE("Content at WebGLRenderingContext buffer start: " << start_content.str());
        std::stringstream current_content;
        for (uint32_t i = std::max(0, (int)current - 64); i < std::min(buffer_len, current + 64); ++i) {
          current_content << "[" << i << "]" << ReadBuffer<uint32_t>(command_buffer, i);
        }
        LOGE("Content around WebGLRenderingContext current: " << current_content.str());
        LOGE("==========================================================");
        NOTREACHED();
        break;
      }
    }
  }
  // Reset buffer length.
  command_buffer[0] = 1u;
}

// static
void NapiWebGLRenderingContext::OnFrame(const Napi::ObjectReference& object_ref) {
  Napi::HandleScope scope(object_ref.Env());
  auto object = object_ref.Value();
  if (object.IsEmpty()) {
      return;
  }
  DCHECK(!object.IsUndefined() && !object.IsNull());
  if (object.Get("_drew_in_this_frame")) {
    object.Set("_drew_in_this_frame", false);
    FlushCommandBuffer(object.Env());
  }
}

// static
Napi::Class* NapiWebGLRenderingContext::Class(Napi::Env env) {
  auto* clazz = env.GetInstanceData<Napi::Class>(kWebGLRenderingContextClassID);
  if (clazz) {
    return clazz;
  }

  std::vector<Wrapped::PropertyDescriptor> props;

  // Attributes
  AddAttribute(props, "canvas",
               &NapiWebGLRenderingContext::CanvasAttributeGetter,
               nullptr
               );
  AddAttribute(props, "drawingBufferWidth",
               &NapiWebGLRenderingContext::DrawingBufferWidthAttributeGetter,
               nullptr
               );
  AddAttribute(props, "drawingBufferHeight",
               &NapiWebGLRenderingContext::DrawingBufferHeightAttributeGetter,
               nullptr
               );

  // Methods
  AddInstanceMethod(props, "bindAttribLocation", &NapiWebGLRenderingContext::BindAttribLocationMethod);
  AddInstanceMethod(props, "bufferData_", &NapiWebGLRenderingContext::BufferDataMethod);
  AddInstanceMethod(props, "bufferSubData_", &NapiWebGLRenderingContext::BufferSubDataMethod);
  AddInstanceMethod(props, "checkFramebufferStatus", &NapiWebGLRenderingContext::CheckFramebufferStatusMethod);
  AddInstanceMethod(props, "compressedTexImage2D", &NapiWebGLRenderingContext::CompressedTexImage2DMethod);
  AddInstanceMethod(props, "compressedTexSubImage2D", &NapiWebGLRenderingContext::CompressedTexSubImage2DMethod);
  AddInstanceMethod(props, "createBuffer", &NapiWebGLRenderingContext::CreateBufferMethod);
  AddInstanceMethod(props, "createFramebuffer", &NapiWebGLRenderingContext::CreateFramebufferMethod);
  AddInstanceMethod(props, "createProgram", &NapiWebGLRenderingContext::CreateProgramMethod);
  AddInstanceMethod(props, "createRenderbuffer", &NapiWebGLRenderingContext::CreateRenderbufferMethod);
  AddInstanceMethod(props, "createShader", &NapiWebGLRenderingContext::CreateShaderMethod);
  AddInstanceMethod(props, "createTexture", &NapiWebGLRenderingContext::CreateTextureMethod);
  AddInstanceMethod(props, "finish", &NapiWebGLRenderingContext::FinishMethod);
  AddInstanceMethod(props, "getActiveAttrib", &NapiWebGLRenderingContext::GetActiveAttribMethod);
  AddInstanceMethod(props, "getActiveUniform", &NapiWebGLRenderingContext::GetActiveUniformMethod);
  AddInstanceMethod(props, "getAttachedShaders", &NapiWebGLRenderingContext::GetAttachedShadersMethod);
  AddInstanceMethod(props, "getAttribLocation", &NapiWebGLRenderingContext::GetAttribLocationMethod);
  AddInstanceMethod(props, "getBufferParameter", &NapiWebGLRenderingContext::GetBufferParameterMethod);
  AddInstanceMethod(props, "getContextAttributes", &NapiWebGLRenderingContext::GetContextAttributesMethod);
  AddInstanceMethod(props, "getError", &NapiWebGLRenderingContext::GetErrorMethod);
  AddInstanceMethod(props, "getExtension", &NapiWebGLRenderingContext::GetExtensionMethod);
  AddInstanceMethod(props, "getFramebufferAttachmentParameter", &NapiWebGLRenderingContext::GetFramebufferAttachmentParameterMethod);
  AddInstanceMethod(props, "getParameter", &NapiWebGLRenderingContext::GetParameterMethod);
  AddInstanceMethod(props, "getProgramParameter", &NapiWebGLRenderingContext::GetProgramParameterMethod);
  AddInstanceMethod(props, "getProgramInfoLog", &NapiWebGLRenderingContext::GetProgramInfoLogMethod);
  AddInstanceMethod(props, "getRenderbufferParameter", &NapiWebGLRenderingContext::GetRenderbufferParameterMethod);
  AddInstanceMethod(props, "getShaderParameter", &NapiWebGLRenderingContext::GetShaderParameterMethod);
  AddInstanceMethod(props, "getShaderInfoLog", &NapiWebGLRenderingContext::GetShaderInfoLogMethod);
  AddInstanceMethod(props, "getShaderPrecisionFormat", &NapiWebGLRenderingContext::GetShaderPrecisionFormatMethod);
  AddInstanceMethod(props, "getShaderSource", &NapiWebGLRenderingContext::GetShaderSourceMethod);
  AddInstanceMethod(props, "getSupportedExtensions", &NapiWebGLRenderingContext::GetSupportedExtensionsMethod);
  AddInstanceMethod(props, "getTexParameter", &NapiWebGLRenderingContext::GetTexParameterMethod);
  AddInstanceMethod(props, "getUniform", &NapiWebGLRenderingContext::GetUniformMethod);
  AddInstanceMethod(props, "getUniformLocation", &NapiWebGLRenderingContext::GetUniformLocationMethod);
  AddInstanceMethod(props, "getVertexAttrib", &NapiWebGLRenderingContext::GetVertexAttribMethod);
  AddInstanceMethod(props, "getVertexAttribOffset", &NapiWebGLRenderingContext::GetVertexAttribOffsetMethod);
  AddInstanceMethod(props, "isBuffer", &NapiWebGLRenderingContext::IsBufferMethod);
  AddInstanceMethod(props, "isContextLost", &NapiWebGLRenderingContext::IsContextLostMethod);
  AddInstanceMethod(props, "isEnabled", &NapiWebGLRenderingContext::IsEnabledMethod);
  AddInstanceMethod(props, "isFramebuffer", &NapiWebGLRenderingContext::IsFramebufferMethod);
  AddInstanceMethod(props, "isProgram", &NapiWebGLRenderingContext::IsProgramMethod);
  AddInstanceMethod(props, "isRenderbuffer", &NapiWebGLRenderingContext::IsRenderbufferMethod);
  AddInstanceMethod(props, "isShader", &NapiWebGLRenderingContext::IsShaderMethod);
  AddInstanceMethod(props, "isTexture", &NapiWebGLRenderingContext::IsTextureMethod);
  AddInstanceMethod(props, "readPixels", &NapiWebGLRenderingContext::ReadPixelsMethod);
  AddInstanceMethod(props, "shaderSource", &NapiWebGLRenderingContext::ShaderSourceMethod);
  AddInstanceMethod(props, "texImage2D", &NapiWebGLRenderingContext::TexImage2DMethod);
  AddInstanceMethod(props, "texSubImage2D", &NapiWebGLRenderingContext::TexSubImage2DMethod);
  AddInstanceMethod(props, "createVertexArrayOES", &NapiWebGLRenderingContext::CreateVertexArrayOESMethod);
  AddInstanceMethod(props, "isVertexArrayOES", &NapiWebGLRenderingContext::IsVertexArrayOESMethod);
  AddInstanceMethod(props, "getSupportedProfiles", &NapiWebGLRenderingContext::GetSupportedProfilesMethod);
  AddInstanceMethod(props, "texImage3D", &NapiWebGLRenderingContext::TexImage3DMethod);

  // Cache the class
  clazz = new Napi::Class(Wrapped::DefineClass(env, "WebGLRenderingContext", props));
  env.SetInstanceData<Napi::Class>(kWebGLRenderingContextClassID, clazz);
  return clazz;
}

// static
Function NapiWebGLRenderingContext::Constructor(Napi::Env env) {
  FunctionReference* ref = env.GetInstanceData<FunctionReference>(kWebGLRenderingContextConstructorID);
  if (ref) {
    return ref->Value();
  }

  // Cache the constructor for future use
  ref = new FunctionReference();
  ref->Reset(Class(env)->Get(env), 1);
  env.SetInstanceData<FunctionReference>(kWebGLRenderingContextConstructorID, ref);
  return ref->Value();
}

// static
void NapiWebGLRenderingContext::Install(Napi::Env env, Object& target) {
  if (target.Has("WebGLRenderingContext")) {
    return;
  }
  target.Set("WebGLRenderingContext", Constructor(env));

  Napi::Object impl = Napi::Object::New(env);
  Napi::ArrayBuffer js_command_buffer = Napi::ArrayBuffer::New(env, 1024 * 200);
  impl["commands"] = js_command_buffer;
  uint32_t* command_buffer = (uint32_t*)js_command_buffer.Data();
  command_buffer[0] = 1u;
  env.SetInstanceData(kWebGLRenderingContextCommandBufferID, command_buffer, nullptr, nullptr);
  impl["flushCommandBuffer"] = Napi::Function::New(env, &FlushCommandBufferCallback);
  target.Set("_commandBufferImpl", impl);
}

}  // namespace canvas
}  // namespace lynx
