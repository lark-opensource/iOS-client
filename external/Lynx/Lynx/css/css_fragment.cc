// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/css_fragment.h"

namespace lynx {
namespace tasm {

void CSSFragment::PrintStyles() {
  for (UNUSED_LOG_VARIABLE auto& iter : css()) {
    LOGE("CSSFragment::PrintStyles key: " << iter.first);
  }
}

const std::vector<std::shared_ptr<CSSFontFaceToken>>&
CSSFragment::GetDefaultFontFaceList() {
  static base::NoDestructor<std::vector<std::shared_ptr<CSSFontFaceToken>>>
      fontfaces{};
  return *fontfaces;
}

}  // namespace tasm
}  // namespace lynx
