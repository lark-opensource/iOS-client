// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_BASE_MISC_UTIL_H_
#define ANIMAX_BASE_MISC_UTIL_H_

#include "Lynx/base/compiler_specific.h"
#include "animax/model/basic_model.h"

namespace lynx {
namespace animax {

static ALLOW_UNUSED_TYPE float Lerp(float a, float b, float percentage) {
  return a + percentage * (b - a);
}

static ALLOW_UNUSED_TYPE int32_t Lerp(int32_t a, int32_t b, float percentage) {
  return a + percentage * (b - a);
}

static ALLOW_UNUSED_TYPE void Lerp(Integer& a, Integer& b, float percentage,
                                   Integer* out) {
  out->Set(Lerp(a.Get(), b.Get(), percentage));
}

static ALLOW_UNUSED_TYPE void Lerp(Float& a, Float& b, float percentage,
                                   Float* out) {
  out->Set(Lerp(a.Get(), b.Get(), percentage));
}

static ALLOW_UNUSED_TYPE int32_t FloorMod(int32_t x, int32_t y) {
  int32_t r = x / y;
  // if the signs are different and modulo not zero, round down
  if ((x ^ y) < 0 && (r * y != x)) {
    r--;
  }
  return x - r * y;
}

static ALLOW_UNUSED_TYPE void GammaEvaluate(Color& start_color,
                                            Color& end_color, float progress,
                                            Color* out) {
  auto start_a = static_cast<float>(start_color.GetA());
  auto start_r = static_cast<float>(start_color.GetR());
  auto start_g = static_cast<float>(start_color.GetG());
  auto start_b = static_cast<float>(start_color.GetB());

  auto end_a = static_cast<float>(end_color.GetA());
  auto end_r = static_cast<float>(end_color.GetR());
  auto end_g = static_cast<float>(end_color.GetG());
  auto end_b = static_cast<float>(end_color.GetB());

  auto a = Lerp(start_a, end_a, progress);
  auto r = Lerp(start_r, end_r, progress);
  auto g = Lerp(start_g, end_g, progress);
  auto b = Lerp(start_b, end_b, progress);

  out->Set(a, r, g, b);
}

static ALLOW_UNUSED_TYPE int32_t GammaEvaluate(int32_t start_color,
                                               int32_t end_color,
                                               float progress) {
  auto start_a = (start_color >> 24) & 0xff;
  auto start_r = (start_color >> 16) & 0xff;
  auto start_g = (start_color >> 8) & 0xff;
  auto start_b = start_color & 0xff;

  auto end_a = (end_color >> 24) & 0xff;
  auto end_r = (end_color >> 16) & 0xff;
  auto end_g = (end_color >> 8) & 0xff;
  auto end_b = end_color & 0xff;

  auto a = Lerp(start_a, end_a, progress);
  auto r = Lerp(start_r, end_r, progress);
  auto g = Lerp(start_g, end_g, progress);
  auto b = Lerp(start_b, end_b, progress);

  return Color::ToInt(a, r, g, b);
}

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_BASE_MISC_UTIL_H_
