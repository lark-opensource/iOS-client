// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_BACKGROUND_DATA_H_
#define LYNX_STARLIGHT_STYLE_BACKGROUND_DATA_H_

#include <starlight/types/nlength.h>

#include <array>
#include <vector>

#include "lepus/value.h"
#include "starlight/style/css_type.h"

namespace lynx {
namespace starlight {

struct BackgroundData {
  BackgroundData();
  ~BackgroundData() = default;
  unsigned int color;
  unsigned int image_count;
  lepus::Value image;
  std::vector<NLength> position;
  std::vector<NLength> size;
  std::vector<BackgroundRepeatType> repeat;
  std::vector<BackgroundOriginType> origin;
  std::vector<BackgroundClipType> clip;
  bool HasBackground() const;
  bool operator==(const BackgroundData& rhs) const {
    return std::tie(color, image, image_count, position, size, repeat, origin,
                    clip) == std::tie(rhs.color, rhs.image, rhs.image_count,
                                      rhs.position, rhs.size, rhs.repeat,
                                      rhs.origin, rhs.clip);
  }
};
}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_BACKGROUND_DATA_H_
