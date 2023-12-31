// Copyright 2017 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_CSS_TYPE_H_
#define LYNX_STARLIGHT_STYLE_CSS_TYPE_H_

#include <limits.h>
#include <stdint.h>

namespace lynx {
namespace starlight {

// align-self及align-item类型
enum class FlexAlignType : unsigned {
  kAuto,
  kStretch,
  kFlexStart,
  kFlexEnd,
  kCenter,
  kBaseline
};

enum class JustifyType : unsigned { kAuto, kStretch, kStart, kEnd, kCenter };

enum class OverflowType : unsigned {
  kVisible,
  kHidden,
  kScroll,
};

// 长度可枚举类型
enum class LengthValueType : unsigned {
  kAuto,
  kPercentage,
  kCalc,
  kRpx,
  kPx,
  kRem,
  kEm,
  kVw,
  kVh,
  kNumber,
  kPPx,
  kMaxContent,
  kFitContent,
};

enum class BorderStyleType : unsigned {
  kSolid,
  kDashed,
  kDotted,
  kDouble,
  kGroove,
  kRidge,
  kInset,
  kOutset,
  kHide,
  kNone,
  kUndefined = INT_MAX,  // default no border style
};

enum class BorderWidthType : unsigned {
  kThin = 1,
  kMedium = 3,
  kThick = 5,
};

enum class TimingFunctionType : unsigned {
  kLinear,
  kEaseIn,
  kEaseOut,
  kEaseInEaseOut,
  kSquareBezier,
  kCubicBezier,
  kSteps,
};

enum class StepsType : unsigned {
  kInvalid,
  kStart,
  kEnd,
  kJumpBoth,
  kJumpNone
};

enum class AnimationPropertyType : unsigned {
  kNone = 0,
  kOpacity = 1 << 0,
  kScaleX = 1 << 1,
  kScaleY = 1 << 2,
  kScaleXY = 1 << 3,
  kWidth = 1 << 4,
  kHeight = 1 << 5,
  kBackgroundColor = 1 << 6,
  kVisibility = 1 << 7,
  kLeft = 1 << 8,
  kTop = 1 << 9,
  kRight = 1 << 10,
  kBottom = 1 << 11,
  kTransform = 1 << 12,
  kColor = 1 << 13,
  kLayout = kWidth | kHeight | kLeft | kTop | kRight | kBottom,
  kAll = kOpacity | kWidth | kHeight | kBackgroundColor | kVisibility | kLeft |
         kTop | kRight | kBottom | kTransform | kColor,
};

enum class TransformType : unsigned {
  kNone = 0,
  kTranslate = 1,
  kTranslateX = 1 << 1,
  kTranslateY = 1 << 2,
  kTranslateZ = 1 << 3,
  kTranslate3d = 1 << 4,
  kRotate = 1 << 5,
  kRotateX = 1 << 6,
  kRotateY = 1 << 7,
  kRotateZ = 1 << 8,
  kScale = 1 << 9,
  kScaleX = 1 << 10,
  kScaleY = 1 << 11,
  kSkew = 1 << 12,
  kSkewX = 1 << 13,
  kSkewY = 1 << 14
};

enum class TextDecorationType : unsigned {
  kNone = 0,
  kUnderLine = 1 << 0,
  kLineThrough = 1 << 1,
  kSolid = 1 << 2,
  kDouble = 1 << 3,
  kDotted = 1 << 4,
  kDashed = 1 << 5,
  kWavy = 1 << 6,
  kColor = 1 << 7
};

enum class FontFaceSrcType {
  kUrl = 1,
  kLocal = 2,
};

enum LayoutAnimationType { kCreate, kUpdate, kDelete };

enum class ShadowOption { kNone = 0, kInset = 1, kInitial = 2, kInherit = 3 };

enum class VerticalAlignType {
  kDefault = 0,
  kBaseline = 1,
  kSub = 2,
  kSuper = 3,
  kTop = 4,
  kTextTop = 5,
  kMiddle = 6,
  kBottom = 7,
  kTextBottom = 8,
  kLength = 9,
  kPercent = 10,
  kCenter = 11
};

enum class ContentType { kInvalid = 0, kPlain = 1, kImage, kText, kLayer };

enum class PlatformLengthUnit { NUMBER = 0, PERCENTAGE = 1, CALC = 2 };

enum class PerspectiveLengthUnit {
  NUMBER = 0,
  VW = 1,
  VH = 2,
  DEFAULT = 3,
  PX = 4
};

enum class BackgroundImageType {
  kNone,
  kUrl,
  kLinearGradient,
  kRadialGradient
};

enum class CursorType {
  kUrl,
  kKeyword,
};

enum class BackgroundOriginType : unsigned {
  kPaddingBox = 0,  // version:1.0
  kBorderBox = 1,   // version:1.0
  kContentBox = 2,  // version:1.0
};
enum class BackgroundRepeatType : unsigned {
  kRepeat = 0,    // version:1.0
  kNoRepeat = 1,  // version:1.0
  kRepeatX = 2,   // version:1.0
  kRepeatY = 3,   // version:1.0
  kRound = 4,     // version:1.0
  kSpace = 5,     // version:1.0
};

enum class BackgroundPositionType : unsigned {
  kTop = (1 << 5),
  kRight,
  kBottom,
  kLeft,
  kCenter,
};

enum class BackgroundSizeType : unsigned {
  kAuto = (1 << 5),
  kCover,
  kContain,
};

enum class BackgroundClipType : unsigned {
  kPaddingBox = 0,  // version:1.0
  kBorderBox = 1,   // version:1.0
  kContentBox = 2,  // version:1.0
};

enum class RadialGradientShapeType : unsigned {
  kEllipse = 0,
  kCircle,
};

enum class RadialGradientSizeType : unsigned {
  kFarthestCorner = 0,
  kFarthestSide,
  kClosestCorner,
  kClosestSide,
};

enum class AnimationDirectionType : unsigned {
  kNormal = 0,            // version:1.0
  kReverse = 1,           // version:1.0
  kAlternate = 2,         // version:1.0
  kAlternateReverse = 3,  // version:1.0
};

enum class AnimationFillModeType : unsigned {
  kNone = 0,       // version:1.0
  kForwards = 1,   // version:1.0
  kBackwards = 2,  // version:1.0
  kBoth = 3,       // version:1.0
};

enum class AnimationPlayStateType : unsigned {
  kPaused = 0,   // version:1.0
  kRunning = 1,  // version:1.0
};

enum class GridAutoFlowType : unsigned {
  kRow = 0,          // version:2.1
  kColumn = 1,       // version:2.1
  kDense = 2,        // version:2.1
  kRowDense = 3,     // version:2.1
  kColumnDense = 4,  // version:2.1
};

// AUTO INSERT, DON'T CHANGE IT!
enum class PositionType : unsigned {
  kAbsolute = 0,  // version:1.0
  kRelative = 1,  // version:1.0
  kFixed = 2,     // version:1.0
  kSticky = 3,    // version:1.4
};
enum class BoxSizingType : unsigned {
  kBorderBox = 0,   // version:1.0
  kContentBox = 1,  // version:1.0
  kAuto = 2,        // version:2.0
};
enum class DisplayType : unsigned {
  kNone = 0,      // version:1.0
  kFlex = 1,      // version:1.0
  kGrid = 2,      // version:1.0
  kLinear = 3,    // version:1.0
  kRelative = 4,  // version:2.0
  kBlock = 5,     // version:2.0
  kAuto = 6,      // version:2.0
};
enum class WhiteSpaceType : unsigned {
  kNormal = 0,  // version:1.0
  kNowrap = 1,  // version:1.0
};
enum class TextAlignType : unsigned {
  kLeft = 0,     // version:1.0
  kCenter = 1,   // version:1.0
  kRight = 2,    // version:1.0
  kStart = 3,    // version:2.0
  kEnd = 4,      // version:2.0
  kJustify = 5,  // version:2.10
};
enum class TextOverflowType : unsigned {
  kClip = 0,      // version:1.0
  kEllipsis = 1,  // version:1.0
};
enum class FontWeightType : unsigned {
  kNormal = 0,  // version:1.0
  kBold = 1,    // version:1.0
  k100 = 2,     // version:1.0
  k200 = 3,     // version:1.0
  k300 = 4,     // version:1.0
  k400 = 5,     // version:1.0
  k500 = 6,     // version:1.0
  k600 = 7,     // version:1.0
  k700 = 8,     // version:1.0
  k800 = 9,     // version:1.0
  k900 = 10,    // version:1.0
};
enum class FlexDirectionType : unsigned {
  kColumn = 0,         // version:1.0
  kRow = 1,            // version:1.0
  kRowReverse = 2,     // version:1.0
  kColumnReverse = 3,  // version:1.0
};
enum class FlexWrapType : unsigned {
  kWrap = 0,         // version:1.0
  kNowrap = 1,       // version:1.0
  kWrapReverse = 2,  // version:1.0
};
enum class AlignContentType : unsigned {
  kFlexStart = 0,     // version:1.0
  kFlexEnd = 1,       // version:1.0
  kCenter = 2,        // version:1.0
  kStretch = 3,       // version:1.0
  kSpaceBetween = 4,  // version:1.0
  kSpaceAround = 5,   // version:1.0
};
enum class JustifyContentType : unsigned {
  kFlexStart = 0,     // version:1.0
  kCenter = 1,        // version:1.0
  kFlexEnd = 2,       // version:1.0
  kSpaceBetween = 3,  // version:1.0
  kSpaceAround = 4,   // version:1.0
  kSpaceEvenly = 5,   // version:1.0
  kStretch = 6,       // version:2.1
};
enum class FontStyleType : unsigned {
  kNormal = 0,   // version:1.0
  kItalic = 1,   // version:1.0
  kOblique = 2,  // version:1.0
};
enum class LinearOrientationType : unsigned {
  kHorizontal = 0,         // version:1.0
  kVertical = 1,           // version:1.0
  kHorizontalReverse = 2,  // version:1.0
  kVerticalReverse = 3,    // version:1.0
  kRow = 4,                // version:2.2
  kColumn = 5,             // version:2.2
  kRowReverse = 6,         // version:2.2
  kColumnReverse = 7,      // version:2.2
};
enum class LinearGravityType : unsigned {
  kNone = 0,              // version:1.0
  kTop = 1,               // version:1.0
  kBottom = 2,            // version:1.0
  kLeft = 3,              // version:1.0
  kRight = 4,             // version:1.0
  kCenterVertical = 5,    // version:1.0
  kCenterHorizontal = 6,  // version:1.0
  kSpaceBetween = 7,      // version:1.0
  kStart = 8,             // version:1.6
  kEnd = 9,               // version:1.6
  kCenter = 10,           // version:1.6
};
enum class LinearLayoutGravityType : unsigned {
  kNone = 0,              // version:1.0
  kTop = 1,               // version:1.0
  kBottom = 2,            // version:1.0
  kLeft = 3,              // version:1.0
  kRight = 4,             // version:1.0
  kCenterVertical = 5,    // version:1.0
  kCenterHorizontal = 6,  // version:1.0
  kFillVertical = 7,      // version:1.0
  kFillHorizontal = 8,    // version:1.0
  kCenter = 9,            // version:1.6
  kStretch = 10,          // version:1.6
  kStart = 11,            // version:1.6
  kEnd = 12,              // version:1.6
};
enum class VisibilityType : unsigned {
  kHidden = 0,    // version:1.0
  kVisible = 1,   // version:1.0
  kNone = 2,      // version:1.0
  kCollapse = 3,  // version:1.0
};
enum class WordBreakType : unsigned {
  kNormal = 0,    // version:1.0
  kBreakAll = 1,  // version:1.0
  kKeepAll = 2,   // version:1.0
};
enum class DirectionType : unsigned {
  kNormal = 0,   // version:1.0
  kLynxRtl = 1,  // version:1.0
  kRtl = 2,      // version:1.0
  kLtr = 3,      // version:2.0
};
enum class RelativeCenterType : unsigned {
  kNone = 0,        // version:1.0
  kVertical = 1,    // version:1.0
  kHorizontal = 2,  // version:1.0
  kBoth = 3,        // version:1.0
};
enum class LinearCrossGravityType : unsigned {
  kNone = 0,     // version:1.0
  kStart = 1,    // version:1.0
  kEnd = 2,      // version:1.0
  kCenter = 3,   // version:1.0
  kStretch = 4,  // version:1.6
};
// AUTO INSERT END, DON'T CHANGE IT!

// Reserved numbers for relative align type
class RelativeAlignType {
 public:
  static constexpr int kNone = -1;
  static constexpr int kParent = 0;

 private:
  RelativeAlignType() {}
};

enum class FilterType : uint32_t {
  kNone = 0,
  kGrayscale = 1,
  kBlur = 2,
};

enum class BasicShapeType : uint32_t {
  kUnknown = 0,
  kCircle = 1,
  kEllipse = 2,
  kPath = 3,
  kSuperEllipse = 4,
  kInset = 5,
};

enum class LinearGradientDirection : uint32_t {
  kNone = 0,
  kTop = 1,
  kBottom = 2,
  kLeft = 3,
  kRight = 4,
  kTopRight = 5,
  kTopLeft = 6,
  kBottomRight = 7,
  kBottomLeft = 8,
  kAngle = 9,
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_CSS_TYPE_H_
