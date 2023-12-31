// Copyright 2023 The Lynx Authors. All rights reserved.
// Copyright 2018 Airbnb, Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef ANIMAX_MODEL_MARKER_MODEL_H_
#define ANIMAX_MODEL_MARKER_MODEL_H_

#include <memory>
#include <string>

namespace lynx {
namespace animax {

class MarkerModel {
 public:
  MarkerModel(std::string name, float start_frame, float duration_frames)
      : name_(std::move(name)),
        start_frame_(start_frame),
        duration_frames_(duration_frames) {}
  ~MarkerModel() {}

  bool MatchesName(const std::string& name) {
    if (strcasecmp(name.c_str(), name_.c_str()) == 0) {
      return true;
    }
    // TODO(aiyongbiao): return protect p1
    return false;
  }

  std::string& GetName() { return name_; }
  float GetStartFrame() { return start_frame_; }
  float GetDurationFrames() { return duration_frames_; }

 private:
  std::string name_;
  float start_frame_;
  float duration_frames_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_MARKER_MODEL_H_
