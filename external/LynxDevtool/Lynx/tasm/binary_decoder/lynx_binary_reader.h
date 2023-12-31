//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_BINARY_DECODER_LYNX_BINARY_READER_H_
#define LYNX_TASM_BINARY_DECODER_LYNX_BINARY_READER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/trace_event/trace_event.h"
#include "lynx_binary_base_template_reader.h"
#include "lynx_template_bundle.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/template_binary.h"
#include "tasm/template_themed.h"

namespace lynx {
namespace tasm {

class LynxBinaryReader : public LynxBinaryBaseTemplateReader {
 public:
  LynxBinaryReader(std::unique_ptr<lepus::InputStream> stream)
      : LynxBinaryBaseTemplateReader(std::move(stream)) {
    enable_pre_process_attributes_ = true;
  };

  LynxTemplateBundle GetTemplateBundle() { return std::move(template_bundle_); }

 protected:
  virtual bool DidDecodeHeader() override;
  virtual bool DidDecodeAppType() override;
  virtual bool DidDecodeTemplate() override;

  // decode lepus
  virtual bool DecodeContext() override;

  // decode css
  virtual bool DecodeCSSDescriptor(bool is_hmr = false) override;

  // decode themed
  virtual struct Themed& Themed() override;

  bool DecodeParsedStylesSection() override;

  bool DecodeElementTemplateSection() override;

  ParsedStyleMap& GetParsedStyleMap() override {
    return template_bundle_.parsed_styles_map_;
  }

  AirParsedStylesMap& GetAirParsedStylesMap() override {
    return template_bundle_.air_parsed_styles_map_;
  }

 private:
  LynxTemplateBundle template_bundle_;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_BINARY_DECODER_LYNX_BINARY_READER_H_
