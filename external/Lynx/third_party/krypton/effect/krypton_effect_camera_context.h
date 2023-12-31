//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_EFFECT_CAMERA_CONTEXT_H
#define LYNX_KRYPTON_EFFECT_CAMERA_CONTEXT_H

#include "canvas/platform/camera_context.h"
#include "effect/krypton_effect_wrapper.h"
#include "krypton_effect_output_struct.h"

namespace lynx {
namespace canvas {
namespace effect {

extern uint32_t AlgorithmsCurrentlyReady();

extern void InitAndPrepareResourceAsync(
    const std::shared_ptr<CanvasApp>& canvas_app, uint32_t algorithms,
    std::function<void(std::optional<std::string> err)> callback);

extern void RequestUserMediaWithEffectForCameraContext(
    const std::shared_ptr<CanvasApp>& canvas_app,
    std::unique_ptr<CameraOption> option,
    const CameraContext::UserMediaCallback& callback);

}  // namespace effect
}  // namespace canvas
}  // namespace lynx

#endif /* LYNX_KRYPTON_EFFECT_CAMERA_CONTEXT_H */
