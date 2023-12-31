// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_dictionary.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_DOM_MATRIX_2D_INIT_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_DOM_MATRIX_2D_INIT_H_

#include "base/log/logging.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {

class DOMMatrix2DInit {
 public:
  static std::unique_ptr<DOMMatrix2DInit> ToImpl(const Napi::Value&);

  Napi::Object ToJsObject(Napi::Env);

  bool hasA() { return has_a_; }
  double a() {
    return a_;
  }

  bool hasB() { return has_b_; }
  double b() {
    return b_;
  }

  bool hasC() { return has_c_; }
  double c() {
    return c_;
  }

  bool hasD() { return has_d_; }
  double d() {
    return d_;
  }

  bool hasE() { return has_e_; }
  double e() {
    return e_;
  }

  bool hasF() { return has_f_; }
  double f() {
    return f_;
  }

  bool hasM11() { return has_m11_; }
  double m11() {
    return m11_;
  }

  bool hasM12() { return has_m12_; }
  double m12() {
    return m12_;
  }

  bool hasM21() { return has_m21_; }
  double m21() {
    return m21_;
  }

  bool hasM22() { return has_m22_; }
  double m22() {
    return m22_;
  }

  bool hasM41() { return has_m41_; }
  double m41() {
    return m41_;
  }

  bool hasM42() { return has_m42_; }
  double m42() {
    return m42_;
  }

  // Dictionary name
  static constexpr const char* DictionaryName() {
    return "DOMMatrix2DInit";
  }

 private:
  bool has_a_ = false;
  bool has_b_ = false;
  bool has_c_ = false;
  bool has_d_ = false;
  bool has_e_ = false;
  bool has_f_ = false;
  bool has_m11_ = false;
  bool has_m12_ = false;
  bool has_m21_ = false;
  bool has_m22_ = false;
  bool has_m41_ = false;
  bool has_m42_ = false;

  double a_;
  double b_;
  double c_;
  double d_;
  double e_;
  double f_;
  double m11_;
  double m12_;
  double m21_;
  double m22_;
  double m41_;
  double m42_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_DOM_MATRIX_2D_INIT_H_
