// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_TEMPLATE_BINARY_READER_H_
#define LYNX_TASM_TEMPLATE_BINARY_READER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "css/shared_css_fragment.h"
#include "tasm/binary_decoder/lynx_binary_base_template_reader.h"
#include "tasm/moulds.h"
#include "tasm/template_binary.h"
#include "tasm/template_entry.h"
#include "tasm/template_themed.h"

namespace lynx {
namespace lepus {
class InputStream;
}
namespace tasm {

class VirtualNode;
class VirtualComponent;
class TemplateAssembler;
class TemplateEntry;
class PageConfig;

class TemplateBinaryReader : public LynxBinaryBaseTemplateReader {
 public:
  class PageConfigger {
   public:
    PageConfigger() = default;
    virtual ~PageConfigger() = default;

    virtual void InitLepusDebugger() = 0;
    virtual void SetSupportComponentJS(bool support) = 0;
    virtual void SetTargetSdkVersion(const std::string& targetSdkVersion) = 0;
    virtual std::shared_ptr<PageConfig> GetPageConfig() = 0;
    virtual void SetPageConfig(const std::shared_ptr<PageConfig>& config) = 0;
    virtual struct Themed& Themed() = 0;
  };

  TemplateBinaryReader(PageConfigger* configger, TemplateEntry* entry,
                       std::unique_ptr<lepus::InputStream> stream)
      : LynxBinaryBaseTemplateReader(std::move(stream)),
        context_(entry->GetVm().get()),
        configger_(configger),
        entry_(entry) {}

  bool DecodeForHMR();

  //  const std::vector<int>& lepus_version() { return lepus_version_; }

  bool DecodeCSSFragmentById(int32_t id);

 protected:
  virtual bool DecodeContext() override;
  // Async CSS Descriptor
  virtual bool DecodeCSSDescriptor(bool is_hmr = false) override;
  bool DecodeCSSFragmentAsync(std::shared_ptr<CSSStyleSheetManager> manager);
  bool GetCSSLazyDecode();
  bool GetCSSAsyncDecode();

  // Themed
  virtual struct Themed& Themed() override { return configger_->Themed(); };
  virtual bool DidDecodeHeader() override;
  virtual bool DidDecodeTemplate() override;

  ParsedStyleMap& GetParsedStyleMap() override { return parsed_styles_map_; }
  AirParsedStylesMap& GetAirParsedStylesMap() override {
    return air_parsed_styles_map_;
  }

  lepus::Context* context_;
  PageConfigger* configger_;
  TemplateEntry* entry_;

 private:
  bool ConstructContext();

  ParsedStyleMap parsed_styles_map_{};
  AirParsedStylesMap air_parsed_styles_map_{};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_TEMPLATE_BINARY_READER_H_
