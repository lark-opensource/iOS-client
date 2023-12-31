// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_ANIMATION_ANIMATION_DELEGATE_H_
#define LYNX_ANIMATION_ANIMATION_DELEGATE_H_

#include <memory>
#include <queue>
#include <set>
#include <string>
#include <unordered_map>

#include "base/lynx_ordered_map.h"
#include "css/css_property.h"

namespace lynx {
namespace animation {

class Animation;
class AnimationDelegate {
 public:
  virtual ~AnimationDelegate() {}
  virtual void RequestNextFrame(std::weak_ptr<Animation> ptr){};
  virtual void UpdateFinalStyleMap(const tasm::StyleMap& styles){};
  virtual void FlushAnimatedStyle(){};
  virtual void SetNeedsAnimationStyleRecalc(const std::string& name){};
  virtual void NotifyClientAnimated(tasm::StyleMap& styles,
                                    tasm::CSSValue value,
                                    tasm::CSSPropertyID css_id){};
  tasm::Element* element() { return element_; }

 protected:
  std::queue<std::weak_ptr<Animation>> active_animations_;
  tasm::Element* element_{nullptr};
};

}  // namespace animation
}  // namespace lynx

#endif  // LYNX_ANIMATION_ANIMATION_DELEGATE_H_
