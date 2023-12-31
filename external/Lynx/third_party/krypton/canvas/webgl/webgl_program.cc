// Copyright 2021 The Lynx Authors. All rights reserved.

#include "webgl_program.h"

#include "canvas/gpu/gl/gl_api.h"

namespace lynx {
namespace canvas {
namespace {

#define BUF_SIZE 256

void DumpAttribsInfo(uint32_t vProgramID, int32_t &voNumActiveAttributes,
                     std::vector<WebGLProgramAttrib> &voAttribsInfo) {
  int32_t length, location, size;
  uint32_t type;
  char cur_buf[BUF_SIZE];

  GL::GetProgramiv(vProgramID, KR_GL_ACTIVE_ATTRIBUTES, &voNumActiveAttributes);
  voAttribsInfo.resize(voNumActiveAttributes);
  for (int i = 0; i < voNumActiveAttributes; ++i) {
    memset(cur_buf, 0, BUF_SIZE);
    GL::GetActiveAttrib(vProgramID, i, BUF_SIZE, &length, &size, &type,
                        cur_buf);
    location = GL::GetAttribLocation(vProgramID, cur_buf);
    voAttribsInfo[i].name_.append(cur_buf, length);
    voAttribsInfo[i].size_ = size;
    voAttribsInfo[i].type_ = type;
    voAttribsInfo[i].location_ = location;
  }
}

void DumpUniformsInfo(uint32_t program_id, int32_t &num_active_uniforms,
                      std::vector<WebGLProgramUniform> &uniforms_info) {
  int32_t length, size, location = 0;
  uint32_t type, index;
  char cur_buf[BUF_SIZE];

  GL::GetProgramiv(program_id, KR_GL_ACTIVE_UNIFORMS, &num_active_uniforms);
  // make sure it is empty.
  uniforms_info.clear();

  for (int i = 0; i < num_active_uniforms; ++i) {
    memset(cur_buf, 0, BUF_SIZE);

    GL::GetActiveUniform(program_id, i, BUF_SIZE, &length, &size, &type,
                         cur_buf);
    location = GL::GetUniformLocation(program_id, cur_buf);
    if (location != -1) {
      uniforms_info.emplace_back(std::string(cur_buf), type, size, location,
                                 true);
    }

    if (size > 1) {
      size_t array_head_index = uniforms_info.size() - 1;

      index = static_cast<uint32_t>(
          uniforms_info[array_head_index].name_.length() - 2);
      while (uniforms_info[array_head_index].name_[index] != '[' &&
             index >= 0) {
        index--;
      }

      std::string head_name;
      std::string k_name;
      head_name.append(uniforms_info[array_head_index].name_, 0, index);

      for (int k = 1; k < size; ++k) {
        k_name = head_name + '[' + std::to_string(k) + ']';
        location = GL::GetUniformLocation(program_id, k_name.c_str());
        uniforms_info.emplace_back(k_name, type, size - k, location, false);
      }
    }
  }
}
}  // namespace

WebGLProgram::WebGLProgram(WebGLRenderingContext *context)
    : WebGLContextObject(context),
      link_count_(0),
      has_gl_object_pending_(true) {
  related_id().Build(GetRecorder());
  shader_status_ = std::make_shared<WebGLProgramShaderStatus>();

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) {
      DCHECK(content_);
      content_->Set(GL::CreateProgram());
    }
    PuppetContent<uint32_t> *content_ = nullptr;
  };
  auto cmd = GetRecorder()->Alloc<Runnable>();
  cmd->content_ = related_id().Get();
}

void WebGLProgram::Link(CommandRecorder *recorder) {
  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) {
      DCHECK(content_);
      auto program_id = content_->Get();

      // TODO(luchengxuan) need check attribute location valid as
      // https://source.chromium.org/chromium/chromium/src/+/main:gpu/command_buffer/service/program_manager.cc;l=1758;drc=8f93beff3b0c31250766e3a1b4e1313b00a7507f;bpv=1;bpt=1

      // TODO（luchengxuan) maybe need delay varying set to here
      //
      //      if (tf_buffer_mode_ != KR_GL_NONE) {
      //        char **name_buffer_ = new char *[tf_varyings_.size()];
      //        for (int i = 0; i < tf_varyings_.size(); ++i) {
      //          name_buffer_[i] = const_cast<char *>(tf_varyings_[i].data());
      //        }
      //
      //        ::glTransformFeedbackVaryings(
      //            content_->get(), static_cast<GLsizei>(tf_varyings_.size()),
      //            name_buffer_, tf_buffer_mode_);
      //        delete[] name_buffer_;
      //      }

      GL::LinkProgram(program_id);

      status_->reset();
      int32_t link_status = KR_GL_TRUE;
      GL::GetProgramiv(program_id, KR_GL_LINK_STATUS, &link_status);
      status_->is_success = link_status == KR_GL_TRUE;

      // FIXME(luchengxuan)
      // Therefore, program should have previously been the target of a call to
      // glLinkProgram, but it is not necessary for it to have been linked
      // successfully.
      // https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetActiveUniform.xhtml
      if (!status_->is_success) {
        char error_log[512] = {0};
        int32_t size = 512;
        GL::GetProgramInfoLog(program_id, 512, &size, error_log);
        status_->program_info.append(error_log, size);
      } else {
        DumpAttribsInfo(program_id, status_->num_active_attribs,
                        status_->attribs);
        DumpUniformsInfo(program_id, status_->num_active_uniforms,
                         status_->uniforms);
      }
    }

    PuppetContent<uint32_t> *content_ = nullptr;
    std::shared_ptr<WebGLProgramShaderStatus> status_;
    std::vector<std::string> tf_varyings_;
    uint32_t tf_buffer_mode_;
  };

  auto cmd = recorder->Alloc<Runnable>();
  cmd->content_ = related_id_.Get();
  cmd->status_ = shader_status_;
  //  cmd->tf_varyings_ = tf_varyings;
  //  cmd->tf_buffer_mode_ = tf_buffer_mode;
}

void WebGLProgram::DeleteObjectImpl(CommandRecorder *recorder) {
  shader_status_->reset();

  if (!DestructionInProgress()) {
    if (fragment_shader_) {
      fragment_shader_->OnDetached(recorder);
      fragment_shader_ = nullptr;
    }
    if (vertex_shader_) {
      vertex_shader_->OnDetached(recorder);
      vertex_shader_ = nullptr;
    }
  }

  has_gl_object_pending_ = false;

  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) {
      GLint p;
      GL::GetIntegerv(GL_CURRENT_PROGRAM, &p);
      if (p == content_->Get()) {
        GL::UseProgram(0);
      }
      GL::DeleteProgram(content_->Get());
    }
    PuppetContent<uint32_t> *content_ = nullptr;
  };
  auto cmd = recorder->Alloc<Runnable>();
  cmd->content_ = related_id_.Get();
}

bool WebGLProgram::HasObject() const { return has_gl_object_pending_; }

WebGLShader *WebGLProgram::GetAttachedShader(GLenum type) {
  switch (type) {
    case GL_VERTEX_SHADER:
      return vertex_shader_;
    case GL_FRAGMENT_SHADER:
      return fragment_shader_;
    default:
      return nullptr;
  }
}

bool WebGLProgram::AttachShader(WebGLShader *shader) {
  if (!shader || !shader->HasObject()) return false;

  switch (shader->GetType()) {
    case GL_VERTEX_SHADER:
      if (vertex_shader_) return false;
      vertex_shader_ = shader;
      return true;
    case GL_FRAGMENT_SHADER:
      if (fragment_shader_) return false;
      fragment_shader_ = shader;
      return true;
    default:
      return false;
  }
}

bool WebGLProgram::DetachShader(WebGLShader *shader) {
  if (!shader || !shader->HasObject()) return false;
  switch (shader->GetType()) {
    case GL_VERTEX_SHADER:
      if (vertex_shader_ != shader) return false;
      vertex_shader_ = nullptr;
      return true;
    case GL_FRAGMENT_SHADER:
      if (fragment_shader_ != shader) return false;
      fragment_shader_ = nullptr;
      return true;
    default:
      return false;
  }
}

}  // namespace canvas
}  // namespace lynx
