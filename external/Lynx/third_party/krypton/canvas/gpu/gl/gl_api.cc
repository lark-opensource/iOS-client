// Copyright 2021 The Lynx Authors. All rights reserved.

#include "gl_api.h"

#include "canvas/base/log.h"
#include "canvas/gpu/gl_context.h"
#include "canvas/gpu/gl_virtual_context.h"

// #define DEBUG_GL
// #define PRINT_GL_COMMAND
#ifdef DEBUG_GL
#define GL_CHECK(gl)                          \
  gl;                                         \
  int err = glGetError();                     \
  if (err != GL_NO_ERROR) {                   \
    KRYPTON_LOGE("[GL ERROR] err = ") << err; \
    ForGLErrorBreakpoint();                   \
  }
#else

#ifdef PRINT_GL_COMMAND
#define GL_CHECK(gl) \
  gl;                \
  LOGI("[GL COMMAND] ") << #gl;
#else
#define GL_CHECK(gl) gl;
#endif

#endif

namespace lynx {
namespace canvas {
namespace {
#ifdef DEBUG_GL
void ForGLErrorBreakpoint() { printf("GL ERROR THROW "); }
#endif
}  // namespace
void GL::ActiveTexture(GLenum texture) { GL_CHECK(glActiveTexture(texture)) }

void GL::AttachShader(GLuint program, GLuint shader) {
  GL_CHECK(glAttachShader(program, shader))
}

void GL::BindAttribLocation(GLuint program, GLuint index, const GLchar* name) {
  GL_CHECK(glBindAttribLocation(program, index, name))
}

void GL::BindBuffer(GLenum target, GLuint buffer) {
  GL_CHECK(glBindBuffer(target, buffer))
}

void GL::BindFramebuffer(GLenum target, GLuint framebuffer) {
  GL_CHECK(glBindFramebuffer(target, framebuffer))
}

void GL::BindRenderbuffer(GLenum target, GLuint renderbuffer) {
  GL_CHECK(glBindRenderbuffer(target, renderbuffer))
}

void GL::BindTexture(GLenum target, GLuint texture) {
  GL_CHECK(glBindTexture(target, texture))
}

void GL::BlendColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha) {
  GL_CHECK(glBlendColor(red, green, blue, alpha));
}

void GL::BlendEquation(GLenum mode) { GL_CHECK(glBlendEquation(mode)) }

void GL::BlendEquationSeparate(GLenum modeRGB, GLenum modeAlpha) {
  GL_CHECK(glBlendEquationSeparate(modeRGB, modeAlpha))
}

void GL::BlendFunc(GLenum sfactor, GLenum dfactor) {
  GL_CHECK(glBlendFunc(sfactor, dfactor))
}

void GL::BlendFuncSeparate(GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha,
                           GLenum dstAlpha) {
  GL_CHECK(glBlendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha))
}

void GL::BufferData(GLenum target, GLsizeiptr size, const GLvoid* data,
                    GLenum usage) {
  GL_CHECK(glBufferData(target, size, data, usage))
}

void GL::BufferSubData(GLenum target, GLintptr offset, GLsizeiptr size,
                       const GLvoid* data){
    GL_CHECK(glBufferSubData(target, offset, size, data))}

GLenum GL::CheckFramebufferStatus(GLenum target) {
  GL_CHECK(GLenum res = glCheckFramebufferStatus(target));
  return res;
}

void GL::Clear(GLbitfield mask) { GL_CHECK(glClear(mask)); }

void GL::ClearColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha) {
  GL_CHECK(glClearColor(red, green, blue, alpha));
}

void GL::ClearDepthf(GLclampf depth) { GL_CHECK(glClearDepthf(depth)) }

void GL::ClearStencil(GLint s) { GL_CHECK(glClearStencil(s)) }

void GL::ColorMask(GLboolean red, GLboolean green, GLboolean blue,
                   GLboolean alpha) {
  GL_CHECK(glColorMask(red, green, blue, alpha))
}

void GL::CompileShader(GLuint shader) { GL_CHECK(glCompileShader(shader)) }

void GL::CompressedTexImage2D(GLenum target, GLint level, GLenum internalformat,
                              GLsizei width, GLsizei height, GLint border,
                              GLsizei imageSize, const GLvoid* data) {
  GL_CHECK(glCompressedTexImage2D(target, level, internalformat, width, height,
                                  border, imageSize, data))
}

void GL::CompressedTexSubImage2D(GLenum target, GLint level, GLint xoffset,
                                 GLint yoffset, GLsizei width, GLsizei height,
                                 GLenum format, GLsizei imageSize,
                                 const GLvoid* data) {
  GL_CHECK(glCompressedTexSubImage2D(target, level, xoffset, yoffset, width,
                                     height, format, imageSize, data))
}

void GL::CopyTexImage2D(GLenum target, GLint level, GLenum internalformat,
                        GLint x, GLint y, GLsizei width, GLsizei height,
                        GLint border) {
  GL_CHECK(glCopyTexImage2D(target, level, internalformat, x, y, width, height,
                            border))
}

void GL::CopyTexSubImage2D(GLenum target, GLint level, GLint xoffset,
                           GLint yoffset, GLint x, GLint y, GLsizei width,
                           GLsizei height){
    GL_CHECK(glCopyTexSubImage2D(target, level, xoffset, yoffset, x, y, width,
                                 height))}

GLuint GL::CreateProgram(void) {
  GL_CHECK(GLuint res = glCreateProgram())
  return res;
}

GLuint GL::CreateShader(GLenum type) {
  GL_CHECK(GLuint res = glCreateShader(type))
  return res;
}

void GL::CullFace(GLenum mode) { GL_CHECK(glCullFace(mode)) }

void GL::DeleteBuffers(GLsizei n, const GLuint* buffers) {
  GL_CHECK(glDeleteBuffers(n, buffers))
}

void GL::DeleteFramebuffers(GLsizei n, const GLuint* framebuffers) {
  GL_CHECK(glDeleteFramebuffers(n, framebuffers))
}

void GL::DeleteProgram(GLuint program) { GL_CHECK(glDeleteProgram(program)) }

void GL::DeleteRenderbuffers(GLsizei n, const GLuint* renderbuffers) {
  GL_CHECK(glDeleteRenderbuffers(n, renderbuffers))
}

void GL::DeleteShader(GLuint shader) { GL_CHECK(glDeleteShader(shader)) }

void GL::DeleteTextures(GLsizei n, const GLuint* textures) {
  GL_CHECK(glDeleteTextures(n, textures))
}

void GL::DepthFunc(GLenum func) { GL_CHECK(glDepthFunc(func)) }

void GL::DepthMask(GLboolean flag) { GL_CHECK(glDepthMask(flag)) }

void GL::DepthRangef(GLclampf zNear, GLclampf zFar) {
  GL_CHECK(glDepthRangef(zNear, zFar))
}

void GL::DetachShader(GLuint program, GLuint shader) {
  GL_CHECK(glDetachShader(program, shader))
}

void GL::Disable(GLenum cap) { GL_CHECK(glDisable(cap)) }

void GL::DisableVertexAttribArray(GLuint index) {
  GL_CHECK(glDisableVertexAttribArray(index))
}

void GL::DrawArrays(GLenum mode, GLint first, GLsizei count) {
  GL_CHECK(glDrawArrays(mode, first, count))
}

void GL::DrawElements(GLenum mode, GLsizei count, GLenum type,
                      const GLvoid* indices) {
  GL_CHECK(glDrawElements(mode, count, type, indices))
}

void GL::Enable(GLenum cap) { GL_CHECK(glEnable(cap)) }

void GL::EnableVertexAttribArray(GLuint index) {
  GL_CHECK(glEnableVertexAttribArray(index))
}

void GL::Finish(void) { GL_CHECK(glFinish()) }

void GL::Flush(void) { GL_CHECK(glFlush()) }

void GL::FramebufferRenderbuffer(GLenum target, GLenum attachment,
                                 GLenum renderbuffertarget,
                                 GLuint renderbuffer) {
  GL_CHECK(glFramebufferRenderbuffer(target, attachment, renderbuffertarget,
                                     renderbuffer));
}

void GL::FramebufferTexture2D(GLenum target, GLenum attachment,
                              GLenum textarget, GLuint texture, GLint level) {
  GL_CHECK(
      glFramebufferTexture2D(target, attachment, textarget, texture, level))
}

void GL::FrontFace(GLenum mode) { GL_CHECK(glFrontFace(mode)) }

void GL::GenBuffers(GLsizei n, GLuint* buffers) {
  GL_CHECK(glGenBuffers(n, buffers))
}

void GL::GenerateMipmap(GLenum target) { GL_CHECK(glGenerateMipmap(target)) }

void GL::GenFramebuffers(GLsizei n, GLuint* framebuffers) {
  GL_CHECK(glGenFramebuffers(n, framebuffers))
}

void GL::GenRenderbuffers(GLsizei n, GLuint* renderbuffers) {
  GL_CHECK(glGenRenderbuffers(n, renderbuffers))
}

void GL::GenTextures(GLsizei n, GLuint* textures) {
  GL_CHECK(glGenTextures(n, textures))
}

void GL::GetActiveAttrib(GLuint program, GLuint index, GLsizei bufsize,
                         GLsizei* length, GLint* size, GLenum* type,
                         GLchar* name) {
  GL_CHECK(glGetActiveAttrib(program, index, bufsize, length, size, type, name))
}

void GL::GetActiveUniform(GLuint program, GLuint index, GLsizei bufsize,
                          GLsizei* length, GLint* size, GLenum* type,
                          GLchar* name) {
  GL_CHECK(
      glGetActiveUniform(program, index, bufsize, length, size, type, name))
}

void GL::GetAttachedShaders(GLuint program, GLsizei maxcount, GLsizei* count,
                            GLuint* shaders) {
  GL_CHECK(glGetAttachedShaders(program, maxcount, count, shaders))
}

int GL::GetAttribLocation(GLuint program, const GLchar* name) {
  GL_CHECK(int res = glGetAttribLocation(program, name))
  return res;
}

void GL::GetBooleanv(GLenum pname, GLboolean* params) {
  GL_CHECK(glGetBooleanv(pname, params))
}

void GL::GetBufferParameteriv(GLenum target, GLenum pname, GLint* params) {
  GL_CHECK(glGetBufferParameteriv(target, pname, params))
}

void GL::GetFloatv(GLenum pname, GLfloat* params) {
  GL_CHECK(glGetFloatv(pname, params))
}

void GL::GetFramebufferAttachmentParameteriv(GLenum target, GLenum attachment,
                                             GLenum pname, GLint* params) {
  GL_CHECK(
      glGetFramebufferAttachmentParameteriv(target, attachment, pname, params))
}

void GL::GetIntegerv(GLenum pname, GLint* params) {
  GL_CHECK(glGetIntegerv(pname, params))
}

void GL::GetProgramiv(GLuint program, GLenum pname, GLint* params) {
  GL_CHECK(glGetProgramiv(program, pname, params))
}

void GL::GetProgramInfoLog(GLuint program, GLsizei bufsize, GLsizei* length,
                           GLchar* infolog) {
  GL_CHECK(glGetProgramInfoLog(program, bufsize, length, infolog))
}

void GL::GetRenderbufferParameteriv(GLenum target, GLenum pname,
                                    GLint* params) {
  GL_CHECK(glGetRenderbufferParameteriv(target, pname, params))
}

void GL::GetShaderiv(GLuint shader, GLenum pname, GLint* params) {
  GL_CHECK(glGetShaderiv(shader, pname, params))
}

void GL::GetShaderInfoLog(GLuint shader, GLsizei bufsize, GLsizei* length,
                          GLchar* infolog) {
  GL_CHECK(glGetShaderInfoLog(shader, bufsize, length, infolog))
}

void GL::GetShaderPrecisionFormat(GLenum shadertype, GLenum precisiontype,
                                  GLint* range, GLint* precision) {
  GL_CHECK(
      glGetShaderPrecisionFormat(shadertype, precisiontype, range, precision))
}

void GL::GetShaderSource(GLuint shader, GLsizei bufsize, GLsizei* length,
                         GLchar* source) {
  GL_CHECK(glGetShaderSource(shader, bufsize, length, source))
}

const GLubyte* GL::GetString(GLenum name) {
  GL_CHECK(const GLubyte* res = glGetString(name))
  return res;
}

void GL::GetTexParameterfv(GLenum target, GLenum pname, GLfloat* params) {
  GL_CHECK(glGetTexParameterfv(target, pname, params))
}

void GL::GetTexParameteriv(GLenum target, GLenum pname, GLint* params) {
  GL_CHECK(glGetTexParameteriv(target, pname, params))
}

void GL::GetUniformfv(GLuint program, GLint location, GLfloat* params) {
  GL_CHECK(glGetUniformfv(program, location, params))
}

void GL::GetUniformiv(GLuint program, GLint location, GLint* params) {
  GL_CHECK(glGetUniformiv(program, location, params))
}

int GL::GetUniformLocation(GLuint program, const GLchar* name) {
  GL_CHECK(int res = glGetUniformLocation(program, name))
  return res;
}

void GL::GetVertexAttribfv(GLuint index, GLenum pname, GLfloat* params) {
  GL_CHECK(glGetVertexAttribfv(index, pname, params))
}

void GL::GetVertexAttribiv(GLuint index, GLenum pname, GLint* params) {
  GL_CHECK(glGetVertexAttribiv(index, pname, params))
}

void GL::GetVertexAttribPointerv(GLuint index, GLenum pname, GLvoid** pointer) {
  GL_CHECK(glGetVertexAttribPointerv(index, pname, pointer))
}

void GL::Hint(GLenum target, GLenum mode){GL_CHECK(glHint(target, mode))}

GLboolean GL::IsBuffer(GLuint buffer) {
  GL_CHECK(GLboolean res = glIsBuffer(buffer))
  return res;
}

GLboolean GL::IsEnabled(GLenum cap) {
  GL_CHECK(GLboolean res = glIsEnabled(cap))
  return res;
}

GLboolean GL::IsFramebuffer(GLuint framebuffer) {
  GL_CHECK(GLboolean res = glIsFramebuffer(framebuffer))
  return res;
}

GLboolean GL::IsProgram(GLuint program) {
  GL_CHECK(GLboolean res = glIsProgram(program))
  return res;
}

GLboolean GL::IsRenderbuffer(GLuint renderbuffer) {
  GL_CHECK(GLboolean res = glIsRenderbuffer(renderbuffer))
  return res;
}

GLboolean GL::IsShader(GLuint shader) {
  GL_CHECK(GLboolean res = glIsShader(shader));
  return res;
}

GLboolean GL::IsTexture(GLuint texture) {
  GL_CHECK(GLboolean res = glIsTexture(texture))
  return res;
}

void GL::LineWidth(GLfloat width) { GL_CHECK(glLineWidth(width)) }

void GL::LinkProgram(GLuint program) { GL_CHECK(glLinkProgram(program)) }

void GL::PixelStorei(GLenum pname, GLint param) {
  GL_CHECK(glPixelStorei(pname, param))
}

void GL::PolygonOffset(GLfloat factor, GLfloat units) {
  GL_CHECK(glPolygonOffset(factor, units))
}

void GL::ReadPixels(GLint x, GLint y, GLsizei width, GLsizei height,
                    GLenum format, GLenum type, GLvoid* pixels) {
  GL_CHECK(glReadPixels(x, y, width, height, format, type, pixels))
}

void GL::ReleaseShaderCompiler(void) { GL_CHECK(glReleaseShaderCompiler()) }

void GL::RenderbufferStorage(GLenum target, GLenum internalformat,
                             GLsizei width, GLsizei height) {
  GL_CHECK(glRenderbufferStorage(target, internalformat, width, height))
}

void GL::SampleCoverage(GLclampf value, GLboolean invert) {
  GL_CHECK(glSampleCoverage(value, invert))
}

void GL::Scissor(GLint x, GLint y, GLsizei width, GLsizei height) {
  GL_CHECK(glScissor(x, y, width, height))
}

void GL::ShaderBinary(GLsizei n, const GLuint* shaders, GLenum binaryformat,
                      const GLvoid* binary, GLsizei length) {
  GL_CHECK(glShaderBinary(n, shaders, binaryformat, binary, length))
}

void GL::ShaderSource(GLuint shader, GLsizei count, const GLchar* const* string,
                      const GLint* length) {
  GL_CHECK(glShaderSource(shader, count, string, length))
}

void GL::StencilFunc(GLenum func, GLint ref, GLuint mask) {
  GL_CHECK(glStencilFunc(func, ref, mask))
}

void GL::StencilFuncSeparate(GLenum face, GLenum func, GLint ref, GLuint mask) {
  GL_CHECK(glStencilFuncSeparate(face, func, ref, mask))
}

void GL::StencilMask(GLuint mask) { GL_CHECK(glStencilMask(mask)) }

void GL::StencilMaskSeparate(GLenum face, GLuint mask) {
  GL_CHECK(glStencilMaskSeparate(face, mask))
}

void GL::StencilOp(GLenum fail, GLenum zfail, GLenum zpass) {
  GL_CHECK(glStencilOp(fail, zfail, zpass))
}

void GL::StencilOpSeparate(GLenum face, GLenum fail, GLenum zfail,
                           GLenum zpass) {
  GL_CHECK(glStencilOpSeparate(face, fail, zfail, zpass))
}

void GL::TexImage2D(GLenum target, GLint level, GLint internalformat,
                    GLsizei width, GLsizei height, GLint border, GLenum format,
                    GLenum type, const GLvoid* pixels) {
  GL_CHECK(glTexImage2D(target, level, internalformat, width, height, border,
                        format, type, pixels))
}

void GL::TexParameterf(GLenum target, GLenum pname, GLfloat param) {
  GL_CHECK(glTexParameterf(target, pname, param))
}

void GL::TexParameterfv(GLenum target, GLenum pname, const GLfloat* params) {
  GL_CHECK(glTexParameterfv(target, pname, params))
}

void GL::TexParameteri(GLenum target, GLenum pname, GLint param) {
  GL_CHECK(glTexParameteri(target, pname, param))
}

void GL::TexParameteriv(GLenum target, GLenum pname, const GLint* params) {
  GL_CHECK(glTexParameteriv(target, pname, params))
}

void GL::TexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset,
                       GLsizei width, GLsizei height, GLenum format,
                       GLenum type, const GLvoid* pixels) {
  GL_CHECK(glTexSubImage2D(target, level, xoffset, yoffset, width, height,
                           format, type, pixels))
}

void GL::Uniform1f(GLint location, GLfloat x) {
  GL_CHECK(glUniform1f(location, x))
}

void GL::Uniform1fv(GLint location, GLsizei count, const GLfloat* v) {
  GL_CHECK(glUniform1fv(location, count, v))
}

void GL::Uniform1i(GLint location, GLint x) {
  GL_CHECK(glUniform1i(location, x))
}

void GL::Uniform1iv(GLint location, GLsizei count, const GLint* v) {
  GL_CHECK(glUniform1iv(location, count, v))
}

void GL::Uniform2f(GLint location, GLfloat x, GLfloat y) {
  GL_CHECK(glUniform2f(location, x, y))
}

void GL::Uniform2fv(GLint location, GLsizei count, const GLfloat* v) {
  GL_CHECK(glUniform2fv(location, count, v))
}

void GL::Uniform2i(GLint location, GLint x, GLint y) {
  GL_CHECK(glUniform2i(location, x, y))
}

void GL::Uniform2iv(GLint location, GLsizei count, const GLint* v) {
  GL_CHECK(glUniform2iv(location, count, v))
}

void GL::Uniform3f(GLint location, GLfloat x, GLfloat y, GLfloat z) {
  GL_CHECK(glUniform3f(location, x, y, z))
}

void GL::Uniform3fv(GLint location, GLsizei count, const GLfloat* v) {
  GL_CHECK(glUniform3fv(location, count, v))
}

void GL::Uniform3i(GLint location, GLint x, GLint y, GLint z) {
  GL_CHECK(glUniform3i(location, x, y, z))
}

void GL::Uniform3iv(GLint location, GLsizei count, const GLint* v) {
  GL_CHECK(glUniform3iv(location, count, v))
}

void GL::Uniform4f(GLint location, GLfloat x, GLfloat y, GLfloat z, GLfloat w) {
  GL_CHECK(glUniform4f(location, x, y, z, w))
}

void GL::Uniform4fv(GLint location, GLsizei count, const GLfloat* v) {
  GL_CHECK(glUniform4fv(location, count, v))
}

void GL::Uniform4i(GLint location, GLint x, GLint y, GLint z, GLint w) {
  GL_CHECK(glUniform4i(location, x, y, z, w))
}

void GL::Uniform4iv(GLint location, GLsizei count, const GLint* v) {
  GL_CHECK(glUniform4iv(location, count, v))
}

void GL::UniformMatrix2fv(GLint location, GLsizei count, GLboolean transpose,
                          const GLfloat* value) {
  GL_CHECK(glUniformMatrix2fv(location, count, transpose, value))
}

void GL::UniformMatrix3fv(GLint location, GLsizei count, GLboolean transpose,
                          const GLfloat* value) {
  GL_CHECK(glUniformMatrix3fv(location, count, transpose, value))
}

void GL::UniformMatrix4fv(GLint location, GLsizei count, GLboolean transpose,
                          const GLfloat* value) {
  GL_CHECK(glUniformMatrix4fv(location, count, transpose, value))
}

void GL::UseProgram(GLuint program) { GL_CHECK(glUseProgram(program)) }

void GL::ValidateProgram(GLuint program) {
  GL_CHECK(glValidateProgram(program))
}

void GL::VertexAttrib1f(GLuint indx, GLfloat x) {
  GL_CHECK(glVertexAttrib1f(indx, x))
}

void GL::VertexAttrib1fv(GLuint indx, const GLfloat* values) {
  GL_CHECK(glVertexAttrib1fv(indx, values))
}

void GL::VertexAttrib2f(GLuint indx, GLfloat x, GLfloat y) {
  GL_CHECK(glVertexAttrib2f(indx, x, y))
}

void GL::VertexAttrib2fv(GLuint indx, const GLfloat* values) {
  GL_CHECK(glVertexAttrib2fv(indx, values))
}

void GL::VertexAttrib3f(GLuint indx, GLfloat x, GLfloat y, GLfloat z) {
  GL_CHECK(glVertexAttrib3f(indx, x, y, z))
}

void GL::VertexAttrib3fv(GLuint indx, const GLfloat* values) {
  GL_CHECK(glVertexAttrib3fv(indx, values))
}

void GL::VertexAttrib4f(GLuint indx, GLfloat x, GLfloat y, GLfloat z,
                        GLfloat w) {
  GL_CHECK(glVertexAttrib4f(indx, x, y, z, w))
}

void GL::VertexAttrib4fv(GLuint indx, const GLfloat* values) {
  GL_CHECK(glVertexAttrib4fv(indx, values))
}

void GL::VertexAttribPointer(GLuint indx, GLint size, GLenum type,
                             GLboolean normalized, GLsizei stride,
                             const GLvoid* ptr) {
  GL_CHECK(glVertexAttribPointer(indx, size, type, normalized, stride, ptr))
}

void GL::Viewport(GLint x, GLint y, GLsizei width, GLsizei height) {
  GL_CHECK(glViewport(x, y, width, height))
}

void GL::BlitFramebuffer(GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1,
                         GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1,
                         GLbitfield mask, GLenum filter) {
  GL_CHECK(glBlitFramebuffer(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1,
                             dstY1, mask, filter))
}

void GL::InvalidateFramebuffer(GLenum target, GLsizei numAttachments,
                               const GLenum* attachments) {
  GL_CHECK(glInvalidateFramebuffer(target, numAttachments, attachments))
}

void GL::BindVertexArray(GLuint array) { GL_CHECK(glBindVertexArray(array)) }

void GL::DeleteVertexArrays(GLsizei n, const GLuint* arrays) {
  GL_CHECK(glDeleteVertexArrays(n, arrays))
}
void GL::GenVertexArrays(GLsizei n,
                         GLuint* arrays){GL_CHECK(glGenVertexArrays(n, arrays))}

GLboolean GL::IsVertexArray(GLuint array) {
  GL_CHECK(GLboolean res = glIsVertexArray(array))
  return res;
}

void GL::ReadBuffer(GLenum mode) { GL_CHECK(glReadBuffer(mode)); };

void GL::DrawArraysInstanced(GLenum mode, GLint first, GLsizei count,
                             GLsizei instancecount) {
  GL_CHECK(glDrawArraysInstanced(mode, first, count, instancecount));
}

void GL::DrawElementsInstanced(GLenum mode, GLsizei count, GLenum type,
                               const GLvoid* indices, GLsizei instancecount) {
  GL_CHECK(glDrawElementsInstanced(mode, count, type, indices, instancecount));
}

void GL::VertexAttribDivisor(GLuint index, GLuint divisor) {
  GL_CHECK(glVertexAttribDivisor(index, divisor));
}

GLsync GL::FenceSync(GLenum condition, GLbitfield flags) {
  GL_CHECK(GLsync res = glFenceSync(condition, flags));
  return res;
}

void GL::WaitSync(GLsync sync, GLbitfield flags, GLuint64 timeout) {
  GL_CHECK(glWaitSync(sync, flags, timeout));
}

void GL::ClientWaitSync(GLsync sync, GLbitfield flags, GLuint64 timeout) {
  GL_CHECK(glClientWaitSync(sync, flags, timeout));
}

GLenum GL::GetError() {
  auto* current_context = GLContext::GetCurrent();

  auto err = glGetError();
  if (err != GL_NO_ERROR) {
    // clear saved error if have
    if (current_context) {
      static_cast<GLVirtualContext*>(current_context)->GetSavedError();
    }
    return err;
  }

  // maybe has saved err
  if (current_context) {
    return static_cast<GLVirtualContext*>(current_context)->GetSavedError();
  }

  return GL_NO_ERROR;
}

void GL::SetError(GLenum error) {
  // TODO(luchengxuan) should move all gl interface to gl context to avoid this
  auto* current_context = GLContext::GetCurrent();
  DCHECK(current_context);
  if (current_context) {
    static_cast<GLVirtualContext*>(current_context)->SetErrorToSave(error);
  }
}

void GL::RenderbufferStorageMultisample(GLenum target, GLsizei samples,
                                        GLenum internalformat, GLsizei width,
                                        GLsizei height) {
  GL_CHECK(glRenderbufferStorageMultisample(target, samples, internalformat,
                                            width, height));
}

#ifdef OS_ANDROID
namespace {
PFNGLRENDERBUFFERSTORAGEMULTISAMPLEEXTPROC glRenderbufferStorageMultisampleEXT =
    nullptr;
PFNGLFRAMEBUFFERTEXTURE2DMULTISAMPLEEXTPROC
glFramebufferTexture2DMultisampleEXT = nullptr;
}  // namespace

bool GL::LoadExtension(GL::Extension extension) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch"
  switch (extension) {
    case kMultisampledRenderToTexture: {
      glRenderbufferStorageMultisampleEXT =
          reinterpret_cast<PFNGLRENDERBUFFERSTORAGEMULTISAMPLEEXTPROC>(
              eglGetProcAddress("glRenderbufferStorageMultisampleEXT"));
      glFramebufferTexture2DMultisampleEXT =
          reinterpret_cast<PFNGLFRAMEBUFFERTEXTURE2DMULTISAMPLEEXTPROC>(
              eglGetProcAddress("glFramebufferTexture2DMultisampleEXT"));

      return glRenderbufferStorageMultisampleEXT &&
             glFramebufferTexture2DMultisampleEXT;
    }
  }
#pragma clang diagnostic pop
  return false;
}

void GL::RenderbufferStorageMultisampleEXT(GLenum target, GLsizei samples,
                                           GLenum internalformat, GLsizei width,
                                           GLsizei height) {
  DCHECK(glRenderbufferStorageMultisampleEXT);
  GL_CHECK(glRenderbufferStorageMultisampleEXT(target, samples, internalformat,
                                               width, height));
}
#elif OS_IOS
bool GL::LoadExtension(GL::Extension extension) {
  switch (extension) {
    case kAPPLEFramebufferMultisample: {
      return true;
    }
  }
  return false;
}

void GL::RenderbufferStorageMultisampleEXT(GLenum target, GLsizei samples,
                                           GLenum internalformat, GLsizei width,
                                           GLsizei height) {
  GL_CHECK(glRenderbufferStorageMultisampleAPPLE(
      target, samples, internalformat, width, height));
}
#else
void GL::RenderbufferStorageMultisampleEXT(GLenum target, GLsizei samples,
                                           GLenum internalformat, GLsizei width,
                                           GLsizei height) {
  // we do not support msaa with ext on other platform.
  NOTREACHED();
}
#endif

void GL::TexImage3D(GLenum target, GLint level, GLint internalformat,
                    GLsizei width, GLsizei height, GLsizei depth, GLint border,
                    GLenum format, GLenum type, const GLvoid* pixels) {
  GL_CHECK(glTexImage3D(target, level, internalformat, width, height, depth,
                        border, format, type, pixels));
}

}  // namespace canvas
}  // namespace lynx
