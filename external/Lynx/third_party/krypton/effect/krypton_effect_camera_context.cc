//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "krypton_effect_camera_context.h"

#include <pthread.h>

#include <string>

#include "bef_effect_public_face_define.h"
#include "krypton_effect.h"
#include "krypton_effect_resource_downloader.h"
#include "krypton_effect_video_context.h"
#include "third_party/fml/make_copyable.h"

namespace lynx {
namespace canvas {
namespace effect {

void RequestUserMediaWithEffectForCameraContext(
    const std::shared_ptr<CanvasApp>& canvas_app,
    std::unique_ptr<CameraOption> option,
    const CameraContext::UserMediaCallback& callback) {
#if TARGET_IPHONE_SIMULATOR
  callback(nullptr, "simulator not support");
  return;
#endif

  uint32_t effect_algorithms = option->effect_algorithms;
  KRYPTON_LOGI("request camera start");
  CameraContext::DoRequestUserMedia(
      canvas_app, std::move(option),
      [callback, canvas_app, effect_algorithms](
          std::unique_ptr<VideoContext> camera_impl,
          std::optional<std::string> err) mutable {
        KRYPTON_LOGI("request camera finished");

        if (err || !camera_impl) {
          KRYPTON_LOGI("request camera failed ") << err->c_str();
          callback(nullptr, err);
          return;
        }

        effect::InitAndPrepareResourceAsync(
            canvas_app, effect_algorithms,
            fml::MakeCopyable([callback, effect_algorithms, canvas_app,
                               camera = std::move(camera_impl)](
                                  std::optional<std::string> err) mutable {
              if (err || !camera) {
                callback(nullptr, err);
                return;
              }

              auto effect_video = std::make_unique<effect::EffectVideoContext>(
                  canvas_app, std::move(camera), effect_algorithms);
              callback(std::move(effect_video), {});
            }));
      });
}

uint32_t& InnerReadyAlgorithmsVar() {
  static uint32_t local_ready_algorithms = 0;
  return local_ready_algorithms;
}

uint32_t AlgorithmsCurrentlyReady() { return InnerReadyAlgorithmsVar(); }

void InitAndPrepareResourceAsync(
    const std::shared_ptr<CanvasApp>& canvas_app, uint32_t algorithms,
    std::function<void(std::optional<std::string> err)> callback) {
  DCHECK(callback);

  KRYPTON_LOGI("init effect start");
  if (!effect::InitEffect(canvas_app)) {
    KRYPTON_LOGI("init effect failed");
    callback("load effect symbols failed");
  } else {
    // download effect models and related resource
    KRYPTON_LOGI("prepare effect resource start");
    effect::EffectResourceDownloader::Instance()->PrepareEffectResource(
        algorithms, [callback, algorithms](std::optional<std::string> err) {
          if (!err) {
            InnerReadyAlgorithmsVar() |= algorithms;
          }
          callback(err);
        });
  }
}
}  // namespace effect
}  // namespace canvas
}  // namespace lynx
