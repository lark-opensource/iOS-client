//  Copyright 2023 The Lynx Authors. All rights reserved.

#include "rtc/krypton_rtc_engine.h"

#include "canvas/base/log.h"
#include "jsbridge/napi/callback_helper.h"
#include "rtc/krypton_rtc_helper.h"
#include "third_party/fml/make_copyable.h"

namespace lynx {
namespace canvas {

enum KryptonRtcInternalError {
  kRtcErrorCreateRtcEngineFailed = -100,
  kRtcErrorValidateRtcEngineNull = -101,
  kRtcErrorValidateIdMissMatch = -102,
  kRtcErrorChannelIdEmpty = -103,
  kRtcErrorUserIdEmpty = -104,
};

RtcEngine::~RtcEngine() {
  if (engine_) {
    bytertc::destroyRtcEngine(engine_);
    engine_ = nullptr;
  }

  if (event_handler_) {
    delete event_handler_;
    event_handler_ = nullptr;
  }
}

void RtcEngine::ResetEngine() {
  if (!canvas_app_ || app_id_.empty()) {
    KRYPTON_LOGE("ResetEngine error with state");
    return;
  }

  KRYPTON_LOGI("ResetEngine start ...");

  if (engine_) {
    bytertc::destroyRtcEngine(engine_);
    engine_ = nullptr;
  }

  if (!event_handler_) {
    event_handler_ = new rtc::RtcEventHandler(this);
  }

#if defined(ANDROID) || defined(__ANDROID__)
  auto context = rtc::RtcHelper::Instance().GetAppContext();
  if (!context) {
    KRYPTON_LOGE("ResetEngine get app context error");
    return;
  }
  bytertc::setApplicationContext((jobject)context);
  bytertc::setHardWareEncodeContext(nullptr);
#endif

  // https://console.volcengine.com/rtc/listRTC/appConfig?appId=635904e17322f50189512e61
  engine_ = bytertc::createRtcEngine(app_id_.c_str(), event_handler_, "");
  ++id_;

  if (engine_ != nullptr) {
    KRYPTON_LOGI("ResetEngine result true with id ") << id_;
  } else {
    KRYPTON_LOGE("ResetEngine createRtcEngine return null with id ") << id_;
    OnInternalError(kRtcErrorCreateRtcEngineFailed);
  }
}

void RtcEngine::OnWrapped() {
  KRYPTON_LOGI("ResetEngine OnWrapped ...");

  canvas_app_ = CanvasModule::From(Env())->GetCanvasApp();
  if (!instance_guard_) {
    instance_guard_ = InstanceGuard<RtcEngine>::CreateSharedGuard(this);
  }

  ResetEngine();
}

void RtcEngine::OnInternalError(int error) {
  if (event_handler_) {
    event_handler_->onError(error);
  }
}

bool RtcEngine::ValidateEngine(uint32_t id) {
  if (!engine_) {
    KRYPTON_LOGE("ValidateEngine error: engine null");
    OnInternalError(kRtcErrorValidateRtcEngineNull);
    return false;
  }

  if (id_ != id) {
    KRYPTON_LOGE("ValidateEngine error: id match ") << (id_ == id);
    OnInternalError(kRtcErrorValidateIdMissMatch);
    return false;
  }

  return true;
}

bool RtcEngine::JoinChannel(const std::string& channel_id,
                            const std::string& user_id,
                            const std::string& token) {
  if (!ValidateEngine(id_)) {
    KRYPTON_LOGW("JoinChannel ValidateEngine error: valid engine failed");
    return false;
  }

  if (channel_id.empty()) {
    KRYPTON_LOGW("JoinChannel ValidateEngine error: channel id empty");
    OnInternalError(kRtcErrorChannelIdEmpty);
    return false;
  }

  if (user_id.empty()) {
    KRYPTON_LOGW("JoinChannel ValidateEngine error: user id empty");
    OnInternalError(kRtcErrorUserIdEmpty);
    return false;
  }

  engine_->stopVideoCapture();

  PauseAudioEngine();

  engine_->setAudioPlayoutMixStream(true, 44100, 2);

  StartAudioEngineCapture();
  ResumeAudioEngine();

  bytertc::UserInfo info;
  info.uid = user_id.c_str();
  auto flag = engine_->joinRoom(token.c_str(), channel_id.c_str(), info,
                                bytertc::kRoomProfileTypeCommunication);
  return flag == 0;
}

bool RtcEngine::LeaveChannel() {
  if (!ValidateEngine(id_)) {
    return false;
  }

  engine_->setAudioPlayoutMixStream(false, 44100, 2);

  StopAudioEngineCapture();

  engine_->leaveRoom();
  return true;
}

bool RtcEngine::EnableLocalAudio() {
  if (!ValidateEngine(id_)) {
    return false;
  }

  PauseAudioEngine();
  engine_->startAudioCapture();
  ResumeAudioEngine();

  OnEnableAudioChanged(true);
  return true;
}

bool RtcEngine::DisableLocalAudio() {
  if (!ValidateEngine(id_)) {
    return false;
  }

  PauseAudioEngine();
  engine_->stopAudioCapture();
  ResumeAudioEngine();

  OnEnableAudioChanged(false);
  return true;
}

bool RtcEngine::MuteLocalAudioStream() {
  if (!ValidateEngine(id_)) {
    return false;
  }

  engine_->muteLocalAudio(bytertc::kMuteStateOn);
  return true;
}

bool RtcEngine::UnmuteLocalAudioStream() {
  if (!ValidateEngine(id_)) {
    return false;
  }

  engine_->muteLocalAudio(bytertc::kMuteStateOff);
  return true;
}

bool RtcEngine::MuteRemoteAudioStream(const std::string& user_id) {
  if (!ValidateEngine(id_)) {
    return false;
  }

  if (user_id.empty()) {
    OnInternalError(kRtcErrorUserIdEmpty);
    return false;
  }

  engine_->muteRemoteAudio(user_id.c_str(), bytertc::kMuteStateOn);
  return true;
}

bool RtcEngine::UnmuteRemoteAudioStream(const std::string& user_id) {
  if (!ValidateEngine(id_)) {
    return false;
  }

  if (user_id.empty()) {
    OnInternalError(kRtcErrorUserIdEmpty);
    return false;
  }

  engine_->muteRemoteAudio(user_id.c_str(), bytertc::kMuteStateOff);
  return true;
}

bool RtcEngine::MuteAllRemoteAudioStream() {
  if (!ValidateEngine(id_)) {
    return false;
  }

  engine_->muteAllRemoteAudio(bytertc::kMuteStateOn);
  return true;
}

bool RtcEngine::UnmuteAllRemoteAudioStream() {
  if (!ValidateEngine(id_)) {
    return false;
  }

  engine_->muteAllRemoteAudio(bytertc::kMuteStateOff);
  return true;
}

int32_t RtcEngine::AdjustVolumeParam(int32_t volume) {
  if (volume < 0) {
    return 0;
  }
  if (volume > 400) {
    return 400;
  }
  return volume;
}

bool RtcEngine::AdjustPlaybackSignalVolume(int32_t volume) {
  if (!ValidateEngine(id_)) {
    return false;
  }

  engine_->setPlaybackVolume(AdjustVolumeParam(volume));
  return true;
}

bool RtcEngine::AdjustRecordingSignalVolume(int32_t volume) {
  if (!ValidateEngine(id_)) {
    return false;
  }

  engine_->setRecordingVolume(AdjustVolumeParam(volume));
  return true;
}

bool RtcEngine::EnableAudioVolumeIndication(int32_t interval) {
  if (!ValidateEngine(id_)) {
    return false;
  }

  engine_->setAudioVolumeIndicationInterval(interval);
  return true;
}

void RtcEngine::DoSendEvent(const rtc::RtcEventInfo& info) {
  auto env = Env();
  Napi::ContextScope cscope(env);
  Napi::HandleScope hscope(env);
  auto event_str = rtc::RtcEventHandler::EventTypeString(info.GetEventType());
  auto callback_name = std::string("on") + event_str;
  if (!JsObject().Has(callback_name.c_str())) {
    return;
  }
  Napi::Value callback = JsObject()[callback_name.c_str()];
  if (!callback.IsFunction()) {
    return;
  }
  piper::CallbackHelper helper;
  Napi::Function callback_function = callback.As<Napi::Function>();
  if (!helper.PrepareForCall(callback_function)) {
    return;
  }

  auto napi_result = Napi::Object::New(env);
  auto params = info.GetParams();
  for (auto it = params.begin(); it != params.end(); ++it) {
    switch (it->type) {
      case rtc::RtcEventInfo::Param::Type::Int:
        napi_result.Set(it->key.c_str(), Napi::Number::New(env, it->int_val));
        break;
      case rtc::RtcEventInfo::Param::Type::Boolean:
        napi_result.Set(it->key.c_str(), Napi::Boolean::New(env, it->int_val));
        break;
      case rtc::RtcEventInfo::Param::Type::String:
        napi_result.Set(it->key.c_str(), Napi::String::New(env, it->str_val));
        break;
      default:
        break;
    }
  }
  helper.Call({napi_result});
}

void RtcEngine::SendEvent(rtc::RtcEventInfo info) {
  DCHECK(canvas_app_);
  auto weak_guard = std::weak_ptr<InstanceGuard<RtcEngine>>(instance_guard_);
  canvas_app_->runtime_task_runner()->PostTask(
      fml::MakeCopyable([weak_guard, info = std::move(info)]() mutable {
        auto shared_guard = weak_guard.lock();
        if (shared_guard) {
          shared_guard->Get()->DoSendEvent(info);
        }
      }));
}

}  // namespace canvas
}  // namespace lynx
