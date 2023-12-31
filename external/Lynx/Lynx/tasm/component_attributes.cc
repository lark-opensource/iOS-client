// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/component_attributes.h"

namespace lynx {
namespace tasm {

const std::set<std::string>& ComponentAttributes::GetAttrNames() {
  const static base::NoDestructor<std::set<std::string>> kAttrNames{{
      "name",
      "style",
      "class",
      "flatten",
      "clip-radius",
      "consume-slide-event",
      "overlap",
      "user-interaction-enabled",
      "native-interaction-enabled",
      "block-native-event",
      "block-native-event-areas",
      "enableLayoutOnly",
      "cssAlignWithLegacyW3C",
      "intersection-observers",
      "trigger-global-event",
      "ios-enable-simultaneous-touch",
      "enable-new-animator",
      "enable-touch-pseudo-propagation",
      "exposure-scene",
      "exposure-id",
      "exposure-screen-margin-top",
      "exposure-screen-margin-bottom",
      "exposure-screen-margin-left",
      "exposure-screen-margin-right",
      "focusable",
      "focus-index",
      "accessibility-label",
      "accessibility-element",
      "accessibility-traits",
  }};
  return *kAttrNames;
}

}  // namespace tasm
}  // namespace lynx
