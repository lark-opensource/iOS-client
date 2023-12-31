// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_SSR_SSR_ENCODER_H_
#define LYNX_SSR_SSR_ENCODER_H_
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "napi.h"
#include "tasm/template_binary_reader.h"
#include "tasm/template_entry.h"
namespace lynx {
namespace tasm {
class RadonNode;
}
namespace ssr {

class SSRConfigger : public tasm::TemplateBinaryReader::PageConfigger {
 public:
  SSRConfigger() : page_config_(std::make_shared<tasm::PageConfig>()) {}
  virtual ~SSRConfigger() = default;

  void InitLepusDebugger() override {
    // No lepus will run for react ssr.
  }
  void SetSupportComponentJS(bool support) override {
    // Support by default in react.
  }
  void SetTargetSdkVersion(const std::string& targetSdkVersion) override {
    // Currently target sdk version is not used when running page logic when ssr
    // react code.
  }
  std::shared_ptr<tasm::PageConfig> GetPageConfig() override {
    return page_config_;
  }
  void SetPageConfig(const std::shared_ptr<tasm::PageConfig>& config) override {
    page_config_ = config;
  }
  tasm::Themed& Themed() override { return themed_; }

 private:
  std::shared_ptr<tasm::PageConfig> page_config_;
  tasm::Themed themed_;
};

struct SSREntry {
  explicit SSREntry(std::unique_ptr<tasm::TemplateEntry> entry)
      : entry_(std::move(entry)){};
  SSRConfigger configger_;
  std::unique_ptr<tasm::TemplateEntry> entry_;
};

SSREntry* CreateTemplateEntry(const std::vector<uint8_t>& source);
std::vector<uint8_t> JSXToBinary(tasm::TemplateEntry* entry,
                                 const Napi::Value& value,
                                 const Napi::Value& config);
std::vector<uint8_t> EncodeDom(tasm::RadonNode* dom,
                               tasm::TemplateAssembler* template_assembler,
                               const lepus::Value& config,
                               const lepus::Value& additional_value,
                               const std::string& api_version);

}  // namespace ssr
}  // namespace lynx

#endif  // LYNX_SSR_SSR_ENCODER_H_
