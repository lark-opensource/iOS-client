//  Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_RTC_ENGINE_H_
#define LYNX_KRYPTON_RTC_ENGINE_H_

#include "canvas/canvas_app.h"
#include "canvas/event_target.h"
#include "canvas/instance_guard.h"
#include "jsbridge/napi/base.h"
#include "rtc/krypton_rtc_event_handler.h"

namespace bytertc {
class IRtcEngine;
}

namespace lynx {
namespace canvas {
namespace au {
class AudioEngine;
}

using piper::BridgeBase;
using piper::ImplBase;

class RtcEngine : public ImplBase, public rtc::RtcEventDelegate {
 public:
  static RtcEngine* CreateInstance(const std::string& app_id);
  RtcEngine(const std::string& app_id) : app_id_(app_id) {}
  virtual ~RtcEngine();

  const std::string& GetAppId() const { return app_id_; }
  bool JoinChannel(const std::string& channel_id, const std::string& user_id,
                   const std::string& token);
  bool LeaveChannel();
  bool EnableLocalAudio();
  bool DisableLocalAudio();
  bool MuteLocalAudioStream();
  bool UnmuteLocalAudioStream();
  bool MuteRemoteAudioStream(const std::string& user_id);
  bool UnmuteRemoteAudioStream(const std::string& user_id);
  bool MuteAllRemoteAudioStream();
  bool UnmuteAllRemoteAudioStream();
  bool AdjustPlaybackSignalVolume(int32_t volume);
  bool AdjustRecordingSignalVolume(int32_t volume);
  bool EnableAudioVolumeIndication(int32_t interval);

  virtual void SetAudioEngine(std::weak_ptr<au::AudioEngine>) {}

  void SendEvent(rtc::RtcEventInfo info) override;

 protected:
  virtual void StartAudioEngineCapture() {}
  virtual void StopAudioEngineCapture() {}
  virtual void PauseAudioEngine() {}
  virtual void ResumeAudioEngine() {}
  virtual void OnEnableAudioChanged(bool val) {}

 private:
  void OnInternalError(int error);
  void OnWrapped() override;
  void DoSendEvent(const rtc::RtcEventInfo& info);
  int32_t AdjustVolumeParam(int32_t volume);
  void ResetEngine();
  bool ValidateEngine(uint32_t id);

 protected:
  uint32_t id_;
  std::string app_id_;
  bytertc::IRtcEngine* engine_{nullptr};
  rtc::RtcEventHandler* event_handler_{nullptr};
  std::shared_ptr<CanvasApp> canvas_app_{nullptr};
  std::shared_ptr<InstanceGuard<RtcEngine>> instance_guard_{nullptr};
};

}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_RTC_ENGINE_H_
