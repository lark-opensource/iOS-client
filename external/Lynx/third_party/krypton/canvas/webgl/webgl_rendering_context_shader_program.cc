// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/gpu/gl/gl_api.h"
#include "canvas/webgl/webgl_rendering_context.h"

namespace lynx {
namespace canvas {

bool WebGLRenderingContext::ValidateWebGLProgramOrShader(
    const char *function_name, WebGLObjectNG *object) {
  DCHECK(object);
  // OpenGL ES 3.0.5 p. 45:
  // "Commands that accept shader or program object names will generate the
  // error INVALID_VALUE if the provided name is not the name of either a shader
  // or program object and INVALID_OPERATION if the provided name identifies an
  // object that is not the expected type."
  //
  // Programs and shaders also have slightly different lifetime rules than other
  // objects in the API; they continue to be usable after being marked for
  // deletion.
  if (!object->HasObject()) {
    SynthesizeGLError(GL_INVALID_VALUE, function_name,
                      "attempt to use a deleted object");
    return false;
  }
  if (!object->Validate(this)) {
    SynthesizeGLError(GL_INVALID_OPERATION, function_name,
                      "object does not belong to this context");
    return false;
  }
  return true;
}

/**
 * Reviewed by luchengxuan 06/23/2021
 */
void WebGLRenderingContext::AttachShader(WebGLProgram *program,
                                         WebGLShader *shader) {
  DCHECK(Recorder());

  if (!ValidateWebGLProgramOrShader("attachShader", program) ||
      !ValidateWebGLProgramOrShader("attachShader", shader))
    return;

  if (!program->AttachShader(shader)) {
    SynthesizeGLError(KR_GL_INVALID_OPERATION, "attachShader",
                      "shader attachment already has shader");
  }

  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      DCHECK(program_content_ && shader_content_);
      auto program = program_content_->Get();
      auto shader = shader_content_->Get();
      GL::AttachShader(program, shader);
    }
    PuppetContent<uint32_t> *program_content_ = nullptr;
    PuppetContent<uint32_t> *shader_content_ = nullptr;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->program_content_ = program->related_id().Get();
  cmd->shader_content_ = shader->related_id().Get();

  shader->OnAttached();
}

// Return true if a character belongs to the ASCII subset as defined in
// GLSL ES 1.0 spec section 3.1.
static bool CharacterIsValidForGLES(unsigned char c) {
  // Printing characters are valid except " $ ` @ \ ' DEL.
  if (c >= 32 && c <= 126 && c != '"' && c != '$' && c != '`' && c != '@' &&
      c != '\\' && c != '\'') {
    return true;
  }
  // Horizontal tab, line feed, vertical tab, form feed, carriage return
  // are also valid.
  if (c >= 9 && c <= 13) {
    return true;
  }

  return false;
}

static bool StringIsValidForGLES(const std::string &str) {
  return str.length() == 0 ||
         std::find_if_not(str.begin(), str.end(), CharacterIsValidForGLES) ==
             str.end();
}

/**
 * Reviewed by luchengxuan 06/23/2021
 */
void WebGLRenderingContext::BindAttribLocation(WebGLProgram *program,
                                               GLuint index,
                                               const std::string &name) {
  if (!ValidateWebGLProgramOrShader("bindAttribLocation", program)) return;
  if (!ValidateLocationLength("bindAttribLocation", name)) return;
  if (IsPrefixReserved(name)) {
    SynthesizeGLError(GL_INVALID_OPERATION, "bindAttribLocation",
                      "reserved prefix");
    return;
  }
  if (!StringIsValidForGLES(name)) {
    SynthesizeGLError(GL_INVALID_VALUE, "bindAttribLocation",
                      "Invalid character");
    return;
  }

  if (index > device_attributes_.max_vertex_attribs_) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "bindAttribLocation", "",
                      kDontDisplayInConsole);
    return;
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      auto program = content_->Get();
      GL::BindAttribLocation(program, index_, (char *)name_.c_str());
    }

    PuppetContent<GLuint> *content_ = nullptr;
    GLuint index_;
    std::string name_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->content_ = program->related_id().Get();
  cmd->index_ = index;
  cmd->name_ = std::move(name);
}

/**
 * Reviewed by luchengxuan 06/23/2021
 */
void WebGLRenderingContext::CompileShader(WebGLShader *shader) {
  DCHECK(Recorder());

  if (!ValidateWebGLProgramOrShader("compileShader", shader)) return;

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      auto shader = content_->Get();
      GL::CompileShader(shader);

      if (is_success_ && result_str_) {
        *is_success_ = KR_GL_FALSE;
        GL::GetShaderiv(shader, KR_GL_COMPILE_STATUS, is_success_);

        if (KR_GL_FALSE == *is_success_) {
          int32_t info_str_len = 0;
          GL::GetShaderiv(shader, KR_GL_INFO_LOG_LENGTH, &info_str_len);

          if (info_str_len > 0) {
            result_str_->resize(info_str_len + 1);
            GL::GetShaderInfoLog(shader, info_str_len, nullptr,
                                 (char *)result_str_->c_str());
          }
        }
      }
    }
    PuppetContent<uint32_t> *content_ = nullptr;
    int32_t *is_success_ = nullptr;
    std::string *result_str_ = nullptr;
  };

  int32_t is_success = 0;
  std::string result_str;
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->content_ = shader->related_id().Get();
  cmd->is_success_ = &is_success;
  cmd->result_str_ = &result_str;
  Present(true);

  // save status
  if (KR_GL_TRUE == is_success) {
    shader->SetState(EShaderState::COMPILE_SUCC);
    shader->SetInfoLog("");
  } else {
    shader->SetState(EShaderState::COMPILE_FAIL);
    shader->SetInfoLog(result_str);
  }
}

WebGLProgram *WebGLRenderingContext::CreateProgram() {
  DCHECK(Recorder());

  // create obj
  return new WebGLProgram(this);
}

bool WebGLRenderingContext::ValidateShaderType(const char *function_name,
                                               GLenum shader_type) {
  switch (shader_type) {
    case GL_VERTEX_SHADER:
    case GL_FRAGMENT_SHADER:
      return true;
    default:
      SynthesizeGLError(GL_INVALID_ENUM, function_name, "invalid shader type");
      return false;
  }
}

/**
 * Reviewed by luchengxuan 06/23/2021
 */
WebGLShader *WebGLRenderingContext::CreateShader(GLenum type) {
  DCHECK(Recorder());

  if (!ValidateShaderType("createShader", type)) {
    return nullptr;
  }

  return new WebGLShader(this, type);
}

/**
 * Reviewed by luchengxuan 06/23/2021
 */
void WebGLRenderingContext::DeleteProgram(WebGLProgram *program) {
  DCHECK(Recorder());

  DeleteObject(program);
}

/**
 * Reviewed by luchengxuan 06/23/2021
 */
void WebGLRenderingContext::DeleteShader(WebGLShader *shader) {
  DCHECK(Recorder());

  DeleteObject(shader);
}

/**
 * Reviewed by luchengxuan 06/23/2021
 */
void WebGLRenderingContext::DetachShader(WebGLProgram *program,
                                         WebGLShader *shader) {
  DCHECK(Recorder());

  if (!ValidateWebGLProgramOrShader("detachShader", program) ||
      !ValidateWebGLProgramOrShader("detachShader", shader))
    return;
  if (!program->DetachShader(shader)) {
    SynthesizeGLError(GL_INVALID_OPERATION, "detachShader",
                      "shader not attached");
    return;
  }
  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      auto program = program_content_->Get();
      auto shader = shader_content_->Get();
      GL::DetachShader(program, shader);
    }

    PuppetContent<uint32_t> *program_content_;
    PuppetContent<uint32_t> *shader_content_;
  };

  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->program_content_ = program->related_id().Get();
  cmd->shader_content_ = shader->related_id().Get();

  shader->OnDetached(Recorder());
}

/**
 * Reviewed by luchengxuan 06/23/2021
 */
std::vector<WebGLShader *> WebGLRenderingContext::GetAttachedShaders(
    WebGLProgram *program) const {
  DCHECK(Recorder());

  std::vector<WebGLShader *> result;
  for (GLenum shaderType : {GL_VERTEX_SHADER, GL_FRAGMENT_SHADER}) {
    WebGLShader *shader = program->GetAttachedShader(shaderType);
    if (shader) result.push_back(shader);
  }

  return result;
}

/**
 * Reviewed by luchengxuan 06/23/2021
 */
Value WebGLRenderingContext::GetProgramParameter(WebGLProgram *program,
                                                 GLenum pname) {
  DCHECK(Recorder());

  if (!ValidateWebGLProgramOrShader("getProgramParamter", program)) {
    return Env().Null();
  }

  Napi::Value result;
  auto status = program->GetShaderStatus();
  switch (pname) {
    case KR_GL_DELETE_STATUS:
      result = Napi::Value::From(Env(), program->MarkedForDeletion());
      break;
    case KR_GL_LINK_STATUS:
      result = Napi::Value::From(Env(), status->is_success);
      break;
    case KR_GL_VALIDATE_STATUS:
      // TODO : TEST THIS CASE
      result = Napi::Value::From(Env(), status->is_success);
      break;
    case KR_GL_ATTACHED_SHADERS: {
      int shader_count = 0;
      if (program->GetAttachedShader(GL_VERTEX_SHADER)) {
        shader_count++;
      }
      if (program->GetAttachedShader(GL_FRAGMENT_SHADER)) {
        shader_count++;
      }
      result = Napi::Value::From(Env(), shader_count);
      break;
    }
    case KR_GL_ACTIVE_ATTRIBUTES:
      result = Napi::Value::From(Env(), (int32_t)status->num_active_attribs);
      break;
    case KR_GL_ACTIVE_UNIFORMS:
      result = Napi::Value::From(Env(), (int32_t)status->num_active_uniforms);
      break;
      //    case KR_GL_TRANSFORM_FEEDBACK_BUFFER_MODE: {
      //      GLint value = 0;
      //      struct Runnable {
      //        void Run(command_buffer::RunnableBuffer *) {
      //          GL::GetProgramiv(
      //              content_->get(), GL_TRANSFORM_FEEDBACK_BUFFER_MODE,
      //              value_);
      //        }
      //        puppet_content<uint32_t> *content_;
      //        GLint *value_;
      //      };
      //      auto cmd = Recorder()->Alloc<Runnable>();
      //      cmd->content_ = program->related_id().get();
      //      cmd->value_ = &value;
      //      Present(true);
      //      result = Napi::Value::From(Env(), (int32_t)value);
      //    } break;
      //    case KR_GL_TRANSFORM_FEEDBACK_VARYINGS: {
      //      GLint value = 0;
      //      struct Runnable {
      //        void Run(command_buffer::RunnableBuffer *) {
      //          GL::GetProgramiv(content_->get(),
      //          GL_TRANSFORM_FEEDBACK_VARYINGS, value_);
      //        }
      //        puppet_content<uint32_t> *content_;
      //        GLint *value_;
      //      };
      //      auto cmd = Recorder()->Alloc<Runnable>();
      //      cmd->content_ = program->related_id().get();
      //      cmd->value_ = &value;
      //      Present(true);
      //      result = Napi::Value::From(Env(), (int32_t)value);
      //    } break;
      //    case KR_GL_ACTIVE_UNIFORM_BLOCKS:
      //      result =
      //          Napi::Value::From(Env(),
      //          (int32_t)status->num_active_uniform_blocks);
      //      break;
    default:
      SynthesizeGLError(GL_INVALID_ENUM, "getProgramParameter",
                        "invalid parameter name");
      return Env().Null();
  }

  return result;
}

/**
 * Reviewed by luchengxuan 06/23/2021
 */
std::string WebGLRenderingContext::GetProgramInfoLog(WebGLProgram *program) {
  if (!ValidateWebGLProgramOrShader("getProgramInfoLog", program)) return "";

  auto status = program->GetShaderStatus();

  return status->program_info;
}

/**
 * Reviewed by luchengxuan 06/23/2021
 */
Value WebGLRenderingContext::GetShaderParameter(WebGLShader *shader,
                                                GLenum pname) {
  DCHECK(Recorder());

  /* Grab from Cache*/
  switch (pname) {
    case KR_GL_DELETE_STATUS:
      return Napi::Value::From(Env(), shader->MarkedForDeletion());
    case KR_GL_COMPILE_STATUS:
      return Napi::Value::From(Env(), shader->GetState() == COMPILE_SUCC);
    case KR_GL_SHADER_TYPE:
      return Napi::Value::From(Env(), (int32_t)shader->GetType());
    default:
      SynthesizeGLError(GL_INVALID_ENUM, "getShaderParameter",
                        "invalid parameter name");
      return Env().Null();
  }
}

/**
 * Reviewed by luchengxuan 06/23/2021
 */
WebGLShaderPrecisionFormat *WebGLRenderingContext::GetShaderPrecisionFormat(
    GLenum shader_type, GLenum precision_type) {
  DCHECK(Recorder());

  // logic check
  if (!ValidateShaderType("getShaderPrecisionFormat", shader_type)) {
    return nullptr;
  }

  GLint range_min = 0, range_max = 0, precision = 0;

  if (GL_FRAGMENT_SHADER == shader_type) {
    switch (precision_type) {
      case KR_GL_LOW_FLOAT:
        range_min = device_attributes_.fs_l_f_.range_min;
        range_max = device_attributes_.fs_l_f_.range_max;
        precision = device_attributes_.fs_l_f_.precision;
        break;
      case KR_GL_MEDIUM_FLOAT:
        range_min = device_attributes_.fs_m_f_.range_min;
        range_max = device_attributes_.fs_m_f_.range_max;
        precision = device_attributes_.fs_m_f_.precision;
        break;
      case KR_GL_HIGH_FLOAT:
        range_min = device_attributes_.fs_h_f_.range_min;
        range_max = device_attributes_.fs_h_f_.range_max;
        precision = device_attributes_.fs_h_f_.precision;
        break;
      case KR_GL_LOW_INT:
        range_min = device_attributes_.fs_l_i_.range_min;
        range_max = device_attributes_.fs_l_i_.range_max;
        precision = device_attributes_.fs_l_i_.precision;
        break;
      case KR_GL_MEDIUM_INT:
        range_min = device_attributes_.fs_m_i_.range_min;
        range_max = device_attributes_.fs_m_i_.range_max;
        precision = device_attributes_.fs_m_i_.precision;
        break;
      case KR_GL_HIGH_INT:
        range_min = device_attributes_.fs_h_i_.range_min;
        range_max = device_attributes_.fs_h_i_.range_max;
        precision = device_attributes_.fs_h_i_.precision;
        break;
      default:
        SynthesizeGLError(KR_GL_INVALID_ENUM, "getShaderPrecisionFormat", "");
        return nullptr;
    }
  } else if (GL_VERTEX_SHADER == shader_type) {
    switch (precision_type) {
      case KR_GL_LOW_FLOAT:
        range_min = device_attributes_.vs_l_f_.range_min;
        range_max = device_attributes_.vs_l_f_.range_max;
        precision = device_attributes_.vs_l_f_.precision;
        break;
      case KR_GL_MEDIUM_FLOAT:
        range_min = device_attributes_.vs_m_f_.range_min;
        range_max = device_attributes_.vs_m_f_.range_max;
        precision = device_attributes_.vs_m_f_.precision;
        break;
      case KR_GL_HIGH_FLOAT:
        range_min = device_attributes_.vs_h_f_.range_min;
        range_max = device_attributes_.vs_h_f_.range_max;
        precision = device_attributes_.vs_h_f_.precision;
        break;
      case KR_GL_LOW_INT:
        range_min = device_attributes_.vs_l_i_.range_min;
        range_max = device_attributes_.vs_l_i_.range_max;
        precision = device_attributes_.vs_l_i_.precision;
        break;
      case KR_GL_MEDIUM_INT:
        range_min = device_attributes_.vs_m_i_.range_min;
        range_max = device_attributes_.vs_m_i_.range_max;
        precision = device_attributes_.vs_m_i_.precision;
        break;
      case KR_GL_HIGH_INT:
        range_min = device_attributes_.vs_h_i_.range_min;
        range_max = device_attributes_.vs_h_i_.range_max;
        precision = device_attributes_.vs_h_i_.precision;
        break;
      default:
        SynthesizeGLError(GL_INVALID_ENUM, "getShaderPrecisionFormat",
                          "invalid precision type");
        return nullptr;
    }
  } else {
    SynthesizeGLError(GL_INVALID_ENUM, "getShaderPrecisionFormat",
                      "invalid precision type");
    return nullptr;
  }

  // genarate js object
  return new WebGLShaderPrecisionFormat(range_min, range_max, precision);
}

/**
 * Reviewed by luchengxuan 06/23/2021
 */
std::string WebGLRenderingContext::GetShaderInfoLog(WebGLShader *shader) {
  DCHECK(Recorder());
  if (!ValidateWebGLProgramOrShader("getShaderInfoLog", shader))
    return std::string();

  return shader->GetInfoLog();
}

/**
 * Reviewed by luchengxuan 06/23/2021
 */
std::string WebGLRenderingContext::GetShaderSource(WebGLShader *shader) {
  DCHECK(Recorder());
  if (!ValidateWebGLProgramOrShader("getShaderSource", shader)) {
    return std::string();
  }
  return shader->GetSourceStr();
}

/**
 * Reviewed by luchengxuan 06/23/2021
 */
GLboolean WebGLRenderingContext::IsProgram(WebGLProgram *program) {
  DCHECK(Recorder());

  if (!program || !program->Validate(this)) return GL_FALSE;

  // OpenGL ES special-cases the behavior of program objects; if they're deleted
  // while attached to the current context state, glIsProgram is supposed to
  // still return true. For this reason, MarkedForDeletion is not checked here.
  GLboolean result;
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      auto program = program_content->Get();
      *result_ptr = GL::IsProgram(program);
    }
    PuppetContent<uint32_t> *program_content = nullptr;
    GLboolean *result_ptr;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->program_content = program->related_id().Get();
  cmd->result_ptr = &result;

  Present(true);
  return result;
}

/**
 * Reviewed by luchengxuan 06/24/2021
 */
GLboolean WebGLRenderingContext::IsShader(WebGLShader *shader) const {
  DCHECK(Recorder());

  // this diff from chromium as we can exactly trace the shader attachment count
  // as the difference of logic in WebGLProgram::DeleteObjectImpl
  return shader && shader->Validate(this) && shader->HasObject();
}

/**
 * Reviewed by luchengxuan 06/24/2021
 */
void WebGLRenderingContext::LinkProgram(WebGLProgram *program) {
  if (!ValidateWebGLProgramOrShader("linkProgram", program)) return;

  //  webgl2 feature
  //  if (program->ActiveTransformFeedbackCount() > 0) {
  //    SynthesizeGLError(
  //        GL_INVALID_OPERATION, "linkProgram",
  //        "program being used by one or more active transform feedback
  //        objects");
  //    return;
  //  }

  //  TODO(luchengxuan) consider to use kKHRParallelShaderCompile for async
  //  query GLuint query = 0u; if
  //  (ExtensionEnabled(kKHRParallelShaderCompileName)) {
  //    ContextGL()->GenQueriesEXT(1, &query);
  //    ContextGL()->BeginQueryEXT(GL_PROGRAM_COMPLETION_QUERY_CHROMIUM, query);
  //  }
  program->Link(Recorder());
  //  if (ExtensionEnabled(kKHRParallelShaderCompileName)) {
  //    ContextGL()->EndQueryEXT(GL_PROGRAM_COMPLETION_QUERY_CHROMIUM);
  //    addProgramCompletionQuery(program, query);
  //  }

  Present(true);
  program->IncreaseLinkCount();
}

using UChar = uint16_t;
inline bool IsASCII(UChar c) { return !(c & ~0x7F); }

// Replaces non-ASCII characters with a placeholder. Given
// shaderSource's new rules as of
// https://github.com/KhronosGroup/WebGL/pull/3206 , the browser must
// not generate INVALID_VALUE for these out-of-range characters.
// Shader compilation must fail for invalid constructs farther in the
// pipeline.
class ReplaceNonASCII {
 public:
  explicit ReplaceNonASCII(const std::string &str) { Parse(str); }

  std::string Result() { return builder_.str(); }

 private:
  void Parse(const std::string &source_string) {
    unsigned len = static_cast<unsigned>(source_string.length());
    for (unsigned i = 0; i < len; ++i) {
      UChar current = source_string[i];
      if (IsASCII(current))
        builder_ << (char)current;
      else
        builder_ << '?';
    }
  }

  std::ostringstream builder_;
};

/**
 * Reviewed by luchengxuan 06/24/2021
 */
void WebGLRenderingContext::ShaderSource(WebGLShader *shader,
                                         std::string source) {
  DCHECK(Recorder());

  if (!ValidateWebGLProgramOrShader("shaderSource", shader)) return;

  auto ascii_source = ReplaceNonASCII(source).Result();

  // Save Cache
  // GetShaderSource should return origin but should only pass ascii only one to
  // GL
  shader->SetSourceStr(std::move(source));

  /* commit to change*/
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GLint src_size = static_cast<GLint>(source_.size());
      const char *source = source_.c_str();
      auto shader = content_->Get();
      GL::ShaderSource(shader, 1, &source, &src_size);
    }
    std::string source_;
    PuppetContent<uint32_t> *content_ = nullptr;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->source_ = ascii_source;
  cmd->content_ = shader->related_id().Get();
}

/**
 * Reviewed by luchengxuan 06/24/2021
 */
void WebGLRenderingContext::UseProgram(WebGLProgram *program) {
  GLenum err;
  const char *err_msg;
  if (!ValidateNullableWebGLObject(program, &err, &err_msg)) {
    SynthesizeGLError(GL_INVALID_OPERATION, "useProgram", err_msg);
    return;
  }

  if (program && !program->GetShaderStatus()->is_success) {
    SynthesizeGLError(GL_INVALID_OPERATION, "useProgram", "program not valid");
    return;
  }

  if (local_cache_.current_program_ != program) {
    if (local_cache_.current_program_)
      local_cache_.current_program_->OnDetached(Recorder());
    local_cache_.current_program_ = program;

    // commit command
    struct Runnable {
      void Run(command_buffer::RunnableBuffer *buffer) const {
        auto program = content_ ? content_->Get() : 0;
        GL::UseProgram(program);
      }
      PuppetContent<uint32_t> *content_ = nullptr;
    };
    auto cmd = Recorder()->Alloc<Runnable>();
    cmd->content_ = program ? program->related_id().Get() : nullptr;

    if (program) program->OnAttached();
  }
}

/**
 * Reviewed by luchengxuan 06/24/2021
 */
void WebGLRenderingContext::ValidateProgram(WebGLProgram *program) {
  if (!ValidateWebGLProgramOrShader("validateProgram", program)) return;

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::ValidateProgram(content_->Get());
    }
    PuppetContent<uint32_t> *content_ = nullptr;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->content_ = program->related_id().Get();
}
}  // namespace canvas
}  // namespace lynx
