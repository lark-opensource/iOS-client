// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_GENERATOR_TEMPLATE_DYNAMIC_COMPONENT_PARSER_H_
#define LYNX_TASM_GENERATOR_TEMPLATE_DYNAMIC_COMPONENT_PARSER_H_

#include <string>

#include "tasm/generator/template_parser.h"

namespace lynx {
namespace tasm {

class TemplateDynamicComponentParser : public TemplateParser {
 public:
  TemplateDynamicComponentParser(const EncoderOptions& encoder_options);
  ~TemplateDynamicComponentParser() override;

  void Parse() override;

 protected:
  std::string GenDynamicComponentSource(
      DynamicComponent* dynamic_component) override;

  std::string GenDynamicComponentSourceForTT(
      DynamicComponent* dynamic_component);
  std::string GenDynamicComponentSourceForReactCompilerNG(
      DynamicComponent* dynamic_component);
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_GENERATOR_TEMPLATE_DYNAMIC_COMPONENT_PARSER_H_
