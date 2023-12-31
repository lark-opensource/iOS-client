//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "lynx_binary_base_css_reader.h"

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/trace_event/trace_event.h"
#include "tasm/lynx_trace_event.h"

namespace lynx {
namespace tasm {

bool LynxBinaryBaseCSSReader::DecodeCSSSelector(
    css::LynxCSSSelector* selector) {
  DECODE_VALUE(data);
  css::LynxCSSSelector::FromLepus(*selector, data);
  return true;
}

bool LynxBinaryBaseCSSReader::DecodeCSSRoute(CSSRoute& css_route) {
  DECODE_U32LEB(size);
  for (size_t i = 0; i < size; ++i) {
    DECODE_S32LEB(id);
    // CSSRange
    DECODE_U32LEB(start);
    DECODE_U32LEB(end);
    css_route.fragment_ranges.insert({id, CSSRange(start, end)});
  }
  return true;
}

bool LynxBinaryBaseCSSReader::DecodeCSSFragment(SharedCSSFragment* fragment,
                                                size_t descriptor_end) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeCSSFragment");
  // Id
  DECODE_U32LEB(id);
  fragment->id_ = id;
  // Dependents css id
  DECODE_U32LEB(dependent_ids_size);
  for (size_t i = 0; i < dependent_ids_size; ++i) {
    DECODE_S32LEB(id);
    fragment->dependent_ids_.emplace_back(id);
  }

  // GetCSSParserConfig
  auto parser_config =
      CSSParserConfigs::GetCSSParserConfigsByComplierOptions(compile_options_);

  // Decode the selector and parse token when enable the css selector
  if (compile_options_.enable_css_selector_) {
    // If enable the CSS invalidation
    if (compile_options_.enable_css_invalidation_) {
      fragment->SetEnableCSSInvalidation();
    }
    fragment->SetEnableCSSSelector();
    DECODE_U32LEB(selector_size);
    for (size_t i = 0; i < selector_size; i++) {
      DECODE_U32LEB(flattened_size);
      if (flattened_size == 0) {
        // We do not support this CSS selector
        // See TemplateBinaryWriter::EncodeLynxCSSSelectorTuple
        continue;
      }
      auto selector_array =
          std::make_unique<css::LynxCSSSelector[]>(flattened_size);
      for (size_t i = 0; i < flattened_size; i++) {
        DecodeCSSSelector(&selector_array[i]);
        if (selector_array[i].GetPseudoType() ==
            css::LynxCSSSelector::kPseudoActive) {
          fragment->MarkHasTouchPseudoToken();
        }
      }
      auto parser_token = std::make_shared<CSSParseToken>(parser_config);
      ERROR_UNLESS(DecodeCSSParseToken(parser_token.get()));
      fragment->AddStyleRule(std::move(selector_array),
                             std::move(parser_token));
    }
  }

  // When enable the css selector, the `css_size` will be zero
  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "DecodeCSSParseToken");
  DECODE_U32LEB(size);
  uint32_t css_size = size << 16 >> 16;
  uint32_t keyframes_size = size >> 16;
  // CSS parse token
  for (size_t i = 0; i < css_size; ++i) {
    DECODE_STDSTR(key);
    auto parser_token = std::make_shared<CSSParseToken>(parser_config);
    ERROR_UNLESS(DecodeCSSParseToken(parser_token.get()));
    if (parser_token->IsTouchPseudoToken()) {
      fragment->MarkHasTouchPseudoToken();
    }
    fragment->FindSpecificMapAndAdd(key, parser_token);
    fragment->css_.insert({std::move(key), std::move(parser_token)});
  }
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);

  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "DecodeCSSKeyframesToken");
  for (size_t i = 0; i < keyframes_size; ++i) {
    DECODE_STR(name);

    CSSKeyframesToken* token = new CSSKeyframesToken(parser_config);
    ERROR_UNLESS(DecodeCSSKeyframesToken(token));
    std::shared_ptr<CSSKeyframesToken> token_ptr(token);
    fragment->keyframes_.insert({name->c_str(), std::move(token_ptr)});
  }
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);

  // for other types
  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "DecodeCSSFontFaceToken");
  while (CheckSize(5, static_cast<uint32_t>(descriptor_end))) {
    DECODE_U8(type);
    DECODE_U32LEB(typed_size);
    bool enable_font_face_extension = Config::IsHigherOrEqual(
        compile_options_.target_sdk_version_, FEATURE_CSS_FONT_FACE_EXTENSION);
    switch (type) {
      case CSS_BINARY_FONT_FACE_TYPE:
        for (size_t i = 0; i < typed_size; ++i) {
          std::vector<std::shared_ptr<CSSFontFaceToken>> token_list;
          std::string token_key;
          if (enable_font_face_extension) {
            DECODE_U32LEB(token_size);
            for (size_t i = 0; i < token_size; ++i) {
              CSSFontFaceToken* token = new CSSFontFaceToken();
              ERROR_UNLESS(DecodeCSSFontFaceToken(token));
              std::shared_ptr<CSSFontFaceToken> token_ptr(token);
              token_list.emplace_back(token_ptr);
            }
          } else {
            CSSFontFaceToken* token = new CSSFontFaceToken();
            ERROR_UNLESS(DecodeCSSFontFaceToken(token));
            std::shared_ptr<CSSFontFaceToken> token_ptr(token);
            token_list.emplace_back(token_ptr);
          }
          token_key = token_list.size() > 0 ? token_list[0]->getKey() : "";
          fragment->fontfaces_.insert(
              std::pair<std::string,
                        std::vector<std::shared_ptr<CSSFontFaceToken>>>(
                  token_key, token_list));
        }
        break;
      default:
        break;
    }
  }
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);

  return true;
}

bool LynxBinaryBaseCSSReader::DecodeCSSParseToken(CSSParseToken* token) {
  StyleMap attrs;
  RawStyleMap raw_attrs;
  ERROR_UNLESS(DecodeCSSAttributes(&attrs, &raw_attrs, token->parser_configs_));

  CSSVariableMap style_variables;
  if (enable_css_variable_) {
    ERROR_UNLESS(DecodeCSSStyleVariables(style_variables));
  }
  if (!compile_options_.enable_css_selector_) {
    DECODE_U32LEB(size);
    std::vector<std::shared_ptr<CSSSheet>> sheets(size);

    for (size_t i = 0; i < size; i++) {
      CSSSheet* parent = (i == 0) ? nullptr : sheets[i - 1].get();
      std::shared_ptr<CSSSheet> sheet(new CSSSheet());
      ERROR_UNLESS(DecodeCSSSheet(parent, sheet.get()));
      if (sheet->IsTouchPseudo()) {
        token->MarkAsTouchPseudoToken();
      }
      sheets[i] = std::move(sheet);
    }
    token->sheets_ = std::move(sheets);
  }

  token->attributes_ = std::move(attrs);
  token->raw_attributes_ = std::move(raw_attrs);
  token->style_variables = std::move(style_variables);
  return true;
}

bool LynxBinaryBaseCSSReader::DecodeCSSFontFaceToken(CSSFontFaceToken* token) {
  DECODE_U32LEB(size);
  for (size_t i = 0; i < size; ++i) {
    DECODE_STR(str_key);
    DECODE_STR(str_val);
    token->addAttribute(str_key->str(), str_val->str());
  }
  return true;
}

bool LynxBinaryBaseCSSReader::DecodeCSSKeyframesToken(
    CSSKeyframesToken* token) {
  CSSKeyframesMap map;
  CSSRawKeyframesMap raw_map;
  ERROR_UNLESS(DecodeCSSKeyframesMap(&map, &raw_map, token->parser_configs_));
  token->SetKeyframeStyles(std::move(map));
  token->SetRawKeyframeStyles(std::move(raw_map));
  return true;
}

bool LynxBinaryBaseCSSReader::DecodeCSSSheet(CSSSheet* parent,
                                             CSSSheet* sheet) {
  DECODE_U32LEB(type);  // Not used
  DECODE_STR(name);
  DECODE_STR(selector);
  sheet->type_ = 0;  // The ConfirmType will update the value of type
  sheet->name_ = std::move(name);
  sheet->selector_ = std::move(selector);
  sheet->parent_ = parent;
  sheet->ConfirmType();
  return true;
}

bool LynxBinaryBaseCSSReader::DecodeCSSAttributes(
    StyleMap* attrs, RawStyleMap* raw_attrs,
    const CSSParserConfigs& parser_config) {
  DECODE_U32LEB(size);
  for (size_t i = 0; i < size; ++i) {
    DECODE_U32LEB(id);
    CSSPropertyID property_id = static_cast<CSSPropertyID>(id);
    DECODE_CSS_VALUE(value);
    if (enable_css_parser_) {
      attrs->insert({property_id, std::move(value)});
    } else {
      if (value.GetValueType() == CSSValueType::VARIABLE) {
        attrs->insert(
            {property_id,
             CSSValue(value.GetValue(), CSSValuePattern::STRING,
                      CSSValueType::VARIABLE, value.GetDefaultValue())});
      } else {
        if (enable_pre_process_attributes_) {
          UnitHandler::Process(property_id, value.GetValue(), *attrs,
                               parser_config);
        } else if (raw_attrs != nullptr) {
          raw_attrs->insert({property_id, value.GetValue()});
        }
      }
    }
  }
  return true;
}

bool LynxBinaryBaseCSSReader::DecodeCSSStyleVariables(
    CSSVariableMap& style_variables) {
  DECODE_U32LEB(size);
  for (size_t i = 0; i < size; ++i) {
    std::string key;
    ReadStringDirectly(&key);
    std::string value;
    ReadStringDirectly(&value);
    style_variables.insert({key.c_str(), value.c_str()});
  }
  return true;
}

bool LynxBinaryBaseCSSReader::DecodeCSSKeyframesMap(
    CSSKeyframesMap* keyframes, CSSRawKeyframesMap* raw_keyframes,
    const CSSParserConfigs& parser_config) {
  DECODE_U32LEB(size);
  for (size_t i = 0; i < size; ++i) {
    float key;
    if (enable_css_parser_) {
      DECODE_DOUBLE(key_val);
      key = key_val;
    } else {
      DECODE_STDSTR(key_text);
      key = CSSKeyframesToken::ParseKeyStr(
          key_text, compile_options_.enable_css_strict_mode_);
    }

    StyleMap* attrs = new StyleMap();
    RawStyleMap* raw_attrs = new RawStyleMap();
    ERROR_UNLESS(DecodeCSSAttributes(attrs, raw_attrs, parser_config));
    std::shared_ptr<StyleMap> attrs_ptr(attrs);
    keyframes->insert(
        std::pair<float, std::shared_ptr<StyleMap>>(key, attrs_ptr));
    if (!raw_attrs->empty()) {
      std::shared_ptr<RawStyleMap> raw_attrs_ptr(raw_attrs);
      raw_keyframes->insert(
          std::pair<float, std::shared_ptr<RawStyleMap>>(key, raw_attrs_ptr));
    } else {
      delete raw_attrs;
    }
  }
  return true;
}

bool LynxBinaryBaseCSSReader::DecodeCSSValue(tasm::CSSValue* result) {
  ERROR_UNLESS(
      DecodeCSSValue(result, enable_css_parser_, enable_css_variable_));
  return true;
}

bool LynxBinaryBaseCSSReader::DecodeCSSValue(tasm::CSSValue* result,
                                             bool enable_css_parser,
                                             bool enable_css_variable) {
  if (enable_css_parser) {
    DECODE_U32LEB(pattern);
    DECODE_VALUE(value);
    result->SetPattern(static_cast<tasm::CSSValuePattern>(pattern));
    result->SetValue(value);
  } else {
    DECODE_VALUE(value);
    result->SetValue(value);
  }
  if (enable_css_variable) {
    DECODE_U32LEB(value_type);
    DECODE_STR(default_value);
    result->SetType(static_cast<tasm::CSSValueType>(value_type));
    result->SetDefaultValue(default_value);
  }
  return true;
}

}  // namespace tasm
}  // namespace lynx
