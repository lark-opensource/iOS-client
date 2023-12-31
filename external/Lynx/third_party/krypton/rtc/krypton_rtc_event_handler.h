//  Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_RTC_EVENT_HANDLER_H_
#define LYNX_KRYPTON_RTC_EVENT_HANDLER_H_

#if defined(KRYPTON_RTC_UNITTEST)
#include "rtc/krypton_rtc_unittest.h"
#elif defined(ANDROID) || defined(__ANDROID__)
#include <jni.h>

#include "bytertc_advance.h"
#include "bytertc_engine_interface.h"
#else
#include "VolcEngineRTC/native/rtc/bytertc_engine_interface.h"
#endif

#include <stdint.h>

#include <string>
#include <vector>

namespace lynx {
namespace canvas {
namespace rtc {

struct RtcEventInfo {
  RtcEventInfo(uint32_t type) : event_type_(type) {}
  struct Param {
    enum Type { String, Int, Boolean } type;
    int32_t int_val;
    std::string key, str_val;
  };
  void AddParam(const std::string& key, bool val = false) {
    params_.push_back({
        .type = Param::Boolean,
        .int_val = val,
        .key = key,
    });
  }
  void AddParam(const std::string& key, int32_t val) {
    params_.push_back({
        .type = Param::Int,
        .int_val = val,
        .key = key,
    });
  }
  void AddParam(const std::string& key, const char* val) {
    params_.push_back({
        .type = Param::String,
        .key = key,
        .str_val = (val ?: ""),
    });
  }
  const std::vector<Param>& GetParams() const { return params_; }
  uint32_t GetEventType() const { return event_type_; }

 private:
  uint32_t event_type_;
  std::vector<Param> params_;
};

class RtcEventDelegate {
 public:
  virtual void SendEvent(RtcEventInfo info) {}
  virtual void OnEventLogReport(const char* log_type, const char* log_content) {
  }
  virtual void OnEventFirstAudioFrame() {}
};

class RtcEventHandler : public bytertc::IRtcEngineEventHandler {
 public:
  RtcEventHandler(RtcEventDelegate* delegate);

  void onRoomStateChanged(const char* room_id, const char* uid, int state,
                          const char* extra_info) override;
  void onLeaveRoom(const bytertc::RtcRoomStats& stats) override;
  void onWarning(int warn) override;
  void onError(int err) override;
  void onAudioVolumeIndication(const bytertc::AudioVolumeInfo* speakers,
                               unsigned int speaker_number,
                               int total_remote_volume) override;
  void onLocalStreamStats(const bytertc::LocalStreamStats& stats) override;
  void onRemoteStreamStats(const bytertc::RemoteStreamStats& stats) override;
  void onUserJoined(const bytertc::UserInfo& user_info, int elapsed) override;
  void onUserLeave(const char* uid, bytertc::UserOfflineReason reason) override;
  void onUserStartAudioCapture(const char* user_id) override;
  void onUserStopAudioCapture(const char* user_id) override;
  void onUserMuteAudio(const char* user_id,
                       bytertc::MuteState mute_state) override;
  void onConnectionStateChanged(bytertc::ConnectionState state) override;
  void onFirstLocalAudioFrame(bytertc::StreamIndex index) override;
  void onFirstRemoteAudioFrame(const bytertc::RemoteStreamKey& key) override;
  void onLogReport(const char* log_type, const char* log_content) override;

  static const char* EventTypeString(uint32_t event_type);

 public:
  enum Type {
    ChannelStateChanged,
    LeaveChannel,
    NetworkQuality,
    UserJoined,
    ConnectionLost,
    ConnectionInterrupted,
    UserOffline,
    Warning,
    FirstLocalAudioFrame,
    FirstRemoteAudioFrame,
    UserMuteAudio,
    UserEnableAudio,
    UserEnableLocalAudio,
    Error,
    LogReport,
    AudioVolumeIndication
  };

 private:
  RtcEventDelegate* delegate_;
  std::string uid_;
};

}  // namespace rtc
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_RTC_EVENT_HANDLER_H_
