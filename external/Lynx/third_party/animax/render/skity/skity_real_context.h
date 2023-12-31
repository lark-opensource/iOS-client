// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKITY_SKITY_REAL_CONTEXT_H_
#define ANIMAX_RENDER_SKITY_SKITY_REAL_CONTEXT_H_

#include "animax/render/include/real_context.h"
#include "skity/skity.hpp"

namespace skity {
class RenderContext;
}

namespace lynx {
namespace animax {

class SkityRealContext : public RealContext {
 public:
  SkityRealContext(skity::RenderContext *context) : context_(context) {}
  ~SkityRealContext() override = default;
  skity::RenderContext *Get() const { return context_; }

 private:
  skity::RenderContext *context_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKITY_SKITY_REAL_CONTEXT_H_
