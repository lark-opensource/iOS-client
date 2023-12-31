// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/recorder/recorder_controller.h"

#include <sstream>
#include <utility>

namespace lynx {
namespace tasm {
namespace recorder {

bool RecorderController::Enable() {
#if ENABLE_ARK_RECORDER
  return true;
#else
  return false;
#endif
}

void RecorderController::StartRecord(std::string& filter_url) {
#if ENABLE_ARK_RECORDER
  lynx::tasm::recorder::ArkBaseRecorder::GetInstance().StartRecord(filter_url);
#endif
}

void RecorderController::EndRecord(
    base::MoveOnlyClosure<void, std::vector<std::string>&,
                          std::vector<int64_t>&>
        send_complete) {
#if ENABLE_ARK_RECORDER
  lynx::tasm::recorder::ArkBaseRecorder::GetInstance().EndRecord(
      std::move(send_complete));
#endif
}

void RecorderController::InitConfig(const std::string& path, int64_t session_id,
                                    float screen_width, float screen_height,
                                    int64_t record_id) {
#if ENABLE_ARK_RECORDER
  lynx::tasm::recorder::ArkBaseRecorder::GetInstance().AddLynxViewSessionID(
      record_id, session_id);
  lynx::tasm::recorder::ArkBaseRecorder::GetInstance().SetRecorderPath(path);
  lynx::tasm::recorder::ArkBaseRecorder::GetInstance().SetScreenSize(
      record_id, screen_width, screen_height);
#endif
}

void RecorderController::RecordResource(const char* url, const char* source) {
#if ENABLE_ARK_RECORDER
  lynx::tasm::recorder::ArkBaseRecorder::GetInstance().RecordResource(url,
                                                                      source);
#endif
}

void* RecorderController::GetArkBaseRecorderInstance() {
#if ENABLE_ARK_RECORDER
  return static_cast<void*>(
      &lynx::tasm::recorder::ArkBaseRecorder::GetInstance());
#else
  return nullptr;
#endif
}

}  // namespace recorder
}  // namespace tasm
}  // namespace lynx
