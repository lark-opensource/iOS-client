// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/gl_command_buffer.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef CANVAS_GPU_COMMAND_BUFFER_GL_COMMAND_BUFFER_H_
#define CANVAS_GPU_COMMAND_BUFFER_GL_COMMAND_BUFFER_H_

#include <string>

#include "third_party/krypton/canvas/gpu/command_buffer/command_recorder.h"
#include "canvas/gpu/gl/gl_api.h"

namespace lynx {
namespace canvas {

using std::string;

class GLCommandBuffer {
 public:
  GLCommandBuffer(CommandRecorder* recorder);
  GLCommandBuffer(const GLCommandBuffer& gl) = delete;
  GLCommandBuffer() = delete;

  void ActiveTexture(uint32_t texture);
  void AttachShader(uint32_t program, uint32_t shader);
  void BindAttribLocation(uint32_t program, uint32_t index, string name);
  void BindBuffer(uint32_t target, uint32_t buffer);
  void BindFramebuffer(uint32_t target, uint32_t framebuffer);
  void BindRenderbuffer(uint32_t target, uint32_t renderbuffer);
  void BindTexture(uint32_t target, uint32_t texture);
  void BlendColor(float red, float green, float blue, float alpha);
  void BlendEquation(uint32_t mode);
  void BlendEquationSeparate(uint32_t modeRGB, uint32_t modeAlpha);
  void BlendFunc(uint32_t sfactor, uint32_t dfactor);
  void BlendFuncSeparate(uint32_t sfactorRGB, uint32_t dfactorRGB, uint32_t sfactorAlpha, uint32_t dfactorAlpha);
  void BufferData(uint32_t target, int64_t size, const void* data, uint32_t usage);
  void BufferSubData(uint32_t target, int64_t offset, int64_t size, const void* data);
  uint32_t CheckFramebufferStatus(uint32_t target);
  void Clear(uint32_t mask);
  void ClearColor(float red, float green, float blue, float alpha);
  void ClearDepthf(float d);
  void ClearStencil(int32_t s);
  void ColorMask(GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha);
  void CompileShader(uint32_t shader);
  void CompressedTexImage2D(uint32_t target, int32_t level, uint32_t internalformat, int32_t width, int32_t height, int32_t border, int32_t imageSize, string data);
  void CompressedTexSubImage2D(uint32_t target, int32_t level, int32_t xoffset, int32_t yoffset, int32_t width, int32_t height, uint32_t format, int32_t imageSize, string data);
  void CopyTexImage2D(uint32_t target, int32_t level, uint32_t internalformat, int32_t x, int32_t y, int32_t width, int32_t height, int32_t border);
  void CopyTexSubImage2D(uint32_t target, int32_t level, int32_t xoffset, int32_t yoffset, int32_t x, int32_t y, int32_t width, int32_t height);
  uint32_t CreateProgram();
  uint32_t CreateShader(uint32_t type);
  void CullFace(uint32_t mode);
  void DeleteBuffers(int32_t n, uint32_t *buffers);
  void DeleteFramebuffers(int32_t n, uint32_t *framebuffers);
  void DeleteProgram(uint32_t program);
  void DeleteRenderbuffers(int32_t n, uint32_t *renderbuffers);
  void DeleteShader(uint32_t shader);
  void DeleteTextures(int32_t n, uint32_t *textures);
  void DepthFunc(uint32_t func);
  void DepthMask(GLboolean flag);
  void DepthRangef(float n, float f);
  void DetachShader(uint32_t program, uint32_t shader);
  void Disable(uint32_t cap);
  void DisableVertexAttribArray(uint32_t index);
  void DrawArrays(uint32_t mode, int32_t first, int32_t count);
  void DrawElements(uint32_t mode, int32_t count, uint32_t type, const void* indices);
  void Enable(uint32_t cap);
  void EnableVertexAttribArray(uint32_t index);
  void Finish();
  void Flush();
  void FramebufferRenderbuffer(uint32_t target, uint32_t attachment, uint32_t renderbuffertarget, uint32_t renderbuffer);
  void FramebufferTexture2D(uint32_t target, uint32_t attachment, uint32_t textarget, uint32_t texture, int32_t level);
  void FrontFace(uint32_t mode);
  void GenBuffers(int32_t n, uint32_t *buffers);
  void GenerateMipmap(uint32_t target);
  void GenFramebuffers(int32_t n, uint32_t *framebuffers);
  void GenRenderbuffers(int32_t n, uint32_t *renderbuffers);
  void GenTextures(int32_t n, uint32_t *textures);
  void GetActiveAttrib(uint32_t program, uint32_t index, int32_t bufSize, int32_t* length, int32_t* size, uint32_t* type, GLchar *name);
  void GetActiveUniform(uint32_t program, uint32_t index, int32_t bufSize, int32_t* length, int32_t* size, uint32_t* type, GLchar *name);
  void GetAttachedShaders(uint32_t program, int32_t maxCount, int32_t* count, uint32_t *shaders);
  int32_t GetAttribLocation(uint32_t program, string name);
  void GetBooleanv(uint32_t pname, GLboolean* data);
  void GetBufferParameteriv(uint32_t target, uint32_t pname, int32_t* params);
  uint32_t GetError();
  void GetFloatv(uint32_t pname, float* data);
  void GetFramebufferAttachmentParameteriv(uint32_t target, uint32_t attachment, uint32_t pname, int32_t* params);
  void GetIntegerv(uint32_t pname, int32_t* data);
  void GetProgramiv(uint32_t program, uint32_t pname, int32_t* params);
  void GetProgramInfoLog(uint32_t program, int32_t bufSize, int32_t* length, GLchar* infoLog);
  void GetRenderbufferParameteriv(uint32_t target, uint32_t pname, int32_t* params);
  void GetShaderiv(uint32_t shader, uint32_t pname, int32_t* params);
  void GetShaderInfoLog(uint32_t shader, int32_t bufSize, int32_t* length, GLchar* infoLog);
  void GetShaderPrecisionFormat(uint32_t shadertype, uint32_t precisiontype, int32_t* range, int32_t* precision);
  void GetShaderSource(uint32_t shader, int32_t bufSize, int32_t* length, GLchar* source);
  uint8_t const * GetString(uint32_t name);
  void GetTexParameterfv(uint32_t target, uint32_t pname, float* params);
  void GetTexParameteriv(uint32_t target, uint32_t pname, int32_t* params);
  void GetUniformfv(uint32_t program, int32_t location, float* params);
  void GetUniformiv(uint32_t program, int32_t location, int32_t* params);
  int32_t GetUniformLocation(uint32_t program, string name);
  void GetVertexAttribfv(uint32_t index, uint32_t pname, float* params);
  void GetVertexAttribiv(uint32_t index, uint32_t pname, int32_t* params);
  void GetVertexAttribPointerv(uint32_t index, uint32_t pname, void** pointer);
  void Hint(uint32_t target, uint32_t mode);
  bool IsBuffer(uint32_t buffer);
  bool IsEnabled(uint32_t cap);
  bool IsFramebuffer(uint32_t framebuffer);
  bool IsProgram(uint32_t program);
  bool IsRenderbuffer(uint32_t renderbuffer);
  bool IsShader(uint32_t shader);
  bool IsTexture(uint32_t texture);
  void LineWidth(float width);
  void LinkProgram(uint32_t program);
  void PixelStorei(uint32_t pname, int32_t param);
  void PolygonOffset(float factor, float units);
  void ReadPixels(int32_t x, int32_t y, int32_t width, int32_t height, uint32_t format, uint32_t type, std::vector<GLchar>* pixels);
  void GetPixels(int32_t x, int32_t y, int32_t width, int32_t height, void* pixels, uint32_t fbo, bool flipy, bool premultiply_alpha);
  void PutPixels(void *pixels, int32_t width, int32_t height, uint32_t fbo, int32_t srcX, int32_t srcY, int32_t srcWidth, int32_t srcHeight, int32_t dstX, int32_t dstY, int32_t dstWidth, int32_t dstHeight);
  void ReleaseShaderCompiler();
  void RenderbufferStorage(uint32_t target, uint32_t internalformat, int32_t width, int32_t height);
  void SampleCoverage(float value, GLboolean invert);
  void Scissor(int32_t x, int32_t y, int32_t width, int32_t height);
  void ShaderBinary(int32_t count,uint32_t* shaders, uint32_t binaryformat, const void* binary, int32_t length);
  void ShaderSource(uint32_t shader, int32_t count, const GLchar** strings, int32_t* length);
  void StencilFunc(uint32_t func, int32_t ref, uint32_t mask);
  void StencilFuncSeparate(uint32_t face, uint32_t func, int32_t ref, uint32_t mask);
  void StencilMask(uint32_t mask);
  void StencilMaskSeparate(uint32_t face, uint32_t mask);
  void StencilOp(uint32_t fail, uint32_t zfail, uint32_t zpass);
  void StencilOpSeparate(uint32_t face, uint32_t sfail, uint32_t dpfail, uint32_t dppass);
  void TexImage2D(uint32_t target, int32_t level, int32_t internalformat, int32_t width, int32_t height, int32_t border, uint32_t format, uint32_t type, const void* pixels);
  void TexParameterf(uint32_t target, uint32_t pname, float param);
  void TexParameterfv(uint32_t target, uint32_t pname, std::vector<float> params);
  void TexParameteri(uint32_t target, uint32_t pname, int32_t param);
  void TexParameteriv(uint32_t target, uint32_t pname, std::vector<int32_t> params);
  void TexSubImage2D(uint32_t target, int32_t level, int32_t xoffset, int32_t yoffset, int32_t width, int32_t height, uint32_t format, uint32_t type, const void* pixels);
  void Uniform1f(int32_t location, float v0);
  void Uniform1fv(int32_t location, int32_t count, const float* value);
  void Uniform1i(int32_t location, int32_t v0);
  void Uniform1iv(int32_t location, int32_t count, const int32_t* value);
  void Uniform2f(int32_t location, float v0, float v1);
  void Uniform2fv(int32_t location, int32_t count, const float* value);
  void Uniform2i(int32_t location, int32_t v0, int32_t v1);
  void Uniform2iv(int32_t location, int32_t count, const int32_t* value);
  void Uniform3f(int32_t location, float v0, float v1, float v2);
  void Uniform3fv(int32_t location, int32_t count, const float* value);
  void Uniform3i(int32_t location, int32_t v0, int32_t v1, int32_t v2);
  void Uniform3iv(int32_t location, int32_t count, const int32_t* value);
  void Uniform4f(int32_t location, float v0, float v1, float v2, float v3);
  void Uniform4fv(int32_t location, int32_t count, const float* value);
  void Uniform4i(int32_t location, int32_t v0, int32_t v1, int32_t v2, int32_t v3);
  void Uniform4iv(int32_t location, int32_t count, const int32_t* value);
  void UniformMatrix2fv(int32_t location, int32_t count, GLboolean transpose, const float* value);
  void UniformMatrix3fv(int32_t location, int32_t count, GLboolean transpose, const float* value);
  void UniformMatrix4fv(int32_t location, int32_t count, GLboolean transpose, const float* value);
  void UseProgram(uint32_t program);
  void ValidateProgram(uint32_t program);
  void VertexAttrib1F(uint32_t index, float x);
  void VertexAttrib1Fv(uint32_t index, const float* v);
  void VertexAttrib2F(uint32_t index, float x, float y);
  void VertexAttrib2Fv(uint32_t index, const float* v);
  void VertexAttrib3F(uint32_t index, float x, float y, float z);
  void VertexAttrib3Fv(uint32_t index, const float* v);
  void VertexAttrib4F(uint32_t index, float x, float y, float z, float w);
  void VertexAttrib4Fv(uint32_t index, const float* v);
  void VertexAttribPointer(uint32_t index, int32_t size, uint32_t type, GLboolean normalized, int32_t stride, const void* pointer);
  void Viewport(int32_t x, int32_t y, int32_t width, int32_t height);

 private:
  void Flush(bool is_sync) {
    recorder_->Commit(is_sync);
  }

  CommandRecorder* recorder_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_COMMAND_BUFFER_GL_COMMAND_BUFFER_H_
