// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_WEBGL_VERTEX_ARRAY_OBJECT_H_
#define CANVAS_WEBGL_WEBGL_VERTEX_ARRAY_OBJECT_H_

#include "canvas/gpu/command_buffer/puppet.h"
#include "canvas/util/js_object_pair.h"
#include "canvas/webgl/webgl_context_object.h"
#include "jsbridge/napi/base.h"
#include "vertex_attrib_pointer.h"
#include "webgl_buffer.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class WebGLVertexArrayObjectOES : public WebGLContextObject {
 public:
  enum VaoType {
    kVaoTypeDefault,
    kVaoTypeUser,
  };

  WebGLVertexArrayObjectOES(WebGLRenderingContext* context, VaoType vao_type);

  bool HasObject() const final;

  bool IsDefaultObject() const { return type_ == kVaoTypeDefault; }

  bool IsAllEnabledAttribBufferBound() const {
    return is_all_enabled_attrib_buffer_bound_;
  }

  WebGLBuffer* BoundElementArrayBuffer() const {
    return bound_element_array_buffer_;
  }
  void SetElementArrayBuffer(WebGLBuffer*);

  WebGLBuffer* GetArrayBufferForAttrib(GLuint index);

  void SetHasEverBeenBound() { has_ever_been_bound_ = true; }

  void UnbindBuffer(WebGLBuffer* buffer);
  void UpdateAttribBufferBoundStatus();
  void SetArrayBufferForAttrib(uint32_t index, WebGLBuffer* buffer);
  void SetAttribEnabled(uint32_t index, bool enabled);

  // TODO for compatibility, but consider to remove
  VertexAttribPointer& GetAttrPointerRef(uint32_t index);

 public:
  void DeleteObjectImpl(CommandRecorder*) final;
  void DispatchDetached(CommandRecorder*);

  bool has_gl_object_pending_;
  VaoType type_;
  bool is_all_enabled_attrib_buffer_bound_;
  Puppet<uint32_t> related_id_;
  JsObjectPair<WebGLBuffer> bound_element_array_buffer_;
  std::vector<VertexAttribPointer> attrib_pointer_vector_;
  bool has_ever_been_bound_{false};
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_WEBGL_VERTEX_ARRAY_OBJECT_H_
