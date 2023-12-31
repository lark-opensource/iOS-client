// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_WEBGL_SHADER_H_
#define CANVAS_WEBGL_WEBGL_SHADER_H_

#include "canvas/gpu/command_buffer/puppet.h"
#include "canvas/gpu/gl_constants.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"
#include "webgl_context_object.h"

namespace lynx {
namespace canvas {

enum EShaderState : uint32_t { NONE = 0, COMPILE_SUCC = 1, COMPILE_FAIL = 2 };

class WebGLShader : public WebGLContextObject {
 public:
  WebGLShader(WebGLRenderingContext* context, GLenum type);

  Puppet<uint32_t>& related_id() { return related_id_; }

  GLenum GetType() const { return type_; }

  void SetType(GLenum type) { type_ = type; }

  std::string GetInfoLog() const { return info_log_; }

  void SetInfoLog(std::string info_log) { info_log_ = std::move(info_log); }

  EShaderState GetState() const { return state_; };

  void SetState(EShaderState state) { state_ = state; }

  std::string GetSourceStr() const { return source_str_; }

  void SetSourceStr(std::string source_str) {
    source_str_ = std::move(source_str);
  }

  bool HasObject() const final;

 protected:
  void DeleteObjectImpl(CommandRecorder*) final;

 private:
  bool has_gl_object_pending_;

  Puppet<uint32_t> related_id_;
  GLenum type_;
  std::string info_log_;
  EShaderState state_;
  std::string source_str_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_WEBGL_SHADER_H_
