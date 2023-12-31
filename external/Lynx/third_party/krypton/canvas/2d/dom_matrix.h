// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_2D_DOM_MATRIX_H_
#define CANVAS_2D_DOM_MATRIX_H_

#include "jsbridge/napi/base.h"

namespace lynx {
namespace canvas {
// 2d dom matrix
class DOMMatrix : public piper::ImplBase {
 public:
  DOMMatrix(float matrix[6])
      : a_(matrix[0]),
        b_(matrix[1]),
        c_(matrix[2]),
        d_(matrix[3]),
        e_(matrix[4]),
        f_(matrix[5]){};
  bool GetIs2D() { return true; };
  bool GetIsIdentity() {
    return a_ == 1 && b_ == 0 && c_ == 0 && d_ == 1 && e_ == 0 && f_ == 0;
  }
  double GetA() const { return a_; }
  double GetB() const { return b_; }
  double GetC() const { return c_; }
  double GetD() const { return d_; }
  double GetE() const { return e_; }
  double GetF() const { return f_; }

 private:
  double a_ = 1;
  double b_ = 0;
  double c_ = 0;
  double d_ = 1;
  double e_ = 0;
  double f_ = 0;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_2D_DOM_MATRIX_H_
