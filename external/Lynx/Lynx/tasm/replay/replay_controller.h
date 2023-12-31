// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REPLAY_REPLAY_CONTROLLER_H_
#define LYNX_TASM_REPLAY_REPLAY_CONTROLLER_H_

#include <map>
#include <string>

#include "base/base_export.h"

namespace lynx {

namespace lepus {
class Value;
}  // namespace lepus

namespace tasm {
namespace replay {

class ReplayController {
 public:
  BASE_EXPORT_FOR_DEVTOOL static bool Enable();
  BASE_EXPORT_FOR_DEVTOOL static void StartTest();
  BASE_EXPORT_FOR_DEVTOOL static void EndTest(const std::string& file_path);
  BASE_EXPORT_FOR_DEVTOOL static void SendFileByAgent(const std::string& type,
                                                      const std::string& file);

  static std::string ConvertEventInfo(const lepus::Value& info);
};
}  // namespace replay
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REPLAY_REPLAY_CONTROLLER_H_
