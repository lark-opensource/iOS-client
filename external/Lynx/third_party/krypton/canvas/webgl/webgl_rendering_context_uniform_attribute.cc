// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/gpu/gl/gl_api.h"
#include "canvas/webgl/webgl_rendering_context.h"

namespace lynx {
namespace canvas {

/**
 *  Reviewed by luchengxuan 06/25/2021
 */
void WebGLRenderingContext::DisableVertexAttribArray(GLuint index) {
  DCHECK(Recorder());

  if (index >= device_attributes_.max_vertex_attribs_) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "disableVertexAttribArray",
                      "index out of range");
    return;
  }

  // save cache
  local_cache_.ValidVertexArrayObject()->SetAttribEnabled(index, false);

  // commit command
  class Runnable {
   public:
    Runnable(GLuint index) : index_(index) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::DisableVertexAttribArray(index_);
    }

   private:
    GLuint index_;
  };
  Recorder()->Alloc<Runnable>(index);
}

/**
 *  Reviewed by luchengxuan 06/25/2021
 */
void WebGLRenderingContext::EnableVertexAttribArray(GLuint index) {
  DCHECK(Recorder());

  if (index >= device_attributes_.max_vertex_attribs_) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "enableVertexAttribArray",
                      "index out of range");
    return;
  }

  // save cache
  local_cache_.ValidVertexArrayObject()->SetAttribEnabled(index, true);

  // commit command
  class Runnable {
   public:
    Runnable(GLuint index) : index_(index) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::EnableVertexAttribArray(index_);
    }

   private:
    GLuint index_;
  };
  Recorder()->Alloc<Runnable>(index);
}

/**
 *  Reviewed by luchengxuan 06/25/2021
 */
WebGLActiveInfo *WebGLRenderingContext::GetActiveAttrib(WebGLProgram *program,
                                                        GLuint index) {
  DCHECK(Recorder());

  if (!ValidateWebGLProgramOrShader("getActiveAttrib", program)) return nullptr;

  auto &shader_status_ = *program->GetShaderStatus();
  if (index >= shader_status_.num_active_attribs) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "GetActiveAttrib",
                      "index out of bound.");
    return nullptr;
  }

  auto &cur_attrib = shader_status_.attribs[index];
  auto active_info_obj = new WebGLActiveInfo();
  active_info_obj->name_ = cur_attrib.name_;
  active_info_obj->size_ = cur_attrib.size_;
  active_info_obj->type_ = cur_attrib.type_;

  return active_info_obj;
}

/**
 *  Reviewed by luchengxuan 06/25/2021
 */
WebGLActiveInfo *WebGLRenderingContext::GetActiveUniform(WebGLProgram *program,
                                                         GLuint index) {
  DCHECK(Recorder());

  if (!ValidateWebGLProgramOrShader("getActiveUniform", program))
    return nullptr;

  auto status = program->GetShaderStatus();
  if (index >= status->num_active_uniforms) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "GetActiveUniform",
                      "index out of bound.");
    return nullptr;
  }

  size_t active_count = 0;
  for (int i = 0; i < status->uniforms.size(); ++i) {
    if (status->uniforms[i].standalone) {
      active_count++;
    }

    if (active_count == index + 1) {
      // found
      auto &cur_uniform = status->uniforms[i];
      auto active_info_obj = new WebGLActiveInfo();
      active_info_obj->name_ = cur_uniform.name_;
      active_info_obj->size_ = cur_uniform.size_;
      active_info_obj->type_ = cur_uniform.type_;

      return active_info_obj;
    }
  }

  return nullptr;
}

/**
 *  Reviewed by luchengxuan 06/25/2021
 */
GLint WebGLRenderingContext::GetAttribLocation(WebGLProgram *program,
                                               std::string name) {
  DCHECK(Recorder());

  if (!ValidateWebGLProgramOrShader("getAttribLocation", program)) return -1;
  if (!ValidateLocationLength("getAttribLocation", name)) return -1;
  if (!ValidateString("getAttribLocation", name)) return -1;
  if (IsPrefixReserved(name)) return -1;

  auto status = program->GetShaderStatus();
  if (!status->is_success) {
    SynthesizeGLError(KR_GL_INVALID_OPERATION, "getAttribLocation",
                      "program not linked");
    return 0;
  }

  auto &attrib = status->attribs;
  int32_t location = -1;
  for (auto &i : attrib) {
    if (i.name_ == name) {
      location = i.location_;
      break;
    }
  }

  return location;
}

/**
 *  Reviewed by luchengxuan 06/28/2021
 */
Value WebGLRenderingContext::GetUniform(
    WebGLProgram *program, WebGLUniformLocation *uniform_location) {
  if (!ValidateWebGLProgramOrShader("getUniform", program)) return Env().Null();
  DCHECK(uniform_location);

  if (uniform_location->Program() != program) {
    SynthesizeGLError(KR_GL_INVALID_OPERATION, "getUniform",
                      "no uniformlocation or not valid for this program");
    return Env().Null();
  }
  GLint location = uniform_location->Location();

  auto status = program->GetShaderStatus();
  auto &uniform = status->GetUniformByLocation(location);
  const auto type = uniform.type_;

  uint32_t base_type = 0, length = 0;
  switch (type) {
    case KR_GL_BOOL:
      base_type = KR_GL_BOOL;
      length = 1;
      break;
    case KR_GL_BOOL_VEC2:
      base_type = KR_GL_BOOL;
      length = 2;
      break;
    case KR_GL_BOOL_VEC3:
      base_type = KR_GL_BOOL;
      length = 3;
      break;
    case KR_GL_BOOL_VEC4:
      base_type = KR_GL_BOOL;
      length = 4;
      break;
    case KR_GL_INT:
      base_type = KR_GL_INT;
      length = 1;
      break;
    case KR_GL_INT_VEC2:
      base_type = KR_GL_INT;
      length = 2;
      break;
    case KR_GL_INT_VEC3:
      base_type = KR_GL_INT;
      length = 3;
      break;
    case KR_GL_INT_VEC4:
      base_type = KR_GL_INT;
      length = 4;
      break;
    case KR_GL_FLOAT:
      base_type = KR_GL_FLOAT;
      length = 1;
      break;
    case KR_GL_FLOAT_VEC2:
      base_type = KR_GL_FLOAT;
      length = 2;
      break;
    case KR_GL_FLOAT_VEC3:
      base_type = KR_GL_FLOAT;
      length = 3;
      break;
    case KR_GL_FLOAT_VEC4:
      base_type = KR_GL_FLOAT;
      length = 4;
      break;
    case KR_GL_FLOAT_MAT2:
      base_type = KR_GL_FLOAT;
      length = 4;
      break;
    case KR_GL_FLOAT_MAT3:
      base_type = KR_GL_FLOAT;
      length = 9;
      break;
    case KR_GL_FLOAT_MAT4:
      base_type = KR_GL_FLOAT;
      length = 16;
      break;
    case KR_GL_SAMPLER_2D:
    case KR_GL_SAMPLER_CUBE:
      base_type = KR_GL_INT;
      length = 1;
      break;
    default:
      SynthesizeGLError(KR_GL_INVALID_VALUE, "getUniform", "unhandled type");
      return Env().Null();
  }
  switch (base_type) {
    case KR_GL_FLOAT: {
      float value[16] = {0};
      struct Runnable {
        void Run(command_buffer::RunnableBuffer *buffer) const {
          DCHECK(program_content_);
          auto program = program_content_->Get();
          GL::GetUniformfv(program, location_, value_);
        }
        PuppetContent<uint32_t> *program_content_ = nullptr;
        uint32_t location_;
        float *value_;
      };
      auto cmd = Recorder()->Alloc<Runnable>();
      cmd->program_content_ = program->related_id().Get();
      cmd->location_ = location;
      cmd->value_ = value;
      Present(true);
      if (length == 1) return Napi::Value::From(Env(), value[0]);
      auto ret = Napi::Array::New(Env(), length);
      for (uint32_t i = 0; i < length; ++i) {
        ret.Set(i, value[i]);
      }
      return ret;
    }
    case KR_GL_INT: {
      int32_t value[4] = {0};
      struct Runnable {
        void Run(command_buffer::RunnableBuffer *buffer) const {
          DCHECK(program_content_);
          auto program = program_content_->Get();
          GL::GetUniformiv(program, location_, value_);
        }
        PuppetContent<uint32_t> *program_content_ = nullptr;
        uint32_t location_;
        int32_t *value_;
      };
      auto cmd = Recorder()->Alloc<Runnable>();
      cmd->program_content_ = program->related_id().Get();
      cmd->location_ = location;
      cmd->value_ = value;
      Present(true);
      if (length == 1) {
        return Napi::Value::From(Env(), value[0]);
      }
      auto ret = Napi::Array::New(Env(), length);
      for (uint32_t i = 0; i < length; ++i) {
        ret.Set(i, value[i]);
      }
      return ret;
    }
    case KR_GL_BOOL: {
      int32_t value[4] = {0};
      struct Runnable {
        void Run(command_buffer::RunnableBuffer *buffer) const {
          DCHECK(program_content_);
          auto program = program_content_->Get();
          GL::GetUniformiv(program, location_, value_);
        }
        PuppetContent<uint32_t> *program_content_ = nullptr;
        uint32_t location_;
        int32_t *value_;
      };
      auto cmd = Recorder()->Alloc<Runnable>();
      cmd->program_content_ = program->related_id().Get();
      cmd->location_ = location;
      cmd->value_ = value;
      Present(true);
      if (length == 1) {
        return Napi::Value::From(Env(), static_cast<bool>(value[0]));
      }
      auto ret = Napi::Array::New(Env(), length);
      for (uint32_t i = 0; i < length; ++i) {
        ret.Set(i, static_cast<bool>(value[i]));
      }
      return ret;
    }
    default:;
      //      DCHECK(false);
  }

  // If we get here, something went wrong in our unfortunately complex logic
  // above
  SynthesizeGLError(KR_GL_INVALID_VALUE, "getUniform", "unknown error");
  return Env().Null();
}

/**
 *  Reviewed by luchengxuan 06/28/2021
 */
WebGLUniformLocation *WebGLRenderingContext::GetUniformLocation(
    WebGLProgram *program, const std::string &name) {
  if (!ValidateWebGLProgramOrShader("getUniformLocation", program))
    return nullptr;
  if (!ValidateLocationLength("getUniformLocation", name)) return nullptr;
  if (!ValidateString("getUniformLocation", name)) return nullptr;
  if (IsPrefixReserved(name)) return nullptr;
  if (!program->GetShaderStatus()->is_success) {
    SynthesizeGLError(KR_GL_INVALID_OPERATION, "getUniformLocation",
                      "program not linked");
    return nullptr;
  }

  auto &uniforms = program->GetShaderStatus()->uniforms;
  GLint location = -1;
  for (int i = 0; i < uniforms.size(); ++i) {
    if (uniforms[i].name_ == name) {
      location = uniforms[i].location_;
      break;
    } else if (uniforms[i].name_.length() > name.length() &&
               uniforms[i].name_[name.length()] == '[') {
      std::string cur_name;
      cur_name.append(uniforms[i].name_, 0, name.length());
      if (cur_name == name) {
        location = uniforms[i].location_;
        break;
      }
    }
  }
  if (location == -1) {
    return nullptr;
  }
  return new WebGLUniformLocation(program, location);
}

/**
 *  Reviewed by luchengxuan 06/28/2021
 */
Value WebGLRenderingContext::GetVertexAttrib(GLuint index, GLenum pname) {
  if (index >= device_attributes_.max_vertex_attribs_) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "getVertexAttrib",
                      "index out of range");
    return Env().Null();
  }

  const auto &vertexattrib =
      local_cache_.ValidVertexArrayObject()->GetAttrPointerRef(index);
  switch (pname) {
    case GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING: {
      WebGLBuffer *buffer =
          local_cache_.ValidVertexArrayObject()->GetArrayBufferForAttrib(index);
      return buffer ? buffer->JsObject() : Env().Null();
    }
    case GL_VERTEX_ATTRIB_ARRAY_ENABLED: {
      return Value::From(Env(), vertexattrib.enable_);
    }
    case GL_VERTEX_ATTRIB_ARRAY_NORMALIZED: {
      return Value::From(Env(), vertexattrib.normalized_);
    }
    case GL_VERTEX_ATTRIB_ARRAY_SIZE: {
      return Value::From(Env(), vertexattrib.size_);
    }
    case GL_VERTEX_ATTRIB_ARRAY_STRIDE: {
      return Value::From(Env(), vertexattrib.stride_);
    }
    case GL_VERTEX_ATTRIB_ARRAY_TYPE: {
      return Value::From(Env(), vertexattrib.array_elem_type_);
    }
    case GL_CURRENT_VERTEX_ATTRIB: {
      auto values = local_cache_.vertex_attrib_values_[index];
      if (values.attr_type_ == KR_GL_UNSIGNED_INT) {
        Napi::Uint32Array ret = Napi::Uint32Array::New(Env(), 4);
        for (uint32_t i = 0; i < 4; i++) {
          ret[i] = values.value_.ui_[i];
        }
        return ret;
      } else if (values.attr_type_ == KR_GL_INT) {
        Napi::Int32Array ret = Napi::Int32Array ::New(Env(), 4);
        for (uint32_t i = 0; i < 4; i++) {
          ret[i] = values.value_.i_[i];
        }
        return ret;
      } else if (values.attr_type_ == KR_GL_FLOAT) {
        Napi::Float32Array ret = Napi::Float32Array::New(Env(), 4);
        for (uint32_t i = 0; i < 4; i++) {
          ret[i] = values.value_.f_[i];
        }
        return ret;
      } else {
        return Env().Null();
      }
    }
    case KR_GL_VERTEX_ATTRIB_ARRAY_DIVISOR:
      if (!local_cache_.vertex_attrib_divisors_.size()) {
        return Value::From(Env(), 0);
      } else {
        return Value::From(Env(), local_cache_.vertex_attrib_divisors_[index]);
      }
    case GL_VERTEX_ATTRIB_ARRAY_INTEGER:
      //      if (IsWebGL2()) {
      //        GLint value = 0;
      //        ContextGL()->GetVertexAttribiv(index, pname, &value);
      //        return WebGLAny(script_state, static_cast<bool>(value));
      //      }
      //      FALLTHROUGH;
    default:
      SynthesizeGLError(KR_GL_INVALID_ENUM, "getVertexAttrib",
                        "invalid parameter name");
      return Env().Null();
  }
}

/**
 *  Reviewed by luchengxuan 06/28/2021
 */
int64_t WebGLRenderingContext::GetVertexAttribOffset(GLuint index,
                                                     GLenum pname) {
  if (pname != GL_VERTEX_ATTRIB_ARRAY_POINTER) {
    SynthesizeGLError(KR_GL_INVALID_ENUM, "getVertexAttribOffset",
                      "invalid parameter name");
  }

  return local_cache_.ValidVertexArrayObject()
      ->GetAttrPointerRef(index)
      .offset_;
}

bool WebGLRenderingContext::ValidateUniformParameters(
    const char *function_name, const WebGLUniformLocation *location,
    const void *v, size_t size, GLsizei required_min_size, GLuint src_offset,
    size_t src_length) {
  return ValidateUniformMatrixParameters(function_name, location, false, v,
                                         size, required_min_size, src_offset,
                                         src_length);
}

bool WebGLRenderingContext::ValidateUniformMatrixParameters(
    const char *function_name, const WebGLUniformLocation *location,
    GLboolean transpose, const void *v, size_t size, GLsizei required_min_size,
    GLuint src_offset, size_t src_length) {
  DCHECK(size >= 0 && required_min_size > 0);
  if (!location) return false;
  if (location->Program() != local_cache_.current_program_) {
    SynthesizeGLError(KR_GL_INVALID_OPERATION, function_name,
                      "location is not from current program");
    return false;
  }
  if (!v) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, function_name, "no array");
    return false;
  }
  if (size > std::numeric_limits<GLsizei>::max()) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, function_name,
                      "array exceeds the maximum supported size");
    return false;
  }
  if (transpose && !IsWebGL2()) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, function_name,
                      "transpose not FALSE");
    return false;
  }
  if (src_offset >= static_cast<GLuint>(size)) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, function_name, "invalid srcOffset");
    return false;
  }
  GLsizei actual_size = static_cast<GLsizei>(size) - src_offset;
  if (src_length > 0) {
    if (src_length > static_cast<GLuint>(actual_size)) {
      SynthesizeGLError(KR_GL_INVALID_VALUE, function_name,
                        "invalid srcOffset + srcLength");
      return false;
    }
    actual_size = static_cast<GLsizei>(src_length);
  }
  if (actual_size < required_min_size || (actual_size % required_min_size)) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, function_name, "invalid size");
    return false;
  }
  return true;
}

bool WebGLRenderingContext::ValidateUniformMatrixParameters(
    const char *function_name, const WebGLUniformLocation *location,
    GLboolean transpose, const Float32Array &v, GLsizei required_min_size,
    GLuint src_offset, size_t src_length) {
  if (!v) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, function_name, "no array");
    return false;
  }
  if (src_length > std::numeric_limits<GLuint>::max()) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, function_name,
                      "src_length exceeds the maximum supported length");
    return false;
  }
  return ValidateUniformMatrixParameters(
      function_name, location, transpose, const_cast<Float32Array &>(v).Data(),
      v.ElementLength(), required_min_size, src_offset,
      static_cast<GLuint>(src_length));
}

/**
 *  Reviewed by luchengxuan 06/28/2021
 */
void WebGLRenderingContext::Uniform1F(const WebGLUniformLocation *location,
                                      GLfloat x) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!location) {
      return;
    }

    if (location->Program() != local_cache_.current_program_) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform1f",
                        "location not for current program");
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_FLOAT && uniform.type_ != GL_BOOL) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform1f",
                        "uniform type is not float or bool",
                        kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform1f(location_, value_);
    }

    int location_;
    float value_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->location_ = location->Location();
  cmd->value_ = x;
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform1Fv(const WebGLUniformLocation *location,
                                       const Float32Array &v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!ValidateUniformParameters("uniform1fv", location, v, 1, 0,
                                   v.ElementLength())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_FLOAT && uniform.type_ != GL_BOOL) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform1fv",
                        "uniform type is not float", kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const Float32Array &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.ElementLength())) {
      const auto byte_size = sizeof(GLfloat) * size_;
      data_ = static_cast<GLfloat *>(std::malloc(byte_size));
      std::memcpy(data_, const_cast<Float32Array &>(value).Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform1fv(location_, size_, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLfloat *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform1Fv(const WebGLUniformLocation *location,
                                       SharedVector<GLfloat> v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!ValidateUniformParameters("uniform1fv", location, v.Data(), v.Size(),
                                   1, 0, v.Size())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_FLOAT && uniform.type_ != GL_BOOL) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform1f",
                        "uniform type is not float", kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const SharedVector<GLfloat> &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.Size())) {
      const auto byte_size = sizeof(GLfloat) * size_;
      data_ = static_cast<GLfloat *>(std::malloc(byte_size));
      std::memcpy(data_, value.Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform1fv(location_, size_, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLfloat *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform1I(const WebGLUniformLocation *location,
                                      GLint x) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!location) return;

    if (location->Program() != local_cache_.current_program_) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform1i",
                        "location not for current program");
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_INT && uniform.type_ != GL_BOOL &&
        uniform.type_ != GL_SAMPLER_2D && uniform.type_ != GL_SAMPLER_CUBE &&
        uniform.type_ != GL_SAMPLER_2D_ARRAY) {
      if (!IsWebGL2() || (uniform.type_ != GL_SAMPLER_3D &&
                          uniform.type_ != GL_SAMPLER_2D_SHADOW &&
                          uniform.type_ != GL_SAMPLER_2D_ARRAY &&
                          uniform.type_ != GL_SAMPLER_2D_ARRAY_SHADOW &&
                          uniform.type_ != GL_SAMPLER_CUBE_SHADOW &&
                          uniform.type_ != GL_INT_SAMPLER_2D &&
                          uniform.type_ != GL_INT_SAMPLER_3D &&
                          uniform.type_ != GL_INT_SAMPLER_CUBE &&
                          uniform.type_ != GL_INT_SAMPLER_2D_ARRAY)) {
        SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform1i",
                          "uniform type is not int", kDontDisplayInConsole);
        return;
      }
    }

    if (uniform.IsSampler() &&
        x >= device_attributes_.max_combined_texture_image_units_) {
      SynthesizeGLError(KR_GL_INVALID_VALUE, "glUniform1i",
                        "texture unit out of range");
      return;
    }
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform1i(location, value);
    }

    int location;
    int value;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->location = location->Location();
  cmd->value = x;
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform1Iv(const WebGLUniformLocation *location,
                                       const Int32Array &v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!ValidateUniformParameters("uniform1iv", location, v, 1, 0,
                                   v.ElementLength())) {
      return;
    }

    if (location->Program() != local_cache_.current_program_) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform1iv",
                        "location not for current program");
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_INT && uniform.type_ != GL_BOOL &&
        uniform.type_ != GL_SAMPLER_2D && uniform.type_ != GL_SAMPLER_CUBE) {
      if (!IsWebGL2() || (uniform.type_ != GL_SAMPLER_3D &&
                          uniform.type_ != GL_SAMPLER_2D_SHADOW &&
                          uniform.type_ != GL_SAMPLER_2D_ARRAY &&
                          uniform.type_ != GL_SAMPLER_2D_ARRAY_SHADOW &&
                          uniform.type_ != GL_SAMPLER_CUBE_SHADOW &&
                          uniform.type_ != GL_INT_SAMPLER_2D &&
                          uniform.type_ != GL_INT_SAMPLER_3D &&
                          uniform.type_ != GL_INT_SAMPLER_CUBE &&
                          uniform.type_ != GL_INT_SAMPLER_2D_ARRAY)) {
        SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform1iv",
                          "uniform type is not int", kDontDisplayInConsole);
        return;
      }
    }

    if (uniform.IsSampler()) {
      size_t safe_count = std::min<size_t>(v.ElementLength(), uniform.size_);

      for (size_t i = 0; i < safe_count; i++) {
        if (const_cast<Int32Array &>(v).Data()[i] >=
            device_attributes_.max_combined_texture_image_units_) {
          SynthesizeGLError(KR_GL_INVALID_VALUE, "glUniform1i",
                            "texture unit out of range");
          return;
        }
      }
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const Int32Array &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.ElementLength())) {
      const auto byte_size = sizeof(GLint) * size_;
      data_ = static_cast<GLint *>(std::malloc(byte_size));
      std::memcpy(data_, const_cast<Int32Array &>(value).Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform1iv(location_, size_, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLint *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform1Iv(const WebGLUniformLocation *location,
                                       SharedVector<GLint> v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!ValidateUniformParameters("uniform1iv", location, v.Data(), v.Size(),
                                   1, 0, v.Size())) {
      return;
    }

    if (location->Program() != local_cache_.current_program_) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform1iv",
                        "location not for current program");
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_INT && uniform.type_ != GL_BOOL &&
        uniform.type_ != GL_SAMPLER_2D && uniform.type_ != GL_SAMPLER_CUBE) {
      if (!IsWebGL2() || (uniform.type_ != GL_SAMPLER_3D &&
                          uniform.type_ != GL_SAMPLER_2D_SHADOW &&
                          uniform.type_ != GL_SAMPLER_2D_ARRAY &&
                          uniform.type_ != GL_SAMPLER_2D_ARRAY_SHADOW &&
                          uniform.type_ != GL_SAMPLER_CUBE_SHADOW &&
                          uniform.type_ != GL_INT_SAMPLER_2D &&
                          uniform.type_ != GL_INT_SAMPLER_3D &&
                          uniform.type_ != GL_INT_SAMPLER_CUBE &&
                          uniform.type_ != GL_INT_SAMPLER_2D_ARRAY)) {
        SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform1iv",
                          "uniform type is not int", kDontDisplayInConsole);
        return;
      }
    }

    if (uniform.IsSampler()) {
      size_t safe_count = std::min<size_t>(v.Size(), uniform.size_);

      for (size_t i = 0; i < safe_count; i++) {
        if (v[i] >= device_attributes_.max_combined_texture_image_units_) {
          SynthesizeGLError(KR_GL_INVALID_VALUE, "glUniform1i",
                            "texture unit out of range");
          return;
        }
      }
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const SharedVector<GLint> &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.Size())) {
      const auto byte_size = sizeof(GLint) * size_;
      data_ = static_cast<GLint *>(std::malloc(byte_size));
      std::memcpy(data_, value.Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform1iv(location_, size_, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLint *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform2F(const WebGLUniformLocation *location,
                                      GLfloat x, GLfloat y) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!location) {
      return;
    }

    if (location->Program() != local_cache_.current_program_) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform2f",
                        "location not for current program");
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_FLOAT_VEC2 && uniform.type_ != GL_BOOL_VEC2) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform2f",
                        "uniform type is not float or bool",
                        kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform2f(location, v0, v1);
    }

    int location;
    float v0, v1;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->location = location->Location();
  cmd->v0 = x;
  cmd->v1 = y;
}

/**
 *  Reviewed by luchengxuan 06/289/2021
 */
void WebGLRenderingContext::Uniform2Fv(const WebGLUniformLocation *location,
                                       const Float32Array &v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!ValidateUniformParameters("uniform2fv", location, v, 2, 0,
                                   v.ElementLength())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_FLOAT_VEC2 && uniform.type_ != GL_BOOL_VEC2) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform2fv",
                        "uniform type is not float", kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const Float32Array &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.ElementLength())) {
      const auto byte_size = sizeof(GLfloat) * size_;
      data_ = static_cast<GLfloat *>(std::malloc(byte_size));
      std::memcpy(data_, const_cast<Float32Array &>(value).Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform2fv(location_, size_ >> 1u, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLfloat *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform2Fv(const WebGLUniformLocation *location,
                                       SharedVector<GLfloat> v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!ValidateUniformParameters("uniform2fv", location, v.Data(), v.Size(),
                                   2, 0, v.Size())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_FLOAT_VEC2 && uniform.type_ != GL_BOOL_VEC2) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform2f",
                        "uniform type is not float", kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const SharedVector<GLfloat> &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.Size())) {
      const auto byte_size = sizeof(GLfloat) * size_;
      data_ = static_cast<GLfloat *>(std::malloc(byte_size));
      std::memcpy(data_, value.Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform2fv(location_, size_ >> 1u, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLfloat *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform2I(const WebGLUniformLocation *location,
                                      GLint x, GLint y) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!location) return;

    if (location->Program() != local_cache_.current_program_) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform2i",
                        "location not for current program");
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_INT_VEC2 && uniform.type_ != GL_BOOL_VEC2) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform2i",
                        "uniform type is not int", kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform2i(location, v0, v1);
    }

    int location;
    int v0, v1;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->location = location->Location();
  cmd->v0 = x;
  cmd->v1 = y;
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform2Iv(const WebGLUniformLocation *location,
                                       const Int32Array &v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!ValidateUniformParameters("uniform2iv", location, v, 2, 0,
                                   v.ElementLength())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_INT_VEC2 && uniform.type_ != GL_BOOL_VEC2) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform2iv",
                        "uniform type is not int", kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const Int32Array &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.ElementLength())) {
      const auto byte_size = sizeof(GLint) * size_;
      data_ = static_cast<GLint *>(std::malloc(byte_size));
      std::memcpy(data_, const_cast<Int32Array &>(value).Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform2iv(location_, size_ >> 1u, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLint *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform2Iv(const WebGLUniformLocation *location,
                                       SharedVector<GLint> v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!ValidateUniformParameters("uniform2iv", location, v.Data(), v.Size(),
                                   2, 0, v.Size())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_INT_VEC2 && uniform.type_ != GL_BOOL_VEC2) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform2iv",
                        "uniform type is not int", kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const SharedVector<GLint> &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.Size())) {
      const auto byte_size = sizeof(GLint) * size_;
      data_ = static_cast<GLint *>(std::malloc(byte_size));
      std::memcpy(data_, value.Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform2iv(location_, size_ >> 1u, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLint *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform3F(const WebGLUniformLocation *location,
                                      GLfloat x, GLfloat y, GLfloat z) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!location) {
      return;
    }

    if (location->Program() != local_cache_.current_program_) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform3f",
                        "location not for current program");
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_FLOAT_VEC3 && uniform.type_ != GL_BOOL_VEC3) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform3f",
                        "uniform type is not float or bool",
                        kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform3f(location, v0, v1, v2);
    }

    int location;
    float v0, v1, v2;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->location = location->Location();
  cmd->v0 = x;
  cmd->v1 = y;
  cmd->v2 = z;
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform3Fv(const WebGLUniformLocation *location,
                                       const Float32Array &v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!ValidateUniformParameters("uniform3fv", location, v, 3, 0,
                                   v.ElementLength())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_FLOAT_VEC3 && uniform.type_ != GL_BOOL_VEC3) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform3fv",
                        "uniform type is not float", kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const Float32Array &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.ElementLength())) {
      const auto byte_size = sizeof(GLfloat) * size_;
      data_ = static_cast<GLfloat *>(std::malloc(byte_size));
      std::memcpy(data_, const_cast<Float32Array &>(value).Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform3fv(location_, size_ / 3, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLfloat *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform3Fv(const WebGLUniformLocation *location,
                                       SharedVector<GLfloat> v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!ValidateUniformParameters("uniform3fv", location, v.Data(), v.Size(),
                                   3, 0, v.Size())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_FLOAT_VEC3 && uniform.type_ != GL_BOOL_VEC3) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform3f",
                        "uniform type is not float", kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const SharedVector<GLfloat> &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.Size())) {
      const auto byte_size = sizeof(GLfloat) * size_;
      data_ = static_cast<GLfloat *>(std::malloc(byte_size));
      std::memcpy(data_, value.Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform3fv(location_, size_ / 3, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLfloat *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform3I(const WebGLUniformLocation *location,
                                      GLint x, GLint y, GLint z) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!location) return;

    if (location->Program() != local_cache_.current_program_) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform3i",
                        "location not for current program");
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_INT_VEC3 && uniform.type_ != GL_BOOL_VEC3) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform3i",
                        "uniform type is not int", kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform3i(location, v0, v1, v2);
    }

    int location;
    int v0, v1, v2;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->location = location->Location();
  cmd->v0 = x;
  cmd->v1 = y;
  cmd->v2 = z;
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform3Iv(const WebGLUniformLocation *location,
                                       const Int32Array &v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!ValidateUniformParameters("uniform3iv", location, v, 3, 0,
                                   v.ElementLength())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_INT_VEC3 && uniform.type_ != GL_BOOL_VEC3) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform3iv",
                        "uniform type is not int", kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const Int32Array &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.ElementLength())) {
      const auto byte_size = sizeof(GLint) * size_;
      data_ = static_cast<GLint *>(std::malloc(byte_size));
      std::memcpy(data_, const_cast<Int32Array &>(value).Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform3iv(location_, size_ / 3, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLint *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform3Iv(const WebGLUniformLocation *location,
                                       SharedVector<GLint> v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!ValidateUniformParameters("uniform3iv", location, v.Data(), v.Size(),
                                   3, 0, v.Size())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_INT_VEC2 && uniform.type_ != GL_BOOL_VEC2) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform3iv",
                        "uniform type is not int", kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const SharedVector<GLint> &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.Size())) {
      const auto byte_size = sizeof(GLint) * size_;
      data_ = static_cast<GLint *>(std::malloc(byte_size));
      std::memcpy(data_, value.Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform3iv(location_, size_ / 3, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLint *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform4F(const WebGLUniformLocation *location,
                                      GLfloat x, GLfloat y, GLfloat z,
                                      GLfloat w) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!location) {
      return;
    }

    if (location->Program() != local_cache_.current_program_) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform4f",
                        "location not for current program");
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_FLOAT_VEC4 && uniform.type_ != GL_BOOL_VEC4) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform4f",
                        "uniform type is not float or bool",
                        kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform4f(location, v0, v1, v2, v3);
    }

    int location;
    float v0, v1, v2, v3;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->location = location->Location();
  cmd->v0 = x;
  cmd->v1 = y;
  cmd->v2 = z;
  cmd->v3 = w;
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform4Fv(const WebGLUniformLocation *location,
                                       const Float32Array &v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    constexpr size_t len = 4;
    if (!ValidateUniformParameters("uniform4fv", location, v, len, 0,
                                   v.ElementLength())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_FLOAT_VEC4 && uniform.type_ != GL_BOOL_VEC4) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform4fv",
                        "uniform type is not float", kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const Float32Array &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.ElementLength())) {
      const auto byte_size = sizeof(GLfloat) * size_;
      data_ = static_cast<GLfloat *>(std::malloc(byte_size));
      std::memcpy(data_, const_cast<Float32Array &>(value).Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform4fv(location_, size_ >> 2u, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLfloat *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform4Fv(const WebGLUniformLocation *location,
                                       SharedVector<GLfloat> v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    constexpr int len = 4;
    if (!ValidateUniformParameters("uniform4fv", location, v.Data(), v.Size(),
                                   len, 0, v.Size())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_FLOAT_VEC4 && uniform.type_ != GL_BOOL_VEC4) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform4f",
                        "uniform type is not float", kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const SharedVector<GLfloat> &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.Size())) {
      const auto byte_size = sizeof(GLfloat) * size_;
      data_ = static_cast<GLfloat *>(std::malloc(byte_size));
      std::memcpy(data_, value.Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform4fv(location_, size_ >> 2u, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLfloat *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform4I(const WebGLUniformLocation *location,
                                      GLint x, GLint y, GLint z, GLint w) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!location) return;

    if (location->Program() != local_cache_.current_program_) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform4i",
                        "location not for current program");
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_INT_VEC4 && uniform.type_ != GL_BOOL_VEC4) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform4i",
                        "uniform type is not int", kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform4i(location, v0, v1, v2, v3);
    }

    int location;
    int v0, v1, v2, v3;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->location = location->Location();
  cmd->v0 = x;
  cmd->v1 = y;
  cmd->v2 = z;
  cmd->v3 = w;
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform4Iv(const WebGLUniformLocation *location,
                                       const Int32Array &v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!ValidateUniformParameters("uniform4iv", location, v, 4, 0,
                                   v.ElementLength())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_INT_VEC4 && uniform.type_ != GL_BOOL_VEC4) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform4iv",
                        "uniform type is not int4vec", kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const Int32Array &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.ElementLength())) {
      const auto byte_size = sizeof(GLint) * size_;
      data_ = static_cast<GLint *>(std::malloc(byte_size));
      std::memcpy(data_, const_cast<Int32Array &>(value).Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform4iv(location_, size_ >> 2u, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLint *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::Uniform4Iv(const WebGLUniformLocation *location,
                                       SharedVector<GLint> v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (!ValidateUniformParameters("uniform2iv", location, v.Data(), v.Size(),
                                   4, 0, v.Size())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != GL_INT_VEC4 && uniform.type_ != GL_BOOL_VEC4) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniform4iv",
                        "uniform type is not int4vec", kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const SharedVector<GLint> &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.Size())) {
      const auto byte_size = sizeof(GLint) * size_;
      data_ = static_cast<GLint *>(std::malloc(byte_size));
      std::memcpy(data_, value.Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Uniform4iv(location_, size_ >> 2u, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLint *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::UniformMatrix2Fv(
    const WebGLUniformLocation *location, GLboolean transpose,
    const Float32Array &v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    constexpr int len = 4;

    if (!ValidateUniformMatrixParameters("uniformMatrix2fv", location,
                                         transpose, v, len, 0,
                                         v.ElementLength())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != KR_GL_FLOAT_MAT2) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniformMatrix2fv",
                        "uniform type is not float mat2",
                        kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const Float32Array &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.ElementLength())) {
      const auto byte_size = sizeof(GLfloat) * size_;
      data_ = static_cast<GLfloat *>(std::malloc(byte_size));
      std::memcpy(data_, const_cast<Float32Array &>(value).Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::UniformMatrix2fv(location_, size_ >> 2u, false, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLfloat *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::UniformMatrix2Fv(
    const WebGLUniformLocation *location, GLboolean transpose,
    SharedVector<GLfloat> v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    constexpr int len = 4;

    if (!ValidateUniformMatrixParameters("uniformMatrix2fv", location,
                                         transpose, v.Data(), v.Size(), len, 0,
                                         v.Size())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != KR_GL_FLOAT_MAT2) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniformMatrix2fv",
                        "uniform type is not float mat2",
                        kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const SharedVector<GLfloat> &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.Size())) {
      const auto byte_size = sizeof(GLfloat) * size_;
      data_ = static_cast<GLfloat *>(std::malloc(byte_size));
      std::memcpy(data_, value.Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::UniformMatrix2fv(location_, size_ >> 2u, false, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLfloat *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::UniformMatrix3Fv(
    const WebGLUniformLocation *location, GLboolean transpose,
    const Float32Array &v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    constexpr int len = 9;

    if (!ValidateUniformMatrixParameters("uniformMatrix3fv", location,
                                         transpose, v, len, 0,
                                         v.ElementLength())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != KR_GL_FLOAT_MAT3) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniformMatrix3fv",
                        "uniform type is not float mat3",
                        kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const Float32Array &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.ElementLength())) {
      const auto byte_size = sizeof(GLfloat) * size_;
      data_ = static_cast<GLfloat *>(std::malloc(byte_size));
      std::memcpy(data_, const_cast<Float32Array &>(value).Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::UniformMatrix3fv(location_, size_ / 9, false, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLfloat *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::UniformMatrix3Fv(
    const WebGLUniformLocation *location, GLboolean transpose,
    SharedVector<GLfloat> v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    constexpr int len = 9;

    if (!ValidateUniformMatrixParameters("uniformMatrix3fv", location,
                                         transpose, v.Data(), v.Size(), len, 0,
                                         v.Size())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != KR_GL_FLOAT_MAT3) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniformMatrix3fv",
                        "uniform type is not float mat3",
                        kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const SharedVector<GLfloat> &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.Size())) {
      const auto byte_size = sizeof(GLfloat) * size_;
      data_ = static_cast<GLfloat *>(std::malloc(byte_size));
      std::memcpy(data_, value.Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::UniformMatrix3fv(location_, size_ / 9, false, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLfloat *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::UniformMatrix4Fv(
    const WebGLUniformLocation *location, GLboolean transpose,
    const Float32Array &v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    constexpr int len = 16;
    if (!ValidateUniformMatrixParameters("uniformMatrix4fv", location,
                                         transpose, v, len, 0,
                                         v.ElementLength())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != KR_GL_FLOAT_MAT4) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniformMatrix4fv",
                        "uniform type is not float mat4",
                        kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const Float32Array &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.ElementLength())) {
      const auto byte_size = sizeof(GLfloat) * size_;
      data_ = static_cast<GLfloat *>(std::malloc(byte_size));
      std::memcpy(data_, const_cast<Float32Array &>(value).Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::UniformMatrix4fv(location_, size_ >> 4u, false, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLfloat *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::UniformMatrix4Fv(
    const WebGLUniformLocation *location, GLboolean transpose,
    SharedVector<GLfloat> v) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    constexpr int len = 16;
    if (!ValidateUniformMatrixParameters("uniformMatrix4fv", location,
                                         transpose, v.Data(), v.Size(), len, 0,
                                         v.Size())) {
      return;
    }

    // no match: size | type
    auto &uniform =
        location->Program()->GetShaderStatus()->GetUniformByLocation(
            location->Location());
    if (uniform.type_ != KR_GL_FLOAT_MAT4) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "uniformMatrix4fv",
                        "uniform type is not float mat4",
                        kDontDisplayInConsole);
      return;
    }
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLint location, const SharedVector<GLfloat> &value)
        : location_(location),
          data_(nullptr),
          size_(static_cast<uint32_t>(value.Size())) {
      const auto byte_size = sizeof(GLfloat) * size_;
      data_ = static_cast<GLfloat *>(std::malloc(byte_size));
      std::memcpy(data_, value.Data(), byte_size);
    }

    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::UniformMatrix4fv(location_, size_ >> 4u, false, data_);
      std::free(data_);
    }
    GLint location_;
    // due to DataHolder has approx 15% performance loss with raw ptr,
    // we use raw ptr for best performance
    GLfloat *data_;
    uint32_t size_;
  };
  Recorder()->Alloc<Runnable>(location->Location(), v);
}

#define VERTEX_ATTRIB_N_FV(N)                                               \
  void WebGLRenderingContext::VertexAttrib##N##Fv(                          \
      GLuint index, const Napi::Float32Array &values) {                     \
    if (index >= MaxVertexAttribs()) {                                      \
      SynthesizeGLError(KR_GL_INVALID_VALUE, "vertexAttrib" #N "v",         \
                        "index is larger than GL_MAX_VERTEX_ATTRIBS");      \
      return;                                                               \
    }                                                                       \
                                                                            \
    auto local_value = local_cache_.vertex_attrib_values_[index].value_.f_; \
    const int len = N;                                                      \
    if (values.ElementLength() < len) {                                     \
      SynthesizeGLError(KR_GL_INVALID_VALUE, "vertexAttrib" #N "v",         \
                        "invalid array");                                   \
      return;                                                               \
    }                                                                       \
    local_value[0] = 0;                                                     \
    local_value[1] = 0;                                                     \
    local_value[2] = 0;                                                     \
    local_value[3] = 1;                                                     \
    memcpy(local_value, const_cast<Napi::Float32Array &>(values).Data(),    \
           sizeof(float) * len);                                            \
    local_cache_.vertex_attrib_values_[index].attr_type_ = KR_GL_FLOAT;     \
                                                                            \
    struct Runnable {                                                       \
      void Run(command_buffer::RunnableBuffer *buffer) const {              \
        GL::VertexAttrib##N##fv(index_, value_);                            \
      }                                                                     \
      uint32_t index_;                                                      \
      float value_[len];                                                    \
    };                                                                      \
    auto cmd = Recorder()->Alloc<Runnable>();                               \
    cmd->index_ = index;                                                    \
    memcpy(cmd->value_, local_value, sizeof(float) * len);                  \
  }                                                                         \
                                                                            \
  void WebGLRenderingContext::VertexAttrib##N##Fv(                          \
      GLuint index, SharedVector<GLfloat> values) {                         \
    if (index >= MaxVertexAttribs()) {                                      \
      SynthesizeGLError(KR_GL_INVALID_VALUE, "vertexAttrib" #N "v",         \
                        "index is larger than GL_MAX_VERTEX_ATTRIBS");      \
      return;                                                               \
    }                                                                       \
                                                                            \
    auto local_value = local_cache_.vertex_attrib_values_[index].value_.f_; \
    const int len = N;                                                      \
    if (values.Size() < len) {                                              \
      SynthesizeGLError(KR_GL_INVALID_VALUE, "vertexAttrib" #N "v",         \
                        "invalid array");                                   \
      return;                                                               \
    }                                                                       \
    local_value[0] = 0;                                                     \
    local_value[1] = 0;                                                     \
    local_value[2] = 0;                                                     \
    local_value[3] = 1;                                                     \
    memcpy(local_value, values.Data(), sizeof(float) * len);                \
    local_cache_.vertex_attrib_values_[index].attr_type_ = KR_GL_FLOAT;     \
                                                                            \
    struct Runnable {                                                       \
      void Run(command_buffer::RunnableBuffer *buffer) const {              \
        GL::VertexAttrib##N##fv(index_, value_);                            \
      }                                                                     \
      uint32_t index_;                                                      \
      float value_[len];                                                    \
    };                                                                      \
    auto cmd = Recorder()->Alloc<Runnable>();                               \
    cmd->index_ = index;                                                    \
    memcpy(cmd->value_, local_value, sizeof(float) * len);                  \
  }

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
VERTEX_ATTRIB_N_FV(1)
VERTEX_ATTRIB_N_FV(2)
VERTEX_ATTRIB_N_FV(3)
VERTEX_ATTRIB_N_FV(4)

#undef VERTEX_ATTRIB_N_FV

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::VertexAttrib1F(GLuint index, GLfloat x) {
  if (index >= MaxVertexAttribs()) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "vertexAttrib1f",
                      "index is larger than GL_MAX_VERTEX_ATTRIBS");
    return;
  }

  auto local_value = local_cache_.vertex_attrib_values_[index].value_.f_;
  local_value[0] = x;
  local_value[1] = 0;
  local_value[2] = 0;
  local_value[3] = 1;
  local_cache_.vertex_attrib_values_[index].attr_type_ = GL_FLOAT;

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::VertexAttrib1f(index_, v0_);
    }

    uint32_t index_;
    float v0_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->index_ = index;
  cmd->v0_ = x;
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::VertexAttrib2F(GLuint index, GLfloat x, GLfloat y) {
  if (index >= MaxVertexAttribs()) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "vertexAttrib2f",
                      "index is larger than GL_MAX_VERTEX_ATTRIBS");
    return;
  }

  auto local_value = local_cache_.vertex_attrib_values_[index].value_.f_;
  const int len = 2;
  local_value[0] = x;
  local_value[1] = y;
  local_value[2] = 0;
  local_value[3] = 1;
  local_cache_.vertex_attrib_values_[index].attr_type_ = GL_FLOAT;

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) {
      GL::VertexAttrib2f(index_, value_[0], value_[1]);
    }
    uint32_t index_;
    float value_[len];
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->index_ = index;
  memcpy(cmd->value_, local_value, sizeof(float) * len);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::VertexAttrib3F(GLuint index, GLfloat x, GLfloat y,
                                           GLfloat z) {
  if (index >= MaxVertexAttribs()) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "vertexAttrib3f",
                      "index is larger than GL_MAX_VERTEX_ATTRIBS");
    return;
  }

  auto local_value = local_cache_.vertex_attrib_values_[index].value_.f_;
  const int len = 3;
  local_value[0] = x;
  local_value[1] = y;
  local_value[2] = z;
  local_value[3] = 1;
  local_cache_.vertex_attrib_values_[index].attr_type_ = GL_FLOAT;

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) {
      GL::VertexAttrib3f(index_, value_[0], value_[1], value_[2]);
    }
    uint32_t index_;
    float value_[len];
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->index_ = index;
  memcpy(cmd->value_, local_value, sizeof(float) * len);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::VertexAttrib4F(GLuint index, GLfloat x, GLfloat y,
                                           GLfloat z, GLfloat w) {
  if (index >= MaxVertexAttribs()) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "vertexAttrib4f",
                      "index is larger than GL_MAX_VERTEX_ATTRIBS");
    return;
  }

  auto local_value = local_cache_.vertex_attrib_values_[index].value_.f_;
  const int len = 4;
  local_value[0] = x;
  local_value[1] = y;
  local_value[2] = z;
  local_value[3] = w;
  local_cache_.vertex_attrib_values_[index].attr_type_ = GL_FLOAT;

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) {
      GL::VertexAttrib4f(index_, value_[0], value_[1], value_[2], value_[3]);
    }
    uint32_t index_;
    float value_[len];
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->index_ = index;
  memcpy(cmd->value_, local_value, sizeof(float) * len);
}

/**
 *  Reviewed by luchengxuan 06/29/2021
 */
void WebGLRenderingContext::VertexAttribPointer(GLuint indx, GLint size,
                                                GLenum type,
                                                GLboolean normalized,
                                                GLsizei stride,
                                                int64_t offset) {
  DCHECK(Recorder());

  KRYPTON_ERROR_CHECK_IF_NEED {
    // logic check
    if (indx >= MaxVertexAttribs()) {
      SynthesizeGLError(KR_GL_INVALID_VALUE, "VertexAttribPointer",
                        "index is larger than GL_MAX_VERTEX_ATTRIBS");
      return;
    }

    if (!ValidateValueFitNonNegInt32("vertexAttribPointer", "offset", offset))
      return;

    if (!local_cache_.array_buffer_bind_ && offset != 0) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "vertexAttribPointer",
                        "no ARRAY_BUFFER is bound and offset is non-zero");
      return;
    }

    if (size > 4 || size < 1) {
      SynthesizeGLError(KR_GL_INVALID_VALUE, "vertexAttribPointer",
                        "invalid size");
      return;
    }

    if (type != KR_GL_BYTE && type != KR_GL_SHORT &&
        type != KR_GL_UNSIGNED_BYTE && type != KR_GL_UNSIGNED_SHORT &&
        type != KR_GL_FLOAT && type != KR_GL_HALF_FLOAT) {
      SynthesizeGLError(KR_GL_INVALID_ENUM, "vertexAttribPointer",
                        "type is invalid");
      return;
    }
    if (stride > 255) {
      SynthesizeGLError(KR_GL_INVALID_VALUE, "vertexAttribPointer",
                        "stride is too large");
      return;
    }

    if ((type == KR_GL_SHORT || type == KR_GL_UNSIGNED_SHORT ||
         type == KR_GL_HALF_FLOAT) &&
        (stride % 2 != 0 || offset % 2 != 0)) {  // 16 bits, mutiple of 2
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "vertexAttribPointer",
                        "stride or offset is not multiple of type");
      return;
    }

    if (type == KR_GL_FLOAT &&
        (stride % 4 != 0 || offset % 4 != 0)) {  // 32 bits, mutiple of 4
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "vertexAttribPointer",
                        "stride or offset is not multiple of type");
      return;
    }
  }

  // save cache
  auto &item = local_cache_.ValidVertexArrayObject()->GetAttrPointerRef(indx);
  item.size_ = size;
  item.array_elem_type_ = type;
  item.normalized_ = normalized;
  item.stride_ = stride;
  item.offset_ = offset;
  item.array_buffer_ = local_cache_.array_buffer_bind_;  // related VBO object

  local_cache_.ValidVertexArrayObject()->SetArrayBufferForAttrib(
      indx, local_cache_.array_buffer_bind_);

  /** Future WebGL2.0 TODO Two More conditions to check*/

  // commit command
  class Runnable {
   public:
    Runnable(GLuint index, GLint size, GLenum type, GLboolean normalized,
             GLsizei stride, intptr_t offset)
        : index_(index),
          size_(size),
          type_(type),
          stride_(stride),
          normalized_(normalized),
          offset_((void *)offset) {}

    void Run(command_buffer::RunnableBuffer *buffer) {
      GL::VertexAttribPointer(index_, size_, type_, normalized_, stride_,
                              offset_);
    }

   private:
    GLuint index_;
    GLint size_;
    GLenum type_;
    GLsizei stride_;
    GLboolean normalized_;
    void *offset_;
  };

  Recorder()->Alloc<Runnable>(indx, size, type, normalized, stride,
                              static_cast<intptr_t>(offset));
}
}  // namespace canvas
}  // namespace lynx
