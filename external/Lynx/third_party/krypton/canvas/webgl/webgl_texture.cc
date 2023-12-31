// Copyright 2021 The Lynx Authors. All rights reserved.

#include "webgl_texture.h"

#include "canvas/gpu/gl/gl_api.h"
#include "canvas/gpu/gl/scoped_gl_reset_restore.h"
#if ENABLE_KRYPTON_EFFECT
#include "effect/krypton_effect_helper.h"
#endif

namespace lynx {
namespace canvas {

WebGLTexture::WebGLTexture(WebGLRenderingContext* context)
    : WebGLContextObject(context), has_gl_object_pending_(true) {
  related_id_.Build(GetRecorder());

  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      DCHECK(content_);
      uint32_t v = 0;
      GL::GenTextures(1, &v);
      content_->Set(v);
    }
    PuppetContent<uint32_t>* content_ = nullptr;
  };
  auto cmd = GetRecorder()->Alloc<Runnable>();
  cmd->content_ = related_id_.Get();
}

WebGLTexture::~WebGLTexture() {
#if ENABLE_KRYPTON_EFFECT
  if (tex_copy_on_js_thread_) {
    GL::DeleteTextures(1, &tex_copy_on_js_thread_);
    EffectHelper::Instance().UnRegistryTexture(tex_copy_on_js_thread_);
  }
#endif
}

void WebGLTexture::DeleteObjectImpl(CommandRecorder* recorder) {
  has_gl_object_pending_ = false;

  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      DCHECK(content_);
      GL::DeleteTextures(1, &(content_->Get()));
    }
    PuppetContent<uint32_t>* content_ = nullptr;
  };
  auto cmd = recorder->Alloc<Runnable>();
  cmd->content_ = related_id_.Get();
}

bool WebGLTexture::HasObject() const { return has_gl_object_pending_; }

uint32_t WebGLTexture::GetTarget() const { return target_; }

void WebGLTexture::SetTarget(uint32_t target) { target_ = target; }

void WebGLTexture::UpdateWidthAndHeight(uint32_t w, uint32_t h) {
#if ENABLE_KRYPTON_EFFECT
  if (width_ != w || height_ != h) {
    if (tex_copy_on_js_thread_) {
      need_update_ = true;
    }
  }
#endif
  width_ = w;
  height_ = h;
}

#if ENABLE_KRYPTON_EFFECT
uint32_t WebGLTexture::GetTexCopyOnJsThread() {
  if (!tex_copy_on_js_thread_) {
    ScopedGLResetRestore s(GL_TEXTURE_BINDING_2D);
    GL::GenTextures(1, &tex_copy_on_js_thread_);
    GL::BindTexture(GL_TEXTURE_2D, tex_copy_on_js_thread_);
    GL::TexImage2D(GL_TEXTURE_2D, 0, internal_format_, width_, height_, 0,
                   format_, type_, nullptr);
    EffectHelper::Instance().RegistryTexture(tex_copy_on_js_thread_, this);
  } else if (need_update_) {
    need_update_ = false;
    ScopedGLResetRestore s(GL_TEXTURE_BINDING_2D);
    GL::BindTexture(GL_TEXTURE_2D, tex_copy_on_js_thread_);
    GL::TexImage2D(GL_TEXTURE_2D, 0, internal_format_, width_, height_, 0,
                   format_, type_, nullptr);
  }
  return tex_copy_on_js_thread_;
}

void WebGLTexture::ForceFlushCommandbuffer() {
  resource_provider_->Flush(false, true, true);
}
#endif

}  // namespace canvas
}  // namespace lynx
