// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_RECORDER_TEMPLATE_ASSEMBLER_RECORDER_H_
#define LYNX_TASM_RECORDER_TEMPLATE_ASSEMBLER_RECORDER_H_

#include <memory>
#include <string>
#include <vector>

#include "lepus/value.h"
#include "tasm/recorder/ark_base_recorder.h"
#include "tasm/template_assembler.h"

namespace lynx {
namespace tasm {

class TemplateData;
class TemplateAssembler;

namespace recorder {

class TemplateAssemblerRecorder {
 public:
  static constexpr const char* kParamComponentId = "component_id";
  static constexpr const char* kParamConfig = "config";
  static constexpr const char* kParamData = "data";
  static constexpr const char* kParamGlobalProps = "global_props";
  static constexpr const char* kParamNoticeDelegate = "noticeDelegate";
  static constexpr const char* kParamPreprocessorName = "preprocessorName";
  static constexpr const char* kParamReadOnly = "readOnly";
  static constexpr const char* kParamSource = "source";
  static constexpr const char* kParamTemplateData = "templateData";
  static constexpr const char* kParamUrl = "url";
  static constexpr const char* kParamValue = "value";
  static constexpr const char* kParamIsCSR = "isCSR";

  static constexpr const char* kFuncLoadTemplate = "loadTemplate";
  static constexpr const char* kFuncSetGlobalProps = "setGlobalProps";
  static constexpr const char* kFuncUpdateConfig = "updateConfig";
  static constexpr const char* kUpdatePageOption = "updatePageOption";
  static constexpr const char* kFuncUpdateDataByPreParsedData =
      "updateDataByPreParsedData";
  static constexpr const char* kFuncRecordReloadTemplate = "reloadTemplate";

  // TemplateAssembler Event Func
  static constexpr const char* kFuncSendTouchEvent = "SendTouchEvent";
  static constexpr const char* kFuncSendCustomEvent = "SendCustomEvent";
  static constexpr const char* kEventName = "name";
  static constexpr const char* kEventTag = "tag";
  static constexpr const char* kEventRootTag = "root_tag";
  static constexpr const char* kEventX = "x";
  static constexpr const char* kEventY = "y";
  static constexpr const char* kEventClientX = "client_x";
  static constexpr const char* kEventClientY = "client_y";
  static constexpr const char* kEventPageX = "page_x";
  static constexpr const char* kEventPageY = "page_y";
  static constexpr const char* kEventParaName = "pname";
  static constexpr const char* kEventParams = "params";
  static constexpr const char* kEventMsg = "msg";

  // dynamic component recoder
  static constexpr const char* kSyncTag = "sync_tag";
  static constexpr const char* kCallbackId = "callback_id";
  static constexpr const char* kFuncRequireTemplate = "RequireTemplate";
  static constexpr const char* kFuncLoadComponentWithCallback =
      "LoadComponentWithCallback";

  // Template Assembler Func
  static void RecordLoadTemplate(
      const std::string& url, std::vector<uint8_t>& source,
      const std::shared_ptr<TemplateData> template_data, int64_t record_id,
      bool is_csr = true);
  static void RecordReloadTemplate(
      const std::shared_ptr<TemplateData> template_data, int64_t record_id);
  static void RecordSetGlobalProps(lepus::Value global_props,
                                   int64_t record_id);
  static void RecordUpdateConfig(const lepus::Value& config,
                                 const bool notice_delegate, int64_t record_id);
  static void RecordUpdateDataByPreParsedData(
      const std::shared_ptr<TemplateData> template_data,
      const UpdatePageOption& update_page_option, int64_t record_id);

  static void RecordTouchEvent(std::string name, int tag, int root_tag, float x,
                               float y, float client_x, float client_y,
                               float page_x, float page_y, int64_t record_id);
  static void RecordCustomEvent(std::string name, int tag, int root_tag,
                                const lepus::Value& params, std::string pname,
                                int64_t record_id);

  static void RecordRequireTemplate(const std::string& url, bool sync,
                                    int64_t record_id);

  static void RecordLoadComponentWithCallback(const std::string& url,
                                              std::vector<uint8_t>& source,
                                              bool sync, int32_t callback_id,
                                              int64_t record_id);

 private:
  static void ProcessUpdatePageOption(
      const UpdatePageOption& update_page_option, rapidjson::Value& value);
};

class RecordRequireTemplateScope {
 public:
  RecordRequireTemplateScope(TemplateAssembler* tasm, const std::string& url,
                             int64_t record_id);
  ~RecordRequireTemplateScope();

 private:
  TemplateAssembler* tasm_;
  std::string url_;
  int64_t record_id_;
  bool contain_target_entry_{false};
};

}  // namespace recorder
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RECORDER_TEMPLATE_ASSEMBLER_RECORDER_H_
