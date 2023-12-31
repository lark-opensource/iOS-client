// Copyright 2022 The Lynx Authors. All rights reserved.

#include "Lynx/richtext/rich_text_parser.h"

#include <string>
#include <tuple>

#include "Lynx/css/css_property.h"
#include "Lynx/richtext/rich_text_node.h"
#include "Lynx/starlight/style/computed_css_style.h"
#include "Lynx/starlight/types/measure_context.h"
#include "Lynx/starlight/types/nlength.h"

namespace lynx {
namespace tasm {

static const char *skip_white_space(const char *str, const char *end) {
  while (str < end && *str == ' ') {
    str++;
  }

  return str;
}

static const char *scan_next_string(const char *str, const char *end,
                                    char stop) {
  bool keep = false;
  char keep_char = 0;
  while (str < end) {
    str++;

    if (!keep) {
      if (*str == stop) {
        break;
      }
    }

    if (keep && *str == keep_char) {
      keep = false;
      str++;
      continue;
    }

    if (!keep && (*str == '\'' || *str == '\"')) {
      keep_char = *str;
      keep = true;
      str++;
      continue;
    }
  }
  if (str >= end) {
    return end;
  }
  return str;
}

static std::tuple<std::string, std::string, size_t> parse_inline_style(
    const char *str, const char *end) {
  if (str >= end) {
    return {"", "", 0};
  }

  const char *cursor = skip_white_space(str, end);

  const char *p = cursor;
  const char *pe = scan_next_string(p, end, ':');
  if (pe == p) {
    return {"", "", 0};
  }

  std::string key{p, static_cast<size_t>(pe - p)};
  p = skip_white_space(pe, end);

  if (*p == ':') {
    p++;
  }
  p = skip_white_space(p, end);

  pe = scan_next_string(p, end, ';');

  if (pe == p) {
    return {"", "", 0};
  }

  std::string value{p, static_cast<size_t>(pe - p)};

  pe = skip_white_space(pe, end);

  if (*pe == ';') {
    pe++;
  }

  return {key, value, pe - str};
}

bool RichTextParser::Parse(const char *content, size_t len) {
  lxml::XMLReader xml_reader(content, len);

  return xml_reader.Read(this);
}

void RichTextParser::HandleBeginTag(const char *name, size_t len) {
  std::string tag_name(name, len);

  auto node = std::make_shared<RichTextNode>(tag_name.c_str());

  if (current_node_ == nullptr) {
    nodes_.emplace_back(node);
  } else {
    current_node_->AddChild(node);
  }
  node->SetParent(current_node_);
  current_node_ = node.get();
}

void RichTextParser::HandleEndTag(const char *name, size_t len) {
  if (current_node_ == nullptr) {
    // some thing is error
    return;
  }

  current_node_ = current_node_->GetParent();
}

void RichTextParser::HandleAttribute(const char *name, size_t n_len,
                                     const char *value, size_t v_len) {
  if (!current_node_) {
    return;
  }

  std::string attr_name(name, n_len);
  std::string attr_value(value, v_len);

  if (attr_name != "style") {
    current_node_->SetProps(attr_name.c_str(),
                            lepus::Value(attr_value.c_str()));
    return;
  }

  // parse inline-style
  const char *cursor = value;
  const char *end = value + v_len;

  while (cursor < end) {
    std::string style_key;
    std::string style_value;
    size_t step;
    std::tie(style_key, style_value, step) = parse_inline_style(cursor, end);

    if (step == 0) {
      break;
    }

    if (!tasm::CSSProperty::IsPropertyValid(style_key)) {
      break;
    }

    auto css_id = tasm::CSSProperty::GetPropertyID(style_key);

    tasm::StyleMap style_map;
    tasm::CSSParserConfigs configs;

    if (!tasm::UnitHandler::Process(css_id, lepus::Value(style_value.c_str()),
                                    style_map, configs)) {
      break;
    }

    if (style_map.empty()) {
      break;
    }

    for (auto it : style_map) {
      current_node_->SetProps(
          tasm::CSSProperty::GetPropertyName(it.first).c_str(),
          it.second.GetValue());
    }

    cursor += step;
  }
}

void RichTextParser::HandleContent(const char *content, size_t len) {
  if (!current_node_) {
    HandleBeginTag("p", 1);
  }

  current_node_->AddChild(
      std::make_shared<RichTextNode>("", std::string(content, len)));
}

void RichTextParser::HandleError(const char *index, size_t offset,
                                 size_t total) {
  // do nothing for now
}

void RichTextParser::HandleEnd() {}

}  // namespace tasm
}  // namespace lynx
