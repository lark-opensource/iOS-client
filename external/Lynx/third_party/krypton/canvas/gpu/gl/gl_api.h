// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_GL_GL_API_H_
#define CANVAS_GPU_GL_GL_API_H_

#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
struct GL {
  static void ActiveTexture(GLenum texture);
  static void AttachShader(GLuint program, GLuint shader);
  static void BindAttribLocation(GLuint program, GLuint index,
                                 const GLchar* name);
  static void BindBuffer(GLenum target, GLuint buffer);
  static void BindFramebuffer(GLenum target, GLuint framebuffer);
  static void BindRenderbuffer(GLenum target, GLuint renderbuffer);
  static void BindTexture(GLenum target, GLuint texture);
  static void BlendColor(GLfloat red, GLfloat green, GLfloat blue,
                         GLfloat alpha);
  static void BlendEquation(GLenum mode);
  static void BlendEquationSeparate(GLenum modeRGB, GLenum modeAlpha);
  static void BlendFunc(GLenum sfactor, GLenum dfactor);
  static void BlendFuncSeparate(GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha,
                                GLenum dstAlpha);
  static void BufferData(GLenum target, GLsizeiptr size, const GLvoid* data,
                         GLenum usage);
  static void BufferSubData(GLenum target, GLintptr offset, GLsizeiptr size,
                            const GLvoid* data);
  static GLenum CheckFramebufferStatus(GLenum target);
  static void Clear(GLbitfield mask);
  static void ClearColor(GLfloat red, GLfloat green, GLfloat blue,
                         GLfloat alpha);
  static void ClearDepthf(GLclampf depth);
  static void ClearStencil(GLint s);
  static void ColorMask(GLboolean red, GLboolean green, GLboolean blue,
                        GLboolean alpha);
  static void CompileShader(GLuint shader);
  static void CompressedTexImage2D(GLenum target, GLint level,
                                   GLenum internalformat, GLsizei width,
                                   GLsizei height, GLint border,
                                   GLsizei imageSize, const GLvoid* data);
  static void CompressedTexSubImage2D(GLenum target, GLint level, GLint xoffset,
                                      GLint yoffset, GLsizei width,
                                      GLsizei height, GLenum format,
                                      GLsizei imageSize, const GLvoid* data);
  static void CopyTexImage2D(GLenum target, GLint level, GLenum internalformat,
                             GLint x, GLint y, GLsizei width, GLsizei height,
                             GLint border);
  static void CopyTexSubImage2D(GLenum target, GLint level, GLint xoffset,
                                GLint yoffset, GLint x, GLint y, GLsizei width,
                                GLsizei height);
  static GLuint CreateProgram(void);
  static GLuint CreateShader(GLenum type);
  static void CullFace(GLenum mode);
  static void DeleteBuffers(GLsizei n, const GLuint* buffers);
  static void DeleteFramebuffers(GLsizei n, const GLuint* framebuffers);
  static void DeleteProgram(GLuint program);
  static void DeleteRenderbuffers(GLsizei n, const GLuint* renderbuffers);
  static void DeleteShader(GLuint shader);
  static void DeleteTextures(GLsizei n, const GLuint* textures);
  static void DepthFunc(GLenum func);
  static void DepthMask(GLboolean flag);
  static void DepthRangef(GLclampf zNear, GLclampf zFar);
  static void DetachShader(GLuint program, GLuint shader);
  static void Disable(GLenum cap);
  static void DisableVertexAttribArray(GLuint index);
  static void DrawArrays(GLenum mode, GLint first, GLsizei count);
  static void DrawElements(GLenum mode, GLsizei count, GLenum type,
                           const GLvoid* indices);
  static void Enable(GLenum cap);
  static void EnableVertexAttribArray(GLuint index);
  static void Finish(void);
  static void Flush(void);
  static void FramebufferRenderbuffer(GLenum target, GLenum attachment,
                                      GLenum renderbuffertarget,
                                      GLuint renderbuffer);
  static void FramebufferTexture2D(GLenum target, GLenum attachment,
                                   GLenum textarget, GLuint texture,
                                   GLint level);
  static void FrontFace(GLenum mode);
  static void GenBuffers(GLsizei n, GLuint* buffers);
  static void GenerateMipmap(GLenum target);
  static void GenFramebuffers(GLsizei n, GLuint* framebuffers);
  static void GenRenderbuffers(GLsizei n, GLuint* renderbuffers);
  static void GenTextures(GLsizei n, GLuint* textures);
  static void GetActiveAttrib(GLuint program, GLuint index, GLsizei bufsize,
                              GLsizei* length, GLint* size, GLenum* type,
                              GLchar* name);
  static void GetActiveUniform(GLuint program, GLuint index, GLsizei bufsize,
                               GLsizei* length, GLint* size, GLenum* type,
                               GLchar* name);
  static void GetAttachedShaders(GLuint program, GLsizei maxcount,
                                 GLsizei* count, GLuint* shaders);
  static int GetAttribLocation(GLuint program, const GLchar* name);
  static void GetBooleanv(GLenum pname, GLboolean* params);
  static void GetBufferParameteriv(GLenum target, GLenum pname, GLint* params);
  static GLenum GetError();
  static void GetFloatv(GLenum pname, GLfloat* params);
  static void GetFramebufferAttachmentParameteriv(GLenum target,
                                                  GLenum attachment,
                                                  GLenum pname, GLint* params);
  static void GetIntegerv(GLenum pname, GLint* params);
  static void GetProgramiv(GLuint program, GLenum pname, GLint* params);
  static void GetProgramInfoLog(GLuint program, GLsizei bufsize,
                                GLsizei* length, GLchar* infolog);
  static void GetRenderbufferParameteriv(GLenum target, GLenum pname,
                                         GLint* params);
  static void GetShaderiv(GLuint shader, GLenum pname, GLint* params);
  static void GetShaderInfoLog(GLuint shader, GLsizei bufsize, GLsizei* length,
                               GLchar* infolog);
  static void GetShaderPrecisionFormat(GLenum shadertype, GLenum precisiontype,
                                       GLint* range, GLint* precision);
  static void GetShaderSource(GLuint shader, GLsizei bufsize, GLsizei* length,
                              GLchar* source);
  static const GLubyte* GetString(GLenum name);
  static void GetTexParameterfv(GLenum target, GLenum pname, GLfloat* params);
  static void GetTexParameteriv(GLenum target, GLenum pname, GLint* params);
  static void GetUniformfv(GLuint program, GLint location, GLfloat* params);
  static void GetUniformiv(GLuint program, GLint location, GLint* params);
  static int GetUniformLocation(GLuint program, const GLchar* name);
  static void GetVertexAttribfv(GLuint index, GLenum pname, GLfloat* params);
  static void GetVertexAttribiv(GLuint index, GLenum pname, GLint* params);
  static void GetVertexAttribPointerv(GLuint index, GLenum pname,
                                      GLvoid** pointer);
  static void Hint(GLenum target, GLenum mode);
  static GLboolean IsBuffer(GLuint buffer);
  static GLboolean IsEnabled(GLenum cap);
  static GLboolean IsFramebuffer(GLuint framebuffer);
  static GLboolean IsProgram(GLuint program);
  static GLboolean IsRenderbuffer(GLuint renderbuffer);
  static GLboolean IsShader(GLuint shader);
  static GLboolean IsTexture(GLuint texture);
  static void LineWidth(GLfloat width);
  static void LinkProgram(GLuint program);
  static void PixelStorei(GLenum pname, GLint param);
  static void PolygonOffset(GLfloat factor, GLfloat units);
  static void ReadPixels(GLint x, GLint y, GLsizei width, GLsizei height,
                         GLenum format, GLenum type, GLvoid* pixels);
  static void ReleaseShaderCompiler(void);
  static void RenderbufferStorage(GLenum target, GLenum internalformat,
                                  GLsizei width, GLsizei height);
  static void SampleCoverage(GLclampf value, GLboolean invert);
  static void Scissor(GLint x, GLint y, GLsizei width, GLsizei height);
  static void ShaderBinary(GLsizei n, const GLuint* shaders,
                           GLenum binaryformat, const GLvoid* binary,
                           GLsizei length);
  static void ShaderSource(GLuint shader, GLsizei count,
                           const GLchar* const* string, const GLint* length);
  static void StencilFunc(GLenum func, GLint ref, GLuint mask);
  static void StencilFuncSeparate(GLenum face, GLenum func, GLint ref,
                                  GLuint mask);
  static void StencilMask(GLuint mask);
  static void StencilMaskSeparate(GLenum face, GLuint mask);
  static void StencilOp(GLenum fail, GLenum zfail, GLenum zpass);
  static void StencilOpSeparate(GLenum face, GLenum fail, GLenum zfail,
                                GLenum zpass);
  static void TexImage2D(GLenum target, GLint level, GLint internalformat,
                         GLsizei width, GLsizei height, GLint border,
                         GLenum format, GLenum type, const GLvoid* pixels);
  static void TexParameterf(GLenum target, GLenum pname, GLfloat param);
  static void TexParameterfv(GLenum target, GLenum pname,
                             const GLfloat* params);
  static void TexParameteri(GLenum target, GLenum pname, GLint param);
  static void TexParameteriv(GLenum target, GLenum pname, const GLint* params);
  static void TexSubImage2D(GLenum target, GLint level, GLint xoffset,
                            GLint yoffset, GLsizei width, GLsizei height,
                            GLenum format, GLenum type, const GLvoid* pixels);
  static void Uniform1f(GLint location, GLfloat x);
  static void Uniform1fv(GLint location, GLsizei count, const GLfloat* v);
  static void Uniform1i(GLint location, GLint x);
  static void Uniform1iv(GLint location, GLsizei count, const GLint* v);
  static void Uniform2f(GLint location, GLfloat x, GLfloat y);
  static void Uniform2fv(GLint location, GLsizei count, const GLfloat* v);
  static void Uniform2i(GLint location, GLint x, GLint y);
  static void Uniform2iv(GLint location, GLsizei count, const GLint* v);
  static void Uniform3f(GLint location, GLfloat x, GLfloat y, GLfloat z);
  static void Uniform3fv(GLint location, GLsizei count, const GLfloat* v);
  static void Uniform3i(GLint location, GLint x, GLint y, GLint z);
  static void Uniform3iv(GLint location, GLsizei count, const GLint* v);
  static void Uniform4f(GLint location, GLfloat x, GLfloat y, GLfloat z,
                        GLfloat w);
  static void Uniform4fv(GLint location, GLsizei count, const GLfloat* v);
  static void Uniform4i(GLint location, GLint x, GLint y, GLint z, GLint w);
  static void Uniform4iv(GLint location, GLsizei count, const GLint* v);
  static void UniformMatrix2fv(GLint location, GLsizei count,
                               GLboolean transpose, const GLfloat* value);
  static void UniformMatrix3fv(GLint location, GLsizei count,
                               GLboolean transpose, const GLfloat* value);
  static void UniformMatrix4fv(GLint location, GLsizei count,
                               GLboolean transpose, const GLfloat* value);
  static void UseProgram(GLuint program);
  static void ValidateProgram(GLuint program);
  static void VertexAttrib1f(GLuint indx, GLfloat x);
  static void VertexAttrib1fv(GLuint indx, const GLfloat* values);
  static void VertexAttrib2f(GLuint indx, GLfloat x, GLfloat y);
  static void VertexAttrib2fv(GLuint indx, const GLfloat* values);
  static void VertexAttrib3f(GLuint indx, GLfloat x, GLfloat y, GLfloat z);
  static void VertexAttrib3fv(GLuint indx, const GLfloat* values);
  static void VertexAttrib4f(GLuint indx, GLfloat x, GLfloat y, GLfloat z,
                             GLfloat w);
  static void VertexAttrib4fv(GLuint indx, const GLfloat* values);
  static void VertexAttribPointer(GLuint indx, GLint size, GLenum type,
                                  GLboolean normalized, GLsizei stride,
                                  const GLvoid* ptr);
  static void Viewport(GLint x, GLint y, GLsizei width, GLsizei height);

  // es3 interface
  static void BlitFramebuffer(GLint srcX0, GLint srcY0, GLint srcX1,
                              GLint srcY1, GLint dstX0, GLint dstY0,
                              GLint dstX1, GLint dstY1, GLbitfield mask,
                              GLenum filter);

  static void InvalidateFramebuffer(GLenum target, GLsizei numAttachments,
                                    const GLenum* attachments);

  static void BindVertexArray(GLuint array);
  static void DeleteVertexArrays(GLsizei n, const GLuint* arrays);
  static void GenVertexArrays(GLsizei n, GLuint* arrays);
  static GLboolean IsVertexArray(GLuint array);
  static void ReadBuffer(GLenum mode);
  static void DrawArraysInstanced(GLenum mode, GLint first, GLsizei count,
                                  GLsizei instancecount);
  static void DrawElementsInstanced(GLenum mode, GLsizei count, GLenum type,
                                    const GLvoid* indices,
                                    GLsizei instancecount);
  static void VertexAttribDivisor(GLuint index, GLuint divisor);
  static GLsync FenceSync(GLenum condition, GLbitfield flags);
  static void ClientWaitSync(GLsync sync, GLbitfield flags, GLuint64 timeout);
  static void WaitSync(GLsync sync, GLbitfield flags, GLuint64 timeout);

  // es3
  static void RenderbufferStorageMultisample(GLenum target, GLsizei samples,
                                             GLenum internalformat,
                                             GLsizei width, GLsizei height);
  static void TexImage3D(GLenum target, GLint level, GLint internalformat,
                         GLsizei width, GLsizei height, GLsizei depth,
                         GLint border, GLenum format, GLenum type,
                         const GLvoid* pixels);

  // extension
  enum Extension {
    kMultisampledRenderToTexture,
    kAPPLEFramebufferMultisample,
  };

  // GL_EXT_multisampled_render_to_texture
  static bool LoadExtension(Extension extension);

  static void RenderbufferStorageMultisampleEXT(GLenum target, GLsizei samples,
                                                GLenum internalformat,
                                                GLsizei width, GLsizei height);

  // custom extend
  // only allowed used in scoped_gl_error_check
  static void SetError(GLenum error);
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_GL_GL_API_H_
