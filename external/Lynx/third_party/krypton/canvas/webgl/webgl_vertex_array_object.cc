// Copyright 2021 The Lynx Authors. All rights reserved.

#include "webgl_vertex_array_object.h"

#include "canvas/webgl/webgl_rendering_context.h"

namespace lynx {
namespace canvas {

WebGLVertexArrayObjectOES::WebGLVertexArrayObjectOES(
    WebGLRenderingContext* context, VaoType vao_type)
    : WebGLContextObject(context),
      has_gl_object_pending_(false),
      type_(vao_type),
      is_all_enabled_attrib_buffer_bound_(true) {
  attrib_pointer_vector_.resize(context->MaxVertexAttribs());
  for (auto& i : attrib_pointer_vector_) {
    i.enable_ = false;
  }

  related_id_.Build(GetRecorder());

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      DCHECK(content_);
      uint32_t _id = 0;
      GL::GenVertexArrays(1, &_id);
      content_->Set(_id);
    }
    PuppetContent<uint32_t>* content_ = nullptr;
  };
  auto cmd = GetRecorder()->Alloc<Runnable>();
  cmd->content_ = related_id_.Get();

  has_gl_object_pending_ = true;
}

void WebGLVertexArrayObjectOES::UnbindBuffer(WebGLBuffer* buffer) {
  if (bound_element_array_buffer_ == buffer) {
    buffer->OnDetached(GetRecorder());
    bound_element_array_buffer_ = nullptr;
  }
  for (auto& i : attrib_pointer_vector_) {
    if (i.array_buffer_ == buffer) {
      buffer->OnDetached(GetRecorder());
      i.array_buffer_ = nullptr;
    }
  }
  UpdateAttribBufferBoundStatus();
}

void WebGLVertexArrayObjectOES::UpdateAttribBufferBoundStatus() {
  is_all_enabled_attrib_buffer_bound_ = true;
  for (const auto& i : attrib_pointer_vector_) {
    if (i.enable_ && !i.array_buffer_) {
      is_all_enabled_attrib_buffer_bound_ = false;
      return;
    }
  }
}

void WebGLVertexArrayObjectOES::SetArrayBufferForAttrib(uint32_t index,
                                                        WebGLBuffer* buffer) {
  if (attrib_pointer_vector_[index].array_buffer_) {
    attrib_pointer_vector_[index].array_buffer_->OnDetached(GetRecorder());
  }

  if (buffer) {
    buffer->OnAttached();
    attrib_pointer_vector_[index].array_buffer_ = buffer;
  } else {
    attrib_pointer_vector_[index].array_buffer_ = nullptr;
  }

  UpdateAttribBufferBoundStatus();
}

void WebGLVertexArrayObjectOES::SetAttribEnabled(uint32_t index, bool enabled) {
  attrib_pointer_vector_[index].enable_ = enabled;
  UpdateAttribBufferBoundStatus();
}

bool WebGLVertexArrayObjectOES::HasObject() const {
  return has_gl_object_pending_;
}

void WebGLVertexArrayObjectOES::DeleteObjectImpl(CommandRecorder* recorder) {
  has_gl_object_pending_ = false;
  DispatchDetached(recorder);

  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      DCHECK(content_);
      GL::DeleteVertexArrays(1, &(content_->Get()));
    }
    PuppetContent<uint32_t>* content_ = nullptr;
  };
  auto cmd = GetRecorder()->Alloc<Runnable>();
  cmd->content_ = related_id_.Get();
}

void WebGLVertexArrayObjectOES::DispatchDetached(CommandRecorder* recorder) {
  if (DestructionInProgress()) {
    return;
  }

  if (bound_element_array_buffer_) {
    bound_element_array_buffer_->OnDetached(GetRecorder());
  }

  for (VertexAttribPointer& pointer : attrib_pointer_vector_) {
    if (pointer.array_buffer_) {
      pointer.array_buffer_->OnDetached(GetRecorder());
    }
  }
}

void WebGLVertexArrayObjectOES::SetElementArrayBuffer(WebGLBuffer* buffer) {
  if (buffer) {
    buffer->OnAttached();
  }
  if (bound_element_array_buffer_ != buffer && bound_element_array_buffer_) {
    bound_element_array_buffer_->OnDetached(GetRecorder());
  }
  bound_element_array_buffer_ = buffer;
}

VertexAttribPointer& WebGLVertexArrayObjectOES::GetAttrPointerRef(
    uint32_t index) {
  return attrib_pointer_vector_[index];
}

WebGLBuffer* WebGLVertexArrayObjectOES::GetArrayBufferForAttrib(GLuint index) {
  return attrib_pointer_vector_[index].array_buffer_;
}

}  // namespace canvas
}  // namespace lynx
