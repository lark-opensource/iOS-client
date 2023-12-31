// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_STARLIGHT_TYPES_LAYOUT_MEASUREFUNC_H_
#define LYNX_STARLIGHT_TYPES_LAYOUT_MEASUREFUNC_H_

#include "starlight/types/layout_constraints.h"

namespace lynx {
namespace starlight {

typedef FloatSize (*SLMeasureFunc)(void* context,
                                   const Constraints& constraints,
                                   bool final_measure);
typedef void (*SLAlignmentFunc)(void* context);

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_TYPES_LAYOUT_MEASUREFUNC_H_
