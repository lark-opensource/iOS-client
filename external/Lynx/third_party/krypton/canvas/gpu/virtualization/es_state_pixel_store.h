#ifndef CANVAS_GPU_VIRTUALIZATION_ES_STATE_PIXEL_STORE_H_
#define CANVAS_GPU_VIRTUALIZATION_ES_STATE_PIXEL_STORE_H_

#include "es_state_tracer.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
class EsStatePixelStore : public ESStateTracer {
 public:
  void Save() override;
  void SetCurrent() override;

 private:
  GLint pack_row_length_ = 0;
  GLint pack_skip_pixels_ = 0;
  GLint pack_skip_rows_ = 0;
  GLint pack_alignment_ = 4;
  GLint unpack_row_length_ = 0;
  GLint unpack_image_height_ = 0;
  GLint unpack_skip_pixels_ = 0;
  GLint unpack_skip_rows_ = 0;
  GLint unpack_skip_images_ = 0;
  GLint unpack_alignment_ = 4;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_VIRTUALIZATION_ES_STATE_PIXEL_STORE_H_
