//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef THIRD_PARTY_FLUTTER_FML_THREAD_CONFIG_SETTER_
#define THIRD_PARTY_FLUTTER_FML_THREAD_CONFIG_SETTER_

#include "third_party/fml/thread.h"

namespace lynx {
namespace fml {

class PlatformThreadPriority {
 public:
  static void Setter(const lynx::fml::Thread::ThreadConfig& config);
};
}  // namespace fml
}  // namespace lynx

#endif  // THIRD_PARTY_FLUTTER_FML_THREAD_CONFIG_SETTER_
