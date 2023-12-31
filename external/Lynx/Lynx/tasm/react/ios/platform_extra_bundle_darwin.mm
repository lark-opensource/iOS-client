// Copyright 2022 The Lynx Authors. All rights reserved.

#include "tasm/react/ios/platform_extra_bundle_darwin.h"

namespace lynx {
namespace tasm {

PlatformExtraBundleDarwin::PlatformExtraBundleDarwin(int32_t signature,
                                                     PlatformExtraBundleHolder* holder, id bundle)
    : PlatformExtraBundle(signature, holder), platform_bundle(bundle) {}

}  // namespace tasm
}  // namespace lynx
