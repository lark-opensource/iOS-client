// Copyright 2020 The Lynx Authors. All rights reserved.

#include "css/unit_handler.h"

#include <css/parser/background_clip_handler.h>
#include <css/parser/background_image_handler.h>
#include <css/parser/background_origin_handler.h>
#include <css/parser/background_position_handler.h>
#include <css/parser/background_repeat_handler.h>
#include <css/parser/background_shorthand_handler.h>
#include <css/parser/background_size_handler.h>
#include <css/parser/filter_handler.h>
#include <css/parser/mask_image_handler.h>

#include "base/log/logging.h"
#include "base/no_destructor.h"
#include "base/trace_event/trace_event.h"
#include "css/css_property.h"
#include "css/parser/animation_direction_handler.h"
#include "css/parser/animation_fill_mode_handler.h"
#include "css/parser/animation_iteration_count_handler.h"
#include "css/parser/animation_name_handler.h"
#include "css/parser/animation_play_state_handler.h"
#include "css/parser/animation_property_handler.h"
#include "css/parser/animation_shorthand_handler.h"
#include "css/parser/aspect_ratio_handler.h"
#include "css/parser/bool_handler.h"
#include "css/parser/border_handler.h"
#include "css/parser/border_radius_handler.h"
#include "css/parser/border_style_handler.h"
#include "css/parser/border_width_handler.h"
#include "css/parser/clip_path_handler.h"
#include "css/parser/color_handler.h"
#include "css/parser/cursor_handler.h"
#include "css/parser/enum_handler.h"
#include "css/parser/flex_flow_handler.h"
#include "css/parser/flex_handler.h"
#include "css/parser/font_length_handler.h"
#include "css/parser/four_sides_shorthand_handler.h"
#include "css/parser/grid_position_handler.h"
#include "css/parser/grid_template_handler.h"
#include "css/parser/handler_defines.h"
#include "css/parser/length_handler.h"
#include "css/parser/line_shorthand_handler.h"
#include "css/parser/list_gap_handler.h"
#include "css/parser/number_handler.h"
#include "css/parser/relative_align_handler.h"
#include "css/parser/shadow_handler.h"
#include "css/parser/string_handler.h"
#include "css/parser/text_decoration_handler.h"
#include "css/parser/text_stroke_handler.h"
#include "css/parser/time_handler.h"
#include "css/parser/timing_function_handler.h"
#include "css/parser/transform_handler.h"
#include "css/parser/transform_origin_handler.h"
#include "css/parser/transition_shorthand_handler.h"
#include "css/parser/vertical_align_handler.h"
#include "tasm/lynx_trace_event.h"

#if defined(OS_WIN)
#include <cstdarg>
#endif

namespace lynx {
namespace tasm {

UnitHandler& UnitHandler::Instance() {
  static base::NoDestructor<UnitHandler> instance;
  return *instance;
}

/*
 * if a function calls CSSWarning() but is supposed to return immediately, do
 * things below like:
 * if(!CSSWarning(...)) {return false;}
 *  // then do something
 */
bool UnitHandler::CSSWarning(bool expression, bool enable_css_strict_mode,
                             const char* fmt, ...) {
  if (UNLIKELY(!(expression))) {
    if (enable_css_strict_mode) {
      std::string error_msg;
      va_list args;
      va_start(args, fmt);
      error_msg = base::FormatStringWithVaList(fmt, args);
      va_end(args);
      LynxWarning(false, LYNX_ERROR_CODE_CSS, error_msg);
    }
    return false;
  }
  return true;
}

void UnitHandler::CSSUnreachable(bool enable_css_strict_mode, const char* fmt,
                                 ...) {
  if (UNLIKELY(enable_css_strict_mode)) {
    std::string error_msg;
    va_list args;
    va_start(args, fmt);
    error_msg = base::FormatStringWithVaList(fmt, args);
    va_end(args);
    LynxWarning(false, LYNX_ERROR_CODE_CSS, error_msg)
  }
}

bool UnitHandler::Process(const CSSPropertyID key, const lepus::Value& input,
                          StyleMap& output, const CSSParserConfigs& configs) {
  if (key <= CSSPropertyID::kPropertyStart ||
      key >= CSSPropertyID::kPropertyEnd) {
    LOGE("[UnitHandler] illegal css key:" << key);
    CSSUnreachable(configs.enable_css_strict_mode,
                   "[UnitHandler] illegal css key:%d", key);
    return false;
  }
  TRACE_EVENT(
      LYNX_TRACE_CATEGORY, nullptr, [&](lynx::perfetto::EventContext ctx) {
        ctx.event()->set_name(std::string(CSS_UNIT_HANDLER_PROCESSOR) + "." +
                              CSSProperty::GetPropertyName(key).str());
      });
  auto maybe_handler = Instance().interceptors_[key];
  if (!maybe_handler) {
    output[key] = CSSValue(input);
    return true;
  }
  if (!maybe_handler(key, input, output, configs)) {
    if (!configs.remove_css_parser_log) {
      std::ostringstream output_value;
      input.PrintValue(output_value, false, false);
      LOGE("[UnitHandler] css:" << CSSProperty::GetPropertyName(key).str()
                                << " has invalid value " << output_value.str()
                                << " !!! It has be ignored.");
    }
    return false;
  }
  return true;
}

StyleMap UnitHandler::Process(const CSSPropertyID key,
                              const lepus::Value& input,
                              const CSSParserConfigs& configs) {
  StyleMap ret;
  Process(key, input, ret, configs);
  return ret;
}

UnitHandler::UnitHandler() {
  // TODO(liyanbo): must at first position. other will replace pre define.
  StringHandler::Register(interceptors_);
  AnimationDirectionHandler::Register(interceptors_);
  AnimationFillModeHandler::Register(interceptors_);
  AnimationPlayStateHandler::Register(interceptors_);
  AnimationPropertyHandler::Register(interceptors_);
  AnimationNameHandler::Register(interceptors_);
  AnimationShorthandHandler::Register(interceptors_);
  AspectRatioHandler::Register(interceptors_);
  BoolHandler::Register(interceptors_);
  ColorHandler::Register(interceptors_);
  BorderHandler::Register(interceptors_);
  TextStrokeHandler::Register(interceptors_);
  BorderStyleHandler::Register(interceptors_);
  BorderWidthHandler::Register(interceptors_);
  EnumHandler::Register(interceptors_);
  FlexFlowHandler::Register(interceptors_);
  FlexHandler::Register(interceptors_);
  FontLengthHandler::Register(interceptors_);
  FourSidesShorthandHandler::Register(interceptors_);
  GridPositionHandler::Register(interceptors_);
  GridTemplateHandler::Register(interceptors_);
  LineShorthandHandler::Register(interceptors_);
  LengthHandler::Register(interceptors_);
  NumberHandler::Register(interceptors_);
  AnimIterCountHandler::Register(interceptors_);
  ShadowHandler::Register(interceptors_);
  TimeHandler::Register(interceptors_);
  TimingFunctionHandler::Register(interceptors_);
  TransformHandler::Register(interceptors_);
  TransformOriginHandler::Register(interceptors_);
  TransitionShorthandHandler::Register(interceptors_);
  TextDecorationHandler::Register(interceptors_);
  BorderRadiusHandler::Register(interceptors_);
  BackgroundShorthandHandler::Register(interceptors_);
  BackgroundClipHandler::Register(interceptors_);
  BackgroundImageHandler::Register(interceptors_);
  BackgroundOriginHandler::Register(interceptors_);
  BackgroundPositionHandler::Register(interceptors_);
  BackgroundRepeatHandler::Register(interceptors_);
  BackgroundSizeHandler::Register(interceptors_);
  MaskImageHandler::Register(interceptors_);
  FilterHandler::Register(interceptors_);
  VerticalAlignHandler::Register(interceptors_);
  RelativeAlignHandler::Register(interceptors_);
  ListGapHandler::Register(interceptors_);
  CursorHandler::Register(interceptors_);
  ClipPathHandler::Register(interceptors_);
}

}  // namespace tasm
}  // namespace lynx
