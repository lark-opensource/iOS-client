// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_PARSER_CSS_STRING_PARSER_H_
#define LYNX_CSS_PARSER_CSS_STRING_PARSER_H_

#include <optional>
#include <string>
#include <tuple>
#include <utility>
#include <vector>

#include "css/css_value.h"
#include "css/parser/css_parser_configs.h"
#include "css/parser/css_string_scanner.h"
#include "starlight/style/css_type.h"

namespace lynx {
namespace tasm {

/// A Recursive descent parser implemention to parse CSS background and border
/// string
///   more info see https://en.wikipedia.org/wiki/Recursive_descent_parser
/// Syntax is follow https://developer.mozilla.org/en-US/docs/Web/CSS/

static constexpr unsigned int POS_LEFT =
    static_cast<uint32_t>(starlight::BackgroundPositionType::kLeft);
static constexpr unsigned int POS_TOP =
    static_cast<uint32_t>(starlight::BackgroundPositionType::kTop);
static constexpr unsigned int POS_RIGHT =
    static_cast<uint32_t>(starlight::BackgroundPositionType::kRight);
static constexpr unsigned int POS_BOTTOM =
    static_cast<uint32_t>(starlight::BackgroundPositionType::kBottom);
static constexpr unsigned int POS_CENTER =
    static_cast<uint32_t>(starlight::BackgroundPositionType::kCenter);

class CSSStringParser final {
  static constexpr uint32_t PATTERN_PX =
      static_cast<uint32_t>(CSSValuePattern::PX);
  static constexpr uint32_t PATTERN_PERCENT =
      static_cast<uint32_t>(CSSValuePattern::PERCENT);

  struct StackValue {
    explicit StackValue(TokenType type) : value(), value_type(type) {}
    StackValue(TokenType type, TokenType second_type)
        : value(), value_type(type), second_value_type(second_type) {}
    StackValue(const lepus::Value& value, TokenType type)
        : value(value), value_type(type) {}
    std::optional<lepus::Value> value = {};
    TokenType value_type = {};
    std::optional<TokenType> second_value_type = {};
  };

  struct CSSBackgroundLayer {
    using Length_T = std::pair<uint32_t, float>;
    Length_T position_x = {static_cast<uint32_t>(CSSValuePattern::PERCENT),
                           0.f};
    Length_T position_y = {static_cast<uint32_t>(CSSValuePattern::PERCENT),
                           0.f};
    Length_T size_x = {static_cast<uint32_t>(CSSValuePattern::NUMBER),
                       -1.f * (int)starlight::BackgroundSizeType::kAuto};
    Length_T size_y = {static_cast<uint32_t>(CSSValuePattern::NUMBER),
                       -1.f * (int)starlight::BackgroundSizeType::kAuto};
    uint32_t repeat_x =
        static_cast<uint32_t>(starlight::BackgroundRepeatType::kRepeat);
    uint32_t repeat_y =
        static_cast<uint32_t>(starlight::BackgroundRepeatType::kRepeat);
    uint32_t origin =
        static_cast<uint32_t>(starlight::BackgroundOriginType::kPaddingBox);
    uint32_t clip =
        static_cast<uint32_t>(starlight::BackgroundClipType::kPaddingBox);
    std::pair<uint32_t, std::string> position_x_str = {
        static_cast<uint32_t>(CSSValuePattern::CALC), ""};
    std::pair<uint32_t, std::string> position_y_str = {
        static_cast<uint32_t>(CSSValuePattern::CALC), ""};

    std::optional<StackValue> image;
    std::optional<uint32_t> color;
    CSSBackgroundLayer() = default;
  };

  enum {
    BG_REPEAT = 1 << 0,
    BG_POSITION_AND_SIZE = 1 << 1,
    BG_IMAGE = 1 << 2,
    BG_CLIP_BOX = 1 << 3,
    BG_ORIGIN = 1 << 4,
  };

 public:
  CSSStringParser(const char* cssString, uint32_t cssStringLength,
                  const CSSParserConfigs& configs)
      : scanner_(cssString, cssStringLength), parser_configs_(configs) {}
  ~CSSStringParser() = default;
  /// <background> = [ <bg-layer>, ]* <final-bg-layer>
  CSSValue ParseBackground();
  /// <bg-image> [, <bg-image> ]*
  CSSValue ParseBackgroundImage();

  CSSValue ParseGradient();
  /// <bg-position> [, <bg-position>]*
  /// <bg-position> =
  ///     [
  ///      left | center | right | top | bottom | <length-percentage> ]
  ///       | [ left | center | right | <length-percentage>
  ///     ]
  ///   [top | center | bottom | <length-percentage> ]
  CSSValue ParseBackgroundPosition();
  /// <bg-size> [, <bg-size> ]*
  /// <bg-size> = [ <length-percentage> | auto ]{1,2} | cover | contain
  CSSValue ParseBackgroundSize();
  /// <bg-origin> = <box> [, <box> ]*
  CSSValue ParseBackgroundOrigin();
  /// <bg-clip> = <box> [, <box> ]*
  CSSValue ParseBackgroundClip();
  /// <bg-repeat> [, <bg-repeat>]*
  /// <bg-repeat> = <repeat-style> = repeat-x | repeat-y | [ repeat | space |
  ///               round | no-repeat ]{1,2}
  CSSValue ParseBackgroundRepeat();
  /// <text-color> = <color> | <linear-gradient> | <radial-gradient>
  CSSValue ParseTextColor();

  /// <text-decoration> = <text-decoration-line> || <text-decoration-style> ||
  /// <text-decoration-color>
  CSSValue ParseTextDecoration();

  /// <src> = [ <url> [ format( <string> ) ]? | local( <family-name> )
  CSSValue ParseFontSrc();

  /// font-weight [ normal | bold | <number [1, 1000]>{1, 2}
  CSSValue ParseFontWeight();

  CSSValue ParseBorderStyle();
  /// [ [ <url> [ <x> <y> ]? , ]* [ auto | default | none | ... ] ]
  CSSValue ParseCursor();

  inline void SetIsLegacyParser(bool is_legacy) { legacy_parser_ = is_legacy; }

  // for unit test
  size_t CurrentTokenListSize() const { return token_list_stack_.size(); }

  /// for image related only composed with url
  std::string ParseUrl();

  // <basic-shape>
  lepus::Value ParseClipPath();

  CSSValue ParseLength();

  CSSValue ParseSingleBorderRadius();

  bool ParseBorderRadius(CSSValue horizontal_radii[4],
                         CSSValue vertical_radii[4]);

 private:
  CSSValue Length();
  /// <bg-layer> =
  ///  <bg-image> || <bg-position> [ / <bg-size> ]? || <repeat-style> || <box>
  ///  || <box>
  bool BackgroundLayer();
  /// <final-bg-layer> =
  ///   <color> ||
  ///   <bg-image> ||
  ///   <bg-position> [ / <bg-size> ]? ||
  ///   <repeat-style> ||
  ///   <box> ||
  ///   <box>
  bool FinalBackgroundLayer();
  /// <bg-image> =
  ///   none |
  ///   <url> |
  ///   <gradient>
  bool BackgroundImage();
  /// <bg-origin-box> = <box>
  bool BackgroundOriginBox();
  /// <bg-clip-box> = <box>
  bool BackgroundClipBox();
  /// <box> = [ border-box | padding-box | content-box ]
  bool Box();
  /// <bg-position-and-size> = <bg-position> [ / <bg-size>] ?
  bool BackgroundPositionAndSize();
  /// <bg-position> = [
  ///               [ left | center | right | top | bottom | <length-percentage>
  ///               ]
  ///               |
  ///               [ left | center | right | <length-percentage> ]  [ top |
  ///               center | bottom | <length-percentage> ]
  ///               |
  ///               [ center | [ left | right ] <length-percentage> ? ] && [
  ///               center | [ top | bottom ] < length-percentage> ? ]
  ///             ]
  bool BackgroundPosition();
  /// <bg-size> = [ <length-percentage> | auto ] {1, 2} | cover | contain
  bool BackgroundSize();
  /// <repeat-style> = repeat-x | repeat-y | [ repeat | no-repeat] {1, 2}
  bool BackgroundRepeatStyle();
  bool BorderStyle();
  /// <text-decoration-line> = none | [underline || line-through]
  bool TextDecorationLine();
  /// <text-decoration-style> = solid | double | dotted | dashed | wavy
  bool TextDecorationStyle();
  /// <format> = format('<string>')
  bool Format();
  /// <local> = local('<string>')
  bool Local();
  /// <url> = url('<string>')
  bool Url();
  /// <gradient> =
  ///   <linear-gradient> |
  ///   <radial-gradient>
  bool Gradient();
  /// <linear-gradient> =linear-gradient ( [ <angle> | to <side-or-corner> ] ? ,
  /// <color-stop-list>)
  bool LinearGradient();
  /// <radial-gradient> = radial-gradient( [ <ending-shape> || <size> ] ? [ at
  /// <position> ] ?, <color-stop-list>)
  bool RadialGradient();
  /// <ending-shape> = ellipse | circle
  bool EndingShape();
  /// <size> = closest-side | closest-corner | farthest-side | farthest-corner
  bool EndingShapeSize();
  /// <color-stop-list> = [<color> [, <percentage>] ?]*
  bool ColorStopList(const base::scoped_refptr<lepus::CArray>& colors,
                     const base::scoped_refptr<lepus::CArray>& stops);

  /// <angle> = <number> [ deg | grad | rad | turn]
  bool AngleValue();
  /// <color> =
  ///   <rgba()> |
  ///   <rgb()> |
  ///   <hsla()> |
  ///   <hsl()> |
  ///   <hex-color> |
  ///   <named-color>
  bool Color();
  /// <rgba()> = rgba( <number> , <number>, <number> , <alpha-value>)
  bool RGBAColor();
  /// <rgb()> = rgb(<number> , <number> , <number>)
  bool RGBColor();
  /// <hsla()> = hsla( <number> | <angle>, <percentage>, <percentage>
  bool HSLAColor();
  bool HSLColor();
  /// <hex-color> = #<number>
  bool HexColor();
  /// <named-color> = identifier
  bool NamedColor();
  /// <alpha-value> = ( <percentage-value> | <number>)
  bool AlphaValue();
  /// same as AlphaValue
  bool PositionValue();
  /// <percentage-value> = <number> %
  bool PercentageValue();
  bool NumberValue();
  bool HexValue();
  bool LengthOrPercentageValue();

  /// <basic-shape> =
  ///   inset( <shape-arg>{1,4} [round <border-radius>]? ) |
  ///   circle( [<shape-radius>] [at <position>]? ) |
  ///   ellipse( [<shape-radius>{2}]  [at <position>]? ) |
  ///   polygon( [<fill-rule>,]  [<shape-arg> <shape-arg>]# ) |
  ///   path( [<fill-rule>,]? <string>)
  bool BasicShape();
  /// circle( [shape-radius]? [at <position>]?)
  bool BasicShapeCircle();
  /// ellipse([<shape-radius>{2}]? [at <position>]?)
  bool BasicShapeEllipse();
  bool ParseLengthAndSetValue(base::scoped_refptr<lepus::CArray>&);
  bool ParsePositionAndSetValue(base::scoped_refptr<lepus::CArray>&);
  /// path(<string>)
  /// a string of SVG path data follow EBNF grammar
  bool BasicShapePath();
  /// super-ellipse([<shape-radius>{2}] [<number>{2}] [at <position>] ?)
  bool SuperEllipse();

  /// inset([<length-percentage>{1,4} [(round | super-ellipse ex ey)
  /// <border-radius>]?])
  bool BasicShapeInset();

  /// <length-percentage>{1,4} [/ <length-percentage>{1,4}]?
  bool BorderRadius(CSSValue horizontal_radii[4], CSSValue vertical_radii[4]);

  // parser state function
  void BeginParse();
  void BeginTokenList();
  std::vector<Token>& CurrentTokenList();
  std::vector<Token> EndTokenList();
  void BeginBackgroundLayer();
  void PushValue(const StackValue& value);
  void PushValue(const std::vector<Token>& token_list);
  StackValue PopValue();

  // Scanner function
  bool CheckAndAdvance(TokenType tokenType);
  bool Consume(TokenType tokenType);
  bool ConsumeAndSave(TokenType tokenType);
  bool Check(TokenType tokenType);
  void Advance();

  // utils function
  static uint32_t TokenTypeToTextENUM(TokenType token_type);
  static uint32_t TokenTypeToENUM(TokenType token_type);
  static StackValue MakeStackValue(std::vector<Token> token_list);
  static StackValue MakeColorValue(const std::vector<Token>& token_list);
  static int64_t TokenToInt(const Token& token);
  static double TokenToDouble(const Token& token);
  static double TokenToAngleValue(const Token& token);
  static void BackgroundlayerToArray(const CSSBackgroundLayer& layer,
                                     lepus::CArray* image_array,
                                     lepus::CArray* position_array,
                                     lepus::CArray* size_array,
                                     lepus::CArray* origin_array,
                                     lepus::CArray* repeat_array,
                                     lepus::CArray* clip_array);
  static void ClampColorAndStopList(std::vector<uint32_t>& colors,
                                    std::vector<float>& stops);
  static void ClampColorAndStopListAtFront(std::vector<uint32_t>& colors,
                                           std::vector<float>& stops,
                                           uint32_t first_positive_index);
  static void ClampColorAndStopListAtBack(std::vector<uint32_t>& colors,
                                          std::vector<float>& stops,
                                          uint32_t tail_position);
  static uint32_t LerpColor(uint32_t start_color, uint32_t end_color,
                            float start_pos, float end_pos, float current_pos);
  void MakeCSSLength(const Token& token, const TokenType& tokenType,
                     float& value);

 private:
  friend struct TokenListStack;
  void SkipWhitespaceToken();

  Token current_token_;
  Token previous_token_;
  Scanner scanner_;
  std::vector<std::vector<Token>> token_list_stack_;
  std::vector<StackValue> value_stack_;
  CSSBackgroundLayer current_background_layer_;
  bool legacy_parser_ = true;
  CSSParserConfigs parser_configs_;
  void ConvertPositionKeyWordToValue(unsigned int& type, float& value,
                                     uint32_t&);
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_PARSER_CSS_STRING_PARSER_H_
