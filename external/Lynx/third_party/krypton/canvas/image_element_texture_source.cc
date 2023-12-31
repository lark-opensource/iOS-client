// Copyright 2022 The Lynx Authors. All rights reserved.

#include "canvas/image_element_texture_source.h"

#include "canvas/gpu/gl/scoped_gl_reset_restore.h"

namespace lynx {
namespace canvas {

class ScopedPixelStoreiResetRestore {
 public:
  ScopedPixelStoreiResetRestore() {
    GL::GetIntegerv(GL_UNPACK_ROW_LENGTH, &unpack_row_length_);
    GL::GetIntegerv(GL_UNPACK_IMAGE_HEIGHT, &unpack_image_height_);
    GL::GetIntegerv(GL_UNPACK_SKIP_ROWS, &unpack_skip_rows_);
    GL::GetIntegerv(GL_UNPACK_SKIP_PIXELS, &unpack_skip_pixels_);
    GL::GetIntegerv(GL_UNPACK_SKIP_IMAGES, &unpack_skip_images_);
    GL::GetIntegerv(GL_UNPACK_ALIGNMENT, &unpack_alignment_);
  }

  ~ScopedPixelStoreiResetRestore() {
    GL::PixelStorei(GL_UNPACK_ROW_LENGTH, unpack_row_length_);
    GL::PixelStorei(GL_UNPACK_IMAGE_HEIGHT, unpack_image_height_);
    GL::PixelStorei(GL_UNPACK_SKIP_ROWS, unpack_skip_rows_);
    GL::PixelStorei(GL_UNPACK_SKIP_PIXELS, unpack_skip_pixels_);
    GL::PixelStorei(GL_UNPACK_SKIP_IMAGES, unpack_skip_images_);
    GL::PixelStorei(GL_UNPACK_ALIGNMENT, unpack_alignment_);
  }

 private:
  GLint unpack_row_length_{0};
  GLint unpack_image_height_{0};
  GLint unpack_skip_rows_{0};
  GLint unpack_skip_pixels_{0};
  GLint unpack_skip_images_{0};
  GLint unpack_alignment_{1};
};

ImageElementTextureSource::~ImageElementTextureSource() {
  if (tex_) {
    GL::DeleteTextures(1, &tex_);
  }
};

uint32_t ImageElementTextureSource::Texture() {
  if (!bitmap_) {
    return 0;
  }
  if (!tex_) {
    ScopedGLResetRestore s(GL_TEXTURE_BINDING_2D);
    GL::GenTextures(1, &tex_);
    GL::BindTexture(GL_TEXTURE_2D, tex_);
    GL::TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    GL::TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    GL::TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    GL::TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    /// When calling TexImage2D during the drawImage process,
    /// we need to consider the pixelStore set by nanovg,
    /// otherwise it may cause the OpenGL driver to unpack
    /// texture data in a wrong way, triggering a crash
    ScopedPixelStoreiResetRestore protect_pixelstore_;
    GL::PixelStorei(GL_UNPACK_ROW_LENGTH, bitmap_->Width());
    GL::PixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
    GL::PixelStorei(GL_UNPACK_SKIP_ROWS, 0);
    GL::TexImage2D(GL_TEXTURE_2D, 0, bitmap_->Format(), bitmap_->Width(),
                   bitmap_->Height(), 0, bitmap_->Format(), bitmap_->Type(),
                   bitmap_->Pixels());
  }

  return tex_;
};

uint32_t ImageElementTextureSource::reading_fbo() {
  if (!fb_) {
    uint32_t tex = Texture();
    fb_ = std::make_unique<Framebuffer>(tex);
    if (fb_->InitOnGPUIfNeed()) {
      KRYPTON_LOGE("framebuffer init failed");
      return 0;
    }
  }
  return fb_->Fbo();
}

}  // namespace canvas
}  // namespace lynx
