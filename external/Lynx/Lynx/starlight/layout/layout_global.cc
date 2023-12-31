// Copyright 2017 The Lynx Authors. All rights reserved.

#include "starlight/layout/layout_global.h"

bool IsSLDefiniteMode(SLMeasureMode mode) {
  return mode == SLMeasureModeDefinite;
}

bool IsSLIndefiniteMode(SLMeasureMode mode) {
  return mode == SLMeasureModeIndefinite;
}

bool IsSLAtMostMode(SLMeasureMode mode) { return mode == SLMeasureModeAtMost; }
