// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_GENERATOR_RADON_PAGE_PARSER_H_
#define LYNX_TASM_GENERATOR_RADON_PAGE_PARSER_H_

#include <string>

#include "tasm/generator/radon_parser.h"

namespace lynx {
namespace tasm {

class RadonPageParser : public RadonParser {
 public:
  RadonPageParser(const EncoderOptions& encoder_options);
  ~RadonPageParser() override;

  void Parse() override;

 protected:
  std::string GenPageSource(Page* page) override;
  std::string GenPageSourceForTT(Page* page);
  std::string GenPageSourceForReactCompilerNG(Page* page);

  StringVector GenPageCreateAndUpdateFunc(Page* page);
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_GENERATOR_RADON_PAGE_PARSER_H_
