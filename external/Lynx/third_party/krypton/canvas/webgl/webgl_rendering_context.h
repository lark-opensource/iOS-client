// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_WEBGL_RENDERING_CONTEXT_H_
#define CANVAS_WEBGL_WEBGL_RENDERING_CONTEXT_H_

#include "canvas/base/shared_vector.h"
#include "canvas/bitmap.h"
#include "canvas/canvas_context.h"
#include "canvas/canvas_element.h"
#include "canvas/gpu/command_buffer/gl_command_buffer.h"
#include "canvas/gpu/gl_device_attributes.h"
#include "canvas/image_data.h"
#include "canvas/image_element.h"
#include "canvas/media/video_element.h"
#include "canvas/texture_source.h"
#include "canvas/webgl/canvas_resource_provider_3d.h"
#include "canvas/webgl/webgl_buffer.h"
#include "canvas/webgl/webgl_framebuffer.h"
#include "canvas/webgl/webgl_program.h"
#include "canvas/webgl/webgl_renderbuffer.h"
#include "canvas/webgl/webgl_shader.h"
#include "canvas/webgl/webgl_texture.h"
#include "canvas/webgl/webgl_uniform_location.h"
#include "gl_state_cache.h"
#include "jsbridge/napi/array_buffer_view.h"
#include "third_party/krypton/canvas/gpu/command_buffer/command_recorder.h"
#include "webgl_active_info.h"
#include "webgl_shader_precision_format.h"

using Napi::Array;
using Napi::ArrayBuffer;
using Napi::Float32Array;
using Napi::Int32Array;
using Napi::Number;
using Napi::Value;

namespace lynx {
namespace canvas {

using piper::ArrayBufferView;

enum ChannelBits {
  kRed = 0x1,
  kGreen = 0x2,
  kBlue = 0x4,
  kAlpha = 0x8,
  kDepth = 0x10000,
  kStencil = 0x20000,

  kRGB = kRed | kGreen | kBlue,
  kRGBA = kRGB | kAlpha
};

class WebGLRenderingContext : public CanvasContext {
 public:
  static WebGLRenderingContext *Create(
      CanvasElement *canvas, std::shared_ptr<CanvasApp> canvas_app,
      std::unique_ptr<WebGLContextAttributes> context_attributes) {
    return new WebGLRenderingContext(canvas, canvas_app,
                                     std::move(context_attributes));
  }
  WebGLRenderingContext(
      CanvasElement *canvas, std::shared_ptr<CanvasApp> canvas_app,
      std::unique_ptr<WebGLContextAttributes> context_attributes);
  ~WebGLRenderingContext() override;
  void OnWrapped() override;
  int GetDrawingBufferWidth();
  int GetDrawingBufferHeight();
  void ActiveTexture(GLenum texture);
  void AttachShader(WebGLProgram *program, WebGLShader *shader);
  void BindAttribLocation(WebGLProgram *program, GLuint index,
                          const std::string &name);
  void BindBuffer(GLenum target, WebGLBuffer *buffer);
  void BindFramebuffer(GLenum target, WebGLFramebuffer *framebuffer);
  void BindRenderbuffer(GLenum target, WebGLRenderbuffer *renderbuffer);
  void BindTexture(GLenum target, WebGLTexture *texture);
  void BlendColor(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
  void BlendEquation(GLenum mode);
  void BlendEquationSeparate(GLenum modeRGB, GLenum modeAlpha);
  void BlendFunc(GLenum sfactor, GLenum dfactor);
  void BlendFuncSeparate(GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha,
                         GLenum dstAlpha);

  void BufferData(GLenum target, int64_t size, GLenum usage);
  void BufferData(GLenum target, ArrayBufferView data, GLenum usage);
  void BufferData(GLenum target, ArrayBuffer data, GLenum usage);
  void BufferData(GLenum target, void *data, uint32_t size, GLenum usage);
  void BufferSubData(GLenum target, int64_t offset, ArrayBufferView data);
  void BufferSubData(GLenum target, int64_t offset, ArrayBuffer data);
  void BufferSubData(GLenum target, int64_t offset, void *data, uint32_t size);

  GLenum CheckFramebufferStatus(GLenum target);
  void Clear(GLbitfield mask);
  void ClearColor(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
  void ClearDepth(GLclampf depth);
  void ClearStencil(GLint stencil);
  void ColorMask(GLboolean red, GLboolean green, GLboolean blue,
                 GLboolean alpha);
  void CompileShader(WebGLShader *shader);

  void CompressedTexImage2D(GLenum target, GLint level, GLenum internalformat,
                            GLsizei width, GLsizei height, GLint border,
                            ArrayBufferView data);
  void CompressedTexSubImage2D(GLenum target, GLint level, GLint xoffset,
                               GLint yoffset, GLsizei width, GLsizei height,
                               GLenum format, ArrayBufferView data);
  void CopyTexImage2D(GLenum target, GLint level, GLenum internalformat,
                      GLint x, GLint y, GLsizei width, GLsizei height,
                      GLint border);
  void CopyTexSubImage2D(GLenum target, GLint level, GLint xoffset,
                         GLint yoffset, GLint x, GLint y, GLsizei width,
                         GLsizei height);

  void CullFace(GLenum mode);

  WebGLBuffer *CreateBuffer();
  WebGLFramebuffer *CreateFramebuffer();
  WebGLProgram *CreateProgram();
  WebGLRenderbuffer *CreateRenderbuffer();
  WebGLShader *CreateShader(GLenum type);
  WebGLTexture *CreateTexture();

  void DeleteBuffer(WebGLBuffer *buffer);
  void DeleteFramebuffer(WebGLFramebuffer *framebuffer);
  void DeleteProgram(WebGLProgram *program);
  void DeleteRenderbuffer(WebGLRenderbuffer *renderbuffer);
  void DeleteShader(WebGLShader *shader);
  void DeleteTexture(WebGLTexture *texture);

  void DepthFunc(GLenum func);
  void DepthMask(GLboolean flag);
  void DepthRange(GLfloat zNear, GLfloat zFar);
  void DetachShader(WebGLProgram *program, WebGLShader *shader);
  void Disable(GLenum cap);
  void DisableVertexAttribArray(GLuint index);
  void DrawArrays(GLenum mode, GLint first, GLsizei count);
  void DrawElements(GLenum mode, GLsizei count, GLenum type, int64_t offset);

  void Enable(GLenum cap);
  void EnableVertexAttribArray(GLuint index);
  void Finish();
  void Flush();
  void FramebufferRenderbuffer(GLenum target, GLenum attachment,
                               GLenum renderbuffertarget,
                               WebGLRenderbuffer *renderbuffer);
  void FramebufferTexture2D(GLenum target, GLenum attachment, GLenum textarget,
                            WebGLTexture *texture, GLint level);
  void FrontFace(GLenum mode);
  void GenerateMipmap(GLenum target);
  WebGLActiveInfo *GetActiveAttrib(WebGLProgram *program, GLuint index);
  WebGLActiveInfo *GetActiveUniform(WebGLProgram *program, GLuint index);

  std::vector<WebGLShader *> GetAttachedShaders(WebGLProgram *program) const;

  GLint GetAttribLocation(WebGLProgram *program, std::string name);

  Value GetBufferParameter(GLenum target, GLenum pname);

  WebGLContextAttributes *GetContextAttributes();

  GLenum GetError();

  Value GetExtension(std::string name);

  Value GetFramebufferAttachmentParameter(GLenum target, GLenum attachment,
                                          GLenum pname);
  Value GetParameter(GLenum pname);
  Value GetProgramParameter(WebGLProgram *program, GLenum pname);
  std::string GetProgramInfoLog(WebGLProgram *program);
  Value GetRenderbufferParameter(GLenum target, GLenum pname);
  Value GetShaderParameter(WebGLShader *shader, GLenum pname);

  std::string GetShaderInfoLog(WebGLShader *shader);

  WebGLShaderPrecisionFormat *GetShaderPrecisionFormat(GLenum shader_type,
                                                       GLenum precision_type);

  std::string GetShaderSource(WebGLShader *shader);

  std::vector<std::string> GetSupportedExtensions();

  Value GetTexParameter(GLenum target, GLenum pname);

  void Hint(GLenum target, GLenum mode);
  GLboolean IsBuffer(WebGLBuffer *buffer);
  GLboolean IsContextLost();
  GLboolean IsEnabled(GLenum cap);
  GLboolean IsFramebuffer(WebGLFramebuffer *framebuffer);
  GLboolean IsProgram(WebGLProgram *program);
  GLboolean IsRenderbuffer(WebGLRenderbuffer *renderbuffer);
  GLboolean IsShader(WebGLShader *shader) const;
  GLboolean IsTexture(WebGLTexture *texture);
  void LineWidth(GLfloat width);
  void PixelStorei(GLenum pname, GLint param);
  void PolygonOffset(GLfloat factor, GLfloat units);

  void ReadPixels(GLint x, GLint y, GLsizei width, GLsizei height,
                  GLenum format, GLenum type, ArrayBufferView pixels);

  void RenderbufferStorage(GLenum target, GLenum internalformat, GLsizei width,
                           GLsizei height);
  void SampleCoverage(GLfloat value, bool invert);
  void Scissor(GLint x, GLint y, GLsizei width, GLsizei height);
  void ShaderSource(WebGLShader *shader, std::string source);
  void StencilFunc(GLenum func, GLint ref, GLuint mask);
  void StencilFuncSeparate(GLenum face, GLenum func, GLint ref, GLuint mask);
  void StencilMask(GLuint mask);
  void StencilMaskSeparate(GLenum face, GLuint mask);
  void StencilOp(GLenum fail, GLenum zfail, GLenum zpass);
  void StencilOpSeparate(GLenum face, GLenum fail, GLenum zfail, GLenum zpass);

  void TexParameterf(GLenum target, GLenum pname, GLfloat param);
  void TexParameteri(GLenum target, GLenum pname, GLint param);

  void TexImage2D(GLenum target, GLint level, GLint internalformat,
                  GLsizei width, GLsizei height, GLint border, GLenum format,
                  GLenum type, ArrayBufferView pixels);
  void TexImage2D(GLenum target, GLint level, GLint internalformat,
                  GLenum format, GLenum type, ImageData *pixels);
  void TexImage2D(GLenum target, GLint level, GLint internalformat,
                  GLenum format, GLenum type,
                  CanvasImageSource *canvas_image_source);

  void TexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset,
                     GLsizei width, GLsizei height, GLenum format, GLenum type,
                     ArrayBufferView pixels);
  void TexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset,
                     GLenum format, GLenum type, ImageData *pixels);
  void TexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset,
                     GLenum format, GLenum type,
                     CanvasImageSource *canvas_image_source);

  WebGLUniformLocation *GetUniformLocation(WebGLProgram *,
                                           const std::string &name);

  void LinkProgram(WebGLProgram *program);
  virtual void UseProgram(WebGLProgram *program);
  void ValidateProgram(WebGLProgram *program);

  void VertexAttrib1F(GLuint index, GLfloat x);
  void VertexAttrib1Fv(GLuint index, const Napi::Float32Array &values);
  void VertexAttrib1Fv(GLuint index, SharedVector<GLfloat> values);
  void VertexAttrib2F(GLuint index, GLfloat x, GLfloat y);
  void VertexAttrib2Fv(GLuint index, const Napi::Float32Array &values);
  void VertexAttrib2Fv(GLuint index, SharedVector<GLfloat> values);
  void VertexAttrib3F(GLuint index, GLfloat x, GLfloat y, GLfloat z);
  void VertexAttrib3Fv(GLuint index, const Napi::Float32Array &values);
  void VertexAttrib3Fv(GLuint index, SharedVector<GLfloat> values);
  void VertexAttrib4F(GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
  void VertexAttrib4Fv(GLuint index, const Napi::Float32Array &values);
  void VertexAttrib4Fv(GLuint index, SharedVector<GLfloat> values);
  void VertexAttribPointer(GLuint indx, GLint size, GLenum type,
                           GLboolean normalized, GLsizei stride,
                           int64_t offset);

  void Viewport(GLint x, GLint y, GLsizei width, GLsizei height);

  Value GetUniform(WebGLProgram *program,
                   WebGLUniformLocation *uniform_location);

  Value GetVertexAttrib(GLuint index, GLenum pname);

  int64_t GetVertexAttribOffset(GLuint index, GLenum pname);

  void Uniform1F(const WebGLUniformLocation *, GLfloat x);
  void Uniform1Fv(const WebGLUniformLocation *, const Float32Array &);
  void Uniform1Fv(const WebGLUniformLocation *, SharedVector<GLfloat>);
  void Uniform1I(const WebGLUniformLocation *, GLint x);
  void Uniform1Iv(const WebGLUniformLocation *, const Int32Array &);
  void Uniform1Iv(const WebGLUniformLocation *, SharedVector<GLint>);
  void Uniform2F(const WebGLUniformLocation *, GLfloat x, GLfloat y);
  void Uniform2Fv(const WebGLUniformLocation *, const Float32Array &);
  void Uniform2Fv(const WebGLUniformLocation *, SharedVector<GLfloat>);
  void Uniform2I(const WebGLUniformLocation *, GLint x, GLint y);
  void Uniform2Iv(const WebGLUniformLocation *, const Int32Array &);
  void Uniform2Iv(const WebGLUniformLocation *, SharedVector<GLint>);
  void Uniform3F(const WebGLUniformLocation *, GLfloat x, GLfloat y, GLfloat z);
  void Uniform3Fv(const WebGLUniformLocation *, const Float32Array &);
  void Uniform3Fv(const WebGLUniformLocation *, SharedVector<GLfloat>);
  void Uniform3I(const WebGLUniformLocation *, GLint x, GLint y, GLint z);
  void Uniform3Iv(const WebGLUniformLocation *, const Int32Array &);
  void Uniform3Iv(const WebGLUniformLocation *, SharedVector<GLint>);
  void Uniform4F(const WebGLUniformLocation *, GLfloat x, GLfloat y, GLfloat z,
                 GLfloat w);
  void Uniform4Fv(const WebGLUniformLocation *, const Float32Array &);
  void Uniform4Fv(const WebGLUniformLocation *, SharedVector<GLfloat>);
  void Uniform4I(const WebGLUniformLocation *, GLint x, GLint y, GLint z,
                 GLint w);
  void Uniform4Iv(const WebGLUniformLocation *, const Int32Array &);
  void Uniform4Iv(const WebGLUniformLocation *, SharedVector<GLint>);
  void UniformMatrix2Fv(const WebGLUniformLocation *, GLboolean transpose,
                        const Float32Array &value);
  void UniformMatrix2Fv(const WebGLUniformLocation *, GLboolean transpose,
                        SharedVector<GLfloat> value);
  void UniformMatrix3Fv(const WebGLUniformLocation *, GLboolean transpose,
                        const Float32Array &value);
  void UniformMatrix3Fv(const WebGLUniformLocation *, GLboolean transpose,
                        SharedVector<GLfloat> value);
  void UniformMatrix4Fv(const WebGLUniformLocation *, GLboolean transpose,
                        const Float32Array &value);
  void UniformMatrix4Fv(const WebGLUniformLocation *, GLboolean transpose,
                        SharedVector<GLfloat> value);

  /// extension ANGLE_instanced_arrays
  void DrawArraysInstancedANGLE(GLenum mode, GLint first, GLsizei count,
                                GLsizei primcount);
  void DrawElementsInstancedANGLE(GLenum mode, GLsizei count, GLenum type,
                                  int64_t offset, GLsizei primcount);
  void VertexAttribDivisorANGLE(GLuint index, GLuint divisor);

  /// extension OES_vertex_array_object
  WebGLVertexArrayObjectOES *CreateVertexArrayOES();
  GLboolean IsVertexArrayOES(WebGLVertexArrayObjectOES *arrayObject);
  void DeleteVertexArrayOES(WebGLVertexArrayObjectOES *arrayObject);
  void BindVertexArrayOES(WebGLVertexArrayObjectOES *arrayObject);

  /// extension EXT_tex_image_3d_KR support
  void TexImage3D(GLenum target, GLint level, GLenum internalformat,
                  GLsizei width, GLsizei height, GLsizei depth, GLint border,
                  GLenum format, GLenum type, ArrayBufferView pixels);

  /// extension WEBGL_compressed_texture_astc
  std::vector<std::string> GetSupportedProfiles();

  unsigned MaxVertexAttribs();

  unsigned MaxCombinedTextureImageUnits();

  CommandRecorder *Recorder() const {
    DCHECK(recorder_);
    return recorder_;
  }

  std::shared_ptr<CanvasResourceProvider3D> ResourceProvider() const {
    return std::static_pointer_cast<CanvasResourceProvider3D>(
        element_->ResourceProvider());
  }

  void ResetUnpackParameters();
  void RestoreUnpackParameters();

  size_t UniqueID() const { return unique_id_; }

  void SetClientOnFrameCallback(std::function<void()> on_frame);

 protected:
  virtual bool IsWebGL2() const { return false; };

 private:
  std::shared_ptr<CanvasApp> canvas_app_;

  void Present(bool is_sync);
  void DidDraw();

  void InitNewContext();

  bool ValidateValueFitNonNegInt32(const char *function_name,
                                   const char *param_name, int64_t value);

  bool CheckAttrBeforeDraw() const;
  bool CheckDivisorBeforeDraw() const;
  WebGLFramebuffer *ValidateFramebufferBinding(const uint32_t target);
  GLenum ExtractTypeFromStorageFormat(GLenum internalformat);
  uint32_t ComputeBytesPerPixelForReadPixels(GLenum format, GLenum type);
  bool ValidateReadPixelsFuncParameters(const char *func_name, uint32_t width,
                                        uint32_t height,
                                        uint32_t bytes_per_pixel,
                                        int64_t buffer_size);
  uint32_t ComputeImageSizeInBytes(int64_t bytes_per_pixel, uint32_t width,
                                   uint32_t height, uint32_t depth,
                                   bool is_pack, uint32_t *image_size_in_bytes,
                                   uint32_t *padding_in_bytes,
                                   uint32_t *skip_size_in_bytes);
  bool ValidateStencilFuncEnum(const char *func_name, GLenum func);
  bool ValidateFaceEnum(const char *func_name, GLenum face);

  void FindNewMaxNonDefaultTextureUnit();

  WebGLTexture *ValidateTexture2DBinding(const char *func_name,
                                         const uint32_t target,
                                         bool allow_cube_face = true);
  uint32_t ComputeBytesPerPixel(const char *func_name, GLint internalformat,
                                GLenum format, GLenum type);
  bool ValidateUnpackParams(const char *func_name, const uint32_t width);
  uint32_t ComputeNeedSize2D(uint32_t bytesPerPixel, uint32_t w, uint32_t h);

  enum ConsoleDisplayPreference { kDisplayInConsole, kDontDisplayInConsole };

  // Reports an error to glGetError, sends a message to the JavaScript
  // console.
  void SynthesizeGLError(GLenum, const char *function_name,
                         const char *description,
                         ConsoleDisplayPreference = kDisplayInConsole);

  bool ValidateWebGLObject(WebGLObjectNG *object, GLenum *err,
                           const char **err_msg);
  bool ValidateNullableWebGLObject(WebGLObjectNG *object, GLenum *err,
                                   const char **err_msg);
  bool ValidateBufferBindTarget(GLenum target, WebGLBuffer *buffer, GLenum *err,
                                const char **err_msg);
  bool ValidateFramebufferBindTarget(GLenum target, GLenum *err,
                                     const char **err_msg);
  bool ValidateRenderbufferBindTarget(GLenum target, GLenum *err,
                                      const char **err_msg);
  bool ValidateTextureBindTarget(GLenum target, GLenum *err,
                                 const char **err_msg);
  bool ValidateModeEnum(GLenum mode, GLenum *err, const char **err_msg);
  bool ValidateFuncFactor(GLenum factor, GLenum *err, const char **err_msg);

  WebGLBuffer *ValidateBufferDataTarget(const char *function_name,
                                        GLenum target);

  bool ValidateWebGLProgramOrShader(const char *function_name,
                                    WebGLObjectNG *object);
  bool ValidateLocationLength(const char *function_name, const std::string &);
  bool IsPrefixReserved(const std::string &name);
  bool ValidateShaderType(const char *function_name, GLenum shader_type);
  bool ValidateCharacter(unsigned char c);
  bool ValidateString(const char *function_name, const std::string &string);

  bool DeleteObject(WebGLObjectNG *object);

  // Helper function to validate input parameters for uniform functions.
  bool ValidateUniformParameters(const char *function_name,
                                 const WebGLUniformLocation *, const void *,
                                 size_t size, GLsizei mod, GLuint src_offset,
                                 size_t src_length);
  bool ValidateUniformMatrixParameters(const char *function_name,
                                       const WebGLUniformLocation *,
                                       GLboolean transpose, const void *,
                                       size_t size, GLsizei mod,
                                       GLuint src_offset, size_t src_length);
  bool ValidateUniformMatrixParameters(const char *function_name,
                                       const WebGLUniformLocation *,
                                       GLboolean transpose,
                                       const Float32Array &, GLsizei mod,
                                       GLuint src_offset, size_t src_length);
  bool ValidateUniformParameters(const char *function_name,
                                 const WebGLUniformLocation *location,
                                 const Napi::TypedArray &v,
                                 GLsizei required_min_size, GLuint src_offset,
                                 size_t src_length) {
    GLuint length;
    if (src_length <= std::numeric_limits<GLuint>::max()) {
      length = static_cast<GLuint>(src_length);
    } else {
      SynthesizeGLError(GL_INVALID_VALUE, function_name,
                        "src_length is too big");
      return false;
    }
    GLuint array_length;
    if (v.ElementLength() <= std::numeric_limits<GLuint>::max()) {
      array_length = static_cast<GLuint>(v.ElementLength());
    } else {
      SynthesizeGLError(GL_INVALID_VALUE, function_name, "array is too big");
      return false;
    }
    return ValidateUniformMatrixParameters(
        function_name, location, false, v.ArrayBuffer().Data(), array_length,
        required_min_size, src_offset, length);
  }

  GLenum GetBoundReadFramebufferInternalFormat() const;

  GLenum GetBoundReadFramebufferTextureType() const;

  uint32_t GetChannelsForFormat(int format);

  bool ValidateReadPixelsFormatAndTypeCompatible(uint32_t format,
                                                 uint32_t type);

  bool ValidForTarget(GLenum target, GLint level, GLsizei width, GLsizei height,
                      GLsizei depth);

  // Returns the maximum number of levels.
  GLint MaxLevelsForTarget(GLenum target) const;

  static bool IsFormatColorRenderable(GLenum format, GLenum type);

  // Returns the maximum size.
  GLsizei MaxSizeForTarget(GLenum target) const {
    switch (target) {
      case KR_GL_TEXTURE_2D:
      case KR_GL_TEXTURE_EXTERNAL_OES:
      case KR_GL_TEXTURE_2D_ARRAY:
        return device_attributes_.max_texture_size_;
        //      case GL_TEXTURE_RECTANGLE:
        //        return max_rectangle_texture_size_;
      case KR_GL_TEXTURE_3D:
        return device_attributes_.max_3d_texture_size_;
      default:
        return device_attributes_.max_cube_map_texture_size_;
    }
  }

  size_t GenerateUniqueId() {
    thread_local size_t id = 0;
    return id++;
  }

  GLDeviceAttributes device_attributes_;
  GLStateCache local_cache_;
  std::unique_ptr<WebGLContextAttributes> context_attributes_;

  size_t unique_id_;
  mutable CommandRecorder *recorder_;

 private:
  bool ValidateLevel(const char *func_name, GLint level);
  bool ValidateSize(const char *func_name, GLint level, GLint width,
                    GLint height);
  bool ValidateFormatAndType(const char *func_name, GLenum internal_format,
                             GLenum format, GLenum type);
  bool ValidateBorder(const char *func_name, GLint border);
  bool ValidateTextureBinding(const char *func_name, GLenum target,
                              WebGLTexture *&raw_texture);
  bool ValidateSubTextureBinding(const char *func_name, GLenum target,
                                 GLenum format, GLenum type,
                                 WebGLTexture *&raw_texture);
  bool ValidateArrayType(const char *func_name, const uint32_t type,
                         const ArrayBufferView &array);
  bool ValidateArrayBufferForSub(const char *func_name, const uint32_t type,
                                 const ArrayBufferView &array);

  static void PollifyLumianceAlpha(GLenum target, GLenum format, GLenum type);
  static void PollifyOESTextureFloat(GLenum &internalformat, GLenum &format,
                                     GLenum type);
  static void PollifyEXTSRGB(GLenum &internalformat, GLenum &format);

  void TexImage2DHelperArrayBuffer(bool is_sub, WebGLTexture *raw_texture,
                                   uint32_t target, int32_t level,
                                   int32_t internalformat, int32_t xoffset,
                                   int32_t yoffset, int32_t width,
                                   int32_t height, int32_t border,
                                   uint32_t format, uint32_t type,
                                   ArrayBufferView pixels);

  void TexImage2DHelperImageData(bool is_sub, WebGLTexture *raw_texture,
                                 uint32_t target, int32_t level,
                                 int32_t internalformat, int32_t xoffset,
                                 int32_t yoffset, int32_t width, int32_t height,
                                 uint32_t format, uint32_t type,
                                 ImageData *image_data);

  void TexImage2DHelperCanvasImageSource(
      bool is_sub, WebGLTexture *raw_texture, uint32_t target, int32_t level,
      int32_t internalformat, int32_t xoffset, int32_t yoffset, int32_t width,
      int32_t height, uint32_t format, uint32_t type,
      CanvasImageSource *canvas_image_source);

  void TexCommitCommand(bool is_sub, WebGLTexture *raw_texture, uint32_t target,
                        int32_t level, int32_t internalformat, int32_t xoffset,
                        int32_t yoffset, int32_t width, int32_t height,
                        int32_t border, uint32_t format, uint32_t type,
                        const std::shared_ptr<Bitmap> &bitmap);
  void TexCommitCommand(
      bool is_sub, WebGLTexture *raw_texture, uint32_t target, int32_t level,
      int32_t internalformat, int32_t xoffset, int32_t yoffset, int32_t width,
      int32_t height, int32_t border, uint32_t format, uint32_t type,
      const std::shared_ptr<shell::LynxActor<TextureSource>> &texture_source);
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_WEBGL_RENDERING_CONTEXT_H_
