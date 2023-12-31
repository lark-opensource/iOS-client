// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_PLATFORM_EXTRA_BUNDLE_H_
#define LYNX_TASM_REACT_PLATFORM_EXTRA_BUNDLE_H_

#include <cstdint>

namespace lynx {
namespace tasm {

class PlatformExtraBundle;

class PlatformExtraBundleHolder {
 public:
  PlatformExtraBundleHolder() = default;
  virtual ~PlatformExtraBundleHolder() = default;
};

class PlatformExtraBundle {
 public:
  PlatformExtraBundle(int32_t signature, PlatformExtraBundleHolder *holder)
      : signature_(signature), holder_(holder) {}

  virtual ~PlatformExtraBundle() = default;

  int32_t Signature() const { return signature_; }

  PlatformExtraBundleHolder *Holder() const { return holder_; }

 private:
  int32_t signature_;
  PlatformExtraBundleHolder *holder_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_PLATFORM_EXTRA_BUNDLE_H_
