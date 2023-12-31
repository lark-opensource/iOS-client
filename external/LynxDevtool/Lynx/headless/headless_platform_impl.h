// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_HEADLESS_HEADLESS_PLATFORM_IMPL_H_
#define LYNX_HEADLESS_HEADLESS_PLATFORM_IMPL_H_

#include <string>
#include <vector>

#include "headless/headless_event_emitter.h"
#include "tasm/react/layout_context.h"
#include "tasm/react/layout_context_empty_implementation.h"
#include "tasm/react/painting_context_implementation.h"

namespace lynx {
namespace headless {

class PaintingContext : public tasm::PaintingContextPlatformImpl {
  void FinishTasmOperation(const tasm::PipelineOptions& options) override {
    if (options.has_patched) {
      headless::EventEmitter<decltype(this), std::string>::GetInstance()
          ->EmitSync(this, "OnPatchFinish", nullptr);
    } else {
      headless::EventEmitter<decltype(this), std::string>::GetInstance()
          ->EmitSync(this, "OnPatchFinishNoPatch", nullptr);
    }
  }
};

}  // namespace headless
}  // namespace lynx

#endif  // LYNX_HEADLESS_HEADLESS_PLATFORM_IMPL_H_
