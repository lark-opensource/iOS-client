
#include "es_state_buffer.h"

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {

GLint EsStateBuffer::max_vertex_attribs_size_;
GLint EsStateBuffer::max_draw_buffer_size;

EsStateBuffer::EsStateBuffer() {
  if (!max_vertex_attribs_size_)
    ::glGetIntegerv(GL_MAX_VERTEX_ATTRIBS, &max_vertex_attribs_size_);
  vertex_attrib_.resize(max_vertex_attribs_size_);
  if (!max_draw_buffer_size)
    ::glGetIntegerv(GL_MAX_DRAW_BUFFERS, &max_draw_buffer_size);
  draw_buffer_.resize(max_draw_buffer_size);
  if (max_draw_buffer_size) {
    // set default buffer to GL_BACK, make sure default value is correct when
    // bound to default fbo see
    // https://www.khronos.org/registry/OpenGL-Refpages/es3.0/html/glDrawBuffers.xhtml
    draw_buffer_[0] = GL_BACK;
  }
}

void EsStateBuffer::Save() {
  ::glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &vbo_);
  ::glGetIntegerv(GL_RENDERBUFFER_BINDING, &rbo_);
  ::glGetIntegerv(GL_VERTEX_ARRAY_BINDING, &vao_);
  ::glGetIntegerv(GL_TRANSFORM_FEEDBACK_BUFFER_BINDING, &tbo_);
  ::glGetIntegerv(GL_UNIFORM_BUFFER_BINDING, &ubo_);
  ::glGetIntegerv(GL_COPY_READ_BUFFER_BINDING, &copy_r_buffer_);
  ::glGetIntegerv(GL_COPY_WRITE_BUFFER_BINDING, &copy_w_buffer_);
  ::glGetIntegerv(GL_PIXEL_PACK_BUFFER_BINDING, &pixel_pack_buffer_);
  ::glGetIntegerv(GL_PIXEL_UNPACK_BUFFER_BINDING, &pixel_unpack_buffer_);
  ::glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &draw_fbo_);
  ::glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &read_fbo_);

  // save draw buffers
  for (auto i = 0; i < max_draw_buffer_size; ++i) {
    ::glGetIntegerv(GL_DRAW_BUFFER0 + i, &draw_buffer_[i]);
  }

  // save vao
  ::glGetIntegerv(GL_VERTEX_ARRAY_BINDING, &vao_);
  ::glBindVertexArray(0);
  ::glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &ebo_);
  for (int i = 0; i < max_vertex_attribs_size_; ++i) {
    auto& item = vertex_attrib_[i];
    ::glGetVertexAttribPointerv(i, GL_VERTEX_ATTRIB_ARRAY_POINTER,
                                &item.pointer);
    ::glGetVertexAttribfv(i, GL_CURRENT_VERTEX_ATTRIB, &item.vertex_attrib[0]);
    ::glGetVertexAttribiv(i, GL_VERTEX_ATTRIB_ARRAY_DIVISOR, &item.divisor);
    ::glGetVertexAttribiv(i, GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING,
                          &item.vbo_binding);
    ::glGetVertexAttribiv(i, GL_VERTEX_ATTRIB_ARRAY_ENABLED, &item.enabled);
    ::glGetVertexAttribiv(i, GL_VERTEX_ATTRIB_ARRAY_SIZE, &item.size);
    ::glGetVertexAttribiv(i, GL_VERTEX_ATTRIB_ARRAY_TYPE, &item.type);
    ::glGetVertexAttribiv(i, GL_VERTEX_ATTRIB_ARRAY_NORMALIZED,
                          &item.normalized);
    ::glGetVertexAttribiv(i, GL_VERTEX_ATTRIB_ARRAY_STRIDE, &item.stride);
  }
  ::glBindVertexArray(vao_);
  DCHECK(::glGetError() == GL_NO_ERROR);
}

void EsStateBuffer::SetCurrent() {
  ::glBindBuffer(GL_ARRAY_BUFFER, vbo_);
  ::glBindRenderbuffer(GL_RENDERBUFFER, rbo_);
  ::glBindBuffer(GL_TRANSFORM_FEEDBACK_BUFFER, tbo_);
  ::glBindBuffer(GL_UNIFORM_BUFFER, ubo_);
  ::glBindBuffer(GL_COPY_READ_BUFFER, copy_r_buffer_);
  ::glBindBuffer(GL_COPY_WRITE_BUFFER, copy_w_buffer_);
  ::glBindBuffer(GL_PIXEL_PACK_BUFFER, pixel_pack_buffer_);
  ::glBindBuffer(GL_PIXEL_UNPACK_BUFFER, pixel_unpack_buffer_);
  ::glBindFramebuffer(GL_DRAW_FRAMEBUFFER, draw_fbo_);
  ::glBindFramebuffer(GL_READ_FRAMEBUFFER, read_fbo_);

  // set draw buffers
  const auto size = draw_buffer_.size();
  GLenum draw_buffers[size];
  for (auto i = 0; i < size; ++i) {
    draw_buffers[i] = static_cast<GLenum>(draw_buffer_[i]);
  }
  if (draw_fbo_) {
    ::glDrawBuffers(static_cast<GLsizei>(size), draw_buffers);
  } else {
    // if bound to default fbo, only 1 draw buffer allowed
    // see
    // https://www.khronos.org/registry/OpenGL-Refpages/es3.0/html/glDrawBuffers.xhtml
    DCHECK(draw_buffers[0] == GL_BACK || draw_buffers[0] == GL_FRONT ||
           draw_buffers[0] == GL_NONE);
    ::glDrawBuffers(1, draw_buffers);
  }

  // set vao
  ::glBindVertexArray(0);
  ::glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo_);
  for (int i = 0; i < (int)vertex_attrib_.size(); ++i) {
    auto& item = vertex_attrib_[i];
    ::glBindBuffer(GL_ARRAY_BUFFER, item.vbo_binding);
    ::glVertexAttrib4fv(i, item.vertex_attrib);
    ::glVertexAttribDivisor(i, (GLuint)item.divisor);
    ::glVertexAttribPointer(i, item.size, item.type, item.normalized,
                            item.stride, item.pointer);
    if (item.enabled) {
      ::glEnableVertexAttribArray(i);
    } else {
      ::glDisableVertexAttribArray(i);
    }
  }
  ::glBindVertexArray(vao_);
  ::glBindBuffer(GL_ARRAY_BUFFER, vbo_);
  DCHECK(::glGetError() == GL_NO_ERROR);
}

}  // namespace canvas
}  // namespace lynx
