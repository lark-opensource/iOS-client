// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_GENERATOR_RADON_DYNAMIC_COMPONENT_PARSER_H_
#define LYNX_TASM_GENERATOR_RADON_DYNAMIC_COMPONENT_PARSER_H_

#include <string>

#include "tasm/generator/radon_parser.h"

namespace lynx {
namespace tasm {

class RadonDynamicComponentParser : public RadonParser {
 public:
  RadonDynamicComponentParser(const EncoderOptions& encoder_options);
  ~RadonDynamicComponentParser() override;

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

#endif  // LYNX_TASM_GENERATOR_RADON_DYNAMIC_COMPONENT_PARSER_H_
