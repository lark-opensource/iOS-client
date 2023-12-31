// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_BASE_SCREEN_METADATA_H_
#define LYNX_INSPECTOR_BASE_SCREEN_METADATA_H_

#include <string>
#include <vector>

namespace lynxdev {
namespace devtool {

struct ScreenMetadata {
  /* data */
  ScreenMetadata()
      : offset_top_(0),
        page_scale_factor_(1),
        device_width_(0),
        device_height_(0),
        scroll_off_set_x_(0),
        scroll_off_set_y_(0),
        timestamp_(0) {}
  float offset_top_;
  float page_scale_factor_;
  float device_width_;
  float device_height_;
  float scroll_off_set_x_;
  float scroll_off_set_y_;
  float timestamp_;
};

struct ScreenRequest {
  std::string format_;
  int max_height_;
  int max_width_;
  int quality_;
  int every_nth_frame_;
};

}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_INSPECTOR_BASE_SCREEN_METADATA_H_
