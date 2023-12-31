// Copyright 2021 The Lynx Authors. All rights reserved.

#include "webgl_framebuffer.h"

#include "canvas/gpu/gl/gl_api.h"

namespace lynx {
namespace canvas {
WebGLFramebuffer::WebGLFramebuffer(WebGLRenderingContext *context)
    : WebGLContextObject(context), has_gl_object_pending_(false) {
  related_id_.Build(GetRecorder());
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) {
      DCHECK(content_);
      uint32_t v = 0;
      GL::GenFramebuffers(1, &v);
      content_->Set(v);
    }
    PuppetContent<uint32_t> *content_ = nullptr;
  };
  auto cmd = GetRecorder()->Alloc<Runnable>();
  cmd->content_ = related_id_.Get();
  has_gl_object_pending_ = true;
}

void WebGLFramebuffer::DeleteObjectImpl(CommandRecorder *recorder) {
  has_gl_object_pending_ = false;

  if (!DestructionInProgress()) {
    RemoveAllBindings();
  }

  struct Runnable {
    void Run(command_buffer::RunnableBuffer *) {
      GL::DeleteFramebuffers(1, &(content_->Get()));
    }
    PuppetContent<uint32_t> *content_ = nullptr;
  };
  auto cmd = recorder->Alloc<Runnable>();
  cmd->content_ = related_id_.Get();
}

void WebGLFramebuffer::RemoveAllBindings() {
  if (depth_rbuffer_) {
    depth_rbuffer_->OnDetached(nullptr);
    depth_rbuffer_ = nullptr;
  } else if (depth_texture_) {
    depth_texture_->OnDetached(nullptr);
    depth_texture_ = nullptr;
  }

  if (stencil_rbuffer_) {
    stencil_rbuffer_->OnDetached(nullptr);
    stencil_rbuffer_ = nullptr;
  } else if (stencil_texture_) {
    stencil_texture_->OnDetached(nullptr);
    stencil_texture_ = nullptr;
  }

  if (depth_stencil_rbuffer_) {
    depth_stencil_rbuffer_->OnDetached(nullptr);
    depth_stencil_rbuffer_ = nullptr;
  } else if (depth_stencil_texture_) {
    depth_stencil_texture_->OnDetached(nullptr);
    depth_stencil_texture_ = nullptr;
  }

  for (auto &i : colors_rbuffer_) {
    if (i) {
      i->OnDetached(nullptr);
      i = nullptr;
    }
  }

  for (auto &i : colors_texture_) {
    if (i) {
      i->OnDetached(nullptr);
      i = nullptr;
    }
  }
}

void WebGLFramebuffer::DetachRenderbuffer(GLenum target,
                                          WebGLRenderbuffer *renderbuffer) {
  if (depth_stencil_rbuffer_ == renderbuffer) {
    DetachRenderbufferFromGL(GetRecorder(), target,
                             GL_DEPTH_STENCIL_ATTACHMENT);
    renderbuffer->OnDetached(nullptr);
    depth_stencil_rbuffer_ = nullptr;
  }
  if (depth_rbuffer_ == renderbuffer) {
    DetachRenderbufferFromGL(GetRecorder(), target, GL_DEPTH_ATTACHMENT);
    renderbuffer->OnDetached(nullptr);
    depth_rbuffer_ = nullptr;
  }
  if (stencil_rbuffer_ == renderbuffer) {
    DetachRenderbufferFromGL(GetRecorder(), target, GL_STENCIL_ATTACHMENT);
    renderbuffer->OnDetached(nullptr);
    stencil_rbuffer_ = nullptr;
  }
  for (size_t i = 0; i < colors_rbuffer_.size(); i++) {
    if (colors_rbuffer_[i] == renderbuffer) {
      DetachRenderbufferFromGL(GetRecorder(), target,
                               static_cast<GLenum>(GL_COLOR_ATTACHMENT0 + i));
      renderbuffer->OnDetached(nullptr);
      colors_rbuffer_[i] = nullptr;
    }
  }
}

void WebGLFramebuffer::DetachTexture(GLenum target, WebGLTexture *texture) {
  if (depth_stencil_texture_ == texture) {
    DetachTextureFromGL(GetRecorder(), target, GL_DEPTH_STENCIL_ATTACHMENT,
                        texture);
    texture->OnDetached(nullptr);
    depth_stencil_rbuffer_ = nullptr;
  }
  if (depth_texture_ == texture) {
    DetachTextureFromGL(GetRecorder(), target, GL_DEPTH_ATTACHMENT, texture);
    texture->OnDetached(nullptr);
    depth_texture_ = nullptr;
  }
  if (stencil_texture_ == texture) {
    DetachTextureFromGL(GetRecorder(), target, GL_STENCIL_ATTACHMENT, texture);
    texture->OnDetached(nullptr);
    stencil_texture_ = nullptr;
  }
  for (size_t i = 0; i < colors_texture_.size(); i++) {
    if (colors_texture_[i] == texture) {
      DetachTextureFromGL(GetRecorder(), target,
                          static_cast<GLenum>(GL_COLOR_ATTACHMENT0 + i),
                          texture);
      texture->OnDetached(nullptr);
      colors_texture_[i] = nullptr;
    }
  }
}

void WebGLFramebuffer::AttachAttachment(uint32_t attachment,
                                        WebGLRenderbuffer *renderbuffer) {
  if (renderbuffer) {
    renderbuffer->OnAttached();
  }
  if (attachment >= KR_GL_COLOR_ATTACHMENT0 &&
      attachment < (KR_GL_COLOR_ATTACHMENT0 +
                    device_attributes_.max_color_attachments_)) {
    int index = attachment - KR_GL_COLOR_ATTACHMENT0;
    if (colors_rbuffer_[index]) colors_rbuffer_[index]->OnDetached(nullptr);
    colors_rbuffer_[index] = renderbuffer;
    colors_texture_[index] = nullptr;
  } else if (attachment == KR_GL_DEPTH_ATTACHMENT) {
    if (depth_rbuffer_) depth_rbuffer_->OnDetached(nullptr);
    depth_rbuffer_ = renderbuffer;
    depth_texture_ = nullptr;
  } else if (attachment == KR_GL_DEPTH_STENCIL_ATTACHMENT) {
    if (depth_stencil_rbuffer_) depth_stencil_rbuffer_->OnDetached(nullptr);
    depth_stencil_rbuffer_ = renderbuffer;
    depth_stencil_texture_ = nullptr;
  } else if (attachment == KR_GL_STENCIL_ATTACHMENT) {
    if (stencil_rbuffer_) stencil_rbuffer_->OnDetached(nullptr);
    stencil_rbuffer_ = renderbuffer;
    stencil_texture_ = nullptr;
  }
}

void WebGLFramebuffer::AttachAttachment(uint32_t attachment,
                                        WebGLTexture *texture) {
  if (texture) {
    texture->OnAttached();
  }
  if (attachment >= KR_GL_COLOR_ATTACHMENT0 &&
      attachment < (KR_GL_COLOR_ATTACHMENT0 +
                    device_attributes_.max_color_attachments_)) {
    int index = attachment - KR_GL_COLOR_ATTACHMENT0;
    if (colors_texture_[index]) colors_texture_[index]->OnDetached(nullptr);
    colors_texture_[index] = texture;
    colors_rbuffer_[index] = nullptr;
  } else if (attachment == KR_GL_DEPTH_ATTACHMENT) {
    if (depth_texture_) depth_texture_->OnDetached(nullptr);
    depth_texture_ = texture;
    depth_rbuffer_ = nullptr;
  } else if (attachment == KR_GL_DEPTH_STENCIL_ATTACHMENT) {
    if (depth_stencil_texture_) depth_stencil_texture_->OnDetached(nullptr);
    depth_stencil_texture_ = texture;
    depth_stencil_rbuffer_ = nullptr;
  } else if (attachment == KR_GL_STENCIL_ATTACHMENT) {
    if (stencil_texture_) stencil_texture_->OnDetached(nullptr);
    stencil_texture_ = texture;
    stencil_rbuffer_ = nullptr;
  }
}

void WebGLFramebuffer::SetHasEverBeenBound() { has_ever_been_bound_ = true; }

bool WebGLFramebuffer::HasEverBeenBound() { return has_ever_been_bound_; }

void WebGLFramebuffer::setGlobalAttributes(
    GLDeviceAttributes device_attributes) {
  device_attributes_ = std::move(device_attributes);
  colors_rbuffer_.resize(device_attributes_.max_color_attachments_);
  colors_texture_.resize(device_attributes_.max_color_attachments_);
  colors_textarget_.resize(device_attributes_.max_color_attachments_,
                           KR_GL_TEXTURE_2D);
}

GLenum WebGLFramebuffer::GetAttachmentInternalFormat(uint32_t index) {
  uint32_t array_idx = index - GL_COLOR_ATTACHMENT0;
  if (colors_rbuffer_[array_idx]) {
    return colors_rbuffer_[array_idx]->internal_format_;
  }
  if (colors_texture_[array_idx]) {
    return colors_texture_[array_idx]->internal_format_;
  }
  return 0;
}

GLenum WebGLFramebuffer::GetAttachmentType(uint32_t index) {
  uint32_t array_idx = index - GL_COLOR_ATTACHMENT0;
  if (colors_rbuffer_[array_idx]) {
    return colors_rbuffer_[array_idx]->type_;
  }
  if (colors_texture_[array_idx]) {
    return colors_texture_[array_idx]->type_;
  }
  return 0;
}

GLenum WebGLFramebuffer::IsPossiblyComplete() {
  for (size_t i = 0; i < colors_rbuffer_.size(); i++) {
    if (colors_rbuffer_[i]) {
      uint32_t internal_format = colors_rbuffer_[i]->internal_format_;
      // Workaround for GPU drivers that incorrectly expose these formats as
      // renderable:
      if (internal_format == KR_GL_LUMINANCE ||
          internal_format == KR_GL_ALPHA ||
          internal_format == KR_GL_LUMINANCE_ALPHA) {
        return KR_GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT;
        ;
      }
    }
  }
  for (size_t i = 0; i < colors_texture_.size(); i++) {
    if (colors_texture_[i]) {
      uint32_t internal_format = colors_texture_[i]->internal_format_;
      if (internal_format == KR_GL_LUMINANCE ||
          internal_format == KR_GL_ALPHA ||
          internal_format == KR_GL_LUMINANCE_ALPHA) {
        return KR_GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT;
      }
    }
  }
  return KR_GL_FRAMEBUFFER_COMPLETE;
}

void WebGLFramebuffer::DetachRenderbufferFromGL(CommandRecorder *recorder,
                                                GLenum target,
                                                GLenum attachment) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) {
      GL::FramebufferRenderbuffer(target, attachment, GL_RENDERBUFFER, 0);
    }

    GLenum target;
    GLenum attachment;
  };
  auto *cmd = recorder->Alloc<Runnable>();
  cmd->target = target;
  cmd->attachment = attachment;
}

void WebGLFramebuffer::DetachTextureFromGL(CommandRecorder *recorder,
                                           GLenum target, GLenum attachment,
                                           WebGLTexture *texture) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) {
      // webgl 1 only support framebuffertexture2d with level 0
      GL::FramebufferTexture2D(target, attachment, tex_target, 0, 0);
    }

    GLenum target;
    GLenum attachment;
    GLenum tex_target;
  };
  auto *cmd = recorder->Alloc<Runnable>();
  cmd->target = target;
  cmd->attachment = attachment;
  cmd->tex_target = texture->GetTarget();
}

}  // namespace canvas
}  // namespace lynx
