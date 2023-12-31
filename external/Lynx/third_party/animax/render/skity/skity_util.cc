// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skity/skity_util.h"

namespace lynx {
namespace animax {

skity::Rect SkityUtil::MakeSkityRect(const RectF &rec) {
  return skity::Rect::MakeLTRB(rec.GetLeft(), rec.GetTop(), rec.GetRight(),
                               rec.GetBottom());
}

}  // namespace animax
}  // namespace lynx
