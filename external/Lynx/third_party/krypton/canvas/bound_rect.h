// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_BOUND_RECT_H_
#define CANVAS_BOUND_RECT_H_

#include "jsbridge/napi/base.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class BoundRect : public ImplBase {
 public:
  static std::unique_ptr<BoundRect> Create() {
    return std::unique_ptr<BoundRect>(new BoundRect());
  }
  // get
  int GetX() { return x_; }
  int GetY() { return y_; }
  int GetWidth() { return width_; }
  int GetHeight() { return height_; }
  int GetTop() { return top_; }
  int GetRight() { return right_; }
  int GetBottom() { return bottom_; }
  int GetLeft() { return left_; }

  // set
  void set(int width, int height, int x, int y, int top, int right, int bottom,
           int left) {
    width_ = width;
    height_ = height;
    x_ = x;
    y_ = y;
    top_ = top;
    bottom_ = bottom;
    left_ = left;
    right_ = right;
  }

 private:
  int width_ = 0;
  int height_ = 0;
  int x_ = 0;
  int y_ = 0;
  int top_ = 0;
  int right_ = 0;
  int bottom_ = 0;
  int left_ = 0;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_BOUND_RECT_H_
