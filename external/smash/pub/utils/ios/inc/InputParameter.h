#ifndef __SMASH_INPUT_PARAMETER__
#define __SMASH_INPUT_PARAMETER__
#include <mobilecv2/core.hpp>
#include <vector>
namespace smash {
typedef struct InputParameter {
  unsigned int image_height = 0;
  unsigned int image_width = 0;
  unsigned int extendedWidth = 0;
  unsigned long long detection_config = 0;
  unsigned int pixel_format = 0;
  unsigned int rotation = 0;

  explicit InputParameter() {}
  explicit InputParameter(unsigned int image_height,
                          unsigned int image_width,
                          unsigned int extendedWidth,
                          unsigned int detection_config,
                          unsigned int pixel_format,
                          unsigned int rotation)
      : image_height(image_height),
        image_width(image_width),
        extendedWidth(extendedWidth),
        detection_config(detection_config),
        pixel_format(pixel_format),
        rotation(rotation) {}
} InputParameter;

}  // namespace smash
#endif
