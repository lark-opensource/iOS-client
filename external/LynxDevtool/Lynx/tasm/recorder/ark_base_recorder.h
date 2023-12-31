// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_RECORDER_ARK_BASE_RECORDER_H_
#define LYNX_TASM_RECORDER_ARK_BASE_RECORDER_H_

#include <map>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "base/closure.h"
#include "base/no_destructor.h"
#include "third_party/fml/thread.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace tasm {
namespace recorder {

class ArkBaseRecorder {
 public:
  static constexpr const char* kActionList = "Action List";
  static constexpr const char* kFunctionName = "Function Name";
  static constexpr const char* kInvokedMethodData = "Invoked Method Data";
  static constexpr const char* kResourceData = "Resource Data";
  static constexpr const char* kExternalSource = "External Source";
  static constexpr const char* kConfig = "Config";
  static constexpr const char* kComponentList = "Component List";
  static constexpr const char* kComponentName = "Name";
  static constexpr const char* kComponentType = "Type";
  static constexpr const char* kMethodName = "Method Name";
  static constexpr const char* kModuleName = "Module Name";
  static constexpr const char* kParams = "Params";
  static constexpr const char* kParamRecordTime = "Record Time";
  static constexpr const char* kParamRecordMillisecond = "RecordMillisecond";
  static constexpr const char* kCallback = "Callback";
  static constexpr uint32_t kFilenameBufferSize = 256;
  static constexpr uint32_t kFileDataBufferSize = 65536;
  static constexpr int64_t KRecordIDForGlobalEvent = -1;
  static constexpr const char* KJsbIgnoredInfo = "[]";

  static ArkBaseRecorder& GetInstance();

  bool IsRecordingProcess();

  void RecordAction(const char* function_name, rapidjson::Value& params,
                    int64_t record_id);
  void RecordInvokedMethodData(const char* module_name, const char* method_name,
                               rapidjson::Value& params, int64_t record_id);

  void RecordCallback(const char* module_name, const char* method_name,
                      rapidjson::Value& params, int64_t callback_id,
                      int64_t record_id);

  void RecordComponent(const char* name, int type, int64_t record_id);

  void RecordResource(const char* url, const char* source);

  void RecordExternalSource(const char* url, const char* source);

  rapidjson::Document::AllocatorType& GetAllocator();
  void AddLynxViewItem(int64_t record_id, const std::string& url);
  void SetRecorderPath(const std::string& path);
  void SetScreenSize(int64_t record_id, float screen_width,
                     float screen_height);
  void AddLynxViewSessionID(int64_t record_id, int64_t session);
  void StartRecord(std::string& filter_url);
  void EndRecord(base::MoveOnlyClosure<void, std::vector<std::string>&,
                                       std::vector<int64_t>&>
                     send_complete);

 private:
  friend base::NoDestructor<ArkBaseRecorder>;
  ArkBaseRecorder();
  ~ArkBaseRecorder() = default;
  ArkBaseRecorder(const ArkBaseRecorder&) = delete;
  ArkBaseRecorder& operator=(const ArkBaseRecorder&) = delete;

  void RecordTime(rapidjson::Value& val);
  rapidjson::Value& GetItem(int64_t record_id);
  void CreateItem(int64_t record_id);

  template <typename T>
  void InsertReplayConfig(int64_t record_id, const char* name, T value);

  static std::string ToString(const rapidjson::Value& obj,
                              bool delete_first_and_last = false);

  rapidjson::Document dumped_document_;
  std::unordered_map<int64_t, rapidjson::Value> lynx_view_table_;
  rapidjson::Value resource_table_;
  rapidjson::Value external_source_table_;
  bool is_recording_;
  std::string filter_url_;
  std::string file_path_;
  std::unordered_map<int64_t, rapidjson::Value> replay_config_map_;
  std::unordered_map<int64_t, std::string> url_map_;
  std::unordered_map<int64_t, int64_t> session_ids_;
  fml::Thread thread_;
  void RecordActionKernel(const char* function_name, rapidjson::Value& params,
                          int64_t record_id,
                          rapidjson::Document::AllocatorType& allocator);
};

}  // namespace recorder
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RECORDER_ARK_BASE_RECORDER_H_
