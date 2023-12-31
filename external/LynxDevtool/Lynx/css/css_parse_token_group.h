// Copyright 2019 The Lynx Authors. All rights reserved.
//
// Created by shiwentao on 2019/12/20.
//
#ifndef LYNX_CSS_CSS_PARSE_TOKEN_GROUP_H_
#define LYNX_CSS_CSS_PARSE_TOKEN_GROUP_H_

#include <third_party/rapidjson/document.h>

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "css/css_parser_token.h"
#include "css/ng/parser/css_parser_token_range.h"
#include "css/ng/parser/css_tokenizer.h"
#include "css/ng/selector/css_parser_context.h"
#include "css/ng/selector/css_selector_parser.h"
#include "tasm/compile_options.h"

#define TYPE "type"
#define STYLE_RULE "StyleRule"
#define STYLE "style"
#define SELECTORTEXT "selectorText"
#define STYLE_VARIABLES "variables"
#define COMMA ","
#define COMMA_AND_BLANK ", "
#define NEWLINE "\n"

namespace lynx {
namespace tasm {
class CSSParseTokenGroup {
  /*
   * {
   *      "type": "StyleRule",
   *      "selectorText": "view,componet",
   *      "style": [
   *        {
   *          "name": "width",
   *          "keyLoc": {
   *            "column": 19,
   *            "line": 8
   *          },
   *          "valLoc": {
   *            "column": 25,
   *            "line": 8
   *          },
   *          "value": "100px"
   *        },
   *        {
   *          "name": "height",
   *          "keyLoc": {
   *            "column": 19,
   *            "line": 9
   *          },
   *          "valLoc": {
   *            "column": 27,
   *            "line": 9
   *          },
   *          "value": "100px"
   *      ],
   * }
   *
   */

 private:
  std::vector<std::shared_ptr<CSSParseToken>> tokens;
  std::string path_;
  LynxCSSSelectorTuple selector_tuple_;

  std::string& replace_all(std::string& str, const std::string& old_value,
                           const std::string& new_value) {
    while (true) {
      std::string::size_type pos(0);
      if ((pos = str.find(old_value)) != std::string::npos)
        str.replace(pos, old_value.length(), new_value);
      else
        break;
    }
    return str;
  }

 public:
  std::vector<std::shared_ptr<CSSParseToken>>& getCssTokens() { return tokens; }
  std::string selector_key_;
  LynxCSSSelectorTuple& getSelectorTuple() { return selector_tuple_; }
  /**
   * 将COMMA_AND_BLANK预处理
   * 同时将COMMA连接的选择器分割成多个
   */
  CSSParseTokenGroup(const rapidjson::Value& value, const std::string& path,
                     const CompileOptions& compile_options_)
      : path_(path) {
    if (value.HasMember(TYPE) &&
        std::string(STYLE_RULE).compare(value[TYPE].GetString()) == 0) {
      if (value.HasMember(SELECTORTEXT) && value.HasMember(STYLE)) {
        const rapidjson::Value& css_style = value[STYLE];
        std::string selector = value[SELECTORTEXT]["value"].GetString();
        const rapidjson::Value& style_variables = value[STYLE_VARIABLES];
        if (selector.size() > 0) {
          // pre parse selecotr, the new css ng will be enable in fiber arch or
          // enable the css selector
          if (!compile_options_.enable_css_selector_) {
            // the original logic
            const std::string newline(NEWLINE);
            const std::string comma_and_blank(COMMA_AND_BLANK);
            const std::string comma(COMMA);
            selector = replace_all(selector, newline, "");
            selector = replace_all(selector, comma_and_blank, comma);
            std::vector<std::string> rule;
            CSSParseToken::SplitRules(selector, COMMA, rule);
            for (std::vector<std::string>::const_iterator iter = rule.cbegin();
                 iter != rule.cend(); iter++) {
              std::string str = *iter;
              std::shared_ptr<CSSParseToken> token(new CSSParseToken(
                  css_style, str, path, style_variables, compile_options_));
              tokens.push_back(std::move(token));
            }
          } else {
            // the new css ng logic
            selector_key_ = selector;
            css::CSSParserContext context;
            css::CSSTokenizer tokenizer(selector);
            const auto parser_tokens = tokenizer.TokenizeToEOF();
            css::CSSParserTokenRange range(parser_tokens);
            css::LynxCSSSelectorVector selector_vector =
                css::CSSSelectorParser::ParseSelector(range, &context);
            if (selector_vector.empty()) {
              return;
            }
            size_t flattened_size =
                css::CSSSelectorParser::FlattenedSize(selector_vector);
            auto selector_array =
                std::make_unique<css::LynxCSSSelector[]>(flattened_size);
            css::CSSSelectorParser::AdoptSelectorVector(
                selector_vector, selector_array.get(), flattened_size);
            selector_tuple_.selector_key = selector_key_;
            selector_tuple_.flattened_size = flattened_size;
            selector_tuple_.selector_arr = std::move(selector_array);

            std::shared_ptr<CSSParseToken> token(new CSSParseToken(
                css_style, selector, path, style_variables, compile_options_));
            selector_tuple_.parse_token = std::move(token);
          }
        }
      }
    }
  }

  static bool IsCSSParseToken(const rapidjson::Value& value) {
    return value.HasMember(TYPE) &&
           std::string(STYLE_RULE).compare(value[TYPE].GetString()) == 0;
  }

  CSSParseTokenGroup() {}

  ~CSSParseTokenGroup() {}
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_CSS_PARSE_TOKEN_GROUP_H_
