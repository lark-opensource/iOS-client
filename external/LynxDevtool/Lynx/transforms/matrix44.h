// Copyright 2022 The Lynx Authors. All rights reserved.
// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LYNX_TRANSFORMS_MATRIX44_H_
#define LYNX_TRANSFORMS_MATRIX44_H_

#include "base/log/logging.h"

namespace lynx {
namespace transforms {

class Matrix44 {
 public:
  constexpr Matrix44()
      : fMat{{1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0}, {0, 0, 0, 1}},
        fTypeMask(kIdentity_Mask) {}

  // The parameters are in row-major order.
  Matrix44(float col1row1, float col2row1, float col3row1, float col4row1,
           float col1row2, float col2row2, float col3row2, float col4row2,
           float col1row3, float col2row3, float col3row3, float col4row3,
           float col1row4, float col2row4, float col3row4, float col4row4)
      // fMat is indexed by [col][row] (i.e. col-major).
      : fMat{{col1row1, col1row2, col1row3, col1row4},
             {col2row1, col2row2, col2row3, col2row4},
             {col3row1, col3row2, col3row3, col3row4},
             {col4row1, col4row2, col4row3, col4row4}} {
    recomputeTypeMask();
  }

  using TypeMask = uint8_t;
  enum : TypeMask {
    kIdentity_Mask = 0,
    kTranslate_Mask = 1 << 0,    //!< set if the matrix has translation
    kScale_Mask = 1 << 1,        //!< set if the matrix has any scale != 1
    kAffine_Mask = 1 << 2,       //!< set if the matrix skews or rotates
    kPerspective_Mask = 1 << 3,  //!< set if the matrix is in perspective
  };

  /**
   *  Returns a bitfield describing the transformations the matrix may
   *  perform. The bitfield is computed conservatively, so it may include
   *  false positives. For example, when kPerspective_Mask is true, all
   *  other bits may be set to true even in the case of a pure perspective
   *  transform.
   */
  inline TypeMask getType() const { return fTypeMask; }

  /**
   *  Return true if the matrix is identity.
   */
  inline bool isIdentity() const { return kIdentity_Mask == this->getType(); }

  inline bool HasPerspective() const {
    return this->getType() & kPerspective_Mask;
  }

  /**
   *  Return true if the matrix only contains scale or translate or is identity.
   */
  inline bool isScaleTranslate() const {
    return !(this->getType() & ~(kScale_Mask | kTranslate_Mask));
  }

  void setIdentity();

  /**
   *  get a value from the matrix. The row,col parameters work as follows:
   *  (0, 0)  scale-x
   *  (0, 3)  translate-x
   *  (3, 0)  perspective-x
   */
  inline float rc(int row, int col) const {
    DCHECK((unsigned)row <= 3);
    DCHECK((unsigned)col <= 3);
    return fMat[col][row];
  }

  /**
   *  set a value in the matrix. The row,col parameters work as follows:
   *  (0, 0)  scale-x
   *  (0, 3)  translate-x
   *  (3, 0)  perspective-x
   */
  inline void setRC(int row, int col, float value) {
    DCHECK((unsigned)row <= 3);
    DCHECK((unsigned)col <= 3);
    fMat[col][row] = value;
    this->recomputeTypeMask();
  }

  Matrix44& preTranslate(float dx, float dy, float dz);

  Matrix44& preScale(float sx, float sy, float sz);

  void setRotateAboutXAxis(float deg);
  void setRotateAboutYAxis(float deg);
  void setRotateAboutZAxis(float deg);

  void Skew(float angle_x, float angle_y);

  void setConcat(const Matrix44& a, const Matrix44& b);
  inline void preConcat(const Matrix44& m) { this->setConcat(*this, m); }
  inline void postConcat(const Matrix44& m) { this->setConcat(m, *this); }

  double determinant() const;

 private:
  /* This is indexed by [col][row]. */
  float fMat[4][4];
  TypeMask fTypeMask;

  static constexpr int kAllPublic_Masks = 0xF;

  float transX() const { return fMat[3][0]; }
  float transY() const { return fMat[3][1]; }
  float transZ() const { return fMat[3][2]; }

  float scaleX() const { return fMat[0][0]; }
  float scaleY() const { return fMat[1][1]; }
  float scaleZ() const { return fMat[2][2]; }

  float perspX() const { return fMat[0][3]; }
  float perspY() const { return fMat[1][3]; }
  float perspZ() const { return fMat[2][3]; }

  void recomputeTypeMask();

  inline void setTypeMask(TypeMask mask) {
    DCHECK(0 == (~kAllPublic_Masks & mask));
    fTypeMask = mask;
  }
};

}  // namespace transforms
}  // namespace lynx

#endif  // LYNX_TRANSFORMS_MATRIX44_H_
