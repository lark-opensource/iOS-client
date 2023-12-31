// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_WEBGL_FRAMEBUFFER_H_
#define CANVAS_WEBGL_WEBGL_FRAMEBUFFER_H_

#include "canvas/gpu/command_buffer/puppet.h"
#include "canvas/gpu/gl_device_attributes.h"
#include "webgl_renderbuffer.h"
#include "webgl_texture.h"

namespace lynx {
namespace canvas {
class WebGLRenderingContext;

class WebGLFramebuffer : public WebGLContextObject {
 public:
  WebGLFramebuffer(WebGLRenderingContext* context);
  Puppet<uint32_t> related_id_;
  bool has_ever_been_bound_ = false;

  std::vector<JsObjectPair<WebGLRenderbuffer>> colors_rbuffer_;
  std::vector<JsObjectPair<WebGLTexture>> colors_texture_;
  std::vector<uint32_t> colors_textarget_;

  JsObjectPair<WebGLRenderbuffer> depth_rbuffer_;
  JsObjectPair<WebGLTexture> depth_texture_;

  JsObjectPair<WebGLRenderbuffer> stencil_rbuffer_;
  JsObjectPair<WebGLTexture> stencil_texture_;

  JsObjectPair<WebGLRenderbuffer> depth_stencil_rbuffer_;
  JsObjectPair<WebGLTexture> depth_stencil_texture_;

  void DetachRenderbuffer(GLenum target, WebGLRenderbuffer* renderbuffer);
  void DetachTexture(GLenum target, WebGLTexture* texture);
  void AttachAttachment(uint32_t attachment, WebGLRenderbuffer* renderbuffer);
  void AttachAttachment(uint32_t attachment, WebGLTexture* texture);
  void SetHasEverBeenBound();
  bool HasEverBeenBound();

  std::vector<uint32_t> draw_buffers_;

  void setGlobalAttributes(GLDeviceAttributes device_attributes);

  GLenum GetAttachmentInternalFormat(uint32_t index);
  GLenum GetAttachmentType(uint32_t index);

  GLenum IsPossiblyComplete();

 private:
  bool has_gl_object_pending_;
  GLDeviceAttributes device_attributes_;

 protected:
  bool HasObject() const override { return has_gl_object_pending_; }
  void DeleteObjectImpl(CommandRecorder*) final;
  void RemoveAllBindings();
  void DetachRenderbufferFromGL(CommandRecorder* recorder, GLenum target,
                                GLenum attachment);
  void DetachTextureFromGL(CommandRecorder* recorder, GLenum target,
                           GLenum attachment, WebGLTexture* texture);
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_WEBGL_FRAMEBUFFER_H_
