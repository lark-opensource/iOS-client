// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_WEBGL_PROGRAM_H_
#define CANVAS_WEBGL_WEBGL_PROGRAM_H_

#include "canvas/gpu/command_buffer/puppet.h"
#include "canvas/util/js_object_pair.h"
#include "third_party/krypton/canvas/gpu/command_buffer/command_recorder.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"
#include "webgl_context_object.h"
#include "webgl_program_shader_status.h"
#include "webgl_shader.h"

namespace lynx {
namespace canvas {

class WebGLProgram : public WebGLContextObject {
 public:
  WebGLProgram(WebGLRenderingContext* context);

  void IncreaseLinkCount() { link_count_++; }

  unsigned LinkCount() const { return link_count_; }

  void Link(CommandRecorder* recorder);

  bool HasObject() const final;

  WebGLShader* GetAttachedShader(GLenum type);
  bool AttachShader(WebGLShader*);
  bool DetachShader(WebGLShader*);

  Puppet<uint32_t>& related_id() { return related_id_; }

  std::shared_ptr<WebGLProgramShaderStatus> GetShaderStatus() const {
    return shader_status_;
  }

  //  std::vector<std::string> tf_varyings;
  //  uint32_t tf_buffer_mode = KR_GL_NONE;

 protected:
  void DeleteObjectImpl(CommandRecorder*) final;

 private:
  unsigned link_count_;
  bool has_gl_object_pending_;
  Puppet<uint32_t> related_id_;
  JsObjectPair<WebGLShader> vertex_shader_;
  JsObjectPair<WebGLShader> fragment_shader_;
  std::shared_ptr<WebGLProgramShaderStatus> shader_status_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_WEBGL_PROGRAM_H_
