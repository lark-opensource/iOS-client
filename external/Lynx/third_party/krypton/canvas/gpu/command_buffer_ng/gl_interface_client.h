// Copyright (c) 2023 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_COMMAND_BUFFER_NG_GL_INTERFACE_CLIENT_H_
#define CANVAS_GPU_COMMAND_BUFFER_NG_GL_INTERFACE_CLIENT_H_

#include <memory>

#include "canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
namespace command_buffer {
template <class GLInterfaceService>
class GLInterfaceClient {
 public:
  explicit GLInterfaceClient(std::unique_ptr<GLInterfaceService> service)
      : service_(std::move(service)) {}
  ~GLInterfaceClient() = default;

  GLInterfaceClient(const GLInterfaceClient&) = delete;
  GLInterfaceClient& operator=(const GLInterfaceClient&) = delete;

  inline void ActiveTexture(GLenum texture) {
    service_->ActiveTexture(texture);
  }

  inline void AttachShader(GLuint program, GLuint shader) {
    service_->AttachShader(program, shader);
  }

  inline void BindAttribLocation(GLuint program, GLuint index,
                                 const GLchar* name) {
    service_->BindAttribLocation(program, index, name);
  }

  inline void BindBuffer(GLenum target, GLuint buffer) {
    service_->BindBuffer(target, buffer);
  }

  inline void BindFramebuffer(GLenum target, GLuint framebuffer) {
    service_->BindFramebuffer(target, framebuffer);
  }

  inline void BindRenderbuffer(GLenum target, GLuint renderbuffer) {
    service_->BindRenderbuffer(target, renderbuffer);
  }

  inline void BindTexture(GLenum target, GLuint texture) {
    service_->BindTexture(target, texture);
  }

  inline void BlendColor(GLfloat red, GLfloat green, GLfloat blue,
                         GLfloat alpha) {
    service_->BlendColor(red, green, blue, alpha);
  }

  inline void BlendEquation(GLenum mode) { service_->BlendEquation(mode); }

  inline void BlendEquationSeparate(GLenum modeRGB, GLenum modeAlpha) {
    service_->BlendEquationSeparate(modeRGB, modeAlpha);
  }

  inline void BlendFunc(GLenum sfactor, GLenum dfactor) {
    service_->BlendFunc(sfactor, dfactor);
  }

  inline void BlendFuncSeparate(GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha,
                                GLenum dstAlpha) {
    service_->BlendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
  }

  inline void BufferData(GLenum target, GLsizeiptr size, const GLvoid* data,
                         GLenum usage) {
    service_->BufferData(target, size, data, usage);
  }

  inline void BufferSubData(GLenum target, GLintptr offset, GLsizeiptr size,
                            const GLvoid* data) {
    service_->BufferSubData(target, offset, size, data);
  }

  inline GLenum CheckFramebufferStatus(GLenum target) {
    return service_->CheckFramebufferStatus(target);
  }

  inline void Clear(GLbitfield mask) { service_->Clear(mask); }

  inline void ClearColor(GLfloat red, GLfloat green, GLfloat blue,
                         GLfloat alpha) {
    service_->ClearColor(red, green, blue, alpha);
  }

  inline void ClearDepthf(GLclampf depth) { service_->ClearDepthf(depth); }

  inline void ClearStencil(GLint s) { service_->ClearStencil(s); }

  inline void ColorMask(GLboolean red, GLboolean green, GLboolean blue,
                        GLboolean alpha) {
    service_->ColorMask(red, green, blue, alpha);
  }

  inline void CompileShader(GLuint shader) { service_->CompileShader(shader); }

  inline void CompressedTexImage2D(GLenum target, GLint level,
                                   GLenum internalformat, GLsizei width,
                                   GLsizei height, GLint border,
                                   GLsizei imageSize, const GLvoid* data) {
    service_->CompressedTexImage2D(target, level, internalformat, width, height,
                                   border, imageSize, data);
  }

  inline void CompressedTexSubImage2D(GLenum target, GLint level, GLint xoffset,
                                      GLint yoffset, GLsizei width,
                                      GLsizei height, GLenum format,
                                      GLsizei imageSize, const GLvoid* data) {
    service_->CompressedTexSubImage2D(target, level, xoffset, yoffset, width,
                                      height, format, imageSize, data);
  }

  inline void CopyTexImage2D(GLenum target, GLint level, GLenum internalformat,
                             GLint x, GLint y, GLsizei width, GLsizei height,
                             GLint border) {
    service_->CopyTexImage2D(target, level, internalformat, x, y, width, height,
                             border);
  }

  inline void CopyTexSubImage2D(GLenum target, GLint level, GLint xoffset,
                                GLint yoffset, GLint x, GLint y, GLsizei width,
                                GLsizei height) {
    service_->CopyTexSubImage2D(target, level, xoffset, yoffset, x, y, width,
                                height);
  }

  inline GLuint CreateProgram() { return service_->CreateProgram(); }

  inline GLuint CreateShader(GLenum type) {
    return service_->CreateShader(type);
  }

  inline void CullFace(GLenum mode) { service_->CullFace(mode); }

  inline void DeleteBuffers(GLsizei n, const GLuint* buffers) {
    service_->DeleteBuffers(n, buffers);
  }

  inline void DeleteFramebuffers(GLsizei n, const GLuint* framebuffers) {
    service_->DeleteFramebuffers(n, framebuffers);
  }

  inline void DeleteProgram(GLuint program) {
    service_->DeleteProgram(program);
  }

  inline void DeleteRenderbuffers(GLsizei n, const GLuint* renderbuffers) {
    service_->DeleteRenderbuffers(n, renderbuffers);
  }

  inline void DeleteShader(GLuint shader) { service_->DeleteShader(shader); }

  inline void DeleteTextures(GLsizei n, const GLuint* textures) {
    service_->DeleteTextures(n, textures);
  }

  inline void DepthFunc(GLenum func) { service_->DepthFunc(func); }

  inline void DepthMask(GLboolean flag) { service_->DepthMask(flag); }

  inline void DepthRangef(GLclampf zNear, GLclampf zFar) {
    service_->DepthRangef(zNear, zFar);
  }

  inline void DetachShader(GLuint program, GLuint shader) {
    service_->DetachShader(program, shader);
  }

  inline void Disable(GLenum cap) { service_->Disable(cap); }

  inline void DisableVertexAttribArray(GLuint index) {
    service_->DisableVertexAttribArray(index);
  }

  inline void DrawArrays(GLenum mode, GLint first, GLsizei count) {
    service_->DrawArrays(mode, first, count);
  }

  inline void DrawElements(GLenum mode, GLsizei count, GLenum type,
                           const GLvoid* indices) {
    service_->DrawElements(mode, count, type, indices);
  }

  inline void Enable(GLenum cap) { service_->Enable(cap); }

  inline void EnableVertexAttribArray(GLuint index) {
    service_->EnableVertexAttribArray(index);
  }

  inline void Finish() { service_->Finish(); }

  inline void Flush() { service_->Flush(); }

  inline void FramebufferRenderbuffer(GLenum target, GLenum attachment,
                                      GLenum renderbuffertarget,
                                      GLuint renderbuffer) {
    service_->FramebufferRenderbuffer(target, attachment, renderbuffertarget,
                                      renderbuffer);
  }

  inline void FramebufferTexture2D(GLenum target, GLenum attachment,
                                   GLenum textarget, GLuint texture,
                                   GLint level) {
    service_->FramebufferTexture2D(target, attachment, textarget, texture,
                                   level);
  }

  inline void FrontFace(GLenum mode) { service_->FrontFace(mode); }

  inline void GenBuffers(GLsizei n, GLuint* buffers) {
    service_->GenBuffers(n, buffers);
  }

  inline void GenerateMipmap(GLenum target) {
    service_->GenerateMipmap(target);
  }

  inline void GenFramebuffers(GLsizei n, GLuint* framebuffers) {
    service_->GenFramebuffers(n, framebuffers);
  }

  inline void GenRenderbuffers(GLsizei n, GLuint* renderbuffers) {
    service_->GenRenderbuffers(n, renderbuffers);
  }

  inline void GenTextures(GLsizei n, GLuint* textures) {
    service_->GenTextures(n, textures);
  }

  inline void GetActiveAttrib(GLuint program, GLuint index, GLsizei bufsize,
                              GLsizei* length, GLint* size, GLenum* type,
                              GLchar* name) {
    service_->GetActiveAttrib(program, index, bufsize, length, size, type,
                              name);
  }

  inline void GetActiveUniform(GLuint program, GLuint index, GLsizei bufsize,
                               GLsizei* length, GLint* size, GLenum* type,
                               GLchar* name) {
    service_->GetActiveUniform(program, index, bufsize, length, size, type,
                               name);
  }

  inline void GetAttachedShaders(GLuint program, GLsizei maxcount,
                                 GLsizei* count, GLuint* shaders) {
    service_->GetAttachedShaders(program, maxcount, count, shaders);
  }

  inline GLint GetAttribLocation(GLuint program, const GLchar* name) {
    return service_->GetAttribLocation(program, name);
  }

  inline void GetBooleanv(GLenum pname, GLboolean* params) {
    service_->GetBooleanv(pname, params);
  }

  inline void GetBufferParameteriv(GLenum target, GLenum pname, GLint* params) {
    service_->GetBufferParameteriv(target, pname, params);
  }

  inline GLenum GetError() { return service_->GetError(); }

  inline void GetFloatv(GLenum pname, GLfloat* params) {
    service_->GetFloatv(pname, params);
  }

  inline void GetFramebufferAttachmentParameteriv(GLenum target,
                                                  GLenum attachment,
                                                  GLenum pname, GLint* params) {
    service_->GetFramebufferAttachmentParameteriv(target, attachment, pname,
                                                  params);
  }

  inline void GetIntegerv(GLenum pname, GLint* params) {
    service_->GetIntegerv(pname, params);
  }

  inline void GetProgramiv(GLuint program, GLenum pname, GLint* params) {
    service_->GetProgramiv(program, pname, params);
  }

  inline void GetProgramInfoLog(GLuint program, GLsizei bufsize,
                                GLsizei* length, GLchar* infolog) {
    service_->GetProgramInfoLog(program, bufsize, length, infolog);
  }

  inline void GetRenderbufferParameteriv(GLenum target, GLenum pname,
                                         GLint* params) {
    service_->GetRenderbufferParameteriv(target, pname, params);
  }

  inline void GetShaderiv(GLuint shader, GLenum pname, GLint* params) {
    service_->GetShaderiv(shader, pname, params);
  }

  inline void GetShaderInfoLog(GLuint shader, GLsizei bufsize, GLsizei* length,
                               GLchar* infolog) {
    service_->GetShaderInfoLog(shader, bufsize, length, infolog);
  }

  inline void GetShaderPrecisionFormat(GLenum shadertype, GLenum precisiontype,
                                       GLint* range, GLint* precision) {
    service_->GetShaderPrecisionFormat(shadertype, precisiontype, range,
                                       precision);
  }

  inline void GetShaderSource(GLuint shader, GLsizei bufsize, GLsizei* length,
                              GLchar* source) {
    service_->GetShaderSource(shader, bufsize, length, source);
  }

  inline const GLubyte* GetString(GLenum name) {
    return service_->GetString(name);
  }

  inline void GetTexParameterfv(GLenum target, GLenum pname, GLfloat* params) {
    service_->GetTexParameterfv(target, pname, params);
  }

  inline void GetTexParameteriv(GLenum target, GLenum pname, GLint* params) {
    service_->GetTexParameteriv(target, pname, params);
  }

  inline void GetUniformfv(GLuint program, GLint location, GLfloat* params) {
    service_->GetUniformfv(program, location, params);
  }

  inline void GetUniformiv(GLuint program, GLint location, GLint* params) {
    service_->GetUniformiv(program, location, params);
  }

  inline int GetUniformLocation(GLuint program, const GLchar* name) {
    return service_->GetUniformLocation(program, name);
  }

  inline void GetVertexAttribfv(GLuint index, GLenum pname, GLfloat* params) {
    service_->GetVertexAttribfv(index, pname, params);
  }

  inline void GetVertexAttribiv(GLuint index, GLenum pname, GLint* params) {
    service_->GetVertexAttribiv(index, pname, params);
  }

  inline void GetVertexAttribPointerv(GLuint index, GLenum pname,
                                      GLvoid** pointer) {
    service_->GetVertexAttribPointerv(index, pname, pointer);
  }

  inline void Hint(GLenum target, GLenum mode) { service_->Hint(target, mode); }

  inline GLboolean IsBuffer(GLuint buffer) {
    return service_->IsBuffer(buffer);
  }

  inline GLboolean IsEnabled(GLenum cap) { return service_->IsEnabled(cap); }

  inline GLboolean IsFramebuffer(GLuint framebuffer) {
    return service_->IsFramebuffer(framebuffer);
  }

  inline GLboolean IsProgram(GLuint program) {
    return service_->IsProgram(program);
  }

  inline GLboolean IsRenderbuffer(GLuint renderbuffer) {
    return service_->IsRenderbuffer(renderbuffer);
  }

  inline GLboolean IsShader(GLuint shader) {
    return service_->IsShader(shader);
  }

  inline GLboolean IsTexture(GLuint texture) {
    return service_->IsTexture(texture);
  }

  inline void LineWidth(GLfloat width) { service_->LineWidth(width); }

  inline void LinkProgram(GLuint program) { service_->LinkProgram(program); }

  inline void PixelStorei(GLenum pname, GLint param) {
    service_->PixelStorei(pname, param);
  }

  inline void PolygonOffset(GLfloat factor, GLfloat units) {
    service_->PolygonOffset(factor, units);
  }

  inline void ReadPixels(GLint x, GLint y, GLsizei width, GLsizei height,
                         GLenum format, GLenum type, GLvoid* pixels) {
    service_->ReadPixels(x, y, width, height, format, type, pixels);
  }

  inline void ReleaseShaderCompiler() { service_->ReleaseShaderCompiler(); }

  inline void RenderbufferStorage(GLenum target, GLenum internalformat,
                                  GLsizei width, GLsizei height) {
    service_->RenderbufferStorage(target, internalformat, width, height);
  }

  inline void SampleCoverage(GLclampf value, GLboolean invert) {
    service_->SampleCoverage(value, invert);
  }

  inline void Scissor(GLint x, GLint y, GLsizei width, GLsizei height) {
    service_->Scissor(x, y, width, height);
  }

  inline void ShaderBinary(GLsizei n, const GLuint* shaders,
                           GLenum binaryformat, const GLvoid* binary,
                           GLsizei length) {
    service_->ShaderBinary(n, shaders, binaryformat, binary, length);
  }

  inline void ShaderSource(GLuint shader, GLsizei count, const GLchar** string,
                           const GLint* length) {
    service_->ShaderSource(shader, count, string, length);
  }

  inline void StencilFunc(GLenum func, GLint ref, GLuint mask) {
    service_->StencilFunc(func, ref, mask);
  }

  inline void StencilFuncSeparate(GLenum face, GLenum func, GLint ref,
                                  GLuint mask) {
    service_->StencilFuncSeparate(face, func, ref, mask);
  }

  inline void StencilMask(GLuint mask) { service_->StencilMask(mask); }

  inline void StencilMaskSeparate(GLenum face, GLuint mask) {
    service_->StencilMaskSeparate(face, mask);
  }

  inline void StencilOp(GLenum fail, GLenum zfail, GLenum zpass) {
    service_->StencilOp(fail, zfail, zpass);
  }

  inline void StencilOpSeparate(GLenum face, GLenum fail, GLenum zfail,
                                GLenum zpass) {
    service_->StencilOpSeparate(face, fail, zfail, zpass);
  }

  inline void TexImage2D(GLenum target, GLint level, GLint internalformat,
                         GLsizei width, GLsizei height, GLint border,
                         GLenum format, GLenum type, const GLvoid* pixels) {
    service_->TexImage2D(target, level, internalformat, width, height, border,
                         format, type, pixels);
  }

  inline void TexParameterf(GLenum target, GLenum pname, GLfloat param) {
    service_->TexParameterf(target, pname, param);
  }

  inline void TexParameterfv(GLenum target, GLenum pname,
                             const GLfloat* params) {
    service_->TexParameterfv(target, pname, params);
  }

  inline void TexParameteri(GLenum target, GLenum pname, GLint param) {
    service_->TexParameteri(target, pname, param);
  }

  inline void TexParameteriv(GLenum target, GLenum pname, const GLint* params) {
    service_->TexParameteriv(target, pname, params);
  }

  inline void TexSubImage2D(GLenum target, GLint level, GLint xoffset,
                            GLint yoffset, GLsizei width, GLsizei height,
                            GLenum format, GLenum type, const GLvoid* pixels) {
    service_->TexSubImage2D(target, level, xoffset, yoffset, width, height,
                            format, type, pixels);
  }

  inline void Uniform1f(GLint location, GLfloat x) {
    service_->Uniform1f(location, x);
  }

  inline void Uniform1fv(GLint location, GLsizei count, const GLfloat* v) {
    service_->Uniform1fv(location, count, v);
  }

  inline void Uniform1i(GLint location, GLint x) {
    service_->Uniform1i(location, x);
  }

  inline void Uniform1iv(GLint location, GLsizei count, const GLint* v) {
    service_->Uniform1iv(location, count, v);
  }

  inline void Uniform2f(GLint location, GLfloat x, GLfloat y) {
    service_->Uniform2f(location, x, y);
  }

  inline void Uniform2fv(GLint location, GLsizei count, const GLfloat* v) {
    service_->Uniform2fv(location, count, v);
  }

  inline void Uniform2i(GLint location, GLint x, GLint y) {
    service_->Uniform2i(location, x, y);
  }

  inline void Uniform2iv(GLint location, GLsizei count, const GLint* v) {
    service_->Uniform2iv(location, count, v);
  }

  inline void Uniform3f(GLint location, GLfloat x, GLfloat y, GLfloat z) {
    service_->Uniform3f(location, x, y, z);
  }

  inline void Uniform3fv(GLint location, GLsizei count, const GLfloat* v) {
    service_->Uniform3fv(location, count, v);
  }

  inline void Uniform3i(GLint location, GLint x, GLint y, GLint z) {
    service_->Uniform3i(location, x, y, z);
  }

  inline void Uniform3iv(GLint location, GLsizei count, const GLint* v) {
    service_->Uniform3iv(location, count, v);
  }

  inline void Uniform4f(GLint location, GLfloat x, GLfloat y, GLfloat z,
                        GLfloat w) {
    service_->Uniform4f(location, x, y, z, w);
  }

  inline void Uniform4fv(GLint location, GLsizei count, const GLfloat* v) {
    service_->Uniform4fv(location, count, v);
  }

  inline void Uniform4i(GLint location, GLint x, GLint y, GLint z, GLint w) {
    service_->Uniform4i(location, x, y, z, w);
  }

  inline void Uniform4iv(GLint location, GLsizei count, const GLint* v) {
    service_->Uniform4iv(location, count, v);
  }

  inline void UniformMatrix2fv(GLint location, GLsizei count,
                               GLboolean transpose, const GLfloat* value) {
    service_->UniformMatrix2fv(location, count, transpose, value);
  }

  inline void UniformMatrix3fv(GLint location, GLsizei count,
                               GLboolean transpose, const GLfloat* value) {
    service_->UniformMatrix3fv(location, count, transpose, value);
  }

  inline void UniformMatrix4fv(GLint location, GLsizei count,
                               GLboolean transpose, const GLfloat* value) {
    service_->UniformMatrix4fv(location, count, transpose, value);
  }

  inline void UseProgram(GLuint program) { service_->UseProgram(program); }

  inline void ValidateProgram(GLuint program) {
    service_->ValidateProgram(program);
  }

  inline void VertexAttrib1f(GLuint indx, GLfloat x) {
    service_->VertexAttrib1f(indx, x);
  }

  inline void VertexAttrib1fv(GLuint indx, const GLfloat* values) {
    service_->VertexAttrib1fv(indx, values);
  }

  inline void VertexAttrib2f(GLuint indx, GLfloat x, GLfloat y) {
    service_->VertexAttrib2f(indx, x, y);
  }

  inline void VertexAttrib2fv(GLuint indx, const GLfloat* values) {
    service_->VertexAttrib2fv(indx, values);
  }

  inline void VertexAttrib3f(GLuint indx, GLfloat x, GLfloat y, GLfloat z) {
    service_->VertexAttrib3f(indx, x, y, z);
  }

  inline void VertexAttrib3fv(GLuint indx, const GLfloat* values) {
    service_->VertexAttrib3fv(indx, values);
  }

  inline void VertexAttrib4f(GLuint indx, GLfloat x, GLfloat y, GLfloat z,
                             GLfloat w) {
    service_->VertexAttrib4f(indx, x, y, z, w);
  }

  inline void VertexAttrib4fv(GLuint indx, const GLfloat* values) {
    service_->VertexAttrib4fv(indx, values);
  }

  inline void VertexAttribPointer(GLuint indx, GLint size, GLenum type,
                                  GLboolean normalized, GLsizei stride,
                                  const GLvoid* ptr) {
    service_->VertexAttribPointer(indx, size, type, normalized, stride, ptr);
  }

  inline void Viewport(GLint x, GLint y, GLsizei width, GLsizei height) {
    service_->Viewport(x, y, width, height);
  }

  // es3 below

  inline void BlitFramebuffer(GLint srcX0, GLint srcY0, GLint srcX1,
                              GLint srcY1, GLint dstX0, GLint dstY0,
                              GLint dstX1, GLint dstY1, GLbitfield mask,
                              GLenum filter) {
    service_->BlitFramebuffer(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1,
                              dstY1, mask, filter);
  }

  inline void InvalidateFramebuffer(GLenum target, GLsizei numAttachments,
                                    const GLenum* attachments) {
    service_->InvalidateFramebuffer(target, numAttachments, attachments);
  }

  inline void BindVertexArray(GLuint array) {
    service_->BindVertexArray(array);
  }

  inline void DeleteVertexArrays(GLsizei n, const GLuint* arrays) {
    service_->DeleteVertexArrays(n, arrays);
  }

  inline void GenVertexArrays(GLsizei n, GLuint* arrays) {
    service_->GenVertexArrays(n, arrays);
  }

  inline GLboolean IsVertexArray(GLuint array) {
    return service_->IsVertexArray(array);
  }

  inline void ReadBuffer(GLenum mode) { service_->ReadBuffer(mode); }

  inline void DrawArraysInstanced(GLenum mode, GLint first, GLsizei count,
                                  GLsizei instancecount) {
    service_->DrawArraysInstanced(mode, first, count, instancecount);
  }

  inline void DrawElementsInstanced(GLenum mode, GLsizei count, GLenum type,
                                    const GLvoid* indices,
                                    GLsizei instancecount) {
    service_->DrawElementsInstanced(mode, count, type, indices, instancecount);
  }

  inline void VertexAttribDivisor(GLuint index, GLuint divisor) {
    service_->VertexAttribDivisor(index, divisor);
  }

  inline GLsync FenceSync(GLenum condition, GLbitfield flags) {
    return service_->FenceSync(condition, flags);
  }

  inline void WaitSync(GLsync sync, GLbitfield flags, GLuint64 timeout) {
    service_->WaitSync(sync, flags, timeout);
  }

 private:
  std::unique_ptr<GLInterfaceService> service_;
};

}  // namespace command_buffer
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_COMMAND_BUFFER_NG_GL_INTERFACE_CLIENT_H_
