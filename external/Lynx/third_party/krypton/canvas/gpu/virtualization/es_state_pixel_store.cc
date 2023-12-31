
#include "es_state_pixel_store.h"

#include "canvas/base/log.h"
namespace lynx {
namespace canvas {

void EsStatePixelStore::Save() {
  ::glGetIntegerv(GL_PACK_ROW_LENGTH, &pack_row_length_);
  ::glGetIntegerv(GL_PACK_SKIP_PIXELS, &pack_skip_pixels_);
  ::glGetIntegerv(GL_PACK_SKIP_ROWS, &pack_skip_rows_);
  ::glGetIntegerv(GL_PACK_ALIGNMENT, &pack_alignment_);
  ::glGetIntegerv(GL_UNPACK_ROW_LENGTH, &unpack_row_length_);
  ::glGetIntegerv(GL_UNPACK_IMAGE_HEIGHT, &unpack_image_height_);
  ::glGetIntegerv(GL_UNPACK_SKIP_PIXELS, &unpack_skip_pixels_);
  ::glGetIntegerv(GL_UNPACK_SKIP_ROWS, &unpack_skip_rows_);
  ::glGetIntegerv(GL_UNPACK_SKIP_IMAGES, &unpack_skip_images_);
  ::glGetIntegerv(GL_UNPACK_ALIGNMENT, &unpack_alignment_);
  DCHECK(::glGetError() == GL_NO_ERROR);
}

void EsStatePixelStore::SetCurrent() {
  ::glPixelStorei(GL_PACK_ROW_LENGTH, pack_row_length_);
  ::glPixelStorei(GL_PACK_SKIP_PIXELS, pack_skip_pixels_);
  ::glPixelStorei(GL_PACK_SKIP_ROWS, pack_skip_rows_);
  ::glPixelStorei(GL_PACK_ALIGNMENT, pack_alignment_);
  ::glPixelStorei(GL_UNPACK_ROW_LENGTH, unpack_row_length_);
  ::glPixelStorei(GL_UNPACK_IMAGE_HEIGHT, unpack_image_height_);
  ::glPixelStorei(GL_UNPACK_SKIP_PIXELS, unpack_skip_pixels_);
  ::glPixelStorei(GL_UNPACK_SKIP_ROWS, unpack_skip_rows_);
  ::glPixelStorei(GL_UNPACK_SKIP_IMAGES, unpack_skip_images_);
  ::glPixelStorei(GL_UNPACK_ALIGNMENT, unpack_alignment_);
  DCHECK(::glGetError() == GL_NO_ERROR);
}

}  // namespace canvas
}  // namespace lynx
