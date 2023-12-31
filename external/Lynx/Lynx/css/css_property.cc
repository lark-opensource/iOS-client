// Copyright 2019 The Lynx Authors. All rights reserved.

#include "css/css_property.h"

#include <set>
#include <vector>

#include "base/no_destructor.h"

namespace lynx {
namespace tasm {

const std::set<CSSPropertyID> shorthandCSSProperties{
    kPropertyIDBorder,
    kPropertyIDBorderTop,
    kPropertyIDBorderRight,
    kPropertyIDBorderBottom,
    kPropertyIDBorderLeft,
    kPropertyIDMarginInlineStart,
    kPropertyIDMarginInlineEnd,
    kPropertyIDPaddingInlineStart,
    kPropertyIDPaddingInlineEnd,
    kPropertyIDBorderInlineStartWidth,
    kPropertyIDBorderInlineEndWidth,
    kPropertyIDBorderInlineStartColor,
    kPropertyIDBorderInlineEndColor,
    kPropertyIDBorderInlineStartStyle,
    kPropertyIDBorderInlineEndStyle,
    kPropertyIDBorderStartStartRadius,
    kPropertyIDBorderEndStartRadius,
    kPropertyIDBorderStartEndRadius,
    kPropertyIDBorderEndEndRadius,
    kPropertyIDFlex,
    kPropertyIDFlexFlow,
    kPropertyIDPadding,
    kPropertyIDMargin,
    kPropertyIDInsetInlineStart,
    kPropertyIDInsetInlineEnd,
    kPropertyIDBorderWidth,
    kPropertyIDBackground,
    kPropertyIDBorderColor,
    kPropertyIDBorderStyle,
    kPropertyIDOutline};

CSSPropertyID CSSProperty::GetPropertyID(const lepus::String& name) {
  const static base::NoDestructor<
      std::unordered_map<lepus::String, CSSPropertyID>>
      kPropertyNameMapping{{
#define DECLARE_PROPERTY_NAME(name, c, value) {c, kPropertyID##name},
          FOREACH_ALL_PROPERTY(DECLARE_PROPERTY_NAME)
#undef DECLARE_PROPERTY_NAME
      }};
  auto it = kPropertyNameMapping->find(name);
  return it != kPropertyNameMapping->end() ? it->second : kPropertyEnd;
}

const lepus::String& CSSProperty::GetPropertyName(CSSPropertyID id) {
  const static base::NoDestructor<std::vector<lepus::String>>
      kPropertyIdMapping{{
          "",  // start
#define DECLARE_PROPERTY_ID(name, c, value) c,
          FOREACH_ALL_PROPERTY(DECLARE_PROPERTY_ID)
#undef DECLARE_PROPERTY_ID
              ""  // end
      }};
  if (id > kPropertyStart && id < kPropertyEnd) {
    return (*kPropertyIdMapping)[id];
  }
  const static base::NoDestructor<lepus::String> kEmpty;
  return *kEmpty;
}

CSSPropertyID CSSProperty::GetTimingOptionsPropertyID(
    const lepus::String& name) {
  static const base::NoDestructor<
      std::unordered_map<lepus::String, CSSPropertyID>>
      kAnimationPropertyNameMapping({
#define DECLARE_PROPERTY_NAME(name, alias) {alias, kPropertyID##name},
          FOREACH_ALL_ANIMATIONAPI_PROPERTY(DECLARE_PROPERTY_NAME)
#undef DECLARE_PROPERTY_NAME
      });
  auto it = kAnimationPropertyNameMapping.get()->find(name);
  return it != kAnimationPropertyNameMapping.get()->end() ? it->second
                                                          : kPropertyEnd;
}

const std::unordered_map<std::string, std::string>&
CSSProperty::GetComputeStyleMap() {
  static const base::NoDestructor<std::unordered_map<std::string, std::string>>
      kComputeStyleMap{{
#define DECLARE_PROPERTY_ID(name, c, value) {c, value},
          FOREACH_ALL_PROPERTY(DECLARE_PROPERTY_ID)
#undef DECLARE_PROPERTY_ID
              {"", ""}}};
  return *kComputeStyleMap;
}

bool CSSProperty::IsShorthand(CSSPropertyID id) {
  return shorthandCSSProperties.find(id) != shorthandCSSProperties.end();
}

}  // namespace tasm
}  // namespace lynx
