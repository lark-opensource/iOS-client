//  Copyright 2023 The Lynx Authors. All rights reserved.

#include "rtc/darwin/krypton_rtc_darwin.h"
#include <memory>
#include "canvas/base/scoped_cftypedref.h"
#include "config/config.h"
#include "rtc/krypton_rtc_helper_impl.h"
#if ENABLE_KRYPTON_AURUM
#include "aurum/audio_engine.h"
#endif

namespace lynx {
namespace canvas {

RtcEngine* RtcEngine::CreateInstance(const std::string& app_id) {
  return new rtc::RtcEngineDarwin(app_id);
}

namespace rtc {
RtcHelper& RtcHelper::Instance() {
  static RtcHelperImpl helper;
  return helper;
}

RtcEngineDarwin::RtcEngineDarwin(const std::string& app_id) : RtcEngine(app_id) {
  KRYPTON_CONSTRUCTOR_LOG(RtcEngineDarwin);
}

RtcEngineDarwin::~RtcEngineDarwin() {
  KRYPTON_DESTRUCTOR_LOG(RtcEngineDarwin);

  DoStopAudioEngineCapture();
}

void RtcEngineDarwin::SetAudioEngine(std::weak_ptr<au::AudioEngine> audio_engine) {
#if ENABLE_KRYPTON_AURUM
  weak_audio_engine_ = audio_engine;
#endif
}

void RtcEngineDarwin::StartAudioEngineCapture() {
#if ENABLE_KRYPTON_AURUM
  auto audio_engine = weak_audio_engine_.lock();
  if (audio_engine && audio_engine->IsRunning()) {
    audio_engine->OnCaptureStart();
  }
#endif
}

inline void RtcEngineDarwin::DoStopAudioEngineCapture() {
#if ENABLE_KRYPTON_AURUM
  auto audio_engine = weak_audio_engine_.lock();
  if (audio_engine && audio_engine->IsRunning()) {
    audio_engine->OnCaptureStop();
  }
#endif
}

void RtcEngineDarwin::StopAudioEngineCapture() { DoStopAudioEngineCapture(); }

void RtcEngineDarwin::PauseAudioEngine() {
#if ENABLE_KRYPTON_AURUM
  auto audio_engine = weak_audio_engine_.lock();
  if (audio_engine && audio_engine->IsRunning()) {
    audio_engine->Pause();
  }
#endif
}

void RtcEngineDarwin::ResumeAudioEngine() {
#if ENABLE_KRYPTON_AURUM
  auto audio_engine = weak_audio_engine_.lock();
  if (audio_engine && audio_engine->IsRunning()) {
    audio_engine->Resume();
  }
#endif
}

void RtcEngineDarwin::OnEnableAudioChanged(bool val) { engine_audio_enabled_ = val; }

void RtcEngineDarwin::OnEventLogReport(const char* log_type, const char* log_content) {
  //  if (strstr(log_content, "\"sdk_api_name\":\"leaveRoom\"") != nullptr) {
  //    PauseAudioEngine();
  //  }
  if (strstr(log_content, "\"signaling_event\":\"leaveRoom\"") != nullptr) {
    StopAudioEngineCapture();
    ResumeAudioEngine();
  }

  if (strstr(log_content, "Failed to setActive:") != nullptr && engine_audio_enabled_) {
    StartAudioEngineCapture();
    ResumeAudioEngine();
  }
}

void RtcEngineDarwin::OnEventFirstAudioFrame() {
  StartAudioEngineCapture();
  ResumeAudioEngine();
}

}  // namespace rtc
}  // namespace canvas
}  // namespace lynx
