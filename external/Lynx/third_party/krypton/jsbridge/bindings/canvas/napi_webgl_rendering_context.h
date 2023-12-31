// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_WEBGL_RENDERING_CONTEXT_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_WEBGL_RENDERING_CONTEXT_H_

#include <memory>

#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class WebGLRenderingContext;

class NapiWebGLRenderingContext : public BridgeBase {
 public:
  NapiWebGLRenderingContext(const Napi::CallbackInfo&, bool skip_init_as_base = false);
  ~NapiWebGLRenderingContext() override;

  WebGLRenderingContext* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<WebGLRenderingContext>, Napi::Env);

  template <typename T>
  static T& ReadBuffer(uint32_t* buffer, size_t word_offset) {
    return *reinterpret_cast<T*>(buffer + word_offset);
  }
  static void FlushCommandBuffer(Napi::Env env);
  static void OnFrame(const Napi::ObjectReference&);

  void Init(std::unique_ptr<WebGLRenderingContext>);

  // Attributes
  Napi::Value CanvasAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value DrawingBufferWidthAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value DrawingBufferHeightAttributeGetter(const Napi::CallbackInfo&);

  // Methods
  Napi::Value BindAttribLocationMethod(const Napi::CallbackInfo&);
  Napi::Value CheckFramebufferStatusMethod(const Napi::CallbackInfo&);
  Napi::Value CompressedTexImage2DMethod(const Napi::CallbackInfo&);
  Napi::Value CompressedTexSubImage2DMethod(const Napi::CallbackInfo&);
  Napi::Value CreateBufferMethod(const Napi::CallbackInfo&);
  Napi::Value CreateFramebufferMethod(const Napi::CallbackInfo&);
  Napi::Value CreateProgramMethod(const Napi::CallbackInfo&);
  Napi::Value CreateRenderbufferMethod(const Napi::CallbackInfo&);
  Napi::Value CreateShaderMethod(const Napi::CallbackInfo&);
  Napi::Value CreateTextureMethod(const Napi::CallbackInfo&);
  Napi::Value FinishMethod(const Napi::CallbackInfo&);
  Napi::Value GetActiveAttribMethod(const Napi::CallbackInfo&);
  Napi::Value GetActiveUniformMethod(const Napi::CallbackInfo&);
  Napi::Value GetAttachedShadersMethod(const Napi::CallbackInfo&);
  Napi::Value GetAttribLocationMethod(const Napi::CallbackInfo&);
  Napi::Value GetBufferParameterMethod(const Napi::CallbackInfo&);
  Napi::Value GetContextAttributesMethod(const Napi::CallbackInfo&);
  Napi::Value GetErrorMethod(const Napi::CallbackInfo&);
  Napi::Value GetExtensionMethod(const Napi::CallbackInfo&);
  Napi::Value GetFramebufferAttachmentParameterMethod(const Napi::CallbackInfo&);
  Napi::Value GetParameterMethod(const Napi::CallbackInfo&);
  Napi::Value GetProgramParameterMethod(const Napi::CallbackInfo&);
  Napi::Value GetProgramInfoLogMethod(const Napi::CallbackInfo&);
  Napi::Value GetRenderbufferParameterMethod(const Napi::CallbackInfo&);
  Napi::Value GetShaderParameterMethod(const Napi::CallbackInfo&);
  Napi::Value GetShaderInfoLogMethod(const Napi::CallbackInfo&);
  Napi::Value GetShaderPrecisionFormatMethod(const Napi::CallbackInfo&);
  Napi::Value GetShaderSourceMethod(const Napi::CallbackInfo&);
  Napi::Value GetSupportedExtensionsMethod(const Napi::CallbackInfo&);
  Napi::Value GetTexParameterMethod(const Napi::CallbackInfo&);
  Napi::Value GetUniformMethod(const Napi::CallbackInfo&);
  Napi::Value GetUniformLocationMethod(const Napi::CallbackInfo&);
  Napi::Value GetVertexAttribMethod(const Napi::CallbackInfo&);
  Napi::Value GetVertexAttribOffsetMethod(const Napi::CallbackInfo&);
  Napi::Value IsBufferMethod(const Napi::CallbackInfo&);
  Napi::Value IsContextLostMethod(const Napi::CallbackInfo&);
  Napi::Value IsEnabledMethod(const Napi::CallbackInfo&);
  Napi::Value IsFramebufferMethod(const Napi::CallbackInfo&);
  Napi::Value IsProgramMethod(const Napi::CallbackInfo&);
  Napi::Value IsRenderbufferMethod(const Napi::CallbackInfo&);
  Napi::Value IsShaderMethod(const Napi::CallbackInfo&);
  Napi::Value IsTextureMethod(const Napi::CallbackInfo&);
  Napi::Value ReadPixelsMethod(const Napi::CallbackInfo&);
  Napi::Value ShaderSourceMethod(const Napi::CallbackInfo&);
  Napi::Value CreateVertexArrayOESMethod(const Napi::CallbackInfo&);
  Napi::Value IsVertexArrayOESMethod(const Napi::CallbackInfo&);
  Napi::Value GetSupportedProfilesMethod(const Napi::CallbackInfo&);
  Napi::Value TexImage3DMethod(const Napi::CallbackInfo&);

  // Overload Hubs
  Napi::Value BufferDataMethod(const Napi::CallbackInfo&);
  Napi::Value BufferSubDataMethod(const Napi::CallbackInfo&);
  Napi::Value TexImage2DMethod(const Napi::CallbackInfo&);
  Napi::Value TexSubImage2DMethod(const Napi::CallbackInfo&);

  // Overloads
  Napi::Value BufferDataMethodOverload1(const Napi::CallbackInfo&);
  Napi::Value BufferDataMethodOverload2(const Napi::CallbackInfo&);
  Napi::Value BufferDataMethodOverload3(const Napi::CallbackInfo&);
  Napi::Value BufferSubDataMethodOverload1(const Napi::CallbackInfo&);
  Napi::Value BufferSubDataMethodOverload2(const Napi::CallbackInfo&);
  Napi::Value TexImage2DMethodOverload1(const Napi::CallbackInfo&);
  Napi::Value TexImage2DMethodOverload2(const Napi::CallbackInfo&);
  Napi::Value TexImage2DMethodOverload3(const Napi::CallbackInfo&);
  Napi::Value TexImage2DMethodOverload4(const Napi::CallbackInfo&);
  Napi::Value TexImage2DMethodOverload5(const Napi::CallbackInfo&);
  Napi::Value TexSubImage2DMethodOverload1(const Napi::CallbackInfo&);
  Napi::Value TexSubImage2DMethodOverload2(const Napi::CallbackInfo&);
  Napi::Value TexSubImage2DMethodOverload3(const Napi::CallbackInfo&);
  Napi::Value TexSubImage2DMethodOverload4(const Napi::CallbackInfo&);
  Napi::Value TexSubImage2DMethodOverload5(const Napi::CallbackInfo&);

  // Injection hook
  static void Install(Napi::Env, Napi::Object&);

  static Napi::Function Constructor(Napi::Env);
  static Napi::Class* Class(Napi::Env);

  // Interface name
  static constexpr const char* InterfaceName() {
    return "WebGLRenderingContext";
  }

 private:
  std::unique_ptr<WebGLRenderingContext> impl_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_WEBGL_RENDERING_CONTEXT_H_
