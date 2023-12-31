// Copyright 2022 The Lynx Authors. All rights reserved.
// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifdef OS_WIN
#define _USE_MATH_DEFINES
#endif

#include "transforms/matrix44.h"

#include <cmath>
#include <cstring>
#include <string>

namespace lynx {
namespace transforms {
static inline constexpr double DegToRad(double degrees) {
  return degrees * M_PI / 180.0;
}

void Matrix44::recomputeTypeMask() {
  if (0 != perspX() || 0 != perspY() || 0 != perspZ() || 1 != fMat[3][3]) {
    fTypeMask =
        kTranslate_Mask | kScale_Mask | kAffine_Mask | kPerspective_Mask;
    return;
  }

  TypeMask mask = kIdentity_Mask;
  if (0 != transX() || 0 != transY() || 0 != transZ()) {
    mask |= kTranslate_Mask;
  }

  if (1 != scaleX() || 1 != scaleY() || 1 != scaleZ()) {
    mask |= kScale_Mask;
  }

  if (0 != fMat[1][0] || 0 != fMat[0][1] || 0 != fMat[0][2] ||
      0 != fMat[2][0] || 0 != fMat[1][2] || 0 != fMat[2][1]) {
    mask |= kAffine_Mask;
  }
  fTypeMask = mask;
}

void Matrix44::setIdentity() {
  fMat[0][0] = 1;
  fMat[0][1] = 0;
  fMat[0][2] = 0;
  fMat[0][3] = 0;
  fMat[1][0] = 0;
  fMat[1][1] = 1;
  fMat[1][2] = 0;
  fMat[1][3] = 0;
  fMat[2][0] = 0;
  fMat[2][1] = 0;
  fMat[2][2] = 1;
  fMat[2][3] = 0;
  fMat[3][0] = 0;
  fMat[3][1] = 0;
  fMat[3][2] = 0;
  fMat[3][3] = 1;
  this->setTypeMask(kIdentity_Mask);
}

Matrix44& Matrix44::preTranslate(float dx, float dy, float dz) {
  if (!dx && !dy && !dz) {
    return *this;
  }

  for (int i = 0; i < 4; ++i) {
    fMat[3][i] =
        fMat[0][i] * dx + fMat[1][i] * dy + fMat[2][i] * dz + fMat[3][i];
  }
  this->recomputeTypeMask();
  return *this;
}

Matrix44& Matrix44::preScale(float sx, float sy, float sz) {
  if (1 == sx && 1 == sy && 1 == sz) {
    return *this;
  }

  // The implementation matrix * pureScale can be shortcut
  // by knowing that pureScale components effectively scale
  // the columns of the original matrix.
  for (int i = 0; i < 4; i++) {
    fMat[0][i] *= sx;
    fMat[1][i] *= sy;
    fMat[2][i] *= sz;
  }
  this->recomputeTypeMask();
  return *this;
}

void Matrix44::setRotateAboutXAxis(float deg) {
  double sin_theta = std::sin(DegToRad(deg));
  double cos_theta = std::cos(DegToRad(deg));
  fMat[0][0] = 1;
  fMat[0][1] = 0;
  fMat[0][2] = 0;
  fMat[0][3] = 0;
  fMat[1][0] = 0;
  fMat[1][1] = cos_theta;
  fMat[1][2] = sin_theta;
  fMat[1][3] = 0;
  fMat[2][0] = 0;
  fMat[2][1] = -sin_theta;
  fMat[2][2] = cos_theta;
  fMat[2][3] = 0;
  fMat[3][0] = 0;
  fMat[3][1] = 0;
  fMat[3][2] = 0;
  fMat[3][3] = 1;

  this->recomputeTypeMask();
}

void Matrix44::setRotateAboutYAxis(float deg) {
  double sin_theta = std::sin(DegToRad(deg));
  double cos_theta = std::cos(DegToRad(deg));
  fMat[0][0] = cos_theta;
  fMat[0][1] = 0;
  fMat[0][2] = -sin_theta;
  fMat[0][3] = 0;
  fMat[1][0] = 0;
  fMat[1][1] = 1;
  fMat[1][2] = 0;
  fMat[1][3] = 0;
  fMat[2][0] = sin_theta;
  fMat[2][1] = 0;
  fMat[2][2] = cos_theta;
  fMat[2][3] = 0;
  fMat[3][0] = 0;
  fMat[3][1] = 0;
  fMat[3][2] = 0;
  fMat[3][3] = 1;

  this->recomputeTypeMask();
}

void Matrix44::setRotateAboutZAxis(float deg) {
  double sin_theta = std::sin(DegToRad(deg));
  double cos_theta = std::cos(DegToRad(deg));
  fMat[0][0] = cos_theta;
  fMat[0][1] = sin_theta;
  fMat[0][2] = 0;
  fMat[0][3] = 0;
  fMat[1][0] = -sin_theta;
  fMat[1][1] = cos_theta;
  fMat[1][2] = 0;
  fMat[1][3] = 0;
  fMat[2][0] = 0;
  fMat[2][1] = 0;
  fMat[2][2] = 1;
  fMat[2][3] = 0;
  fMat[3][0] = 0;
  fMat[3][1] = 0;
  fMat[3][2] = 0;
  fMat[3][3] = 1;

  this->recomputeTypeMask();
}

void Matrix44::Skew(float angle_x, float angle_y) {
  if (isIdentity()) {
    setRC(0, 1, std::tan(DegToRad(angle_x)));
    setRC(1, 0, std::tan(DegToRad(angle_y)));
  } else {
    Matrix44 skew;
    skew.setRC(0, 1, std::tan(DegToRad(angle_x)));
    skew.setRC(1, 0, std::tan(DegToRad(angle_y)));
    preConcat(skew);
  }
}

static bool IsBitsOnly(int value, int mask) { return 0 == (value & ~mask); }

void Matrix44::setConcat(const Matrix44& a, const Matrix44& b) {
  const Matrix44::TypeMask a_mask = a.getType();
  const Matrix44::TypeMask b_mask = b.getType();

  if (kIdentity_Mask == a_mask) {
    *this = b;
    return;
  }
  if (kIdentity_Mask == b_mask) {
    *this = a;
    return;
  }

  bool useStorage = (this == &a || this == &b);
  float storage[16];
  float* result = useStorage ? storage : &fMat[0][0];

  // Both matrices are at most scale+translate
  if (IsBitsOnly(a_mask | b_mask, kScale_Mask | kTranslate_Mask)) {
    result[0] = a.fMat[0][0] * b.fMat[0][0];
    result[1] = result[2] = result[3] = result[4] = 0;
    result[5] = a.fMat[1][1] * b.fMat[1][1];
    result[6] = result[7] = result[8] = result[9] = 0;
    result[10] = a.fMat[2][2] * b.fMat[2][2];
    result[11] = 0;
    result[12] = a.fMat[0][0] * b.fMat[3][0] + a.fMat[3][0];
    result[13] = a.fMat[1][1] * b.fMat[3][1] + a.fMat[3][1];
    result[14] = a.fMat[2][2] * b.fMat[3][2] + a.fMat[3][2];
    result[15] = 1;
  } else {
    for (const auto& row : b.fMat) {
      for (int i = 0; i < 4; i++) {
        double value = 0;
        for (int k = 0; k < 4; k++) {
          value += double(a.fMat[k][i]) * row[k];
        }
        *result++ = float(value);
      }
    }
  }

  if (useStorage) {
    std::memcpy(fMat, storage, sizeof(storage));
  }
  this->recomputeTypeMask();
}

/** We always perform the calculation in doubles, to avoid prematurely losing
    precision along the way. This relies on the compiler automatically
    promoting our float values to double (if needed).
 */
double Matrix44::determinant() const {
  if (this->isIdentity()) {
    return 1;
  }
  if (this->isScaleTranslate()) {
    return fMat[0][0] * fMat[1][1] * fMat[2][2] * fMat[3][3];
  }

  double a00 = fMat[0][0];
  double a01 = fMat[0][1];
  double a02 = fMat[0][2];
  double a03 = fMat[0][3];
  double a10 = fMat[1][0];
  double a11 = fMat[1][1];
  double a12 = fMat[1][2];
  double a13 = fMat[1][3];
  double a20 = fMat[2][0];
  double a21 = fMat[2][1];
  double a22 = fMat[2][2];
  double a23 = fMat[2][3];
  double a30 = fMat[3][0];
  double a31 = fMat[3][1];
  double a32 = fMat[3][2];
  double a33 = fMat[3][3];

  double b00 = a00 * a11 - a01 * a10;
  double b01 = a00 * a12 - a02 * a10;
  double b02 = a00 * a13 - a03 * a10;
  double b03 = a01 * a12 - a02 * a11;
  double b04 = a01 * a13 - a03 * a11;
  double b05 = a02 * a13 - a03 * a12;
  double b06 = a20 * a31 - a21 * a30;
  double b07 = a20 * a32 - a22 * a30;
  double b08 = a20 * a33 - a23 * a30;
  double b09 = a21 * a32 - a22 * a31;
  double b10 = a21 * a33 - a23 * a31;
  double b11 = a22 * a33 - a23 * a32;

  // Calculate the determinant
  return b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
}

}  // namespace transforms
}  // namespace lynx
