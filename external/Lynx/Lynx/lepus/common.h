// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_COMMON_H_
#define LYNX_LEPUS_COMMON_H_

namespace lynx {
namespace lepus {

template <typename Dst, typename Src>
Dst BitCast(Src&& value) {
  static_assert(sizeof(Src) == sizeof(Dst), "BitCast sizes must match.");
  Dst result;
  memcpy(&result, &value, sizeof(result));
  return result;
}

}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_COMMON_H_
