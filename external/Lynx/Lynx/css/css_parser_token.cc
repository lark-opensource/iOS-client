// Copyright 2019 The Lynx Authors. All rights reserved.

#include "css/css_parser_token.h"

#include "base/log/logging.h"
#include "base/string/string_utils.h"
#include "base/trace_event/trace_event.h"
#include "lepus/exception.h"
#include "tasm/config.h"
#include "tasm/lynx_trace_event.h"

namespace lynx {
namespace tasm {

#ifdef BUILD_LEPUS
static constexpr char BLANK[] = " ";
static constexpr char DOC[] = ".";
static constexpr char PSEUDO_NOT[] = ":not";
static constexpr unsigned int PSEUOD_NOT_MIN_LEN = 6;
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
 *      "styleVariables": {
 *          "--main-bg-color": "brown",
 *      }
 * }
 *
 */
// parse for mini token
CSSParseToken::CSSParseToken(const rapidjson::Value& style, std::string& rule,
                             const std::string& path,
                             const rapidjson::Value& style_variables,
                             const CompileOptions& compile_options)
    : path_(path), compile_options_(compile_options) {
  // need to generate css_style
  ParseAttributes(style);
  ParseStyleVariables(style_variables);
  if (!compile_options_.enable_css_selector_) {
    SplitSelector(rule);
  }
}

void CSSParseToken::ParseAttributes(const rapidjson::Value& value) {
  if (value.IsObject() || value.IsArray()) {
    auto iterate = [this](const rapidjson::Value& name,
                          const rapidjson::Value& value) {
      CSSPropertyID id = CSSProperty::GetPropertyID(name.GetString());
      if (!CSSProperty::IsPropertyValid(id)) {
        // FIXME: consider not using `std::stringstream`
        std::stringstream error;
        error << "Error In CSSParse: \"" << name.GetString()
              << "\" is not supported now !";

        const rapidjson::Value& loc = value[rapidjson::Value("keyLoc")];
        throw lepus::ParseException(error.str().c_str(), path_.c_str(), loc);
      }
      // FIXME: consider moving these string literals into constexpr static
      lepus::Value css_value = lepus::jsonValueTolepusValue(value["value"]);
      CSSValueType type = CSSValueType::DEFAULT;
      if (value["type"] == "css_var") {
        type = CSSValueType::VARIABLE;
      }
      lepus::String default_value;
      if (value.HasMember("defaultValue")) {
        default_value = value["defaultValue"].GetString();
      }

      if (Config::IsHigherOrEqual(compile_options_.target_sdk_version_,
                                  FEATURE_CSS_STYLE_VARIABLES) &&
          compile_options_.enable_css_variable_ &&
          type == CSSValueType::VARIABLE) {
        attributes_.insert(
            {id, CSSValue(css_value, CSSValuePattern::STRING,
                          CSSValueType::VARIABLE, default_value)});
        return;
      }
      if (Config::IsHigherOrEqual(compile_options_.target_sdk_version_,
                                  FEATURE_CSS_VALUE_VERSION) &&
          compile_options_.enable_css_parser_) {
        auto configs = CSSParserConfigs::GetCSSParserConfigsByComplierOptions(
            compile_options_);
        UnitHandler::Process(id, css_value, attributes_, configs);
      } else {
        attributes_.insert({id, CSSValue(css_value)});
      }
    };
    if (value.IsObject()) {
      for (auto itr = value.MemberBegin(); itr != value.MemberEnd(); ++itr) {
        iterate(itr->name, itr->value);
      }
    } else if (value.IsArray()) {
      for (const auto& attribute : value.GetArray()) {
        iterate(attribute["name"], attribute);
      }
    }
  }
}

void CSSParseToken::ParseStyleVariables(const rapidjson::Value& value) {
  if (!value.IsObject()) {
    return;
  }
  for (rapid_value::ConstMemberIterator itr = value.MemberBegin();
       itr != value.MemberEnd(); ++itr) {
    style_variables.insert({itr->name.GetString(), itr->value.GetString()});
  }
}

void CSSParseToken::HandlePseudoSelector(std::string& select) {
  if (select.length() <= PSEUOD_NOT_MIN_LEN) {
    return;
  }
  // remove extra spaces
  std::string new_select;
  for (auto c : select) {
    if (c != ' ') {
      new_select += c;
    }
  }
  size_t pseudo_not_pos = new_select.find(PSEUDO_NOT);
  size_t left_bracket_pos = new_select.find('(');
  size_t right_bracket_pos = new_select.find(')');
  // valid check, after remove all the extra spaces, the left bracket should be
  // next to the :not string and the right bracket should be the last character
  // of the selector
  if (left_bracket_pos != pseudo_not_pos + 4 ||
      right_bracket_pos != new_select.length() - 1) {
    return;
  }
  std::string scope_content = new_select.substr(
      left_bracket_pos + 1, right_bracket_pos - left_bracket_pos - 1);
  std::string parent = new_select.substr(0, pseudo_not_pos);
  if (scope_content.compare(parent) == 0) {
    return;
  }
  std::shared_ptr<CSSSheet> newSheet(new CSSSheet(new_select));
  sheets_.emplace_back(newSheet);
}

void CSSParseToken::SplitSelector(std::string& select) {
  std::shared_ptr<CSSSheet> parent = nullptr;
  std::vector<std::string> rule;
  if (select.find(PSEUDO_NOT) != std::string::npos) {
    HandlePseudoSelector(select);
    return;
  }
  size_t doc_site = select.rfind(DOC);
  bool is_multi_doc_slector = (doc_site != std::string::npos && doc_site != 0);
  if (is_multi_doc_slector) {
    lynx::base::ReplaceAll(select, DOC, " .");
  }

  bool is_cascade_selector = (select.find(BLANK) != std::string::npos);

  if (is_cascade_selector) {
    SplitRules(select, BLANK, rule);
    for (std::vector<std::string>::const_iterator iter = rule.cbegin();
         iter != rule.cend(); iter++) {
      // FIXME: iter dereferenced and copy assignment operator of std::string
      // called.
      std::string key = *iter;
      if (key.compare("") == 0) {
        continue;
      }
      std::shared_ptr<CSSSheet> newSheet(new CSSSheet(key));
      newSheet->SetParent(parent);
      sheets_.push_back(newSheet);
      parent = newSheet;
    }
  } else {
    std::shared_ptr<CSSSheet> newSheet(new CSSSheet(select));
    // FIXME: sheets_ is a vector of `std::string`, `push_back` leads to copy
    // construction.
    sheets_.push_back(newSheet);
  }
}

#endif

// FIXME: two phase initialization may not be needed, consider move this into
// the constructor of CSSSheet
std::shared_ptr<CSSSheet> CSSParseToken::CreatSheet(
    const std::string& name, std::shared_ptr<CSSSheet> parent) {
  std::shared_ptr<CSSSheet> sheet(new CSSSheet(name));
  if (parent != nullptr) {
    sheet->SetParent(parent);
  }
  return sheet;
}

void CSSParseToken::SplitRules(const std::string& str,
                               const std::string& pattern,
                               std::vector<std::string>& res) {
  if (str.size() > 0) {
    // FIXME: Construction of `std::string` leads to allocation of new memory.
    // Consider using `std::string_view` if cpp17 is available or `const char
    // *`.
    std::string strs = str + pattern;
    size_t pos = strs.find(pattern);
    while (pos != strs.npos) {
      std::string temp = strs.substr(0, pos);
      res.push_back(temp);
      strs = strs.substr(pos + 1, strs.size());
      pos = strs.find(pattern);
    }
  }
}

bool CSSParseToken::IsPseudoStyleToken() const {
  const auto& target_sheet_ptr = TargetSheet();
  if (target_sheet_ptr) {
    return target_sheet_ptr->GetType() > CSSSheet::NAME_SELECT &&
           target_sheet_ptr->GetType() != CSSSheet::ALL_SELECT;
  } else {
    return false;
  }
}

bool CSSParseToken::IsGlobalPseudoStyleToken() const {
  const auto& target_sheet_ptr = TargetSheet();
  if (target_sheet_ptr) {
    const auto& selector = target_sheet_ptr->GetSelector().str();
    // FIXME: consider using `starts_with` or its equivalent
    return selector.find(":") == 0;
  } else {
    return false;
  }
}

bool CSSParseToken::IsCascadeSelectorStyleToken() const {
  return sheets_.size() > 1;
}

const StyleMap& CSSParseToken::GetAttribute() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, CSS_GET_ATTRIBUTES);
  if (!raw_attributes_.empty()) {
    for (const auto& attr : raw_attributes_) {
      UnitHandler::Process(attr.first, attr.second, attributes_,
                           parser_configs_);
    }
    raw_attributes_.clear();
  }
  return attributes_;
}

int CSSParseToken::GetStyleTokenType() const {
  const auto& target_sheet_ptr = TargetSheet();
  return target_sheet_ptr ? target_sheet_ptr->GetType() : 0;
}

void CSSParseToken::MarkAsTouchPseudoToken() { is_touch_pseudo_ = true; }

bool CSSParseToken::IsTouchPseudoToken() const { return is_touch_pseudo_; }

const RawParsedStyleMap& CSSParseToken::GetRawParsedAttribute() {
  if (!raw_attributes_.empty()) {
    for (const auto& attr : raw_attributes_) {
      StyleMap output;
      UnitHandler::Process(attr.first, attr.second, output, parser_configs_);
      raw_parsed_attributes_[attr.first] = {attr.second, output};
    }
    raw_attributes_.clear();
  }
  return raw_parsed_attributes_;
}

}  // namespace tasm
}  // namespace lynx
