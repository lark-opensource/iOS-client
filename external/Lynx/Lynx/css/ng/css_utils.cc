// Copyright 2023 The Lynx Authors. All rights reserved.

#include "css/ng/css_utils.h"

#include "base/no_destructor.h"

namespace lynx {
namespace css {

const std::string& CSSGlobalEmptyString() {
  static const base::NoDestructor<std::string> str;
  return *str;
}

const std::u16string& CSSGlobalEmptyU16String() {
  static const base::NoDestructor<std::u16string> str;
  return *str;
}

const std::string& CSSGlobalStarString() {
  static const base::NoDestructor<std::string> str("*");
  return *str;
}

const std::u16string& CSSGlobalStarU16String() {
  static const base::NoDestructor<std::u16string> str(u"*");
  return *str;
}

}  // namespace css
}  // namespace lynx
