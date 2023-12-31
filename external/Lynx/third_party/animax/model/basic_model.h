// Copyright 2023 The Lynx Authors. All rights reserved.
// Copyright 2018 Airbnb, Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef ANIMAX_MODEL_BASIC_MODEL_H_
#define ANIMAX_MODEL_BASIC_MODEL_H_

#include <cmath>
#include <limits>
#include <memory>
#include <string>

#include "cinttypes"

namespace lynx {
namespace animax {

class Integer {
 public:
  static Integer Make(int32_t value) { return Integer(value); }
  static Integer MakeEmpty() { return Integer(Min()); }

  static inline int32_t Max() { return std::numeric_limits<int32_t>::max(); }
  static inline int32_t Min() { return std::numeric_limits<int32_t>::min(); }

  Integer(int32_t value) : value_(value) {}
  Integer() : value_(0) {}

  ~Integer() = default;

  int32_t Get() const { return value_; };
  void Reset() { value_ = Min(); }
  void Set(int32_t value) { value_ = value; }

  bool IsEmpty() { return value_ == Min(); }

 private:
  int32_t value_;
};

class Float {
 public:
  static Float Make(float value) { return Float(value); }
  static Float MakeEmpty() { return Float(NAN); }

  static inline float Max() { return std::numeric_limits<float>::max(); }
  static inline float Min() { return std::numeric_limits<float>::min(); }

  Float(float value) : value_(value) {}
  Float() : value_(0) {}
  ~Float() = default;

  float Get() const { return value_; }
  void Reset() { value_ = NAN; }
  void Set(float value) { value_ = value; }

  bool IsEmpty() const { return std::isnan(value_); }

 private:
  float value_;
};

class PointF {
 public:
  static PointF Make(float x, float y) { return PointF(x, y); }
  static PointF Make() { return PointF(); }
  static PointF MakeEmpty() { return PointF(NAN, NAN); }

  PointF(float x, float y) : x_(x), y_(y) {}
  PointF() : x_(0), y_(0) {}
  ~PointF() = default;

  float GetX() const { return x_; }
  float GetY() const { return y_; }
  float Length() { return std::hypot(x_, y_); }

  bool Equals(float x, float y) { return x_ == x && y_ == y; }
  bool Equals(const PointF &other) { return Equals(other.x_, other.y_); }
  void Set(float x, float y) {
    x_ = x;
    y_ = y;
  }
  void Reset() {
    x_ = NAN;
    y_ = NAN;
  }

  bool IsEmpty() const { return std::isnan(x_) || std::isnan(y_); }

 private:
  float x_;
  float y_;
};

class ScaleXY {
 public:
  static ScaleXY Make(float x, float y) { return ScaleXY(x, y); }
  static ScaleXY MakeEmpty() { return ScaleXY(NAN, NAN); }

  ScaleXY(float scale_x, float scale_y)
      : scale_x_(scale_x), scale_y_(scale_y) {}
  ScaleXY() : scale_x_(1), scale_y_(1) {}
  ~ScaleXY() = default;

  float GetScaleX() const { return scale_x_; }
  float GetScaleY() const { return scale_y_; }

  void Set(float x, float y) {
    scale_x_ = x;
    scale_y_ = y;
  }
  bool Equals(float x, float y) { return scale_x_ == x && scale_y_ == y; }
  void Reset() {
    scale_x_ = NAN;
    scale_y_ = NAN;
  }

  bool IsEmpty() const { return std::isnan(scale_x_) || std::isnan(scale_y_); }

 private:
  float scale_x_;
  float scale_y_;
};

class Color {
 public:
  static Color Make() { return Color(); }
  static Color Make(uint8_t a, uint8_t r, uint8_t g, uint8_t b) {
    return Color(a, r, g, b);
  }
  static Color MakeEmpty() {
    auto color = Color();
    color.empty_ = true;
    return color;
  }

  static Color ParseColor(std::string &color);
  static int32_t ToInt(uint8_t a, uint8_t r, uint8_t g, uint8_t b) {
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  Color(uint8_t a, uint8_t r, uint8_t g, uint8_t b)
      : a_(a), r_(r), g_(g), b_(b) {}
  Color() : a_(255), r_(255), g_(255), b_(255) {}
  Color(int32_t value) {
    a_ = (value >> 24) & 0xff;
    r_ = (value >> 16) & 0xff;
    g_ = (value >> 8) & 0xff;
    b_ = value & 0xff;
  }
  ~Color() = default;

  uint8_t GetA() const { return a_; }
  uint8_t GetR() const { return r_; }
  uint8_t GetG() const { return g_; }
  uint8_t GetB() const { return b_; }
  int32_t GetInt() { return ToInt(a_, r_, g_, b_); }

  void Reset() {
    a_ = 255;
    r_ = 255;
    g_ = 255;
    b_ = 255;
  }

  void SetA(uint8_t a) { a_ = a; }
  void Set(uint8_t a, uint8_t r, uint8_t g, uint8_t b) {
    a_ = a;
    r_ = r;
    g_ = g;
    b_ = b;
  }

  bool IsEmpty() { return empty_; }

 private:
  uint8_t a_ = 0;
  uint8_t r_ = 0;
  uint8_t g_ = 0;
  uint8_t b_ = 0;
  bool empty_ = false;
};

class Rect {
 public:
  Rect(int32_t left, int32_t right, int32_t top, int32_t bottom)
      : left_(left), right_(right), top_(top), bottom_(bottom) {}
  Rect() : left_(0), right_(0), top_(0), bottom_(0) {}
  ~Rect() = default;
  int32_t GetWidth() { return right_ - left_; }
  int32_t GetHeight() { return bottom_ - top_; }

 private:
  int32_t left_, right_, top_, bottom_;
};

class RectF {
 public:
  RectF(float left, float top, float right, float bottom)
      : left_(left), top_(top), right_(right), bottom_(bottom) {}
  RectF() : left_(0), top_(0), right_(0), bottom_(0) {}
  ~RectF() = default;

  float GetWidth() const { return right_ - left_; }
  float GetHeight() const { return bottom_ - top_; }
  float GetLeft() const { return left_; }
  float GetRight() const { return right_; }
  float GetTop() const { return top_; }
  float GetBottom() const { return bottom_; }
  bool IsEmpty() const { return left_ >= right_ || top_ >= bottom_; }

  void Set(float left, float top, float right, float bottom) {
    left_ = left;
    top_ = top;
    right_ = right;
    bottom_ = bottom;
  }

  void Set(const RectF &rect) {
    left_ = rect.GetLeft();
    top_ = rect.GetTop();
    right_ = rect.GetRight();
    bottom_ = rect.GetBottom();
  }

  void Union(float left, float top, float right, float bottom) {
    if ((left < right) && (top < bottom)) {
      if ((left_ < right_) && (top_ < bottom_)) {
        if (left_ > left) left_ = left;
        if (top_ > top) top_ = top;
        if (right_ < right) right_ = right;
        if (bottom_ < bottom) bottom_ = bottom;
      } else {
        left_ = left;
        top_ = top;
        right_ = right;
        bottom_ = bottom;
      }
    }
  }

  void Union(const RectF &rect) {
    Union(rect.left_, rect.top_, rect.right_, rect.bottom_);
  }

  bool Intersect(const RectF &rect) {
    return Intersect(rect.left_, rect.top_, rect.right_, rect.bottom_);
  }

  bool Intersect(float left, float top, float right, float bottom) {
    if (left_ < right && left < right_ && top_ < bottom && top < bottom_) {
      if (left_ < left) {
        left_ = left;
      }
      if (top_ < top) {
        top_ = top;
      }
      if (right_ > right) {
        right_ = right;
      }
      if (bottom_ > bottom) {
        bottom_ = bottom;
      }
      return true;
    }
    return false;
  }

 private:
  float left_ = 0, top_ = 0, right_ = 0, bottom_ = 0;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_BASIC_MODEL_H_
