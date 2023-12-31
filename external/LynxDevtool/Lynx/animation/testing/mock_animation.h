// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_ANIMATION_TESTING_MOCK_ANIMATION_H_
#define LYNX_ANIMATION_TESTING_MOCK_ANIMATION_H_

#include <memory>
#include <string>
#include <unordered_set>

#include "animation/animation.h"
#include "animation/keyframe_effect.h"
#include "third_party/fml/time/time_point.h"

namespace lynx {

namespace animation {

class MockAnimation : public Animation {
 public:
  MockAnimation(const std::string& name) : Animation(name) {}
  ~MockAnimation() = default;
  const fml::TimePoint& start_time() { return start_time_; }
};

}  // namespace animation
}  // namespace lynx

#endif  // LYNX_ANIMATION_TESTING_MOCK_ANIMATION_H_
