// Copyright 2020 The Lynx Authors. All rights reserved.

#include "css/css_value.h"
#include "css_string_scanner.h"
#ifdef OS_WIN
#define _USE_MATH_DEFINES
#endif

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <string>

#include "base/string/string_number_convert.h"
#include "css/css_color.h"
#include "css/parser/css_string_parser.h"
#include "css/unit_handler.h"
#include "lepus/array.h"

namespace lynx {
namespace tasm {

struct TokenListStack final {
  explicit TokenListStack(CSSStringParser &parser) : parser_(parser) {}
  ~TokenListStack() {
    while (stack_depth_ > 0) {
      parser_.EndTokenList();
      stack_depth_--;
    }
  }

  std::vector<Token> EndTokenList() {
    stack_depth_--;
    return parser_.EndTokenList();
  }

  void BeginTokenList() {
    stack_depth_++;
    parser_.BeginTokenList();
  }

 private:
  CSSStringParser &parser_;
  int32_t stack_depth_ = 0;
};

CSSValue CSSStringParser::ParseBackground() {
  BeginParse();
  Advance();
  TokenListStack stack{*this};
  stack.BeginTokenList();
  auto image_array = lepus::CArray::Create();
  auto position_array = lepus::CArray::Create();
  auto size_array = lepus::CArray::Create();
  auto origin_array = lepus::CArray::Create();
  auto repeat_array = lepus::CArray::Create();
  auto clip_array = lepus::CArray::Create();
  while (BackgroundLayer()) {
    // try to consume ','
    Consume(TokenType::COMMA);
    // if <bg-layer> not contains image, may be this is in final layer
    if (!current_background_layer_.image) {
      continue;
    }
    BackgroundlayerToArray(current_background_layer_, image_array.Get(),
                           position_array.Get(), size_array.Get(),
                           origin_array.Get(), repeat_array.Get(),
                           clip_array.Get());
    BeginBackgroundLayer();
  }

  if (!FinalBackgroundLayer()) {
    return CSSValue(lepus::Value(lepus::CArray::Create()),
                    CSSValuePattern::ARRAY);
  }
  uint32_t color = current_background_layer_.color.has_value()
                       ? *current_background_layer_.color
                       : 0;
  if (current_background_layer_.image) {
    BackgroundlayerToArray(current_background_layer_, image_array.Get(),
                           position_array.Get(), size_array.Get(),
                           origin_array.Get(), repeat_array.Get(),
                           clip_array.Get());
  }

  auto bg_array = lepus::CArray::Create();

  bg_array->push_back(lepus::Value(color));
  bg_array->push_back(lepus::Value(image_array));
  // FIXME: old version parser not handle <position> <size> <repeat> <origin> in
  // short hand parse
  if (!legacy_parser_) {
    bg_array->push_back(lepus::Value(position_array));
    bg_array->push_back(lepus::Value(size_array));
    bg_array->push_back(lepus::Value(repeat_array));
    bg_array->push_back(lepus::Value(origin_array));
    bg_array->push_back(lepus::Value(clip_array));
  }

  return CSSValue(lepus::Value(bg_array), CSSValuePattern::ARRAY);
}

CSSValue CSSStringParser::ParseBackgroundImage() {
  BeginParse();
  Advance();
  TokenListStack stack{*this};
  stack.BeginTokenList();

  auto result = lepus::CArray::Create();
  while (!Check(TokenType::TOKEN_EOF) && !Check(TokenType::SEMICOLON) &&
         !Check(TokenType::ERROR)) {
    if (BackgroundImage()) {
      auto value = PopValue();
      result->push_back(lepus::Value(TokenTypeToENUM(value.value_type)));
      if (value.value) {
        result->push_back(*value.value);
      }
    } else {
      // parse failed
      result = lepus::CArray::Create();
      break;
    }
    if (Consume(TokenType::COMMA)) {
      // ','
      continue;
    }
  }

  return CSSValue(lepus::Value(result), CSSValuePattern::ARRAY);
}

std::string CSSStringParser::ParseUrl() {
  BeginParse();
  Advance();
  TokenListStack stack{*this};
  stack.BeginTokenList();
  std::string result;
  if (!Check(TokenType::TOKEN_EOF) && !Check(TokenType::SEMICOLON)) {
    if (Check(TokenType::URL) && Url()) {
      auto value = PopValue();
      if (value.value) {
        result = value.value->ToString();
      }
    } else {
      // parse failed
      result.clear();
    }
  }
  return result;
}

static void Complete4Sides(CSSValue side[4]) {
  if (!side[3].IsEmpty()) return;
  if (side[2].IsEmpty()) {
    if (side[1].IsEmpty()) side[1] = side[0];
    side[2] = side[0];
  }
  side[3] = side[1];
}

CSSValue CSSStringParser::ParseLength() {
  BeginParse();
  Advance();
  return Length();
}

CSSValue CSSStringParser::ParseSingleBorderRadius() {
  BeginParse();
  Advance();
  CSSValue radii[2] = {CSSValue::Empty(), CSSValue::Empty()};
  radii[0] = Length();
  if (radii[0].IsEmpty()) {
    return CSSValue::Empty();
  }
  // Single value should not have slash, for compatibility
  Consume(TokenType::SLASH);
  radii[1] = Length();
  if (radii[1].IsEmpty()) {
    radii[1] = radii[0];
  }
  auto array = lepus::CArray::Create();
  array->push_back(radii[0].GetValue());
  array->push_back(lepus::Value(static_cast<int>(radii[0].GetPattern())));
  array->push_back(radii[1].GetValue());
  array->push_back(lepus::Value(static_cast<int>(radii[1].GetPattern())));
  return CSSValue(lepus::Value(array), CSSValuePattern::ARRAY);
}

bool CSSStringParser::ParseBorderRadius(CSSValue horizontal_radii[4],
                                        CSSValue vertical_radii[4]) {
  BeginParse();
  Advance();
  if (Check(TokenType::ERROR)) {
    return false;
  }
  if (!BorderRadius(horizontal_radii, vertical_radii)) {
    return false;
  }
  if (!Check(TokenType::TOKEN_EOF)) {
    return false;
  }
  Complete4Sides(horizontal_radii);
  Complete4Sides(vertical_radii);
  return true;
}

bool CSSStringParser::BorderRadius(CSSValue horizontal_radii[4],
                                   CSSValue vertical_radii[4]) {
  unsigned horizontal_value_count = 0;
  for (; horizontal_value_count < 4 && !Check(TokenType::SLASH);
       ++horizontal_value_count) {
    CSSValue length_value = Length();
    if (length_value.IsEmpty()) {
      break;
    }
    horizontal_radii[horizontal_value_count] = length_value;
  }
  if (horizontal_radii[0].IsEmpty()) return false;
  if (!CheckAndAdvance(TokenType::SLASH)) {
    Complete4Sides(horizontal_radii);
    for (unsigned i = 0; i < 4; ++i) {
      vertical_radii[i] = horizontal_radii[i];
    }
    return true;
  } else {
    for (unsigned i = 0; i < 4; ++i) {
      CSSValue length_value = Length();
      if (length_value.IsEmpty()) {
        break;
      }
      vertical_radii[i] = length_value;
    }
    if (vertical_radii[0].IsEmpty()) {
      return false;
    }
  }
  return true;
}

CSSValue CSSStringParser::ParseGradient() {
  BeginParse();
  Advance();
  TokenListStack stack{*this};
  stack.BeginTokenList();

  auto result = lepus::CArray::Create();
  while (Gradient()) {
    auto value = PopValue();
    if (value.value_type != TokenType::LINEAR_GRADIENT &&
        value.value_type != TokenType::RADIAL_GRADIENT) {
      break;
    }

    lepus_value arr_value = *value.value;
    if (!arr_value.IsArrayOrJSArray()) {
      break;
    }
    result->push_back(lepus_value{TokenTypeToENUM(value.value_type)});
    result->push_back(arr_value);

    if (!Consume(TokenType::COMMA)) {
      break;
    }
  }

  return CSSValue{lepus_value{result}, CSSValuePattern::ARRAY};
}

CSSValue CSSStringParser::ParseBackgroundPosition() {
  BeginParse();
  Advance();
  TokenListStack stack{*this};
  stack.BeginTokenList();

  auto pos_arr = lepus::CArray::Create();
  while (BackgroundPosition()) {
    auto pos = lepus::CArray::Create();
    if (current_background_layer_.position_x_str.second.empty()) {
      pos->push_back(lepus::Value(current_background_layer_.position_x.first));
      pos->push_back(lepus::Value(current_background_layer_.position_x.second));
    } else {
      pos->push_back(
          lepus::Value(current_background_layer_.position_x_str.first));
      pos->push_back(lepus::Value(lepus::StringImpl::Create(
          current_background_layer_.position_x_str.second.c_str())));
    }
    if (current_background_layer_.position_y_str.second.empty()) {
      pos->push_back(lepus::Value(current_background_layer_.position_y.first));
      pos->push_back(lepus::Value(current_background_layer_.position_y.second));
    } else {
      pos->push_back(
          lepus::Value(current_background_layer_.position_y_str.first));
      pos->push_back(lepus::Value(lepus::StringImpl::Create(
          current_background_layer_.position_y_str.second.c_str())));
    }
    pos_arr->push_back(lepus::Value(pos));
    BeginBackgroundLayer();
    if (!Consume(TokenType::COMMA)) {
      break;
    }
  }

  return CSSValue(lepus::Value(pos_arr), CSSValuePattern::ARRAY);
}

CSSValue CSSStringParser::ParseBackgroundSize() {
  BeginParse();
  Advance();
  TokenListStack stack{*this};

  auto size_arr = lepus::CArray::Create();

  while (BackgroundSize()) {
    auto size = lepus::CArray::Create();
    if (legacy_parser_) {
      // FIXME: old version parse, <auto> <contain> and <cover> is all 100%
      // tailed
      if (current_background_layer_.size_x.second ==
              -1.f * static_cast<int>(starlight::BackgroundSizeType::kAuto) &&
          current_background_layer_.size_y.second ==
              -1.f * static_cast<int>(starlight::BackgroundSizeType::kAuto)) {
        size->push_back(lepus::Value(TokenTypeToENUM(TokenType::PERCENTAGE)));
        size->push_back(lepus::Value(100.0));
        size->push_back(lepus::Value(TokenTypeToENUM(TokenType::PERCENTAGE)));
        size->push_back(lepus::Value(100.0));
      } else {
        size->push_back(lepus::Value(current_background_layer_.size_x.first));
        size->push_back(lepus::Value(current_background_layer_.size_x.second));
        size->push_back(lepus::Value(current_background_layer_.size_y.first));
        size->push_back(lepus::Value(current_background_layer_.size_y.second));
      }
    } else {
      size->push_back(lepus::Value(current_background_layer_.size_x.first));
      size->push_back(lepus::Value(current_background_layer_.size_x.second));
      size->push_back(lepus::Value(current_background_layer_.size_y.first));
      size->push_back(lepus::Value(current_background_layer_.size_y.second));
    }

    size_arr->push_back(lepus::Value(size));
    BeginBackgroundLayer();
    if (!Consume(TokenType::COMMA)) {
      break;
    }
  }

  return CSSValue(lepus::Value(size_arr), CSSValuePattern::ARRAY);
}

CSSValue CSSStringParser::ParseBackgroundOrigin() {
  BeginParse();
  Advance();
  TokenListStack stack{*this};
  stack.BeginTokenList();

  auto origin_arr = lepus::CArray::Create();
  while (BackgroundOriginBox()) {
    auto stack_value = PopValue();
    origin_arr->push_back(
        lepus::Value(TokenTypeToENUM(stack_value.value_type)));

    if (!Consume(TokenType::COMMA)) {
      break;
    }
  }

  return CSSValue(lepus::Value(origin_arr), CSSValuePattern::ARRAY);
}

CSSValue CSSStringParser::ParseBackgroundClip() {
  return ParseBackgroundOrigin();
}

CSSValue CSSStringParser::ParseBackgroundRepeat() {
  BeginParse();
  Advance();
  TokenListStack stack{*this};
  stack.BeginTokenList();

  auto rep_arr = lepus::CArray::Create();

  while (BackgroundRepeatStyle()) {
    auto repeat = lepus::CArray::Create();

    auto stack_value = PopValue();
    repeat->push_back(lepus::Value(TokenTypeToENUM(stack_value.value_type)));
    repeat->push_back(
        lepus::Value(TokenTypeToENUM(*stack_value.second_value_type)));
    rep_arr->push_back(lepus::Value(repeat));

    if (!Consume(TokenType::COMMA)) {
      break;
    }
  }

  return CSSValue(lepus::Value(rep_arr), CSSValuePattern::ARRAY);
}

CSSValue CSSStringParser::ParseTextColor() {
  BeginParse();
  Advance();
  TokenListStack stack{*this};
  stack.BeginTokenList();

  if (Color() || LinearGradient() || RadialGradient()) {
    StackValue stack_value = PopValue();
    if (stack_value.value_type == TokenType::NUMBER) {
      return CSSValue(*stack_value.value, CSSValuePattern::NUMBER);
    }
    auto arr = lepus::CArray::Create();
    arr->push_back(lepus::Value(TokenTypeToENUM(stack_value.value_type)));
    arr->push_back(*stack_value.value);

    return CSSValue(lepus::Value(arr), CSSValuePattern::ARRAY);
  }

  return CSSValue(lepus::Value(CSSColor{0, 0, 0, 1.f}.Cast()),
                  CSSValuePattern::NUMBER);
}

// parse the text-decoration
// input: text-decoration CSS property
// output: the corresponding value of the property(store in array)
CSSValue CSSStringParser::ParseTextDecoration() {
  BeginParse();
  Advance();
  TokenListStack stack{*this};
  stack.BeginTokenList();

  auto result = lepus::CArray::Create();
  int flag = 0;
  while (!Check(TokenType::TOKEN_EOF) && !Check(TokenType::SEMICOLON) &&
         !Check(TokenType::ERROR)) {
    int temp_flag = 0;
    if (TextDecorationLine()) {  // text-decoration-line
      auto value = PopValue();
      if (value.value_type == TokenType::NONE) {
        result = lepus::CArray::Create();
        result->push_back(lepus::Value(TokenTypeToTextENUM(TokenType::NONE)));
        return CSSValue(lepus::Value(result), CSSValuePattern::ARRAY);
      }
      result->push_back(lepus::Value(TokenTypeToTextENUM(value.value_type)));
    } else if (TextDecorationStyle()) {  // text-decoration-style
      auto value = PopValue();
      result->push_back(lepus::Value(TokenTypeToTextENUM(value.value_type)));
      temp_flag |= 1 << 1;
    } else if (Color()) {  // text-decoration-color
      StackValue value = PopValue();
      result->push_back(lepus::Value(
          static_cast<uint32_t>(starlight::TextDecorationType::kColor)));
      if (value.value) {
        lepus::Value res = *value.value;
        result->push_back(res);
      }
      temp_flag |= 1 << 2;
    } else {
      result = lepus::CArray::Create();
      return CSSValue(lepus::Value(result), CSSValuePattern::EMPTY);
    }
    if ((temp_flag & flag) != 0) {
      result = lepus::CArray::Create();
      return CSSValue(lepus::Value(result), CSSValuePattern::EMPTY);
    }
    flag |= temp_flag;
  }
  return CSSValue(lepus::Value(result), CSSValuePattern::ARRAY);
}

CSSValue CSSStringParser::ParseFontSrc() {
  BeginParse();
  Advance();
  TokenListStack stack{*this};
  stack.BeginTokenList();

  auto result = lepus::CArray::Create();

  while (!Check(TokenType::TOKEN_EOF) && !Check(TokenType::SEMICOLON) &&
         !Check(TokenType::ERROR)) {
    bool check_url = false;
    bool check_local = false;
    bool check_format = false;

    if (Url()) {
      auto value = PopValue();
      result->push_back(lepus::Value(
          static_cast<uint32_t>(starlight::FontFaceSrcType::kUrl)));
      result->push_back(*value.value);

      check_url = true;
    }

    if (!check_url && Local()) {
      auto value = PopValue();
      result->push_back(lepus::Value(
          static_cast<uint32_t>(starlight::FontFaceSrcType::kLocal)));
      result->push_back(*value.value);
      check_local = true;
    }

    if (Format()) {
      // Ignore format for now
      PopValue();
      check_format = true;
    }

    if (Consume(TokenType::COMMA)) {
      if (!check_local && !check_url && !check_format) {
        result = lepus::CArray::Create();
        break;
      }

      continue;
    } else if (Consume(TokenType::SEMICOLON)) {
      // we have done
      break;
    } else {
      // any other unexpected token mark failed
      result = lepus::CArray::Create();
      break;
    }
  }

  return CSSValue(lepus::Value(result), CSSValuePattern::ARRAY);
}

CSSValue CSSStringParser::ParseFontWeight() {
  BeginParse();
  Advance();
  TokenListStack stack{*this};
  stack.BeginTokenList();

  auto result = lepus::CArray::Create();

  while (!Check(TokenType::TOKEN_EOF) && !Check(TokenType::SEMICOLON) &&
         !Check(TokenType::ERROR)) {
    if (Consume(TokenType::NORMAL)) {
      // Normal is just like font-weight: 400
      result->push_back(lepus::Value(static_cast<int32_t>(400)));
    } else if (Consume(TokenType::BOLD)) {
      // Bold is just like font-weight: 700
      result->push_back(lepus::Value(static_cast<int32_t>(700)));
    } else if (ConsumeAndSave(TokenType::NUMBER)) {
      auto number = TokenToInt(CurrentTokenList().back());
      // align number with 100
      number += 99;
      number /= 100;
      number *= 100;
      // clear token list
      CurrentTokenList().pop_back();
      result->push_back(lepus::Value(static_cast<int32_t>(number)));
    } else {
      // unexpected error reset result and return
      result = lepus::CArray::Create();
      break;
    }
  }

  return CSSValue(lepus::Value(result), CSSValuePattern::ARRAY);
}

CSSValue CSSStringParser::ParseBorderStyle() {
  BeginParse();
  Advance();
  TokenListStack stack{*this};
  stack.BeginTokenList();

  if (Color() || LinearGradient() || RadialGradient()) {
    StackValue stack_value = PopValue();
    if (stack_value.value_type == TokenType::NUMBER) {
      return CSSValue(*stack_value.value, CSSValuePattern::NUMBER);
    }
    auto arr = lepus::CArray::Create();
    arr->push_back(lepus::Value(TokenTypeToENUM(stack_value.value_type)));
    arr->push_back(*stack_value.value);

    return CSSValue(lepus::Value(arr), CSSValuePattern::ARRAY);
  }

  return CSSValue(lepus::Value(CSSColor{0, 0, 0, 1.f}.Cast()),
                  CSSValuePattern::NUMBER);
}

CSSValue CSSStringParser::ParseCursor() {
  BeginParse();
  Advance();
  TokenListStack stack{*this};
  stack.BeginTokenList();

  auto result = lepus::CArray::Create();
  while (!Check(TokenType::TOKEN_EOF) && !Check(TokenType::SEMICOLON) &&
         !Check(TokenType::ERROR)) {
    if (Url()) {
      auto value = PopValue();
      result->push_back(
          lepus::Value(static_cast<uint32_t>(starlight::CursorType::kUrl)));
      auto url = lepus::CArray::Create();
      url->push_back(*value.value);

      TokenListStack tls{*this};
      tls.BeginTokenList();
      if (ConsumeAndSave(TokenType::NUMBER) &&
          ConsumeAndSave(TokenType::NUMBER)) {
        auto x = TokenToDouble(CurrentTokenList()[0]);
        auto y = TokenToDouble(CurrentTokenList()[1]);
        url->push_back(lepus::Value(x));
        url->push_back(lepus::Value(y));
      } else {
        url->push_back(lepus::Value(0.f));
        url->push_back(lepus::Value(0.f));
      }
      result->push_back(lepus::Value(url));
    } else if (ConsumeAndSave(TokenType::IDENTIFIER)) {
      auto keyword = CurrentTokenList()[0];
      result->push_back(
          lepus::Value(static_cast<uint32_t>(starlight::CursorType::kKeyword)));
      result->push_back(lepus::Value(lepus::StringImpl::Create(
          std::string(keyword.start, keyword.length))));
    } else {
      result = lepus::CArray::Create();
      break;
    }
    if (Consume(TokenType::COMMA)) {
      // ','
      continue;
    }
  }
  return CSSValue(lepus::Value(result), CSSValuePattern::ARRAY);
}

lepus::Value CSSStringParser::ParseClipPath() {
  BeginParse();
  Advance();
  TokenListStack stack{*this};
  stack.BeginTokenList();
  if (BasicShape()) {
    auto shape = PopValue().value;
    return shape.value_or(lepus::Value());
  }
  UnitHandler::CSSWarning(true, parser_configs_.enable_css_strict_mode,
                          "clip-path parse error");
  return lepus::Value();
}

bool CSSStringParser::BasicShape() {
  switch (current_token_.type) {
    case TokenType::CIRCLE:
      return this->CSSStringParser::BasicShapeCircle();
    case TokenType::ELLIPSE:
      return this->CSSStringParser::BasicShapeEllipse();
    case TokenType::PATH:
      return this->CSSStringParser::BasicShapePath();
    case TokenType::SUPER_ELLIPSE:
      return this->CSSStringParser::SuperEllipse();
    case TokenType::INSET:
      return this->CSSStringParser::BasicShapeInset();
    default:
      return false;
  }
}

CSSValue CSSStringParser::Length() {
  TokenListStack stack{*this};
  stack.BeginTokenList();
  CSSValue css_value = CSSValue::Empty();
  if (!LengthOrPercentageValue()) {
    return css_value;
  }
  auto &token = CurrentTokenList().back();
  auto pattern = TokenTypeToENUM(token.type);
  if (pattern == static_cast<uint32_t>(CSSValuePattern::CALC) ||
      pattern == static_cast<uint32_t>(CSSValuePattern::ENV) ||
      pattern == static_cast<uint32_t>(CSSValuePattern::INTRINSIC)) {
    std::string input = std::string(CurrentTokenList().back().start,
                                    CurrentTokenList().back().length);
    css_value.SetValue(lepus::Value(lepus::StringImpl::Create(input.c_str())));
    css_value.SetPattern(static_cast<CSSValuePattern>(pattern));
  } else if (pattern == static_cast<uint32_t>(CSSValuePattern::ENUM)) {
    // We know the enum pattern is auto
    css_value.SetValue(
        lepus::Value(static_cast<int>(starlight::LengthValueType::kAuto)));
    css_value.SetPattern(CSSValuePattern::ENUM);
  } else if (pattern < static_cast<uint32_t>(CSSValuePattern::COUNT)) {
    auto dest = TokenToDouble(token);
    css_value.SetValue(lepus::Value(dest));
    css_value.SetPattern(static_cast<CSSValuePattern>(pattern));

    // As the FE developer's wish, red screen won't show if no value exists
    // before unit. Only show a red screen when the value is Inf or NaN.
    bool is_normal_number = !(std::isnan(dest) || std::isinf(dest));
    UnitHandler::CSSWarning(is_normal_number,
                            parser_configs_.enable_css_strict_mode,
                            "invalid length: %s", scanner_.content());
  }
  return css_value;
}

bool CSSStringParser::BackgroundLayer() {
  uint8_t full_byte =
      BG_ORIGIN | BG_CLIP_BOX | BG_IMAGE | BG_POSITION_AND_SIZE | BG_REPEAT;

  uint8_t byte = full_byte;

  while (!Check(TokenType::TOKEN_EOF) && !Check(TokenType::SEMICOLON) &&
         !Check(TokenType::COMMA) && !Check(TokenType::ERROR)) {
    uint8_t curr_byte = byte;

    // check origin box first
    if (curr_byte & BG_ORIGIN) {
      if (BackgroundOriginBox()) {
        curr_byte &= ~BG_ORIGIN;
        byte = curr_byte;
        // save stack value to background origin
        auto stack_value = PopValue();
        current_background_layer_.origin =
            TokenTypeToENUM(stack_value.value_type);
        current_background_layer_.clip = current_background_layer_.origin;
        continue;
      }
    } else if (BackgroundClipBox()) {
      if ((curr_byte & BG_CLIP_BOX) == 0) {
        return false;
      }
      curr_byte &= ~BG_CLIP_BOX;
      byte = curr_byte;
      // save stack value to background clip
      auto stack_value = PopValue();
      current_background_layer_.clip = TokenTypeToENUM(stack_value.value_type);
      continue;
    }

    if (BackgroundImage()) {
      if ((curr_byte & BG_IMAGE) == 0) {
        return false;
      }
      curr_byte &= ~BG_IMAGE;
      byte = curr_byte;
      // save stack value
      current_background_layer_.image = PopValue();
      continue;
    }

    if (BackgroundPositionAndSize()) {
      if ((curr_byte & BG_POSITION_AND_SIZE) == 0) {
        return false;
      }

      curr_byte &= ~BG_POSITION_AND_SIZE;
      byte = curr_byte;
      // TODO stack value is handled in BackgroundPositionAndSize(), may be this
      // function need to be pure for value propose
      continue;
    }

    if (BackgroundRepeatStyle()) {
      if ((curr_byte & BG_REPEAT) == 0) {
        return false;
      }

      curr_byte &= ~BG_REPEAT;
      byte = curr_byte;
      StackValue value = PopValue();
      current_background_layer_.repeat_x = TokenTypeToENUM(value.value_type);
      // repeat must have second value
      current_background_layer_.repeat_y =
          TokenTypeToENUM(*value.second_value_type);
      continue;
    }

    if (curr_byte == byte) {
      return false;
    }
  }

  return byte != full_byte;
}

bool CSSStringParser::BasicShapeInset() {
  // Begin with 'inset('
  if (!Consume(TokenType::INSET) || !Consume(TokenType::LEFT_PAREN)) {
    return false;
  }
  auto arr = lepus::CArray::Create();
  arr->push_back(
      lepus::Value(static_cast<uint32_t>(starlight::BasicShapeType::kInset)));
  CSSValue insets[4] = {CSSValue::Empty(), CSSValue::Empty(), CSSValue::Empty(),
                        CSSValue::Empty()};
  unsigned int length_value_num = 0;
  while (length_value_num < 4 && !Check(TokenType::TOKEN_EOF) &&
         !Check(TokenType::RIGHT_PAREN) && !Check(TokenType::ROUND) &&
         !Check(TokenType::SUPER_ELLIPSE)) {
    insets[length_value_num] = Length();
    if (insets[length_value_num].IsEmpty()) {
      return false;
    }
    length_value_num++;
  }
  // insets should be followed by 'round', 'super-ellipse' (lynx support) or
  // ')'.
  if (!Check(TokenType::RIGHT_PAREN) && !Check(TokenType::ROUND) &&
      !Check(TokenType::SUPER_ELLIPSE)) {
    return false;
  }
  Complete4Sides(insets);
  for (const auto &inset : insets) {
    arr->push_back(inset.GetValue());
    arr->push_back(lepus::Value(static_cast<uint32_t>(inset.GetPattern())));
  }

  switch (current_token_.type) {
    case TokenType::RIGHT_PAREN: {
      break;
    }
    case TokenType::SUPER_ELLIPSE: {
      Consume(TokenType::SUPER_ELLIPSE);
      if (!ConsumeAndSave(TokenType::NUMBER) || !Consume(TokenType::NUMBER)) {
        return false;
      }
      arr->push_back(lepus::Value(TokenToDouble(CurrentTokenList().back())));
      arr->push_back(lepus::Value(TokenToDouble(previous_token_)));
    }
    case TokenType::ROUND: {
      Consume(TokenType::ROUND);
      CSSValue x_radii[4] = {CSSValue::Empty(), CSSValue::Empty(),
                             CSSValue::Empty(), CSSValue::Empty()};
      CSSValue y_radii[4] = {CSSValue::Empty(), CSSValue::Empty(),
                             CSSValue::Empty(), CSSValue::Empty()};
      if (!BorderRadius(x_radii, y_radii)) {
        return false;
      }
      Complete4Sides(x_radii);
      Complete4Sides(y_radii);
      for (int i = 0; i < 4; i++) {
        arr->push_back(x_radii[i].GetValue());
        arr->push_back(lepus::Value(static_cast<int>(x_radii[i].GetPattern())));
        arr->push_back(y_radii[i].GetValue());
        arr->push_back(lepus::Value(static_cast<int>(y_radii[i].GetPattern())));
      }
    } break;
    default:
      // error
      return false;
  }
  // not closed with right parenthesis or has other token after ')'.
  if (!Consume(TokenType::RIGHT_PAREN) || !Consume(TokenType::TOKEN_EOF)) {
    return false;
  }
  PushValue(StackValue(lepus::Value(arr), TokenType::INSET));
  return true;
}

bool CSSStringParser::FinalBackgroundLayer() {
  TokenListStack stack{*this};
  stack.BeginTokenList();
  while (!Check(TokenType::TOKEN_EOF) && !Check(TokenType::SEMICOLON) &&
         !Check(TokenType::ERROR)) {
    if (BackgroundLayer()) {
      stack.EndTokenList();
      stack.BeginTokenList();
      continue;
    } else if (Color()) {
      StackValue value = PopValue();
      current_background_layer_.color = value.value->UInt32();
    } else {
      break;
    }
  }

  if (!Check(TokenType::SEMICOLON) && !Check(TokenType::TOKEN_EOF)) {
    return false;
  }

  return true;
}

bool CSSStringParser::BackgroundImage() {
  TokenListStack stack{*this};
  stack.BeginTokenList();
  if (ConsumeAndSave(TokenType::NONE)) {
    PushValue(MakeStackValue(stack.EndTokenList()));
    return true;
  } else if (Check(TokenType::URL)) {
    return Url();
  } else {
    return Gradient();
  }
}

bool CSSStringParser::BackgroundOriginBox() {
  TokenListStack stack{*this};
  stack.BeginTokenList();
  if (Box()) {
    PushValue(MakeStackValue(stack.EndTokenList()));
    return true;
  }
  return false;
}

bool CSSStringParser::BackgroundClipBox() { return BackgroundOriginBox(); }

bool CSSStringParser::Box() {
  return ConsumeAndSave(TokenType::PADDING_BOX) ||
         ConsumeAndSave(TokenType::BORDER_BOX) ||
         ConsumeAndSave(TokenType::CONTENT_BOX);
}

bool CSSStringParser::BackgroundPositionAndSize() {
  if (BackgroundPosition() && !Check(TokenType::COMMA) &&
      !Check(TokenType::SEMICOLON)) {
    // if pass <bg-position> parse and not reach ',' or end of string, try parse
    // <bg-size>
    if (Check(TokenType::SLASH)) {
      return Consume(TokenType::SLASH) && BackgroundSize();
    }
  } else {
    return false;
  }

  return true;
}

bool CSSStringParser::BackgroundPosition() {
  TokenListStack stack{*this};
  stack.BeginTokenList();
  if (!ConsumeAndSave(TokenType::LEFT)       // left
      && !ConsumeAndSave(TokenType::CENTER)  // center
      && !ConsumeAndSave(TokenType::RIGHT)   // right
      && !ConsumeAndSave(TokenType::TOP)     // top
      && !ConsumeAndSave(TokenType::BOTTOM)  // bottom
      && !LengthOrPercentageValue()) {
    return false;
  }

  Token last_token = CurrentTokenList().back();
  TokenType first_type = last_token.type;
  if (last_token.type == TokenType::CALC) {
    std::string first_value_str =
        std::string(last_token.start, last_token.length);
    // remain the string expression
    current_background_layer_.position_x_str = std::pair<uint32_t, std::string>{
        TokenTypeToENUM(first_type), first_value_str};
  } else {
    float first_value;
    MakeCSSLength(last_token, first_type, first_value);

    // first value
    if (first_type == TokenType::LEFT || first_type == TokenType::RIGHT) {
      // left right set to position x
      current_background_layer_.position_x = std::pair<uint32_t, float>{
          TokenTypeToENUM(first_type),
          -1.f * static_cast<int>(TokenTypeToENUM(first_type))};

      current_background_layer_.position_y =
          std::pair<uint32_t, float>{TokenTypeToENUM(TokenType::CENTER), 0.5f};
    } else if (first_type == TokenType::TOP ||
               first_type == TokenType::BOTTOM) {
      // top bottom set to position y
      current_background_layer_.position_y = std::pair<uint32_t, float>{
          TokenTypeToENUM(first_type),
          -1.f * static_cast<int>(TokenTypeToENUM(first_type))};

      current_background_layer_.position_x =
          std::pair<uint32_t, float>{TokenTypeToENUM(TokenType::CENTER), 0.5f};
    } else if (first_type == TokenType::CENTER) {
      // center set to both
      current_background_layer_.position_x =
          current_background_layer_.position_y = std::pair<uint32_t, float>{
              TokenTypeToENUM(TokenType::CENTER), 0.5f};
    } else {
      // other type value
      current_background_layer_.position_x =
          std::pair<uint32_t, float>{TokenTypeToENUM(first_type), first_value};

      current_background_layer_.position_y =
          std::pair<uint32_t, float>{TokenTypeToENUM(TokenType::CENTER), 0.5f};
    }
  }

  if (!ConsumeAndSave(TokenType::LEFT) &&    // left
      !ConsumeAndSave(TokenType::CENTER) &&  // center
      !ConsumeAndSave(TokenType::RIGHT) &&   // right
      !ConsumeAndSave(TokenType::TOP) &&     // top
      !ConsumeAndSave(TokenType::BOTTOM) &&  // bottom
      !LengthOrPercentageValue()) {
    return true;
  }

  last_token = CurrentTokenList().back();
  TokenType second_type = last_token.type;
  stack.EndTokenList();
  if (last_token.type == TokenType::CALC) {
    std::string second_value_str =
        std::string(last_token.start, last_token.length);
    // remain the string expression
    current_background_layer_.position_y_str = std::pair<uint32_t, std::string>{
        TokenTypeToENUM(second_type), second_value_str};
  } else {
    float second_value;
    MakeCSSLength(last_token, second_type, second_value);

    if (second_type == TokenType::LEFT || second_type == TokenType::RIGHT) {
      // second value not specify axis y
      if (first_type == TokenType::LEFT || first_type == TokenType::RIGHT) {
        // parse failed, [left, left] or [left, right]
        return false;
      }

      current_background_layer_.position_x = std::pair<uint32_t, float>{
          TokenTypeToENUM(second_type),
          -1.f * static_cast<int>(TokenTypeToENUM(second_type))};
    } else if (second_type == TokenType::TOP ||
               second_type == TokenType::BOTTOM ||
               second_type == TokenType::CENTER) {
      current_background_layer_.position_y = std::pair<uint32_t, float>{
          TokenTypeToENUM(second_type),
          -1.f * static_cast<int>(TokenTypeToENUM(second_type))};
    } else {
      current_background_layer_.position_y = std::pair<uint32_t, float>{
          TokenTypeToENUM(second_type), second_value};
    }
  }
  return true;
}

bool CSSStringParser::BackgroundSize() {
  if (Consume(TokenType::COVER)) {
    current_background_layer_.size_x = std::pair<uint32_t, float>{
        TokenTypeToENUM(TokenType::NUMBER),
        -1.f * static_cast<int>(starlight::BackgroundSizeType::kCover)};
    current_background_layer_.size_y = std::pair<uint32_t, float>{
        TokenTypeToENUM(TokenType::NUMBER),
        -1.f * static_cast<int>(starlight::BackgroundSizeType::kCover)};
    return true;
  } else if (Consume(TokenType::CONTAIN)) {
    current_background_layer_.size_x = std::pair<uint32_t, float>{
        TokenTypeToENUM(TokenType::NUMBER),
        -1.f * static_cast<int>(starlight::BackgroundSizeType::kContain)};
    current_background_layer_.size_y = std::pair<uint32_t, float>{
        TokenTypeToENUM(TokenType::NUMBER),
        -1.f * static_cast<int>(starlight::BackgroundSizeType::kContain)};
    return true;
  }

  TokenListStack stack{*this};
  stack.BeginTokenList();
  // check first value
  if (!ConsumeAndSave(TokenType::AUTO) && !LengthOrPercentageValue()) {
    return false;
  }

  Token last_token = CurrentTokenList().back();
  TokenType type = last_token.type;
  float value;
  MakeCSSLength(last_token, type, value);
  if (type == TokenType::AUTO) {
    current_background_layer_.size_x = current_background_layer_.size_y =
        std::pair<uint32_t, float>{
            TokenTypeToENUM(TokenType::NUMBER),
            -1.f * static_cast<int>(starlight::BackgroundSizeType::kAuto)};
  } else {
    current_background_layer_.size_x =
        std::pair<uint32_t, float>{TokenTypeToENUM(type), value};
    current_background_layer_.size_y = std::pair<uint32_t, float>{
        TokenTypeToENUM(TokenType::NUMBER),
        -1.f * static_cast<int>(starlight::BackgroundSizeType::kAuto)};
  }

  if (!ConsumeAndSave(TokenType::AUTO) && !LengthOrPercentageValue()) {
    return true;
  }
  last_token = stack.EndTokenList().back();
  type = last_token.type;
  MakeCSSLength(last_token, type, value);
  if (type == TokenType::AUTO) {
    current_background_layer_.size_y = std::pair<uint32_t, float>{
        TokenTypeToENUM(TokenType::NUMBER),
        -1.f * static_cast<int>(starlight::BackgroundSizeType::kAuto)};
  } else {
    current_background_layer_.size_y =
        std::pair<uint32_t, float>{TokenTypeToENUM(type), value};
  }

  return true;
}

bool CSSStringParser::BackgroundRepeatStyle() {
  TokenListStack stack{*this};
  stack.BeginTokenList();
  if (ConsumeAndSave(TokenType::REPEAT_X)     // repeat-x
      || ConsumeAndSave(TokenType::REPEAT_Y)  // repeat-y
  ) {
    // make sure no other repeat style follow this two token
    if (Check(TokenType::REPEAT) || Check(TokenType::REPEAT_X) ||
        Check(TokenType::REPEAT_Y) || Check(TokenType::NO_REPEAT) ||
        Check(TokenType::SPACE) || Check(TokenType::ROUND)) {
      return false;
    }
    // repeat-x | repeat-y can only appear once
    PushValue(MakeStackValue(stack.EndTokenList()));
    return true;
  }

  if (!ConsumeAndSave(TokenType::REPEAT)        // repeat
      && !ConsumeAndSave(TokenType::NO_REPEAT)  // no-repeat
      && !ConsumeAndSave(TokenType::SPACE)      // space
      && !ConsumeAndSave(TokenType::ROUND)      // round
  ) {
    return false;
  }
  // try to check if there is second value
  ConsumeAndSave(TokenType::REPEAT);
  ConsumeAndSave(TokenType::NO_REPEAT);
  ConsumeAndSave(TokenType::SPACE);
  ConsumeAndSave(TokenType::ROUND);

  PushValue(MakeStackValue(stack.EndTokenList()));
  return true;
}

bool CSSStringParser::TextDecorationLine() {
  TokenListStack stack{*this};
  stack.BeginTokenList();
  if (ConsumeAndSave(TokenType::NONE) || ConsumeAndSave(TokenType::UNDERLINE) ||
      ConsumeAndSave(TokenType::LINE_THROUGH)) {
    PushValue(MakeStackValue(stack.EndTokenList()));
    return true;
  }
  return false;
}

bool CSSStringParser::TextDecorationStyle() {
  TokenListStack stack{*this};
  stack.BeginTokenList();
  if (ConsumeAndSave(TokenType::SOLID) || ConsumeAndSave(TokenType::DOUBLE) ||
      ConsumeAndSave(TokenType::DOTTED) || ConsumeAndSave(TokenType::DASHED) ||
      ConsumeAndSave(TokenType::WAVY)) {
    PushValue(MakeStackValue(stack.EndTokenList()));
    return true;
  }
  return false;
}

bool CSSStringParser::Format() {
  TokenListStack stack{*this};
  stack.BeginTokenList();

  if (!ConsumeAndSave(TokenType::FORMAT)) {
    return false;
  }

  if (!Consume(TokenType::LEFT_PAREN)) {
    return false;
  }

  if (!ConsumeAndSave(TokenType::STRING)) {
    return false;
  }

  if (!Consume(TokenType::RIGHT_PAREN)) {
    return false;
  }

  PushValue(MakeStackValue(stack.EndTokenList()));

  return true;
}

bool CSSStringParser::Local() {
  TokenListStack stack{*this};
  stack.BeginTokenList();
  ConsumeAndSave(TokenType::LOCAL);
  if (!Consume(TokenType::LEFT_PAREN)) {  // (
    return false;
  }
  if (ConsumeAndSave(TokenType::STRING) && Consume(TokenType::RIGHT_PAREN)) {
    PushValue(MakeStackValue(stack.EndTokenList()));
    return true;
  }

  if (!Check(TokenType::RIGHT_PAREN)) {
    // may be this <local>(...) with no quotes
    Token virtual_token;
    virtual_token.start = previous_token_.start + previous_token_.length;
    while (!Check(TokenType::RIGHT_PAREN)) {
      if (Check(TokenType::TOKEN_EOF) || Check(TokenType::ERROR)) {
        return false;
      }
      Advance();
    }

    virtual_token.length =
        static_cast<uint32_t>(current_token_.start - virtual_token.start);
    if (!Consume(TokenType::RIGHT_PAREN)) {
      return false;
    }
    CurrentTokenList().push_back(virtual_token);
    PushValue(MakeStackValue(stack.EndTokenList()));
    return true;
  }
  return false;
}

bool CSSStringParser::Url() {
  TokenListStack stack{*this};
  stack.BeginTokenList();
  ConsumeAndSave(TokenType::URL);
  if (!Consume(TokenType::LEFT_PAREN)) {  // (
    return false;
  }
  if (ConsumeAndSave(TokenType::STRING) &&  // <string>
      Consume(TokenType::RIGHT_PAREN)) {    // )
    PushValue(MakeStackValue(stack.EndTokenList()));
    return true;
  }

  if (ConsumeAndSave(TokenType::DATA)) {
    while (!Check(TokenType::RIGHT_PAREN)) {
      if (Check(TokenType::TOKEN_EOF) || Check(TokenType::ERROR)) {
        return false;
      }
      Advance();
    }
    Token const &data_token = CurrentTokenList().back();
    CurrentTokenList().back().length =
        static_cast<uint32_t>(current_token_.start - data_token.start);
    if (!Consume(TokenType::RIGHT_PAREN)) {
      return false;
    }
    PushValue(MakeStackValue(stack.EndTokenList()));
    return true;
  }

  if (!Check(TokenType::RIGHT_PAREN)) {
    // may be this is <url>(...) with no quotes
    Token virtual_token;
    virtual_token.start = previous_token_.start + previous_token_.length;
    while (!Check(TokenType::RIGHT_PAREN)) {
      if (Check(TokenType::TOKEN_EOF) || Check(TokenType::ERROR)) {
        return false;
      }
      Advance();
    }

    virtual_token.length =
        static_cast<uint32_t>(current_token_.start - virtual_token.start);
    if (!Consume(TokenType::RIGHT_PAREN)) {
      return false;
    }
    CurrentTokenList().push_back(virtual_token);
    PushValue(MakeStackValue(stack.EndTokenList()));
    return true;
  }

  return false;
}

bool CSSStringParser::Gradient() {
  if (Check(TokenType::LINEAR_GRADIENT)) {
    return LinearGradient();
  } else if (Check(TokenType::RADIAL_GRADIENT)) {
    return RadialGradient();
  } else {
    return false;
  }
}

bool CSSStringParser::LinearGradient() {
  if (!ConsumeAndSave(TokenType::LINEAR_GRADIENT)) {
    return false;
  }

  if (!Consume(TokenType::LEFT_PAREN)) {  // (
    return false;
  }

  auto side_or_corner = starlight::LinearGradientDirection::kBottom;

  float angle = 180.0;
  if (Check(TokenType::NUMBER)) {
    TokenListStack stack{*this};
    stack.BeginTokenList();
    if (!AngleValue()) {
      return false;
    }
    side_or_corner = starlight::LinearGradientDirection::kAngle;
    auto token_list = stack.EndTokenList();
    angle = TokenToAngleValue(token_list.front());
    // ','
    if (!Consume(TokenType::COMMA)) {
      return false;
    }
  } else if (Check(TokenType::TO)) {
    Consume(TokenType::TO);
    if (Consume(TokenType::LEFT)) {
      if (Consume(TokenType::TOP)) {
        angle = 315.f;
        side_or_corner = starlight::LinearGradientDirection::kTopLeft;
      } else if (Consume(TokenType::BOTTOM)) {
        angle = 225.f;
        side_or_corner = starlight::LinearGradientDirection::kBottomLeft;
      } else {
        angle = 270.f;
        side_or_corner = starlight::LinearGradientDirection::kLeft;
      }
    } else if (Consume(TokenType::BOTTOM)) {
      if (Consume(TokenType::LEFT)) {
        angle = 225.f;
        side_or_corner = starlight::LinearGradientDirection::kBottomLeft;
      } else if (Consume(TokenType::RIGHT)) {
        angle = 135.f;
        side_or_corner = starlight::LinearGradientDirection::kBottomRight;
      } else {
        angle = 180.f;
        side_or_corner = starlight::LinearGradientDirection::kBottom;
      }
    } else if (Consume(TokenType::TOP)) {
      if (Consume(TokenType::LEFT)) {
        angle = 315.f;
        side_or_corner = starlight::LinearGradientDirection::kTopLeft;
      } else if (Consume(TokenType::RIGHT)) {
        angle = 45.f;
        side_or_corner = starlight::LinearGradientDirection::kTopRight;
      } else {
        angle = 0.f;
        side_or_corner = starlight::LinearGradientDirection::kTop;
      }
    } else if (Consume(TokenType::RIGHT)) {
      if (Consume(TokenType::TOP)) {
        angle = 45.f;
        side_or_corner = starlight::LinearGradientDirection::kTopRight;
      } else if (Consume(TokenType::BOTTOM)) {
        angle = 135.f;
        side_or_corner = starlight::LinearGradientDirection::kBottomRight;
      } else {
        angle = 90.f;
        side_or_corner = starlight::LinearGradientDirection::kRight;
      }
    } else {
      return false;
    }
    // ','
    if (!Consume(TokenType::COMMA)) {
      return false;
    }
  } else if (Consume(TokenType::TOLEFT)) {
    angle = 270.f;
    side_or_corner = starlight::LinearGradientDirection::kLeft;
    UnitHandler::CSSWarning(
        true, parser_configs_.enable_css_strict_mode,
        " angle value 'toleft' not support anymore, use 'to left' instead");
    // ','
    if (!Consume(TokenType::COMMA)) {
      return false;
    }
  } else if (Consume(TokenType::TOBOTTOM)) {
    angle = 180.f;
    side_or_corner = starlight::LinearGradientDirection::kBottom;
    UnitHandler::CSSWarning(
        true, parser_configs_.enable_css_strict_mode,
        " angle value 'tobottom' not support anymore, use 'to bottom' instead");
    // ','
    if (!Consume(TokenType::COMMA)) {
      return false;
    }
  } else if (Consume(TokenType::TOTOP)) {
    side_or_corner = starlight::LinearGradientDirection::kTop;
    angle = 0.f;
    UnitHandler::CSSWarning(
        true, parser_configs_.enable_css_strict_mode,
        " angle value 'totop' not support anymore, use 'to top' instead");
    // ','
    if (!Consume(TokenType::COMMA)) {
      return false;
    }
  } else if (Consume(TokenType::TORIGHT)) {
    side_or_corner = starlight::LinearGradientDirection::kRight;
    angle = 90.f;
    UnitHandler::CSSWarning(
        true, parser_configs_.enable_css_strict_mode,
        " angle value 'toright' not support anymore, use 'to right' instead");
    // ','
    if (!Consume(TokenType::COMMA)) {
      return false;
    }
  }

  auto color_array = lepus::CArray::Create();
  auto position_array = lepus::CArray::Create();

  if (!ColorStopList(color_array, position_array)) {
    return false;
  }

  if (color_array->size() == 0) {
    return false;
  }

  auto linear_gradient_obj = lepus::CArray::Create();
  linear_gradient_obj->push_back(lepus::Value(angle));
  linear_gradient_obj->push_back(lepus::Value(color_array));
  linear_gradient_obj->push_back(lepus::Value(position_array));
  linear_gradient_obj->push_back(
      lepus::Value(static_cast<uint32_t>(side_or_corner)));

  PushValue(StackValue(lepus::Value(linear_gradient_obj),
                       TokenType::LINEAR_GRADIENT));
  return true;
}

bool CSSStringParser::RadialGradient() {
  Consume(TokenType::RADIAL_GRADIENT);
  if (!Consume(TokenType::LEFT_PAREN)) {  // '('
    return false;
  }

  auto color_array = lepus::CArray::Create();
  auto position_array = lepus::CArray::Create();

  uint32_t shape =
      static_cast<uint32_t>(starlight::RadialGradientShapeType::kEllipse);
  uint32_t shape_size =
      static_cast<uint32_t>(starlight::RadialGradientSizeType::kFarthestCorner);

  uint32_t pos_x = static_cast<uint32_t>(tasm::CSSValuePattern::PERCENT);
  float pos_x_value = 50.f;
  uint32_t pos_y = pos_x;
  float pos_y_value = pos_x_value;

  bool has_ending_shape = false;
  if (EndingShape()) {
    StackValue value = PopValue();
    shape = TokenTypeToENUM(value.value_type);
    has_ending_shape = true;
  }

  if (EndingShapeSize()) {
    StackValue value = PopValue();
    shape_size = TokenTypeToENUM(value.value_type);
    has_ending_shape = true;
  }

  if (Consume(TokenType::AT)) {
    if (!BackgroundPosition()) {
      return false;
    }

    pos_x = current_background_layer_.position_x.first;
    pos_x_value = current_background_layer_.position_x.second;
    pos_y = current_background_layer_.position_y.first;
    pos_y_value = current_background_layer_.position_y.second;
    has_ending_shape = true;
  }

  if (has_ending_shape && !Consume(TokenType::COMMA)) {
    return false;
  }

  if (!ColorStopList(color_array, position_array)) {
    return false;
  }

  auto radial_gradient_obj = lepus::CArray::Create();
  // ending-shape size position
  {
    auto ending_shape_arr = lepus::CArray::Create();
    ending_shape_arr->push_back(lepus::Value(shape));
    ending_shape_arr->push_back(lepus::Value(shape_size));
    ending_shape_arr->push_back(lepus::Value(pos_x));
    ending_shape_arr->push_back(lepus::Value(pos_x_value));
    ending_shape_arr->push_back(lepus::Value(pos_y));
    ending_shape_arr->push_back(lepus::Value(pos_y_value));
    radial_gradient_obj->push_back(lepus::Value(ending_shape_arr));
  }
  radial_gradient_obj->push_back(lepus::Value(color_array));
  radial_gradient_obj->push_back(lepus::Value(position_array));

  PushValue(StackValue(lepus::Value(radial_gradient_obj),
                       TokenType::RADIAL_GRADIENT));

  return true;
}

bool CSSStringParser::EndingShape() {
  if (Consume(TokenType::ELLIPSE)) {
    PushValue(StackValue(TokenType::ELLIPSE));
    return true;
  } else if (Consume(TokenType::CIRCLE)) {
    PushValue(StackValue(TokenType::CIRCLE));
    return true;
  } else {
    return false;
  }
}

bool CSSStringParser::EndingShapeSize() {
  if (Consume(TokenType::FARTHEST_CORNER)) {
    PushValue(StackValue(TokenType::FARTHEST_CORNER));
    return true;
  } else if (Consume(TokenType::FARTHEST_SIDE)) {
    PushValue(StackValue(TokenType::FARTHEST_SIDE));
    return true;
  } else if (Consume(TokenType::CLOSEST_CORNER)) {
    PushValue(StackValue(TokenType::CLOSEST_CORNER));
    return true;
  } else if (Consume(TokenType::CLOSEST_SIDE)) {
    PushValue(StackValue(TokenType::CLOSEST_SIDE));
    return true;
  } else if (LengthOrPercentageValue() && LengthOrPercentageValue()) {
    // TODO (tangruiwen), support ending shape size with lengh or percentage
    PopValue();
    PopValue();
    PushValue(StackValue(TokenType::CLOSEST_SIDE));
    return true;
  } else {
    return false;
  }
}

bool CSSStringParser::ColorStopList(
    const base::scoped_refptr<lepus::CArray> &color_array,
    const base::scoped_refptr<lepus::CArray> &stop_array) {
  size_t position_begin_index = -1;
  float position_begin_value = 0.f;
  std::vector<uint32_t> temp_color_list;
  std::vector<float> temp_stop_list;
  while (Color() && !(Check(TokenType::TOKEN_EOF))) {
    auto color_value = PopValue();
    temp_color_list.emplace_back(color_value.value->UInt32());
    if (Check(TokenType::COMMA)) {
      // ',' after color, no position
      if (position_begin_index == static_cast<size_t>(-1)) {
        position_begin_index = temp_color_list.size() - 1;
      }
      Consume(TokenType::COMMA);
      continue;
    }
    if (Check(TokenType::RIGHT_PAREN)) {
      break;
    }
    TokenListStack stack{*this};
    stack.BeginTokenList();
    if (!PositionValue()) {
      return false;
    }
    auto token_list = stack.EndTokenList();
    float current_stop_position = TokenToDouble(token_list.front());
    if (token_list.front().type == TokenType::NUMBER) {
      current_stop_position *= 100.f;
    }

    if (position_begin_index != static_cast<size_t>(-1)) {
      // fill empty position with previouse stop position and current stop
      // position

      size_t current_index = temp_color_list.size() - 1;
      if (position_begin_index > 0) {
        position_begin_value = temp_stop_list[position_begin_index - 1];
      } else if (position_begin_index == 0) {
        position_begin_index++;
        temp_stop_list.emplace_back(0.f);
      }

      float step = (current_stop_position - position_begin_value) /
                   (current_index - position_begin_index + 1);

      for (size_t j = position_begin_index; j < current_index; j++) {
        temp_stop_list.emplace_back(position_begin_value +
                                    (j - position_begin_index + 1) * step);
      }
    }
    temp_stop_list.emplace_back(current_stop_position);
    // clear posotion begin index
    position_begin_index = -1;

    if (Check(TokenType::COMMA)) {
      Consume(TokenType::COMMA);
    }
  }

  if (!Consume(TokenType::RIGHT_PAREN)) {
    return false;
  }
  // fill empty position to the end
  int32_t fill_step =
      static_cast<int32_t>(temp_color_list.size() - temp_stop_list.size());
  if (!temp_stop_list.empty() && fill_step > 0) {
    float step_value = (100.f - temp_stop_list.back()) / fill_step;
    float begin_value = temp_stop_list.back();
    for (int32_t i = 1; i < fill_step; i++) {
      temp_stop_list.emplace_back(begin_value + step_value * i);
    }
    temp_stop_list.emplace_back(100.f);
  }
  // clamp color and stop
  ClampColorAndStopList(temp_color_list, temp_stop_list);

  if (temp_color_list.size() < 2 ||
      (!temp_stop_list.empty() &&
       temp_stop_list.size() != temp_color_list.size())) {
    // gradient need at least two colors
    return false;
  }

  for (auto color_value : temp_color_list) {
    color_array->push_back(lepus::Value(color_value));
  }

  for (auto stop_value : temp_stop_list) {
    stop_array->push_back(lepus::Value(stop_value));
  }

  return true;
}

bool CSSStringParser::AngleValue() {
  if (!ConsumeAndSave(TokenType::NUMBER)) {
    return false;
  }

  if (Consume(TokenType::DEG)) {
    CurrentTokenList().back().type = TokenType::DEG;
    return true;
  } else if (Consume(TokenType::TURN)) {
    CurrentTokenList().back().type = TokenType::TURN;
    return true;
  } else if (Consume(TokenType::RAD)) {
    CurrentTokenList().back().type = TokenType::RAD;
    return true;
  } else if (Consume(TokenType::GRAD)) {
    CurrentTokenList().back().type = TokenType::GRAD;
    return true;
  }

  return false;
}

bool CSSStringParser::Color() {
  if (CheckAndAdvance(TokenType::RGBA)) {
    return RGBAColor();
  } else if (CheckAndAdvance(TokenType::RGB)) {
    return RGBColor();
  } else if (CheckAndAdvance(TokenType::HSLA)) {
    return HSLAColor();
  } else if (CheckAndAdvance(TokenType::HSL)) {
    return HSLColor();
  } else if (Check(TokenType::HEX)) {
    return HexColor();
  } else if (CheckAndAdvance(TokenType::IDENTIFIER)) {
    return NamedColor();
  }
  return false;
}

bool CSSStringParser::RGBAColor() {
  TokenListStack stack{*this};
  stack.BeginTokenList();
  // save RGBA prefix
  CurrentTokenList().emplace_back(previous_token_);

  if (Consume(TokenType::LEFT_PAREN)      // (
      && NumberValue()                    // Number 1
      && Consume(TokenType::COMMA)        // ,
      && NumberValue()                    // Number 2
      && Consume(TokenType::COMMA)        // ,
      && NumberValue()                    // Number 3
      && Consume(TokenType::COMMA)        // ,
      && AlphaValue()                     // Alpha
      && Consume(TokenType::RIGHT_PAREN)  // )
  ) {
    PushValue(MakeColorValue(stack.EndTokenList()));
    return true;
  } else {
    return false;
  }
}

bool CSSStringParser::RGBColor() {
  TokenListStack stack{*this};
  stack.BeginTokenList();
  // save RGB prefix
  CurrentTokenList().emplace_back(previous_token_);

  if (Consume(TokenType::LEFT_PAREN)      // (
      && NumberValue()                    // Number 1
      && Consume(TokenType::COMMA)        // ,
      && NumberValue()                    // Number 2
      && Consume(TokenType::COMMA)        // ,
      && NumberValue()                    // Number 3
      && Consume(TokenType::RIGHT_PAREN)  // )
  ) {
    PushValue(MakeColorValue(stack.EndTokenList()));
    return true;
  } else {
    return false;
  }
}

bool CSSStringParser::HSLAColor() {
  TokenListStack stack{*this};
  stack.BeginTokenList();
  // save hsla prefix
  CurrentTokenList().emplace_back(previous_token_);

  if (Consume(TokenType::LEFT_PAREN)      // (
      && NumberValue()                    // hue
      && Consume(TokenType::COMMA)        // ,
      && PercentageValue()                // percentage
      && Consume(TokenType::COMMA)        // ,
      && PercentageValue()                // percentage
      && Consume(TokenType::COMMA)        // ,
      && AlphaValue()                     // alpha
      && Consume(TokenType::RIGHT_PAREN)  // )
  ) {
    PushValue(MakeColorValue(stack.EndTokenList()));
    return true;
  } else {
    return false;
  }
}

bool CSSStringParser::HSLColor() {
  TokenListStack stack{*this};
  stack.BeginTokenList();
  // save hsl
  CurrentTokenList().emplace_back(previous_token_);

  if (Consume(TokenType::LEFT_PAREN)      // (
      && NumberValue()                    // hue
      && Consume(TokenType::COMMA)        // ,
      && PercentageValue()                // percentage
      && Consume(TokenType::COMMA)        // ,
      && PercentageValue()                // percentage
      && Consume(TokenType::RIGHT_PAREN)  // )
  ) {
    PushValue(MakeColorValue(stack.EndTokenList()));
    return true;
  } else {
    return false;
  }
}

bool CSSStringParser::HexColor() {
  TokenListStack stack{*this};
  stack.BeginTokenList();
  // number
  if (HexValue()) {
    PushValue(MakeColorValue(stack.EndTokenList()));
    return true;
  }
  return false;
}

bool CSSStringParser::NamedColor() {
  BeginTokenList();
  CurrentTokenList().emplace_back(previous_token_);
  PushValue(MakeColorValue(EndTokenList()));
  return true;
}

bool CSSStringParser::AlphaValue() {
  if (!Check(TokenType::NUMBER)) {
    return false;
  }

  if (!NumberValue()) {
    return false;
  }
  if (Consume(TokenType::PERCENTAGE)) {
    CurrentTokenList().back().type = TokenType::PERCENTAGE;
  }

  return true;
}

bool CSSStringParser::HexValue() { return ConsumeAndSave(TokenType::HEX); }

bool CSSStringParser::LengthOrPercentageValue() {
  if (ConsumeAndSave(TokenType::CALC) || ConsumeAndSave(TokenType::ENV) ||
      ConsumeAndSave(TokenType::FIT_CONTENT) ||
      ConsumeAndSave(TokenType::MAX_CONTENT) ||
      ConsumeAndSave(TokenType::AUTO)) {
    return true;
  }
  if (!ConsumeAndSave(TokenType::NUMBER)) {
    return false;
  }
  Token &token = CurrentTokenList().back();
  if (Consume(TokenType::PX)) {
    token.type = TokenType::PX;
  } else if (Consume(TokenType::RPX)) {
    token.type = TokenType::RPX;
  } else if (Consume(TokenType::PERCENTAGE)) {
    token.type = TokenType::PERCENTAGE;
  } else if (Consume(TokenType::REM)) {
    token.type = TokenType::REM;
  } else if (Consume(TokenType::EM)) {
    token.type = TokenType::EM;
  } else if (Consume(TokenType::VW)) {
    token.type = TokenType::VW;
  } else if (Consume(TokenType::VH)) {
    token.type = TokenType::VH;
  } else if (Consume(TokenType::PPX)) {
    token.type = TokenType::PPX;
  } else if (Check(TokenType::TOKEN_EOF)) {
    // For compatibility, we use number type
    token.type = TokenType::NUMBER;
  } else {
    const char *c = token.start;
    if (c[0] == '0' && token.length == 1) {
      token.type = TokenType::NUMBER;
      return true;
    }
    // targetSdkVersion >= 2.6
    if (parser_configs_.enable_length_unit_check) {
      return false;
    }
    // If the next char is white space, comma or slash, can be
    // resolved to a valid length value, for compatibility
    const char *next = token.start + token.length;
    if (next[0] == ' ' || next[0] == '/' || next[0] == ',') {
      token.type = TokenType::NUMBER;
      return true;
    }
    return false;
  }
  return true;
}

bool CSSStringParser::PositionValue() { return AlphaValue(); }

bool CSSStringParser::PercentageValue() {
  if (!Consume(TokenType::NUMBER)) {
    return false;
  }

  if (!Check(TokenType::PERCENTAGE)) {
    return false;
  }

  // this is number token
  Token previous = previous_token_;
  previous.type = TokenType::PERCENTAGE;
  Consume(TokenType::PERCENTAGE);
  previous_token_ = previous;

  CurrentTokenList().emplace_back(previous_token_);
  return true;
}

bool CSSStringParser::NumberValue() {
  return ConsumeAndSave(TokenType::NUMBER);
}

void CSSStringParser::BeginParse() { token_list_stack_.clear(); }

void CSSStringParser::BeginTokenList() { token_list_stack_.emplace_back(); }

std::vector<Token> &CSSStringParser::CurrentTokenList() {
  return token_list_stack_.back();
}

std::vector<Token> CSSStringParser::EndTokenList() {
  if (token_list_stack_.empty()) {
    return std::vector<Token>();
  }
  auto back = token_list_stack_.back();
  token_list_stack_.pop_back();
  return back;
}

void CSSStringParser::BeginBackgroundLayer() {
  current_background_layer_ = CSSBackgroundLayer{};
}

void CSSStringParser::PushValue(const StackValue &value) {
  value_stack_.push_back(value);
}

void CSSStringParser::PushValue(const std::vector<Token> &token_list) {
  value_stack_.push_back(MakeStackValue(token_list));
}

CSSStringParser::StackValue CSSStringParser::PopValue() {
  if (value_stack_.empty()) {
    return StackValue(TokenType::ERROR);
  }
  auto value = value_stack_.back();
  value_stack_.pop_back();
  return value;
}

bool CSSStringParser::CheckAndAdvance(TokenType tokenType) {
  if (!Check(tokenType)) {
    return false;
  }
  Advance();
  return current_token_.type != TokenType::ERROR;
}

void CSSStringParser::SkipWhitespaceToken() {
  if (current_token_.type == TokenType::WHITESPACE) {
    Advance();
  }
}

bool CSSStringParser::Consume(TokenType tokenType) {
  SkipWhitespaceToken();
  if (current_token_.type == tokenType) {
    Advance();
    return current_token_.type != TokenType::ERROR;
  }
  return false;
}

bool CSSStringParser::ConsumeAndSave(TokenType tokenType) {
  if (Consume(tokenType)) {
    CurrentTokenList().emplace_back(previous_token_);
    return true;
  }
  return false;
}

bool CSSStringParser::Check(TokenType tokenType) {
  SkipWhitespaceToken();
  return current_token_.type == tokenType;
}

void CSSStringParser::Advance() {
  previous_token_ = current_token_;
  current_token_ = scanner_.ScanToken();
}

uint32_t CSSStringParser::TokenTypeToTextENUM(TokenType token_type) {
  switch (token_type) {
    case TokenType::NONE:
      return static_cast<uint32_t>(starlight::TextDecorationType::kNone);
    case TokenType::UNDERLINE:
      return static_cast<uint32_t>(starlight::TextDecorationType::kUnderLine);
    case TokenType::LINE_THROUGH:
      return static_cast<uint32_t>(starlight::TextDecorationType::kLineThrough);
    case TokenType::SOLID:
      return static_cast<uint32_t>(starlight::TextDecorationType::kSolid);
    case TokenType::DOUBLE:
      return static_cast<uint32_t>(starlight::TextDecorationType::kDouble);
    case TokenType::DOTTED:
      return static_cast<uint32_t>(starlight::TextDecorationType::kDotted);
    case TokenType::DASHED:
      return static_cast<uint32_t>(starlight::TextDecorationType::kDashed);
    case TokenType::WAVY:
      return static_cast<uint32_t>(starlight::TextDecorationType::kWavy);
    default:
      return -1;
  }
}

uint32_t CSSStringParser::TokenTypeToENUM(TokenType token_type) {
  switch (token_type) {
    case TokenType::NUMBER:
      return static_cast<uint32_t>(CSSValuePattern::NUMBER);
    case TokenType::URL:
      return static_cast<uint32_t>(starlight::BackgroundImageType::kUrl);
    case TokenType::LINEAR_GRADIENT:
      return static_cast<uint32_t>(
          starlight::BackgroundImageType::kLinearGradient);
    case TokenType::RADIAL_GRADIENT:
      return static_cast<uint32_t>(
          starlight::BackgroundImageType::kRadialGradient);
    case TokenType::ELLIPSE:
      return static_cast<uint32_t>(
          starlight::RadialGradientShapeType::kEllipse);
    case TokenType::CIRCLE:
      return static_cast<uint32_t>(starlight::RadialGradientShapeType::kCircle);
    case TokenType::FARTHEST_CORNER:
      return static_cast<uint32_t>(
          starlight::RadialGradientSizeType::kFarthestCorner);
    case TokenType::FARTHEST_SIDE:
      return static_cast<uint32_t>(
          starlight::RadialGradientSizeType::kFarthestSide);
    case TokenType::CLOSEST_CORNER:
      return static_cast<uint32_t>(
          starlight::RadialGradientSizeType::kClosestCorner);
    case TokenType::CLOSEST_SIDE:
      return static_cast<uint32_t>(
          starlight::RadialGradientSizeType::kClosestSide);
    case TokenType::BORDER_BOX:
      return static_cast<uint32_t>(starlight::BackgroundOriginType::kBorderBox);
    case TokenType::PADDING_BOX:
      return static_cast<uint32_t>(
          starlight::BackgroundOriginType::kPaddingBox);
    case TokenType::CONTENT_BOX:
      return static_cast<uint32_t>(
          starlight::BackgroundOriginType::kContentBox);
    case TokenType::LEFT:
      return POS_LEFT;
    case TokenType::RIGHT:
      return POS_RIGHT;
    case TokenType::TOP:
      return POS_TOP;
    case TokenType::BOTTOM:
      return POS_BOTTOM;
    case TokenType::CENTER:
      return POS_CENTER;
    case TokenType::PERCENTAGE:
      return static_cast<uint32_t>(CSSValuePattern::PERCENT);
    case TokenType::RPX:
      return static_cast<uint32_t>(CSSValuePattern::RPX);
    case TokenType::PX:
      return static_cast<uint32_t>(CSSValuePattern::PX);
    case TokenType::REM:
      return static_cast<uint32_t>(CSSValuePattern::REM);
    case TokenType::EM:
      return static_cast<uint32_t>(CSSValuePattern::EM);
    case TokenType::VW:
      return static_cast<uint32_t>(CSSValuePattern::VW);
    case TokenType::VH:
      return static_cast<uint32_t>(CSSValuePattern::VH);
    case TokenType::PPX:
      return static_cast<uint32_t>(CSSValuePattern::PPX);
    case TokenType::SP:
      return static_cast<uint32_t>(CSSValuePattern::SP);
    case TokenType::CALC:
      return static_cast<uint32_t>(CSSValuePattern::CALC);
    case TokenType::ENV:
      return static_cast<uint32_t>(CSSValuePattern::ENV);
    case TokenType::MAX_CONTENT:
    case TokenType::FIT_CONTENT:
      return static_cast<uint32_t>(CSSValuePattern::INTRINSIC);
    case TokenType::AUTO:
      return static_cast<uint32_t>(CSSValuePattern::ENUM);
    case TokenType::REPEAT:
    case TokenType::REPEAT_X:
    case TokenType::REPEAT_Y:
      return static_cast<uint32_t>(starlight::BackgroundRepeatType::kRepeat);
    case TokenType::NO_REPEAT:
      return static_cast<uint32_t>(starlight::BackgroundRepeatType::kNoRepeat);
    case TokenType::SPACE:
      return static_cast<uint32_t>(starlight::BackgroundRepeatType::kSpace);
    case TokenType::ROUND:
      return static_cast<uint32_t>(starlight::BackgroundRepeatType::kRound);
    case TokenType::COVER:
      return static_cast<uint32_t>(starlight::BackgroundSizeType::kCover);
    case TokenType::CONTAIN:
      return static_cast<uint32_t>(starlight::BackgroundSizeType::kContain);
    case TokenType::NONE:
      return static_cast<uint32_t>(starlight::BackgroundImageType::kNone);
    default:
      return -1;
  }
}

CSSStringParser::StackValue CSSStringParser::MakeStackValue(
    std::vector<Token> token_list) {
  if (token_list.empty()) {
    return StackValue(TokenType::ERROR);
  }

  switch (token_list.front().type) {
    case TokenType::URL:
      return StackValue{lepus::Value(lepus::StringImpl::Create(std::string(
                            token_list[1].start, token_list[1].length))),
                        TokenType::URL};
    case TokenType::BORDER_BOX:
    case TokenType::CONTENT_BOX:
    case TokenType::PADDING_BOX:
    case TokenType::COVER:
    case TokenType::CONTAIN:
    case TokenType::UNDERLINE:
    case TokenType::LINE_THROUGH:
    case TokenType::SOLID:
    case TokenType::DOUBLE:
    case TokenType::DOTTED:
    case TokenType::DASHED:
    case TokenType::WAVY:
      return StackValue(token_list.front().type);
    case TokenType::REPEAT_X:
      return StackValue{TokenType::REPEAT, TokenType::NO_REPEAT};
    case TokenType::REPEAT_Y:
      return StackValue{TokenType::NO_REPEAT, TokenType::REPEAT};
    case TokenType::REPEAT:
    case TokenType::NO_REPEAT:
    case TokenType::SPACE:
    case TokenType::ROUND:
    case TokenType::NONE:
      if (token_list.size() == 1) {
        return StackValue(token_list.front().type, token_list.front().type);
      } else {
        return StackValue(token_list.front().type, token_list[1].type);
      }
    case TokenType::FORMAT:
      return StackValue{lepus::Value(lepus::StringImpl::Create(std::string(
                            token_list[1].start, token_list[1].length))),
                        TokenType::FORMAT};
    case TokenType::LOCAL:
      return StackValue{lepus::Value(lepus::StringImpl::Create(std::string(
                            token_list[1].start, token_list[1].length))),
                        TokenType::LOCAL};
    default:
      return StackValue(TokenType::ERROR);
  }
}

CSSStringParser::StackValue CSSStringParser::MakeColorValue(
    const std::vector<Token> &token_list) {
  CSSColor color;
  switch (token_list.front().type) {
    case TokenType::RGBA:
      color.r_ = TokenToInt(token_list[1]);
      color.g_ = TokenToInt(token_list[2]);
      color.b_ = TokenToInt(token_list[3]);
      color.a_ = TokenToDouble(token_list[4]);
      break;
    case TokenType::RGB:
      color.r_ = TokenToInt(token_list[1]);
      color.g_ = TokenToInt(token_list[2]);
      color.b_ = TokenToInt(token_list[3]);
      color.a_ = 1.f;
      break;
    case TokenType::IDENTIFIER:
      CSSColor::ParseNamedColor(
          std::string(token_list.front().start, token_list.front().length),
          color);
      break;
    case TokenType::HSLA:
      color = CSSColor::CreateFromHSLA(
          TokenToInt(token_list[1]), TokenToInt(token_list[2]),
          TokenToInt(token_list[3]), TokenToInt(token_list[4]));
      break;
    case TokenType::HSL:
      color = CSSColor::CreateFromHSLA(TokenToInt(token_list[1]),
                                       TokenToInt(token_list[2]),
                                       TokenToInt(token_list[3]), 1.f);
      break;
    case TokenType::HEX: {
      std::string str = "#";
      str.append(token_list[0].start, token_list[0].length);
      lynx::tasm::CSSColor::Parse(str, color);
    } break;
    default:
      break;
  }

  return StackValue(lepus::Value(color.Cast()), TokenType::NUMBER);
}

int64_t CSSStringParser::TokenToInt(const Token &token) {
  int64_t ret;
  base::StringToInt(std::string(token.start, token.length), ret, 10);
  return ret;
}

double CSSStringParser::TokenToDouble(const Token &token) {
  double ret;
  base::StringToDouble(std::string(token.start, token.length), ret);
  return ret;
}

double CSSStringParser::TokenToAngleValue(const Token &token) {
  switch (token.type) {
    case TokenType::DEG:
      return TokenToDouble(token);
    case TokenType::RAD:
      return TokenToDouble(token) * 180.f / M_PI;
    case TokenType::TURN:
      return TokenToDouble(token) * 180.f;
    case TokenType::GRAD:
      return TokenToDouble(token) * 360.f / 400.f;
    default:
      return 0.f;
  }
}

void CSSStringParser::BackgroundlayerToArray(const CSSBackgroundLayer &layer,
                                             lepus::CArray *image_array,
                                             lepus::CArray *position_array,
                                             lepus::CArray *size_array,
                                             lepus::CArray *origin_array,
                                             lepus::CArray *repeat_array,
                                             lepus::CArray *clip_array) {
  image_array->push_back(
      lepus::Value(TokenTypeToENUM(layer.image->value_type)));
  if (layer.image->value) {
    image_array->push_back(*layer.image->value);
  }

  // position
  {
    auto array = lepus::CArray::Create();
    const auto vx = layer.position_x;
    const auto vy = layer.position_y;

    array->push_back(lepus::Value(vx.first));
    array->push_back(lepus::Value(vx.second));
    array->push_back(lepus::Value(vy.first));
    array->push_back(lepus::Value(vy.second));

    position_array->push_back(lepus::Value(array));
  }
  // size
  {
    auto array = lepus::CArray::Create();
    const auto vx = layer.size_x;
    const auto vy = layer.size_y;

    array->push_back(lepus::Value(vx.first));
    array->push_back(lepus::Value(vx.second));
    array->push_back(lepus::Value(vy.first));
    array->push_back(lepus::Value(vy.second));

    size_array->push_back(lepus::Value(array));
  }

  // repeat
  {
    auto array = lepus::CArray::Create();
    const auto vx = layer.repeat_x;
    const auto vy = layer.repeat_y;

    array->push_back(lepus::Value(vx));
    array->push_back(lepus::Value(vy));

    repeat_array->push_back(lepus::Value(array));
  }

  // origin
  origin_array->push_back(lepus::Value(layer.origin));

  // clip
  clip_array->push_back(lepus::Value(layer.origin));
}

void CSSStringParser::ClampColorAndStopList(std::vector<uint32_t> &colors,
                                            std::vector<float> &stops) {
  if (stops.size() < 2) {
    return;
  }
  bool clamp_front = stops.front() < 0.f;
  bool clamp_back = stops.back() > 100.f;

  if (!clamp_front && !clamp_back) {
    return;
  }

  if (clamp_front) {
    // find first positive position
    uint32_t first_positive_index = 0;
    auto result = std::find_if(stops.begin(), stops.end(),
                               [](float v) { return v >= 0.f; });
    if (result != stops.end()) {
      first_positive_index = static_cast<uint32_t>(result - stops.begin());
    }

    if (first_positive_index != 0) {
      ClampColorAndStopListAtFront(colors, stops, first_positive_index);
    }
  }

  if (clamp_back) {
    // find fist greater than 100.f position
    uint32_t tail_position = 0;
    auto result = std::find_if(stops.begin(), stops.end(),
                               [](float v) { return v >= 100.f; });
    if (result != stops.end()) {
      tail_position = static_cast<uint32_t>(result - stops.begin());
    }
    if (tail_position != 0) {
      ClampColorAndStopListAtBack(colors, stops, tail_position);
    }
  }
}

void CSSStringParser::ClampColorAndStopListAtFront(
    std::vector<uint32_t> &colors, std::vector<float> &stops,
    uint32_t first_positive_index) {
  float prev_stop = stops[first_positive_index - 1];
  uint32_t prev_color = colors[first_positive_index - 1];

  float current_stop = stops[first_positive_index];
  uint32_t current_color = colors[first_positive_index];

  uint32_t result_color =
      LerpColor(prev_color, current_color, prev_stop, current_stop, 0.f);
  // update prev content
  stops[first_positive_index - 1] = 0.f;
  colors[first_positive_index - 1] = result_color;

  // remove all other negtive stops and colors
  if (first_positive_index - 1 > 0) {
    stops.erase(stops.begin(), stops.begin() + first_positive_index - 1);
    colors.erase(colors.begin(), colors.begin() + first_positive_index - 1);
  }
}

void CSSStringParser::ClampColorAndStopListAtBack(std::vector<uint32_t> &colors,
                                                  std::vector<float> &stops,
                                                  uint32_t tail_position) {
  float prev_stop = stops[tail_position - 1];
  uint32_t prev_color = colors[tail_position - 1];

  float current_stop = stops[tail_position];
  uint32_t current_color = colors[tail_position];

  uint32_t result_color =
      LerpColor(prev_color, current_color, prev_stop, current_stop, 100.f);
  // update tail content
  stops[tail_position] = 100.f;
  colors[tail_position] = result_color;

  // remote all other greater than 100% stops and colors
  if (tail_position + 1 < stops.size()) {
    stops.erase(stops.begin() + tail_position + 1, stops.end());
    colors.erase(colors.begin() + tail_position + 1, colors.end());
  }
}

uint32_t CSSStringParser::LerpColor(uint32_t start_color, uint32_t end_color,
                                    float start_pos, float end_pos,
                                    float current_pos) {
  float weight = (current_pos - start_pos) / (end_pos - start_pos);

  uint8_t a1 = (start_color >> 24) & 0xFF;
  uint8_t b1 = (start_color >> 16) & 0xFF;
  uint8_t c1 = (start_color >> 8) & 0xFF;
  uint8_t d1 = (start_color)&0xFF;

  uint8_t a2 = (end_color >> 24) & 0xFF;
  uint8_t b2 = (end_color >> 16) & 0xFF;
  uint8_t c2 = (end_color >> 8) & 0xFF;
  uint8_t d2 = (end_color)&0xFF;

  uint8_t a = a1 + static_cast<uint8_t>((a2 - a1) * weight);
  uint8_t b = b1 + static_cast<uint8_t>((b2 - b1) * weight);
  uint8_t c = c1 + static_cast<uint8_t>((c2 - c1) * weight);
  uint8_t d = d1 + static_cast<uint8_t>((d2 - d1) * weight);

  return ((a << 24) & 0xffffffff) | ((b << 16) & 0xffffffff) |
         ((c << 8) & 0xffffffff) | (d & 0xffffffff);
}

void CSSStringParser::MakeCSSLength(const Token &token,
                                    const TokenType &tokenType, float &value) {
  value = TokenToDouble(token);

  switch (token.type) {
    case TokenType::LEFT:
    case TokenType::TOP:
      value = 0.f;
      return;
    case TokenType::RIGHT:
    case TokenType::BOTTOM:
      value = 1.f;
      return;
    case TokenType::CENTER:
      value = 0.5f;
      return;
    default:
      return;
  }
}

bool CSSStringParser::BasicShapeCircle() {
  if (!Consume(TokenType::CIRCLE) || !Consume(TokenType::LEFT_PAREN)) {
    return false;
  }
  auto arr = lepus::CArray::Create();

  constexpr uint32_t BASIC_SHAPE_CIRCLE_TYPE =
      static_cast<uint32_t>(starlight::BasicShapeType::kCircle);
  arr->push_back(lepus::Value(BASIC_SHAPE_CIRCLE_TYPE));

  // Radius is required
  if (!ParseLengthAndSetValue(arr)) {
    return false;
  }

  // position is optional
  if (Check(TokenType::RIGHT_PAREN)) {
    // default center x
    arr->push_back(lepus::Value(50));
    arr->push_back(lepus::Value(PATTERN_PERCENT));

    // default center y
    arr->push_back(lepus::Value(50));
    arr->push_back(lepus::Value(PATTERN_PERCENT));
  } else if (!ParsePositionAndSetValue(arr)) {
    // parse [<position>]? failed
    return false;
  }

  PushValue(StackValue(lepus::Value(arr), TokenType::CIRCLE));
  return true;
}

void CSSStringParser::ConvertPositionKeyWordToValue(unsigned int &type,
                                                    float &value,
                                                    uint32_t &pattern) {
  switch (type) {
    case POS_CENTER:
      value = 50.f;
      pattern = PATTERN_PX;
      return;
    case POS_LEFT:
    case POS_TOP:
      value = 0;
      pattern = PATTERN_PX;
      return;
    case POS_RIGHT:
    case POS_BOTTOM:
      value = 100.f;
      pattern = PATTERN_PERCENT;
      return;
    default:
      pattern = type;
      return;
  }
}

bool CSSStringParser::ParsePositionAndSetValue(
    base::scoped_refptr<lepus::CArray> &arr) {
  uint32_t pattern = 0;
  if (Consume(TokenType::AT) && BackgroundPosition()) {
    // position x
    if (current_background_layer_.position_x_str.second.empty()) {
      auto [type, value] = current_background_layer_.position_x;
      ConvertPositionKeyWordToValue(type, value, pattern);
      arr->push_back(lepus::Value(value));
      arr->push_back(lepus::Value(pattern));
    } else {
      return false;
      // CALC
    }

    // position y
    if (current_background_layer_.position_y_str.second.empty()) {
      auto [type, value] = current_background_layer_.position_y;
      ConvertPositionKeyWordToValue(type, value, pattern);
      arr->push_back(lepus::Value(value));
      arr->push_back(lepus::Value(pattern));
    } else {
      // CALC
      return false;
    }
    return true;
  }
  return false;
}

bool CSSStringParser::BasicShapeEllipse() {
  if (!Consume(TokenType::ELLIPSE) || !Consume(TokenType::LEFT_PAREN)) {
    return false;
  }
  auto arr = lepus::CArray::Create();

  constexpr uint32_t BASIC_SHAPE_ELLIPSE_TYPE =
      static_cast<uint32_t>(starlight::BasicShapeType::kEllipse);
  arr->push_back(lepus::Value(BASIC_SHAPE_ELLIPSE_TYPE));

  // radius is required.
  if (!ParseLengthAndSetValue(arr)) {
    return false;
  }

  if (!ParseLengthAndSetValue(arr)) {
    return false;
  }

  if (Check(TokenType::RIGHT_PAREN)) {
    // [at <position>] is optional, use default value.
    // default center x
    arr->push_back(lepus::Value(50));
    arr->push_back(lepus::Value(PATTERN_PERCENT));

    // default center y
    arr->push_back(lepus::Value(50));
    arr->push_back(lepus::Value(PATTERN_PERCENT));
  } else if (!ParsePositionAndSetValue(arr)) {
    // function not end, but parse position failed, return false.
    return false;
  }

  PushValue(StackValue(lepus::Value(arr), TokenType::ELLIPSE));
  return true;
}

bool CSSStringParser::ParseLengthAndSetValue(
    base::scoped_refptr<lepus::CArray> &arr) {
  CSSValue value = Length();
  if (value.IsEmpty()) {
    return false;
  }
  arr->push_back(value.GetValue());
  arr->push_back(lepus::Value(static_cast<uint32_t>(value.GetPattern())));
  return true;
}

bool CSSStringParser::BasicShapePath() {
  // path()
  if (!Consume(TokenType::PATH) || !Consume(TokenType::LEFT_PAREN)) {
    return false;
  }
  // svg path data string
  if (!Consume(TokenType::STRING)) {
    return false;
  }
  std::string path_data{previous_token_.start, previous_token_.length};
  auto arr = lepus::CArray::Create();

  constexpr uint32_t BASIC_SHAPE_PATH_TYPE =
      static_cast<uint32_t>(starlight::BasicShapeType::kPath);
  arr->push_back(lepus::Value(BASIC_SHAPE_PATH_TYPE));

  arr->push_back(lepus::Value(path_data));
  PushValue(StackValue(lepus::Value(arr), TokenType::PATH));
  return true;
}

bool CSSStringParser::SuperEllipse() {
  // Begin with 'super-ellipse('
  if (!Consume(TokenType::SUPER_ELLIPSE) || !Consume(TokenType::LEFT_PAREN)) {
    return false;
  }
  auto arr = lepus::CArray::Create();

  // append type enum
  constexpr uint32_t SUPER_ELLIPSE_TYPE =
      static_cast<uint32_t>(starlight::BasicShapeType::kSuperEllipse);
  arr->push_back(lepus::Value(SUPER_ELLIPSE_TYPE));

  // [<shape-radius>{2}] are required
  // parse radius x
  if (!ParseLengthAndSetValue(arr)) {
    return false;
  }

  // parse radius y
  if (!ParseLengthAndSetValue(arr)) {
    return false;
  }

  if (Check(TokenType::AT) || Check(TokenType::RIGHT_PAREN)) {
    // [<number>{2}]?  is optional, [at] means use default exponent
    // default exponent is 2
    arr->push_back(lepus::Value(2));
    arr->push_back(lepus::Value(2));

    // [at <position>]? is optional, append default position
    if (Check(TokenType::RIGHT_PAREN)) {
      // default center x
      arr->push_back(lepus::Value(50));
      arr->push_back(
          lepus::Value(static_cast<uint32_t>(CSSValuePattern::PERCENT)));

      // default center y
      arr->push_back(lepus::Value(50));
      arr->push_back(
          lepus::Value(static_cast<uint32_t>(CSSValuePattern::PERCENT)));
      // parse finished
    } else if (!ParsePositionAndSetValue(arr)) {
      // params not end but parse [at <position>] failed
      return false;
    }
  } else if (Check(TokenType::NUMBER)) {
    if (!ConsumeAndSave(TokenType::NUMBER) || !Consume(TokenType::NUMBER)) {
      // [<number>{2}] parse failed
      return false;
    }

    // append exponent x and y
    arr->push_back(lepus::Value(TokenToDouble(CurrentTokenList().back())));
    arr->push_back(lepus::Value(TokenToDouble(previous_token_)));
    CurrentTokenList().pop_back();

    if (Check(TokenType::RIGHT_PAREN)) {
      // default center x, center
      arr->push_back(lepus::Value(50));
      arr->push_back(lepus::Value(PATTERN_PERCENT));

      // default center y, center
      arr->push_back(lepus::Value(50));
      arr->push_back(lepus::Value(PATTERN_PERCENT));
    } else if (!ParsePositionAndSetValue(arr)) {
      return false;
    }
  }

  // Parse finished
  PushValue(StackValue(lepus::Value(arr), TokenType::ELLIPSE));
  return true;
}

}  // namespace tasm
}  // namespace lynx
