// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_TEMPLATE_DATA_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_TEMPLATE_DATA_H_

#include <memory>
#include <string>

#include "lynx_export.h"

namespace lynx {
namespace lepus {
class Value;
}

class LYNX_EXPORT LynxTemplateData {
 public:
  LynxTemplateData();
  ~LynxTemplateData();
  void InitWithJson(const std::string& data);
  void UpdateWithJson(const std::string& data);
  // will convert TemplateData to lepus value
  void UpdateWithTemplateData(LynxTemplateData* value);

  bool CheckIsLegalData();

  void MarkState(const std::string& name);

  /**
   * TemplateData will be sync to Native. For Thread-Safety, we will clone the
   * value in Native Side. In some case, this may result in performance-loss, If
   * your data won't change any more, Please call this method to mark value
   * Read-Only, so we'll no longer clone the value any more to improve
   * performance.
   */
  void MarkReadOnly() { read_only_ = true; }
  bool IsReadOnly() const { return read_only_; }
  lynx::lepus::Value* GetLepusValue();

 private:
  friend class LynxTemplateRender;
  void UpdateWithLepusValue(lynx::lepus::Value* value);

  std::shared_ptr<lynx::lepus::Value> value_;
  std::string processor_name_;
  bool read_only_{false};
};
}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_TEMPLATE_DATA_H_
