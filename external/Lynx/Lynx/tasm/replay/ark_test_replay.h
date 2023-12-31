// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REPLAY_ARK_TEST_REPLAY_H_
#define LYNX_TASM_REPLAY_ARK_TEST_REPLAY_H_

#include <map>
#include <memory>
#include <string>
#include <vector>

#include "base/base_export.h"
#include "base/no_destructor.h"
#include "inspector/inspector_manager.h"

namespace lynx {
namespace tasm {
namespace replay {

class ArkTestReplay {
 public:
  static constexpr uint32_t kFileDataBufferSize = 65536;

  static ArkTestReplay& GetInstance();

  void SendJsonFile(const char* name, std::string& json);

  void SendFileByAgent(const std::string& type, const std::string& file);

  void SetInspectorManager(std::shared_ptr<devtool::InspectorManager> ptr);

  void StartTest();

  void EndTest(const std::string& file_path);

  bool IsStart() { return is_start_; }

 private:
  void SaveDumpFile(const std::string& filename);
  friend base::NoDestructor<ArkTestReplay>;
  ArkTestReplay() = default;
  ~ArkTestReplay() = default;
  ArkTestReplay(const ArkTestReplay&) = delete;
  ArkTestReplay& operator=(const ArkTestReplay&) = delete;

  bool is_start_ = false;
  std::map<std::string, std::vector<std::string>> dump_file_;
  std::weak_ptr<devtool::InspectorManager> inspector_manager_wp_;
};

}  // namespace replay
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REPLAY_ARK_TEST_REPLAY_H_
