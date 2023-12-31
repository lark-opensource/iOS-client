// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_IOS_PLATFORM_EXTRA_BUNDLE_DARWIN_H_
#define LYNX_TASM_REACT_IOS_PLATFORM_EXTRA_BUNDLE_DARWIN_H_

#include "tasm/react/platform_extra_bundle.h"

namespace lynx {
namespace tasm {

class PlatformExtraBundleDarwin : public PlatformExtraBundle {
 public:
  PlatformExtraBundleDarwin(int32_t signature,
                            PlatformExtraBundleHolder* holder, id bundle);

  ~PlatformExtraBundleDarwin() override = default;

  id PlatformBundle() { return platform_bundle; }

 private:
  id platform_bundle;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_IOS_PLATFORM_EXTRA_BUNDLE_DARWIN_H_
