// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_RECORDER_RECORDER_CONTROLLER_H_
#define LYNX_TASM_RECORDER_RECORDER_CONTROLLER_H_

#include <functional>
#include <map>
#include <string>
#include <vector>

#include "base/base_export.h"
#include "base/closure.h"
#include "config/config.h"

#if defined(ENABLE_ARK_RECORDER) && ENABLE_ARK_RECORDER
#include "tasm/recorder/ark_base_recorder.h"
#include "tasm/recorder/list_node_recorder.h"
#include "tasm/recorder/lynxview_init_recorder.h"
#include "tasm/recorder/native_module_recorder.h"
#include "tasm/recorder/template_assembler_recorder.h"
#endif

namespace lynx {
namespace tasm {
namespace recorder {

class RecorderController {
 public:
  BASE_EXPORT_FOR_DEVTOOL static bool Enable();
  BASE_EXPORT_FOR_DEVTOOL static void StartRecord(std::string& filter_url);
  BASE_EXPORT_FOR_DEVTOOL static void EndRecord(
      base::MoveOnlyClosure<void, std::vector<std::string>&,
                            std::vector<int64_t>&>
          send_complete);
  BASE_EXPORT_FOR_DEVTOOL static void InitConfig(const std::string& path,
                                                 int64_t session_id,
                                                 float screen_width,
                                                 float screen_height,
                                                 int64_t record_id);
  BASE_EXPORT_FOR_DEVTOOL static void RecordResource(const char* url,
                                                     const char* source);
  BASE_EXPORT_FOR_DEVTOOL static void* GetArkBaseRecorderInstance();
};
}  // namespace recorder
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RECORDER_RECORDER_CONTROLLER_H_
