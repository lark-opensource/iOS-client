#include "gl_command_buffer.h"

#include "canvas/gpu/gl_constants.h"
#include "canvas/util/texture_util.h"

namespace lynx {
namespace canvas {
namespace {
// maybe should merged into DataHolder but just redefine here.
template <typename T>
class PackData {
 public:
  PackData() : data_(nullptr), count_(0) {}

  PackData(const T* data, size_t count) : data_(nullptr), count_(count) {
    auto size = count_ * sizeof(T);
    data_ = static_cast<T*>(std::malloc(size));
    std::memcpy(data_, data, size);
  }

  PackData(const void* data, size_t count)
      : PackData(reinterpret_cast<const T*>(data), count) {}

  PackData(const PackData&) = delete;
  PackData(PackData&&) = delete;

  ~PackData() { std::free(data_); }

  PackData& operator=(const PackData&) = delete;
  PackData& operator=(PackData&& origin) {
    data_ = origin.data_;
    count_ = origin.count_;
    origin.data_ = nullptr;
    origin.count_ = 0;
    return *this;
  }

  T* Data() { return data_; }

  size_t Count() const { return count_; }

  size_t ByteSize() const { return count_ * sizeof(T); }

 private:
  T* data_;
  size_t count_;
};
}  // namespace

GLCommandBuffer::GLCommandBuffer(CommandRecorder* recorder)
    : recorder_(recorder) {}

void GLCommandBuffer::ActiveTexture(uint32_t texture) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::ActiveTexture(texture_);
    }
    uint32_t texture_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->texture_ = texture;
}

void GLCommandBuffer::AttachShader(uint32_t program, uint32_t shader) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::AttachShader(program_, shader_);
    }
    uint32_t program_;
    uint32_t shader_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->program_ = program;
  cmd->shader_ = shader;
}

void GLCommandBuffer::BindAttribLocation(uint32_t program, uint32_t index,
                                         string name) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::BindAttribLocation(program_, index_, name_.data());
    }
    uint32_t program_;
    uint32_t index_;
    string name_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->program_ = program;
  cmd->index_ = index;
  cmd->name_ = std::move(name);
}

void GLCommandBuffer::BindBuffer(uint32_t target, uint32_t buffer) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::BindBuffer(target_, buffer_);
    }
    uint32_t target_;
    uint32_t buffer_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->buffer_ = buffer;
}

void GLCommandBuffer::BindFramebuffer(uint32_t target, uint32_t framebuffer) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::BindFramebuffer(target_, framebuffer_);
    }
    uint32_t target_;
    uint32_t framebuffer_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->framebuffer_ = framebuffer;
}

void GLCommandBuffer::BindRenderbuffer(uint32_t target, uint32_t renderbuffer) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::BindRenderbuffer(target_, renderbuffer_);
    }
    uint32_t target_;
    uint32_t renderbuffer_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->renderbuffer_ = renderbuffer;
}

void GLCommandBuffer::BindTexture(uint32_t target, uint32_t texture) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::BindTexture(target_, texture_);
    }
    uint32_t target_;
    uint32_t texture_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->texture_ = texture;
}

void GLCommandBuffer::BlendColor(float red, float green, float blue,
                                 float alpha) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::BlendColor(red_, green_, blue_, alpha_);
    }
    float red_;
    float green_;
    float blue_;
    float alpha_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->red_ = red;
  cmd->green_ = green;
  cmd->blue_ = blue;
  cmd->alpha_ = alpha;
}

void GLCommandBuffer::BlendEquation(uint32_t mode) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::BlendEquation(mode_);
    }
    uint32_t mode_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->mode_ = mode;
}

void GLCommandBuffer::BlendEquationSeparate(uint32_t modeRGB,
                                            uint32_t modeAlpha) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::BlendEquationSeparate(modeRGB_, modeAlpha_);
    }
    uint32_t modeRGB_;
    uint32_t modeAlpha_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->modeRGB_ = modeRGB;
  cmd->modeAlpha_ = modeAlpha;
}

void GLCommandBuffer::BlendFunc(uint32_t sfactor, uint32_t dfactor) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::BlendFunc(sfactor_, dfactor_);
    }
    uint32_t sfactor_;
    uint32_t dfactor_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->sfactor_ = sfactor;
  cmd->dfactor_ = dfactor;
}

void GLCommandBuffer::BlendFuncSeparate(uint32_t sfactorRGB,
                                        uint32_t dfactorRGB,
                                        uint32_t sfactorAlpha,
                                        uint32_t dfactorAlpha) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::BlendFuncSeparate(sfactorRGB_, dfactorRGB_, sfactorAlpha_,
                            dfactorAlpha_);
    }
    uint32_t sfactorRGB_;
    uint32_t dfactorRGB_;
    uint32_t sfactorAlpha_;
    uint32_t dfactorAlpha_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->sfactorRGB_ = sfactorRGB;
  cmd->dfactorRGB_ = dfactorRGB;
  cmd->sfactorAlpha_ = sfactorAlpha;
  cmd->dfactorAlpha_ = dfactorAlpha;
}

void GLCommandBuffer::BufferData(uint32_t target, int64_t size,
                                 const void* data, uint32_t usage) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::BufferData(target_, data_.ByteSize(), data_.Data(), usage_);
    }
    uint32_t target_;
    PackData<uint8_t> data_;
    uint32_t usage_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->data_ = PackData<uint8_t>(data, size);
  cmd->usage_ = usage;
}

void GLCommandBuffer::BufferSubData(uint32_t target, int64_t offset,
                                    int64_t size, const void* data) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::BufferSubData(target_, offset_, data_.ByteSize(), data_.Data());
    }
    uint32_t target_;
    int64_t offset_;
    PackData<uint8_t> data_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->offset_ = offset;
  cmd->data_ = PackData<uint8_t>(data, size);
}

uint32_t GLCommandBuffer::CheckFramebufferStatus(uint32_t target) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      *result_ptr = GL::CheckFramebufferStatus(target_);
    }
    uint32_t target_;
    uint32_t* result_ptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;

  uint32_t result;
  cmd->result_ptr = &result;
  Flush(true);
  return result;
}

void GLCommandBuffer::Clear(uint32_t mask) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) { GL::Clear(mask_); }
    uint32_t mask_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->mask_ = mask;
}

void GLCommandBuffer::ClearColor(float red, float green, float blue,
                                 float alpha) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::ClearColor(red_, green_, blue_, alpha_);
    }
    float red_;
    float green_;
    float blue_;
    float alpha_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->red_ = red;
  cmd->green_ = green;
  cmd->blue_ = blue;
  cmd->alpha_ = alpha;
}

void GLCommandBuffer::ClearDepthf(float d) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) { GL::ClearDepthf(d_); }
    float d_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->d_ = d;
}

void GLCommandBuffer::ClearStencil(int32_t s) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) { GL::ClearStencil(s_); }
    int32_t s_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->s_ = s;
}

void GLCommandBuffer::ColorMask(GLboolean red, GLboolean green, GLboolean blue,
                                GLboolean alpha) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::ColorMask(red_, green_, blue_, alpha_);
    }
    GLboolean red_;
    GLboolean green_;
    GLboolean blue_;
    GLboolean alpha_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->red_ = red;
  cmd->green_ = green;
  cmd->blue_ = blue;
  cmd->alpha_ = alpha;
}

void GLCommandBuffer::CompileShader(uint32_t shader) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::CompileShader(shader_);
    }
    uint32_t shader_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->shader_ = shader;
}

void GLCommandBuffer::CompressedTexImage2D(uint32_t target, int32_t level,
                                           uint32_t internalformat,
                                           int32_t width, int32_t height,
                                           int32_t border, int32_t imageSize,
                                           string data) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::CompressedTexImage2D(target_, level_, internalformat_, width_,
                               height_, border_, imageSize_, data_.data());
    }
    uint32_t target_;
    int32_t level_;
    uint32_t internalformat_;
    int32_t width_;
    int32_t height_;
    int32_t border_;
    int32_t imageSize_;
    string data_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->level_ = level;
  cmd->internalformat_ = internalformat;
  cmd->width_ = width;
  cmd->height_ = height;
  cmd->border_ = border;
  cmd->imageSize_ = imageSize;
  cmd->data_ = std::move(data);
}

void GLCommandBuffer::CompressedTexSubImage2D(uint32_t target, int32_t level,
                                              int32_t xoffset, int32_t yoffset,
                                              int32_t width, int32_t height,
                                              uint32_t format,
                                              int32_t imageSize, string data) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::CompressedTexSubImage2D(target_, level_, xoffset_, yoffset_, width_,
                                  height_, format_, imageSize_, data_.data());
    }
    uint32_t target_;
    int32_t level_;
    int32_t xoffset_;
    int32_t yoffset_;
    int32_t width_;
    int32_t height_;
    uint32_t format_;
    int32_t imageSize_;
    string data_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->level_ = level;
  cmd->xoffset_ = xoffset;
  cmd->yoffset_ = yoffset;
  cmd->width_ = width;
  cmd->height_ = height;
  cmd->format_ = format;
  cmd->imageSize_ = imageSize;
  cmd->data_ = std::move(data);
}

void GLCommandBuffer::CopyTexImage2D(uint32_t target, int32_t level,
                                     uint32_t internalformat, int32_t x,
                                     int32_t y, int32_t width, int32_t height,
                                     int32_t border) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::CopyTexImage2D(target_, level_, internalformat_, x_, y_, width_,
                         height_, border_);
    }
    uint32_t target_;
    int32_t level_;
    uint32_t internalformat_;
    int32_t x_;
    int32_t y_;
    int32_t width_;
    int32_t height_;
    int32_t border_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->level_ = level;
  cmd->internalformat_ = internalformat;
  cmd->x_ = x;
  cmd->y_ = y;
  cmd->width_ = width;
  cmd->height_ = height;
  cmd->border_ = border;
}

void GLCommandBuffer::CopyTexSubImage2D(uint32_t target, int32_t level,
                                        int32_t xoffset, int32_t yoffset,
                                        int32_t x, int32_t y, int32_t width,
                                        int32_t height) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::CopyTexSubImage2D(target_, level_, xoffset_, yoffset_, x_, y_, width_,
                            height_);
    }
    uint32_t target_;
    int32_t level_;
    int32_t xoffset_;
    int32_t yoffset_;
    int32_t x_;
    int32_t y_;
    int32_t width_;
    int32_t height_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->level_ = level;
  cmd->xoffset_ = xoffset;
  cmd->yoffset_ = yoffset;
  cmd->x_ = x;
  cmd->y_ = y;
  cmd->width_ = width;
  cmd->height_ = height;
}

uint32_t GLCommandBuffer::CreateProgram() {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      *result_ptr = GL::CreateProgram();
    }
    uint32_t* result_ptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();

  uint32_t result;
  cmd->result_ptr = &result;
  Flush(true);
  return result;
}

uint32_t GLCommandBuffer::CreateShader(uint32_t type) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      *result_ptr = GL::CreateShader(type_);
    }
    uint32_t type_;
    uint32_t* result_ptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->type_ = type;

  uint32_t result;
  cmd->result_ptr = &result;
  Flush(true);
  return result;
}

void GLCommandBuffer::CullFace(uint32_t mode) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) { GL::CullFace(mode_); }
    uint32_t mode_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->mode_ = mode;
}

void GLCommandBuffer::DeleteBuffers(int32_t n, uint32_t* buffers) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::DeleteBuffers(buffers_.Count(), buffers_.Data());
    }
    PackData<uint32_t> buffers_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->buffers_ = PackData<uint32_t>(buffers, n);
}

void GLCommandBuffer::DeleteFramebuffers(int32_t n, uint32_t* framebuffers) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::DeleteFramebuffers(framebuffers_.Count(), framebuffers_.Data());
    }
    PackData<uint32_t> framebuffers_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->framebuffers_ = PackData<uint32_t>(framebuffers, n);
}

void GLCommandBuffer::DeleteProgram(uint32_t program) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::DeleteProgram(program_);
    }
    uint32_t program_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->program_ = program;
}

void GLCommandBuffer::DeleteRenderbuffers(int32_t n, uint32_t* renderbuffers) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::DeleteRenderbuffers(renderbuffers_.Count(), renderbuffers_.Data());
    }
    PackData<uint32_t> renderbuffers_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->renderbuffers_ = PackData<uint32_t>(renderbuffers, n);
}

void GLCommandBuffer::DeleteShader(uint32_t shader) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::DeleteShader(shader_);
    }
    uint32_t shader_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->shader_ = shader;
}

void GLCommandBuffer::DeleteTextures(int32_t n, uint32_t* textures) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::DeleteTextures(textures_.Count(), textures_.Data());
    }
    PackData<uint32_t> textures_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->textures_ = PackData<uint32_t>(textures, n);
}

void GLCommandBuffer::DepthFunc(uint32_t func) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) { GL::DepthFunc(func_); }
    uint32_t func_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->func_ = func;
}

void GLCommandBuffer::DepthMask(GLboolean flag) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) { GL::DepthMask(flag_); }
    GLboolean flag_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->flag_ = flag;
}

void GLCommandBuffer::DepthRangef(float n, float f) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::DepthRangef(n_, f_);
    }
    float n_;
    float f_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->n_ = n;
  cmd->f_ = f;
}

void GLCommandBuffer::DetachShader(uint32_t program, uint32_t shader) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::DetachShader(program_, shader_);
    }
    uint32_t program_;
    uint32_t shader_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->program_ = program;
  cmd->shader_ = shader;
}

void GLCommandBuffer::Disable(uint32_t cap) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) { GL::Disable(cap_); }
    uint32_t cap_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->cap_ = cap;
}

void GLCommandBuffer::DisableVertexAttribArray(uint32_t index) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::DisableVertexAttribArray(index_);
    }
    uint32_t index_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->index_ = index;
}

void GLCommandBuffer::DrawArrays(uint32_t mode, int32_t first, int32_t count) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::DrawArrays(mode_, first_, count_);
    }
    uint32_t mode_;
    int32_t first_;
    int32_t count_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->mode_ = mode;
  cmd->first_ = first;
  cmd->count_ = count;
}

void GLCommandBuffer::DrawElements(uint32_t mode, int32_t count, uint32_t type,
                                   const void* indices) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::DrawElements(mode_, count_, type_, indices_);
    }
    uint32_t mode_;
    int32_t count_;
    uint32_t type_;
    const void* indices_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->mode_ = mode;
  cmd->count_ = count;
  cmd->type_ = type;
  cmd->indices_ = indices;
}

void GLCommandBuffer::Enable(uint32_t cap) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) { GL::Enable(cap_); }
    uint32_t cap_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->cap_ = cap;
}

void GLCommandBuffer::EnableVertexAttribArray(uint32_t index) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::EnableVertexAttribArray(index_);
    }
    uint32_t index_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->index_ = index;
}

void GLCommandBuffer::Finish() {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) { GL::Finish(); }
  };
  recorder_->Alloc<Runnable>();
}

void GLCommandBuffer::Flush() {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) { GL::Flush(); }
  };
  recorder_->Alloc<Runnable>();
}

void GLCommandBuffer::FramebufferRenderbuffer(uint32_t target,
                                              uint32_t attachment,
                                              uint32_t renderbuffertarget,
                                              uint32_t renderbuffer) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::FramebufferRenderbuffer(target_, attachment_, renderbuffertarget_,
                                  renderbuffer_);
    }
    uint32_t target_;
    uint32_t attachment_;
    uint32_t renderbuffertarget_;
    uint32_t renderbuffer_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->attachment_ = attachment;
  cmd->renderbuffertarget_ = renderbuffertarget;
  cmd->renderbuffer_ = renderbuffer;
}

void GLCommandBuffer::FramebufferTexture2D(uint32_t target, uint32_t attachment,
                                           uint32_t textarget, uint32_t texture,
                                           int32_t level) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::FramebufferTexture2D(target_, attachment_, textarget_, texture_,
                               level_);
    }
    uint32_t target_;
    uint32_t attachment_;
    uint32_t textarget_;
    uint32_t texture_;
    int32_t level_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->attachment_ = attachment;
  cmd->textarget_ = textarget;
  cmd->texture_ = texture;
  cmd->level_ = level;
}

void GLCommandBuffer::FrontFace(uint32_t mode) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) { GL::FrontFace(mode_); }
    uint32_t mode_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->mode_ = mode;
}

void GLCommandBuffer::GenBuffers(int32_t n, uint32_t* buffers) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GenBuffers(n_, buffers_);
    }
    int32_t n_;
    uint32_t* buffers_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->n_ = n;
  cmd->buffers_ = buffers;
  Flush(true);
}

void GLCommandBuffer::GenerateMipmap(uint32_t target) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GenerateMipmap(target_);
    }
    uint32_t target_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
}

void GLCommandBuffer::GenFramebuffers(int32_t n, uint32_t* framebuffers) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GenFramebuffers(n_, framebuffers_);
    }
    int32_t n_;
    uint32_t* framebuffers_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->n_ = n;
  cmd->framebuffers_ = framebuffers;
  Flush(true);
}

void GLCommandBuffer::GenRenderbuffers(int32_t n, uint32_t* renderbuffers) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GenRenderbuffers(n_, renderbuffers_);
    }
    int32_t n_;
    uint32_t* renderbuffers_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->n_ = n;
  cmd->renderbuffers_ = renderbuffers;
  Flush(true);
}

void GLCommandBuffer::GenTextures(int32_t n, uint32_t* textures) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GenTextures(n_, textures_);
    }
    int32_t n_;
    uint32_t* textures_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->n_ = n;
  cmd->textures_ = textures;
  Flush(true);
}

void GLCommandBuffer::GetActiveAttrib(uint32_t program, uint32_t index,
                                      int32_t bufSize, int32_t* length,
                                      int32_t* size, uint32_t* type,
                                      GLchar* name) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetActiveAttrib(program_, index_, bufSize_, length_, size_, type_,
                          name_);
    }
    uint32_t program_;
    uint32_t index_;
    int32_t bufSize_;
    int32_t* length_ = nullptr;
    int32_t* size_ = nullptr;
    uint32_t* type_ = nullptr;
    GLchar* name_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->program_ = program;
  cmd->index_ = index;
  cmd->bufSize_ = bufSize;
  cmd->length_ = length;
  cmd->size_ = size;
  cmd->type_ = type;
  cmd->name_ = name;

  Flush(true);
}

void GLCommandBuffer::GetActiveUniform(uint32_t program, uint32_t index,
                                       int32_t bufSize, int32_t* length,
                                       int32_t* size, uint32_t* type,
                                       GLchar* name) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetActiveUniform(program_, index_, bufSize_, length_, size_, type_,
                           name_);
    }
    uint32_t program_;
    uint32_t index_;
    int32_t bufSize_;
    int32_t* length_ = nullptr;
    int32_t* size_ = nullptr;
    uint32_t* type_ = nullptr;
    GLchar* name_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->program_ = program;
  cmd->index_ = index;
  cmd->bufSize_ = bufSize;
  cmd->length_ = length;
  cmd->size_ = size;
  cmd->type_ = type;
  cmd->name_ = name;

  Flush(true);
}

void GLCommandBuffer::GetAttachedShaders(uint32_t program, int32_t maxCount,
                                         int32_t* count, uint32_t* shaders) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetAttachedShaders(program_, maxCount_, count_, shaders_);
    }
    uint32_t program_;
    int32_t maxCount_;
    int32_t* count_ = nullptr;
    uint32_t* shaders_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->program_ = program;
  cmd->maxCount_ = maxCount;
  cmd->count_ = count;
  cmd->shaders_ = shaders;

  Flush(true);
}

int32_t GLCommandBuffer::GetAttribLocation(uint32_t program, string name) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      *result_ptr = GL::GetAttribLocation(program_, name_.data());
    }
    uint32_t program_;
    string name_;
    int32_t* result_ptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->program_ = program;
  cmd->name_ = std::move(name);

  int32_t result;
  cmd->result_ptr = &result;
  Flush(true);
  return result;
}

void GLCommandBuffer::GetBooleanv(uint32_t pname, GLboolean* data) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetBooleanv(pname_, data_);
    }
    uint32_t pname_;
    GLboolean* data_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->pname_ = pname;
  cmd->data_ = data;

  Flush(true);
}

void GLCommandBuffer::GetBufferParameteriv(uint32_t target, uint32_t pname,
                                           int32_t* params) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetBufferParameteriv(target_, pname_, params_);
    }
    uint32_t target_;
    uint32_t pname_;
    int32_t* params_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->pname_ = pname;
  cmd->params_ = params;

  Flush(true);
}

uint32_t GLCommandBuffer::GetError() {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      *result_ptr = GL::GetError();
    }
    uint32_t* result_ptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();

  uint32_t result;
  cmd->result_ptr = &result;
  Flush(true);
  return result;
}

void GLCommandBuffer::GetFloatv(uint32_t pname, float* data) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetFloatv(pname_, data_);
    }
    uint32_t pname_;
    float* data_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->pname_ = pname;
  cmd->data_ = data;

  Flush(true);
}

void GLCommandBuffer::GetFramebufferAttachmentParameteriv(uint32_t target,
                                                          uint32_t attachment,
                                                          uint32_t pname,
                                                          int32_t* params) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetFramebufferAttachmentParameteriv(target_, attachment_, pname_,
                                              params_);
    }
    uint32_t target_;
    uint32_t attachment_;
    uint32_t pname_;
    int32_t* params_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->attachment_ = attachment;
  cmd->pname_ = pname;
  cmd->params_ = params;

  Flush(true);
}

void GLCommandBuffer::GetIntegerv(uint32_t pname, int32_t* data) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetIntegerv(pname_, data_);
    }
    uint32_t pname_;
    int32_t* data_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->pname_ = pname;
  cmd->data_ = data;

  Flush(true);
}

void GLCommandBuffer::GetProgramiv(uint32_t program, uint32_t pname,
                                   int32_t* params) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetProgramiv(program_, pname_, params_);
    }
    uint32_t program_;
    uint32_t pname_;
    int32_t* params_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->program_ = program;
  cmd->pname_ = pname;
  cmd->params_ = params;

  Flush(true);
}

void GLCommandBuffer::GetProgramInfoLog(uint32_t program, int32_t bufSize,
                                        int32_t* length, GLchar* infoLog) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetProgramInfoLog(program_, bufSize_, length_, infoLog_);
    }
    uint32_t program_;
    int32_t bufSize_;
    int32_t* length_;
    GLchar* infoLog_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->program_ = program;
  cmd->bufSize_ = bufSize;
  cmd->length_ = length;
  cmd->infoLog_ = infoLog;

  Flush(true);
}

void GLCommandBuffer::GetRenderbufferParameteriv(uint32_t target,
                                                 uint32_t pname,
                                                 int32_t* params) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetRenderbufferParameteriv(target_, pname_, params_);
    }
    uint32_t target_;
    uint32_t pname_;
    int32_t* params_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->pname_ = pname;
  cmd->params_ = params;

  Flush(true);
}

void GLCommandBuffer::GetShaderiv(uint32_t shader, uint32_t pname,
                                  int32_t* params) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetShaderiv(shader_, pname_, params_);
    }
    uint32_t shader_;
    uint32_t pname_;
    int32_t* params_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->shader_ = shader;
  cmd->pname_ = pname;
  cmd->params_ = params;

  Flush(true);
}

void GLCommandBuffer::GetShaderInfoLog(uint32_t shader, int32_t bufSize,
                                       int32_t* length, GLchar* infoLog) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetShaderInfoLog(shader_, bufSize_, length_, infoLog_);
    }
    uint32_t shader_;
    int32_t bufSize_;
    int32_t* length_;
    GLchar* infoLog_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->shader_ = shader;
  cmd->bufSize_ = bufSize;
  cmd->length_ = length;
  cmd->infoLog_ = infoLog;

  Flush(true);
}

void GLCommandBuffer::GetShaderPrecisionFormat(uint32_t shadertype,
                                               uint32_t precisiontype,
                                               int32_t* range,
                                               int32_t* precision) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetShaderPrecisionFormat(shadertype_, precisiontype_, range_,
                                   precision_);
    }
    uint32_t shadertype_;
    uint32_t precisiontype_;
    int32_t* range_ = nullptr;
    int32_t* precision_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->shadertype_ = shadertype;
  cmd->precisiontype_ = precisiontype;
  cmd->range_ = range;
  cmd->precision_ = precision;

  Flush(true);
}

void GLCommandBuffer::GetShaderSource(uint32_t shader, int32_t bufSize,
                                      int32_t* length, GLchar* source) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetShaderSource(shader_, bufSize_, length_, source_);
    }
    uint32_t shader_;
    int32_t bufSize_;
    int32_t* length_ = nullptr;
    GLchar* source_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->shader_ = shader;
  cmd->bufSize_ = bufSize;
  cmd->length_ = length;
  cmd->source_ = source;

  Flush(true);
}

uint8_t const* GLCommandBuffer::GetString(uint32_t name) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      *result_ptr = GL::GetString(name_);
    }
    uint32_t name_;
    uint8_t const** result_ptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->name_ = name;

  uint8_t const* result;
  cmd->result_ptr = &result;
  Flush(true);
  return result;
}

void GLCommandBuffer::GetTexParameterfv(uint32_t target, uint32_t pname,
                                        float* params) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetTexParameterfv(target_, pname_, params_);
    }
    uint32_t target_;
    uint32_t pname_;
    float* params_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->pname_ = pname;
  cmd->params_ = params;

  Flush(true);
}

void GLCommandBuffer::GetTexParameteriv(uint32_t target, uint32_t pname,
                                        int32_t* params) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetTexParameteriv(target_, pname_, params_);
    }
    uint32_t target_;
    uint32_t pname_;
    int32_t* params_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->pname_ = pname;
  cmd->params_ = params;

  Flush(true);
}

void GLCommandBuffer::GetUniformfv(uint32_t program, int32_t location,
                                   float* params) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetUniformfv(program_, location_, params_);
    }
    uint32_t program_;
    int32_t location_;
    float* params_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->program_ = program;
  cmd->location_ = location;
  cmd->params_ = params;

  Flush(true);
}

void GLCommandBuffer::GetUniformiv(uint32_t program, int32_t location,
                                   int32_t* params) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetUniformiv(program_, location_, params_);
    }
    uint32_t program_;
    int32_t location_;
    int32_t* params_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->program_ = program;
  cmd->location_ = location;
  cmd->params_ = params;

  Flush(true);
}

int32_t GLCommandBuffer::GetUniformLocation(uint32_t program, string name) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      *result_ptr = GL::GetUniformLocation(program_, name_.data());
    }
    uint32_t program_;
    string name_;
    int32_t* result_ptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->program_ = program;
  cmd->name_ = std::move(name);

  int32_t result;
  cmd->result_ptr = &result;
  Flush(true);
  return result;
}

void GLCommandBuffer::GetVertexAttribfv(uint32_t index, uint32_t pname,
                                        float* params) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetVertexAttribfv(index_, pname_, params_);
    }
    uint32_t index_;
    uint32_t pname_;
    float* params_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->index_ = index;
  cmd->pname_ = pname;
  cmd->params_ = params;

  Flush(true);
}

void GLCommandBuffer::GetVertexAttribiv(uint32_t index, uint32_t pname,
                                        int32_t* params) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetVertexAttribiv(index_, pname_, params_);
    }
    uint32_t index_;
    uint32_t pname_;
    int32_t* params_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->index_ = index;
  cmd->pname_ = pname;
  cmd->params_ = params;

  Flush(true);
}

void GLCommandBuffer::GetVertexAttribPointerv(uint32_t index, uint32_t pname,
                                              void** pointer) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::GetVertexAttribPointerv(index_, pname_, pointer_);
    }
    uint32_t index_;
    uint32_t pname_;
    void** pointer_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->index_ = index;
  cmd->pname_ = pname;
  cmd->pointer_ = pointer;

  Flush(true);
}

void GLCommandBuffer::Hint(uint32_t target, uint32_t mode) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Hint(target_, mode_);
    }
    uint32_t target_;
    uint32_t mode_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->mode_ = mode;
}

bool GLCommandBuffer::IsBuffer(uint32_t buffer) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      *result_ptr = GL::IsBuffer(buffer_);
    }
    uint32_t buffer_;
    bool* result_ptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->buffer_ = buffer;

  bool result;
  cmd->result_ptr = &result;
  Flush(true);
  return result;
}

bool GLCommandBuffer::IsEnabled(uint32_t cap) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      *result_ptr = GL::IsEnabled(cap_);
    }
    uint32_t cap_;
    bool* result_ptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->cap_ = cap;

  bool result;
  cmd->result_ptr = &result;
  Flush(true);
  return result;
}

bool GLCommandBuffer::IsFramebuffer(uint32_t framebuffer) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      *result_ptr = GL::IsFramebuffer(framebuffer_);
    }
    uint32_t framebuffer_;
    bool* result_ptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->framebuffer_ = framebuffer;

  bool result;
  cmd->result_ptr = &result;
  Flush(true);
  return result;
}

bool GLCommandBuffer::IsProgram(uint32_t program) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      *result_ptr = GL::IsProgram(program_);
    }
    uint32_t program_;
    bool* result_ptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->program_ = program;

  bool result;
  cmd->result_ptr = &result;
  Flush(true);
  return result;
}

bool GLCommandBuffer::IsRenderbuffer(uint32_t renderbuffer) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      *result_ptr = GL::IsRenderbuffer(renderbuffer_);
    }
    uint32_t renderbuffer_;
    bool* result_ptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->renderbuffer_ = renderbuffer;

  bool result;
  cmd->result_ptr = &result;
  Flush(true);
  return result;
}

bool GLCommandBuffer::IsShader(uint32_t shader) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      *result_ptr = GL::IsShader(shader_);
    }
    uint32_t shader_;
    bool* result_ptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->shader_ = shader;

  bool result;
  cmd->result_ptr = &result;
  Flush(true);
  return result;
}

bool GLCommandBuffer::IsTexture(uint32_t texture) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      *result_ptr = GL::IsTexture(texture_);
    }
    uint32_t texture_;
    bool* result_ptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->texture_ = texture;

  bool result;
  cmd->result_ptr = &result;
  Flush(true);
  return result;
}

void GLCommandBuffer::LineWidth(float width) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) { GL::LineWidth(width_); }
    float width_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->width_ = width;
}

void GLCommandBuffer::LinkProgram(uint32_t program) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::LinkProgram(program_);
    }
    uint32_t program_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->program_ = program;
}

void GLCommandBuffer::PixelStorei(uint32_t pname, int32_t param) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::PixelStorei(pname_, param_);
    }
    uint32_t pname_;
    int32_t param_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->pname_ = pname;
  cmd->param_ = param;
}

void GLCommandBuffer::PolygonOffset(float factor, float units) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::PolygonOffset(factor_, units_);
    }
    float factor_;
    float units_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->factor_ = factor;
  cmd->units_ = units;
}

void GLCommandBuffer::ReadPixels(int32_t x, int32_t y, int32_t width,
                                 int32_t height, uint32_t format, uint32_t type,
                                 std::vector<GLchar>* pixels) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::ReadPixels(x_, y_, width_, height_, format_, type_, pixels_->data());
    }
    int32_t x_;
    int32_t y_;
    int32_t width_;
    int32_t height_;
    uint32_t format_;
    uint32_t type_;
    std::vector<GLchar>* pixels_ = nullptr;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->x_ = x;
  cmd->y_ = y;
  cmd->width_ = width;
  cmd->height_ = height;
  cmd->format_ = format;
  cmd->type_ = type;
  cmd->pixels_ = pixels;

  Flush(true);
}

void GLCommandBuffer::GetPixels(int32_t x, int32_t y, int32_t width,
                                int32_t height, void* pixels, uint32_t fbo,
                                bool flipy, bool premultiply_alpha) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      if (flipy) {
        int32_t rbo, readFbo, drawFbo, enableScissorTest;
        enableScissorTest = GL::IsEnabled(KR_GL_SCISSOR_TEST);
        GL::GetIntegerv(KR_GL_RENDERBUFFER_BINDING, &rbo);
        GL::GetIntegerv(KR_GL_READ_FRAMEBUFFER_BINDING, &readFbo);
        GL::GetIntegerv(KR_GL_DRAW_FRAMEBUFFER_BINDING, &drawFbo);

        if (enableScissorTest) {
          GL::Disable(KR_GL_SCISSOR_TEST);
        }

        uint32_t newFbo, newRbo;
        GL::GenFramebuffers(1, &newFbo);
        GL::GenRenderbuffers(1, &newRbo);
        GL::BindFramebuffer(KR_GL_FRAMEBUFFER, newFbo);
        GL::BindRenderbuffer(KR_GL_RENDERBUFFER, newRbo);
        GL::RenderbufferStorage(KR_GL_RENDERBUFFER, KR_GL_RGBA8, width_,
                                height_);
        GL::FramebufferRenderbuffer(KR_GL_FRAMEBUFFER, KR_GL_COLOR_ATTACHMENT0,
                                    KR_GL_RENDERBUFFER, newRbo);
        int32_t srcX0 = x_, srcY0 = y_;
        int32_t srcX1 = srcX0 + width_, srcY1 = srcY0 + height_;
        int32_t dstX0 = 0, dstY0 = (flipy ? height_ : 0);
        int32_t dstX1 = dstX0 + width_,
                dstY1 = dstY0 + (flipy ? -height_ : height_);
        GL::BindFramebuffer(KR_GL_READ_FRAMEBUFFER, fbo_);
        GL::BlitFramebuffer(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1,
                            dstY1, KR_GL_COLOR_BUFFER_BIT, KR_GL_LINEAR);
        GL::BindFramebuffer(KR_GL_READ_FRAMEBUFFER, newFbo);
        GL::ReadPixels(0, 0, width_, height_, KR_GL_RGBA, KR_GL_UNSIGNED_BYTE,
                       pixels_);
        if (!premultiply_alpha_) {
          TextureUtil::UnpremultiplyAlpha((uint8_t*)pixels_, (uint8_t*)pixels_,
                                          width_, height_, width_ * 4, 4,
                                          KR_GL_UNSIGNED_BYTE);
        }

        if (enableScissorTest) {
          GL::Enable(KR_GL_SCISSOR_TEST);
        }
        GL::BindFramebuffer(KR_GL_READ_FRAMEBUFFER, readFbo);
        GL::BindFramebuffer(KR_GL_DRAW_FRAMEBUFFER, drawFbo);
        GL::BindRenderbuffer(KR_GL_RENDERBUFFER, rbo);
        GL::DeleteFramebuffers(1, &newFbo);
        GL::DeleteRenderbuffers(1, &newRbo);
      } else {
        GL::ReadPixels(x_, y_, width_, height_, KR_GL_RGBA, KR_GL_UNSIGNED_BYTE,
                       pixels_);
      }
    }
    int32_t x_;
    int32_t y_;
    int32_t width_;
    int32_t height_;
    void* pixels_ = nullptr;
    uint32_t fbo_;
    bool flipy;
    bool premultiply_alpha_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->x_ = x;
  cmd->y_ = y;
  cmd->width_ = width;
  cmd->height_ = height;
  cmd->pixels_ = pixels;
  cmd->fbo_ = fbo;
  cmd->flipy = flipy;
  cmd->premultiply_alpha_ = premultiply_alpha;

  Flush(true);
}

void GLCommandBuffer::PutPixels(void* pixels, int32_t width, int32_t height,
                                uint32_t fbo, int32_t srcX, int32_t srcY,
                                int32_t srcWidth, int32_t srcHeight,
                                int32_t dstX, int32_t dstY, int32_t dstWidth,
                                int32_t dstHeight) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      int32_t readFbo, drawFbo, enableScissorTest, boundTex;
      GL::GetIntegerv(KR_GL_READ_FRAMEBUFFER_BINDING, &readFbo);
      GL::GetIntegerv(KR_GL_DRAW_FRAMEBUFFER_BINDING, &drawFbo);
      GL::GetIntegerv(KR_GL_TEXTURE_BINDING_2D, &boundTex);
      enableScissorTest = GL::IsEnabled(KR_GL_SCISSOR_TEST);

      if (enableScissorTest) {
        GL::Disable(KR_GL_SCISSOR_TEST);
      }
      uint32_t newFbo, tex;
      GL::GenFramebuffers(1, &newFbo);
      GL::BindFramebuffer(KR_GL_FRAMEBUFFER, newFbo);
      GL::GenTextures(1, &tex);
      GL::BindTexture(KR_GL_TEXTURE_2D, tex);
      GL::TexParameteri(KR_GL_TEXTURE_2D, KR_GL_TEXTURE_MAG_FILTER,
                        KR_GL_NEAREST);
      GL::TexParameteri(KR_GL_TEXTURE_2D, KR_GL_TEXTURE_MIN_FILTER,
                        KR_GL_NEAREST);
      GL::TexParameteri(KR_GL_TEXTURE_2D, KR_GL_TEXTURE_WRAP_S,
                        KR_GL_CLAMP_TO_EDGE);
      GL::TexParameteri(KR_GL_TEXTURE_2D, KR_GL_TEXTURE_WRAP_T,
                        KR_GL_CLAMP_TO_EDGE);
      TextureUtil::PremultiplyAlpha(pixels_.Data(), pixels_.Data(), width_,
                                    height_, width_ * 4, 4,
                                    KR_GL_UNSIGNED_BYTE);
      GL::TexImage2D(KR_GL_TEXTURE_2D, 0, KR_GL_RGBA, width_, height_, 0,
                     KR_GL_RGBA, KR_GL_UNSIGNED_BYTE, pixels_.Data());
      GL::FramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                               GL_TEXTURE_2D, tex, 0);
      dstY_ = dstY_ + dstHeight_;
      dstHeight_ = -1 * dstHeight_;
      int32_t srcX0 = srcX_, srcY0 = srcY_;
      int32_t srcX1 = srcX0 + srcWidth_, srcY1 = srcY0 + srcHeight_;
      int32_t dstX0 = dstX_, dstY0 = dstY_;
      int32_t dstX1 = dstX0 + dstWidth_, dstY1 = dstY0 + dstHeight_;
      GL::BindFramebuffer(KR_GL_DRAW_FRAMEBUFFER, fbo_);
      GL::BlitFramebuffer(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1,
                          dstY1, KR_GL_COLOR_BUFFER_BIT, KR_GL_LINEAR);

      if (enableScissorTest) {
        GL::Enable(KR_GL_SCISSOR_TEST);
      }
      GL::BindFramebuffer(KR_GL_READ_FRAMEBUFFER, readFbo);
      GL::BindFramebuffer(KR_GL_DRAW_FRAMEBUFFER, drawFbo);
      GL::BindTexture(KR_GL_TEXTURE_2D, boundTex);
      GL::DeleteFramebuffers(1, &newFbo);
      GL::DeleteTextures(1, &tex);
    }
    PackData<uint8_t> pixels_;
    int32_t width_;
    int32_t height_;
    uint32_t fbo_;
    int32_t srcX_;
    int32_t srcY_;
    int32_t srcWidth_;
    int32_t srcHeight_;
    int32_t dstX_;
    int32_t dstY_;
    int32_t dstWidth_;
    int32_t dstHeight_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->pixels_ = PackData<uint8_t>(pixels, width * 4 * height);
  cmd->width_ = width;
  cmd->height_ = height;
  cmd->fbo_ = fbo;
  cmd->srcX_ = srcX;
  cmd->srcY_ = srcY;
  cmd->srcWidth_ = srcWidth;
  cmd->srcHeight_ = srcHeight;
  cmd->dstX_ = dstX;
  cmd->dstY_ = dstY;
  cmd->dstWidth_ = dstWidth;
  cmd->dstHeight_ = dstHeight;
}

void GLCommandBuffer::ReleaseShaderCompiler() {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::ReleaseShaderCompiler();
    }
  };
  recorder_->Alloc<Runnable>();
}

void GLCommandBuffer::RenderbufferStorage(uint32_t target,
                                          uint32_t internalformat,
                                          int32_t width, int32_t height) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::RenderbufferStorage(target_, internalformat_, width_, height_);
    }
    uint32_t target_;
    uint32_t internalformat_;
    int32_t width_;
    int32_t height_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->internalformat_ = internalformat;
  cmd->width_ = width;
  cmd->height_ = height;
}

void GLCommandBuffer::SampleCoverage(float value, GLboolean invert) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::SampleCoverage(value_, invert_);
    }
    float value_;
    GLboolean invert_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->value_ = value;
  cmd->invert_ = invert;
}

void GLCommandBuffer::Scissor(int32_t x, int32_t y, int32_t width,
                              int32_t height) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Scissor(x_, y_, width_, height_);
    }
    int32_t x_;
    int32_t y_;
    int32_t width_;
    int32_t height_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->x_ = x;
  cmd->y_ = y;
  cmd->width_ = width;
  cmd->height_ = height;
}

void GLCommandBuffer::ShaderBinary(int32_t count, uint32_t* shaders,
                                   uint32_t binaryformat, const void* binary,
                                   int32_t length) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::ShaderBinary(count_, shaders_.Data(), binaryformat_, binary_.Data(),
                       binary_.ByteSize());
    }
    int32_t count_;
    PackData<uint32_t> shaders_;
    uint32_t binaryformat_;
    PackData<char> binary_;
  };

  auto cmd = recorder_->Alloc<Runnable>();
  cmd->count_ = count;
  cmd->shaders_ = PackData<uint32_t>(shaders, count);
  cmd->binaryformat_ = binaryformat;
  cmd->binary_ = PackData<char>(reinterpret_cast<const char*>(binary), length);
}

void GLCommandBuffer::ShaderSource(uint32_t shader, int32_t count,
                                   const GLchar** strings, int32_t* length) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      const char* source = str_.c_str();
      GL::ShaderSource(shader_, 1, &source, nullptr);
    }
    uint32_t shader_;
    std::string str_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->shader_ = shader;

  for (GLsizei ii = 0; ii < count; ++ii) {
    if (length && length[ii] > 0)
      cmd->str_.append(strings[ii], length[ii]);
    else
      cmd->str_.append(strings[ii]);
  }
}

void GLCommandBuffer::StencilFunc(uint32_t func, int32_t ref, uint32_t mask) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::StencilFunc(func_, ref_, mask_);
    }
    uint32_t func_;
    int32_t ref_;
    uint32_t mask_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->func_ = func;
  cmd->ref_ = ref;
  cmd->mask_ = mask;
}

void GLCommandBuffer::StencilFuncSeparate(uint32_t face, uint32_t func,
                                          int32_t ref, uint32_t mask) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::StencilFuncSeparate(face_, func_, ref_, mask_);
    }
    uint32_t face_;
    uint32_t func_;
    int32_t ref_;
    uint32_t mask_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->face_ = face;
  cmd->func_ = func;
  cmd->ref_ = ref;
  cmd->mask_ = mask;
}

void GLCommandBuffer::StencilMask(uint32_t mask) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) { GL::StencilMask(mask_); }
    uint32_t mask_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->mask_ = mask;
}

void GLCommandBuffer::StencilMaskSeparate(uint32_t face, uint32_t mask) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::StencilMaskSeparate(face_, mask_);
    }
    uint32_t face_;
    uint32_t mask_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->face_ = face;
  cmd->mask_ = mask;
}

void GLCommandBuffer::StencilOp(uint32_t fail, uint32_t zfail, uint32_t zpass) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::StencilOp(fail_, zfail_, zpass_);
    }
    uint32_t fail_;
    uint32_t zfail_;
    uint32_t zpass_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->fail_ = fail;
  cmd->zfail_ = zfail;
  cmd->zpass_ = zpass;
}

void GLCommandBuffer::StencilOpSeparate(uint32_t face, uint32_t sfail,
                                        uint32_t dpfail, uint32_t dppass) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::StencilOpSeparate(face_, sfail_, dpfail_, dppass_);
    }
    uint32_t face_;
    uint32_t sfail_;
    uint32_t dpfail_;
    uint32_t dppass_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->face_ = face;
  cmd->sfail_ = sfail;
  cmd->dpfail_ = dpfail;
  cmd->dppass_ = dppass;
}

void GLCommandBuffer::TexImage2D(uint32_t target, int32_t level,
                                 int32_t internalformat, int32_t width,
                                 int32_t height, int32_t border,
                                 uint32_t format, uint32_t type,
                                 const void* pixels) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::TexImage2D(target_, level_, internalformat_, width_, height_, border_,
                     format_, type_, pixels_);
    }
    uint32_t target_;
    int32_t level_;
    int32_t internalformat_;
    int32_t width_;
    int32_t height_;
    int32_t border_;
    uint32_t format_;
    uint32_t type_;
    const void* pixels_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->level_ = level;
  cmd->internalformat_ = internalformat;
  cmd->width_ = width;
  cmd->height_ = height;
  cmd->border_ = border;
  cmd->format_ = format;
  cmd->type_ = type;
  cmd->pixels_ = pixels;

  // TODO copy data to avoid sync
  Flush(true);
}

void GLCommandBuffer::TexParameterf(uint32_t target, uint32_t pname,
                                    float param) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::TexParameterf(target_, pname_, param_);
    }
    uint32_t target_;
    uint32_t pname_;
    float param_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->pname_ = pname;
  cmd->param_ = param;
}

void GLCommandBuffer::TexParameterfv(uint32_t target, uint32_t pname,
                                     std::vector<float> params) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::TexParameterfv(target_, pname_, params_.data());
    }
    uint32_t target_;
    uint32_t pname_;
    std::vector<float> params_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->pname_ = pname;
  cmd->params_ = std::move(params);
}

void GLCommandBuffer::TexParameteri(uint32_t target, uint32_t pname,
                                    int32_t param) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::TexParameteri(target_, pname_, param_);
    }
    uint32_t target_;
    uint32_t pname_;
    int32_t param_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->pname_ = pname;
  cmd->param_ = param;
}

void GLCommandBuffer::TexParameteriv(uint32_t target, uint32_t pname,
                                     std::vector<int32_t> params) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::TexParameteriv(target_, pname_, params_.data());
    }
    uint32_t target_;
    uint32_t pname_;
    std::vector<int32_t> params_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->pname_ = pname;
  cmd->params_ = std::move(params);
}

void GLCommandBuffer::TexSubImage2D(uint32_t target, int32_t level,
                                    int32_t xoffset, int32_t yoffset,
                                    int32_t width, int32_t height,
                                    uint32_t format, uint32_t type,
                                    const void* pixels) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::TexSubImage2D(target_, level_, xoffset_, yoffset_, width_, height_,
                        format_, type_, pixels_);
    }
    uint32_t target_;
    int32_t level_;
    int32_t xoffset_;
    int32_t yoffset_;
    int32_t width_;
    int32_t height_;
    uint32_t format_;
    uint32_t type_;
    const void* pixels_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->level_ = level;
  cmd->xoffset_ = xoffset;
  cmd->yoffset_ = yoffset;
  cmd->width_ = width;
  cmd->height_ = height;
  cmd->format_ = format;
  cmd->type_ = type;
  cmd->pixels_ = pixels;

  // TODO copy data to avoid sync
  Flush(true);
}

void GLCommandBuffer::Uniform1f(int32_t location, float v0) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Uniform1f(location_, v0_);
    }
    int32_t location_;
    float v0_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->v0_ = v0;
}

void GLCommandBuffer::Uniform1fv(int32_t location, int32_t count,
                                 const float* value) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Uniform1fv(location_, count_, value_.Data());
    }
    int32_t location_;
    int32_t count_;
    PackData<float> value_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->count_ = count;
  cmd->value_ = PackData<float>(value, count);
}

void GLCommandBuffer::Uniform1i(int32_t location, int32_t v0) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Uniform1i(location_, v0_);
    }
    int32_t location_;
    int32_t v0_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->v0_ = v0;
}

void GLCommandBuffer::Uniform1iv(int32_t location, int32_t count,
                                 const int32_t* value) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Uniform1iv(location_, count_, value_.Data());
    }
    int32_t location_;
    int32_t count_;
    PackData<int32_t> value_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->count_ = count;
  cmd->value_ = PackData<int32_t>(value, count);
}

void GLCommandBuffer::Uniform2f(int32_t location, float v0, float v1) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Uniform2f(location_, v0_, v1_);
    }
    int32_t location_;
    float v0_;
    float v1_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->v0_ = v0;
  cmd->v1_ = v1;
}

void GLCommandBuffer::Uniform2fv(int32_t location, int32_t count,
                                 const float* value) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Uniform2fv(location_, count_, value_.Data());
    }
    int32_t location_;
    int32_t count_;
    PackData<float> value_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->count_ = count;
  cmd->value_ = PackData<float>(value, count * 2);
}

void GLCommandBuffer::Uniform2i(int32_t location, int32_t v0, int32_t v1) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Uniform2i(location_, v0_, v1_);
    }
    int32_t location_;
    int32_t v0_;
    int32_t v1_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->v0_ = v0;
  cmd->v1_ = v1;
}

void GLCommandBuffer::Uniform2iv(int32_t location, int32_t count,
                                 const int32_t* value) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Uniform2iv(location_, count_, value_.Data());
    }
    int32_t location_;
    int32_t count_;
    PackData<int32_t> value_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->count_ = count;
  cmd->value_ = PackData<int32_t>(value, count * 2);
}

void GLCommandBuffer::Uniform3f(int32_t location, float v0, float v1,
                                float v2) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Uniform3f(location_, v0_, v1_, v2_);
    }
    int32_t location_;
    float v0_;
    float v1_;
    float v2_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->v0_ = v0;
  cmd->v1_ = v1;
  cmd->v2_ = v2;
}

void GLCommandBuffer::Uniform3fv(int32_t location, int32_t count,
                                 const float* value) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Uniform3fv(location_, count_, value_.Data());
    }
    int32_t location_;
    int32_t count_;
    PackData<float> value_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->count_ = count;
  cmd->value_ = PackData<float>(value, count * 3);
}

void GLCommandBuffer::Uniform3i(int32_t location, int32_t v0, int32_t v1,
                                int32_t v2) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Uniform3i(location_, v0_, v1_, v2_);
    }
    int32_t location_;
    int32_t v0_;
    int32_t v1_;
    int32_t v2_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->v0_ = v0;
  cmd->v1_ = v1;
  cmd->v2_ = v2;
}

void GLCommandBuffer::Uniform3iv(int32_t location, int32_t count,
                                 const int32_t* value) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Uniform3iv(location_, count_, value_.Data());
    }
    int32_t location_;
    int32_t count_;
    PackData<int32_t> value_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->count_ = count;
  cmd->value_ = PackData<int32_t>(value, count * 3);
}

void GLCommandBuffer::Uniform4f(int32_t location, float v0, float v1, float v2,
                                float v3) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Uniform4f(location_, v0_, v1_, v2_, v3_);
    }
    int32_t location_;
    float v0_;
    float v1_;
    float v2_;
    float v3_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->v0_ = v0;
  cmd->v1_ = v1;
  cmd->v2_ = v2;
  cmd->v3_ = v3;
}

void GLCommandBuffer::Uniform4fv(int32_t location, int32_t count,
                                 const float* value) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Uniform4fv(location_, count_, value_.Data());
    }
    int32_t location_;
    int32_t count_;
    PackData<float> value_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->count_ = count;
  cmd->value_ = PackData<float>(value, count * 4);
}

void GLCommandBuffer::Uniform4i(int32_t location, int32_t v0, int32_t v1,
                                int32_t v2, int32_t v3) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Uniform4i(location_, v0_, v1_, v2_, v3_);
    }
    int32_t location_;
    int32_t v0_;
    int32_t v1_;
    int32_t v2_;
    int32_t v3_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->v0_ = v0;
  cmd->v1_ = v1;
  cmd->v2_ = v2;
  cmd->v3_ = v3;
}

void GLCommandBuffer::Uniform4iv(int32_t location, int32_t count,
                                 const int32_t* value) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Uniform4iv(location_, count_, value_.Data());
    }
    int32_t location_;
    int32_t count_;
    PackData<int32_t> value_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->count_ = count;
  cmd->value_ = PackData<int32_t>(value, count * 4);
}

void GLCommandBuffer::UniformMatrix2fv(int32_t location, int32_t count,
                                       GLboolean transpose,
                                       const float* value) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::UniformMatrix2fv(location_, count_, transpose_, value_.Data());
    }
    int32_t location_;
    int32_t count_;
    GLboolean transpose_;
    PackData<float> value_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->count_ = count;
  cmd->transpose_ = transpose;
  cmd->value_ = PackData<float>(value, count * 4);
}

void GLCommandBuffer::UniformMatrix3fv(int32_t location, int32_t count,
                                       GLboolean transpose,
                                       const float* value) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::UniformMatrix3fv(location_, count_, transpose_, value_.Data());
    }
    int32_t location_;
    int32_t count_;
    GLboolean transpose_;
    PackData<float> value_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->count_ = count;
  cmd->transpose_ = transpose;
  cmd->value_ = PackData<float>(value, count * 9);
}

void GLCommandBuffer::UniformMatrix4fv(int32_t location, int32_t count,
                                       GLboolean transpose,
                                       const float* value) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::UniformMatrix4fv(location_, count_, transpose_, value_.Data());
    }
    int32_t location_;
    int32_t count_;
    GLboolean transpose_;
    PackData<float> value_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->location_ = location;
  cmd->count_ = count;
  cmd->transpose_ = transpose;
  cmd->value_ = PackData<float>(value, count * 16);
}

void GLCommandBuffer::UseProgram(uint32_t program) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::UseProgram(program_);
    }
    uint32_t program_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->program_ = program;
}

void GLCommandBuffer::ValidateProgram(uint32_t program) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::ValidateProgram(program_);
    }
    uint32_t program_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->program_ = program;
}

void GLCommandBuffer::VertexAttrib1F(uint32_t index, float x) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::VertexAttrib1f(index_, x_);
    }
    uint32_t index_;
    float x_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->index_ = index;
  cmd->x_ = x;
}

void GLCommandBuffer::VertexAttrib1Fv(uint32_t index, const float* v) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::VertexAttrib1fv(index_, v_.Data());
    }
    uint32_t index_;
    PackData<float> v_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->index_ = index;
  cmd->v_ = PackData<float>(v, 1);
}

void GLCommandBuffer::VertexAttrib2F(uint32_t index, float x, float y) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::VertexAttrib2f(index_, x_, y_);
    }
    uint32_t index_;
    float x_;
    float y_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->index_ = index;
  cmd->x_ = x;
  cmd->y_ = y;
}

void GLCommandBuffer::VertexAttrib2Fv(uint32_t index, const float* v) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::VertexAttrib2fv(index_, v_.Data());
    }
    uint32_t index_;
    PackData<float> v_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->index_ = index;
  cmd->v_ = PackData<float>(v, 2);
}

void GLCommandBuffer::VertexAttrib3F(uint32_t index, float x, float y,
                                     float z) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::VertexAttrib3f(index_, x_, y_, z_);
    }
    uint32_t index_;
    float x_;
    float y_;
    float z_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->index_ = index;
  cmd->x_ = x;
  cmd->y_ = y;
  cmd->z_ = z;
}

void GLCommandBuffer::VertexAttrib3Fv(uint32_t index, const float* v) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::VertexAttrib3fv(index_, v_.Data());
    }
    uint32_t index_;
    PackData<float> v_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->index_ = index;
  cmd->v_ = PackData<float>(v, 3);
}

void GLCommandBuffer::VertexAttrib4F(uint32_t index, float x, float y, float z,
                                     float w) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::VertexAttrib4f(index_, x_, y_, z_, w_);
    }
    uint32_t index_;
    float x_;
    float y_;
    float z_;
    float w_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->index_ = index;
  cmd->x_ = x;
  cmd->y_ = y;
  cmd->z_ = z;
  cmd->w_ = w;
}

void GLCommandBuffer::VertexAttrib4Fv(uint32_t index, const float* v) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::VertexAttrib4fv(index_, v_.Data());
    }
    uint32_t index_;
    PackData<float> v_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->index_ = index;
  cmd->v_ = PackData<float>(v, 4);
}

void GLCommandBuffer::VertexAttribPointer(uint32_t index, int32_t size,
                                          uint32_t type, GLboolean normalized,
                                          int32_t stride, const void* pointer) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::VertexAttribPointer(index_, size_, type_, normalized_, stride_,
                              pointer_);
    }
    uint32_t index_;
    int32_t size_;
    uint32_t type_;
    GLboolean normalized_;
    int32_t stride_;
    const void* pointer_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->index_ = index;
  cmd->size_ = size;
  cmd->type_ = type;
  cmd->normalized_ = normalized;
  cmd->stride_ = stride;
  cmd->pointer_ = pointer;
}

void GLCommandBuffer::Viewport(int32_t x, int32_t y, int32_t width,
                               int32_t height) {
  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      GL::Viewport(x_, y_, width_, height_);
    }
    int32_t x_;
    int32_t y_;
    int32_t width_;
    int32_t height_;
  };
  auto cmd = recorder_->Alloc<Runnable>();
  cmd->x_ = x;
  cmd->y_ = y;
  cmd->width_ = width;
  cmd->height_ = height;
}

}  // namespace canvas
}  // namespace lynx
