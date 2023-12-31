// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_KRYPTON_GLUE_LYNX_CANVAS_RUNTIME_OBSERVER_H_
#define LYNX_KRYPTON_GLUE_LYNX_CANVAS_RUNTIME_OBSERVER_H_

#include "jsbridge/jsi/jsi.h"

namespace lynx {

namespace piper {
class NapiEnvironment;
}

namespace runtime {
class CanvasRuntimeObserver {
 public:
  CanvasRuntimeObserver() = default;
  virtual ~CanvasRuntimeObserver() = default;

  virtual void RuntimeInit(int64_t runtime_id) = 0;
  virtual void RuntimeDestroy() = 0;
  virtual void OnAppEnterForeground() = 0;
  virtual void OnAppEnterBackground() = 0;
  virtual void RuntimeAttach(piper::NapiEnvironment* env) = 0;
  virtual void RuntimeDetach() = 0;
};

}  // namespace runtime
}  // namespace lynx

#endif  // LYNX_KRYPTON_GLUE_LYNX_CANVAS_RUNTIME_OBSERVER_H_
