//  Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_RTC_DARWIN_H_
#define LYNX_KRYPTON_RTC_DARWIN_H_

#include "rtc/krypton_rtc_engine.h"

namespace lynx {
namespace canvas {
namespace rtc {

class RtcEngineDarwin : public RtcEngine {
 public:
  RtcEngineDarwin(const std::string& app_id);
  ~RtcEngineDarwin();

  void SetAudioEngine(std::weak_ptr<au::AudioEngine> audio_engine) override;
  void OnEventLogReport(const char* log_type, const char* log_content) override;
  void OnEventFirstAudioFrame() override;

 private:
  void StartAudioEngineCapture() override;
  void StopAudioEngineCapture() override;
  void PauseAudioEngine() override;
  void ResumeAudioEngine() override;
  void OnEnableAudioChanged(bool val) override;
  void DoStopAudioEngineCapture();

 private:
  std::weak_ptr<au::AudioEngine> weak_audio_engine_;
  bool engine_audio_enabled_{true};
};
}  // namespace rtc
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_RTC_DARWIN_H_
