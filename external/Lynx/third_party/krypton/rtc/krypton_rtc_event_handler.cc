//  Copyright 2023 The Lynx Authors. All rights reserved.

#include "rtc/krypton_rtc_event_handler.h"

#include "base/json/json_util.h"
#include "base/string/string_number_convert.h"
#include "canvas/base/log.h"

namespace lynx {
namespace canvas {
namespace rtc {

RtcEventHandler::RtcEventHandler(RtcEventDelegate* delegate)
    : delegate_(delegate) {
  DCHECK(delegate_ != nullptr);
}

static bool GetIntValueFromJson(rapidjson::Document& info, const char* key,
                                int32_t& result) {
  if (!info.HasMember(key)) {
    return false;
  }

  auto& value = info[key];
  if (!value.IsLosslessDouble()) {
    return false;
  }

  result = static_cast<int32_t>(value.GetDouble());
  return true;
}

void RtcEventHandler::onRoomStateChanged(const char* room_id, const char* uid,
                                         int state, const char* extra_info) {
  uid_ = uid ?: "";

  RtcEventInfo info(ChannelStateChanged);
  info.AddParam("cid", room_id);
  info.AddParam("uid", uid_.c_str());
  info.AddParam("state", state);

  if (extra_info) {
    rapidjson::Document extra = base::strToJson(extra_info);
    if (!extra.HasParseError()) {
      int join_type = 0, elapsed = 0;
      if (GetIntValueFromJson(extra, "join_type", join_type)) {
        info.AddParam("join_type", join_type);
      }
      if (GetIntValueFromJson(extra, "elapsed", elapsed)) {
        info.AddParam("elapsed", elapsed);
      }
    }
  }

  delegate_->SendEvent(std::move(info));
}

void RtcEventHandler::onLeaveRoom(const bytertc::RtcRoomStats& stats) {
  RtcEventInfo info(LeaveChannel);
  info.AddParam("uid", uid_.c_str());
  delegate_->SendEvent(std::move(info));
}

void RtcEventHandler::onConnectionStateChanged(bytertc::ConnectionState state) {
  if (state == bytertc::kConnectionStateLost) {
    delegate_->SendEvent(RtcEventInfo(ConnectionLost));
    return;
  }
  if (state == bytertc::kConnectionStateDisconnected) {
    delegate_->SendEvent(RtcEventInfo(ConnectionInterrupted));
    return;
  }
}

void RtcEventHandler::onLocalStreamStats(
    const bytertc::LocalStreamStats& stats) {
  RtcEventInfo info(NetworkQuality);
  info.AddParam("uid", uid_.c_str());
  info.AddParam("txQuality", int32_t(stats.local_tx_quality));
  info.AddParam("rxQuality", int32_t(stats.local_rx_quality));
  delegate_->SendEvent(std::move(info));
}

void RtcEventHandler::onRemoteStreamStats(
    const bytertc::RemoteStreamStats& stats) {
  RtcEventInfo info(NetworkQuality);
  info.AddParam("uid", stats.uid);
  info.AddParam("txQuality", int32_t(stats.remote_tx_quality));
  info.AddParam("rxQuality", int32_t(stats.remote_rx_quality));
  delegate_->SendEvent(std::move(info));
}

void RtcEventHandler::onUserJoined(const bytertc::UserInfo& user_info,
                                   int elapsed) {
  RtcEventInfo info(UserJoined);
  info.AddParam("uid", user_info.uid);
  info.AddParam("elapsed", elapsed);
  delegate_->SendEvent(std::move(info));
}

void RtcEventHandler::onUserLeave(const char* uid,
                                  bytertc::UserOfflineReason reason) {
  RtcEventInfo info(UserOffline);
  info.AddParam("uid", uid);
  info.AddParam("reason", int32_t(reason));
  delegate_->SendEvent(std::move(info));
}

void RtcEventHandler::onWarning(int warn) {
  RtcEventInfo info(Warning);
  info.AddParam("warn", warn);
  delegate_->SendEvent(std::move(info));
}

void RtcEventHandler::onFirstLocalAudioFrame(bytertc::StreamIndex index) {
  delegate_->OnEventFirstAudioFrame();
  RtcEventInfo info(FirstLocalAudioFrame);
  info.AddParam("index", int32_t(index));
  delegate_->SendEvent(std::move(info));
}

void RtcEventHandler::onFirstRemoteAudioFrame(
    const bytertc::RemoteStreamKey& key) {
  delegate_->OnEventFirstAudioFrame();
  RtcEventInfo info(FirstRemoteAudioFrame);
  info.AddParam("uid", key.user_id);
  info.AddParam("index", int32_t(key.stream_index));
  delegate_->SendEvent(std::move(info));
}

void RtcEventHandler::onLogReport(const char* log_type,
                                  const char* log_content) {
  KRYPTON_LOGI("OnRtcEngineLogReport ")
      << (log_type ?: "") << " : " << (log_content ?: "");
  delegate_->OnEventLogReport(log_type, log_content);
  RtcEventInfo info(LogReport);
  info.AddParam("type", log_type);
  info.AddParam("content", log_content);
  delegate_->SendEvent(std::move(info));
}

void RtcEventHandler::onUserMuteAudio(const char* user_id,
                                      bytertc::MuteState mute_state) {
  RtcEventInfo info(UserMuteAudio);
  info.AddParam("uid", user_id);
  info.AddParam("muted", bool(mute_state));
  delegate_->SendEvent(std::move(info));
}

void RtcEventHandler::onUserStartAudioCapture(const char* user_id) {
  RtcEventInfo info(UserEnableLocalAudio);
  info.AddParam("uid", user_id);
  info.AddParam("enabled", true);
  delegate_->SendEvent(std::move(info));
}

void RtcEventHandler::onUserStopAudioCapture(const char* user_id) {
  RtcEventInfo info(UserEnableLocalAudio);
  info.AddParam("uid", user_id);
  info.AddParam("enabled", false);
  delegate_->SendEvent(std::move(info));
}

void RtcEventHandler::onError(int err) {
  RtcEventInfo info(Error);
  info.AddParam("err", err);
  delegate_->SendEvent(std::move(info));
}

void RtcEventHandler::onAudioVolumeIndication(
    const bytertc::AudioVolumeInfo* speakers, unsigned int speaker_number,
    int total_remote_volume) {
  for (unsigned int i = 0; i < speaker_number; ++i) {
    RtcEventInfo info(AudioVolumeIndication);
    info.AddParam("uid", speakers[i].uid);
    info.AddParam("speakerNumber", int32_t(speaker_number));
    info.AddParam("linearVolume", int32_t(speakers[i].linear_volume));
    info.AddParam("nonlinearVolume", int32_t(speakers[i].nonlinear_volume));
    delegate_->SendEvent(std::move(info));
  }
}

const char* RtcEventHandler::EventTypeString(uint32_t event_type) {
  switch (event_type) {
    case ChannelStateChanged:
      return "ChannelStateChanged";
    case LeaveChannel:
      return "LeaveChannel";
    case NetworkQuality:
      return "NetworkQuality";
    case UserJoined:
      return "UserJoined";
    case ConnectionLost:
      return "ConnectionLost";
    case ConnectionInterrupted:
      return "ConnectionInterrupted";
    case UserOffline:
      return "UserOffline";
    case Warning:
      return "Warning";
    case FirstLocalAudioFrame:
      return "FirstLocalAudioFrame";
    case FirstRemoteAudioFrame:
      return "FirstRemoteAudioFrame";
    case UserMuteAudio:
      return "UserMuteAudio";
    case UserEnableAudio:
      return "UserEnableAudio";
    case UserEnableLocalAudio:
      return "UserEnableLocalAudio";
    case Error:
      return "Error";
    case LogReport:
      return "LogReport";
    case AudioVolumeIndication:
      return "AudioVolumeIndication";
    default:
      return "UnknownEvent";
  }
}

}  // namespace rtc
}  // namespace canvas
}  // namespace lynx
