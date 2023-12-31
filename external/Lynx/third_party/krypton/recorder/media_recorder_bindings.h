//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef KRYPTON_MEDIA_RECORDER_BINDINGS_H_
#define KRYPTON_MEDIA_RECORDER_BINDINGS_H_

#include "jsbridge/napi/base.h"

namespace lynx {
namespace canvas {
namespace recorder {

void RegisterMediaRecorderBindings(Napi::Object& obj);

}  // namespace recorder
}  // namespace canvas
}  // namespace lynx

#endif /* KRYPTON_MEDIA_RECORDER_BINDINGS_H_ */
