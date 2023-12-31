//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_BINARY_DECODER_LYNX_BINARY_BASE_CSS_READER_H_
#define LYNX_TASM_BINARY_DECODER_LYNX_BINARY_BASE_CSS_READER_H_

#include <memory>
#include <string>
#include <utility>

#include "css/css_value.h"
#include "css/shared_css_fragment.h"
#include "lepus/base_binary_reader.h"
#include "tasm/template_binary.h"

namespace lynx {
namespace tasm {

#define DECODE_CSS_VALUE(name) \
  tasm::CSSValue name;         \
  ERROR_UNLESS(DecodeCSSValue(&name))

class CSSParseToken;
class CSSSheet;
struct CSSRoute;

class LynxBinaryBaseCSSReader : public lepus::BaseBinaryReader {
 public:
  LynxBinaryBaseCSSReader(std::unique_ptr<lepus::InputStream> stream)
      : lepus::BaseBinaryReader(std::move(stream)){};

  virtual ~LynxBinaryBaseCSSReader() = default;

 protected:
  // Utils for decode css.
  bool DecodeCSSRoute(CSSRoute& css_router);
  bool DecodeCSSFragment(SharedCSSFragment* fragment, size_t descriptor_end);
  bool DecodeCSSParseToken(CSSParseToken*);
  bool DecodeCSSKeyframesToken(CSSKeyframesToken*);
  bool DecodeCSSSheet(CSSSheet* parent, CSSSheet* sheet);
  bool DecodeCSSAttributes(StyleMap*, RawStyleMap*, const CSSParserConfigs&);
  bool DecodeCSSStyleVariables(CSSVariableMap& style_variables);
  bool DecodeCSSKeyframesMap(CSSKeyframesMap*, CSSRawKeyframesMap*,
                             const CSSParserConfigs&);
  bool DecodeCSSFontFaceToken(CSSFontFaceToken* token);
  bool DecodeCSSSelector(css::LynxCSSSelector* selector);

  bool DecodeCSSValue(tasm::CSSValue*);
  bool DecodeCSSValue(tasm::CSSValue* result, bool enable_css_parser,
                      bool enable_css_variable);

 protected:
  Range css_section_range_;

  lepus::Value trial_options_;

  bool enable_css_variable_{false};
  bool enable_css_parser_{false};
  std::string absetting_disable_css_lazy_decode_;
  bool enable_pre_process_attributes_{false};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_BINARY_DECODER_LYNX_BINARY_BASE_CSS_READER_H_
