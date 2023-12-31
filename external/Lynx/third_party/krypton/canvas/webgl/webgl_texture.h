// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_WEBGL_TEXTURE_H_
#define CANVAS_WEBGL_WEBGL_TEXTURE_H_

#include "canvas/gpu/command_buffer/puppet.h"
#include "canvas/gpu/gl_constants.h"
#include "config/config.h"
#include "webgl_context_object.h"

namespace lynx {
namespace canvas {

class WebGLTexture : public WebGLContextObject {
 public:
  WebGLTexture(WebGLRenderingContext *context);
  ~WebGLTexture();

  Puppet<uint32_t> related_id_;
  uint32_t internal_format_ = KR_GL_NONE;
  uint32_t format_ = KR_GL_NONE;
  uint32_t type_ = KR_GL_NONE;
  uint32_t width_ = 0, height_ = 0;
  int32_t mag_filter_ = KR_GL_LINEAR;
  int32_t min_filter_ = KR_GL_NEAREST_MIPMAP_LINEAR;
  int32_t wrap_s_ = KR_GL_REPEAT;
  int32_t wrap_t_ = KR_GL_REPEAT;
  int32_t wrap_r_ = KR_GL_REPEAT;
  int32_t base_level_ = 0;
  int32_t max_level_ = 1000;
  int32_t compare_func_ = KR_GL_ALWAYS;
  int32_t compare_mode_ = KR_GL_NONE;
  float min_lod_ = -1000;
  float max_lod_ = 1000;
  float max_anisotropy_ext_ = 1;

  uint32_t GetTarget() const;
  void SetTarget(uint32_t target);
  bool HasObject() const final;

  void UpdateWidthAndHeight(uint32_t w, uint32_t h);

 protected:
  void DeleteObjectImpl(CommandRecorder *) final;

 private:
  GLenum target_ = 0;
  bool has_gl_object_pending_;

#if ENABLE_KRYPTON_EFFECT
 public:
  uint32_t GetTexCopyOnJsThread();
  void ForceFlushCommandbuffer();
  void SetNeedUpdate() { last_update_counts_++; }

  double GetLastUpdateCounts() { return last_update_counts_; }
#endif

 private:
  ALLOW_UNUSED_TYPE uint32_t tex_copy_on_js_thread_{0};
  ALLOW_UNUSED_TYPE int last_update_counts_{0};
  ALLOW_UNUSED_TYPE bool need_update_{false};
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_WEBGL_TEXTURE_H_
