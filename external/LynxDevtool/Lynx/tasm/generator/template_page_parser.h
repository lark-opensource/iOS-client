// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_GENERATOR_TEMPLATE_PAGE_PARSER_H_
#define LYNX_TASM_GENERATOR_TEMPLATE_PAGE_PARSER_H_

#include <string>

#include "tasm/generator/template_parser.h"

namespace lynx {
namespace tasm {

class TemplatePageParser : public TemplateParser {
 public:
  TemplatePageParser(const EncoderOptions& encoder_options);
  ~TemplatePageParser() override;

  void Parse() override;

 protected:
  std::string GenPageSource(Page* page) override;
  std::string GenPageSourceForTT(Page* page);
  std::string GenPageSourceForReactCompilerNG(Page* page);
  std::string GenPageRenderer(Page* page);

  void CheckPageElementValid(const rapidjson::Value& element);

 private:
  // only check whether the first element is page element.
  bool new_page_element_enabled_{false};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_GENERATOR_TEMPLATE_PAGE_PARSER_H_
