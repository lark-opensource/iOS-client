//
//  types.h
//  EEFlexiable
//
//  Created by qihongye on 2018/11/25.
//

#import <yoga/YGEnums.h>
#import <yoga/Yoga.h>
#import <yoga/YGMacros.h>
#import <Foundation/Foundation.h>

#define CSS_ENUM(name) typedef NS_ENUM(int, name)

CSS_ENUM(CSSAlign) {
    CSSAlignAuto,
    CSSAlignFlexStart,
    CSSAlignCenter,
    CSSAlignFlexEnd,
    CSSAlignStretch,
    CSSAlignBaseline,
    CSSAlignSpaceBetween,
    CSSAlignSpaceAround,
};

CSS_ENUM(CSSDirection) {
    CSSDirectionInherit,
    CSSDirectionLTR,
    CSSDirectionRTL,
};

CSS_ENUM(CSSDisplay) {
    CSSDisplayFlex,
    CSSDisplayNone,
};

CSS_ENUM(CSSFlexDirection) {
    CSSFlexDirectionColumn,
    CSSFlexDirectionColumnReverse,
    CSSFlexDirectionRow,
    CSSFlexDirectionRowReverse,
};

CSS_ENUM(CSSJustify) {
    CSSJustifyFlexStart,
    CSSJustifyCenter,
    CSSJustifyFlexEnd,
    CSSJustifySpaceBetween,
    CSSJustifySpaceAround,
    CSSJustifySpaceEvenly
};

CSS_ENUM(CSSOverflow) {
    CSSOverflowVisible,
    CSSOverflowHidden,
    CSSOverflowScroll,
};

CSS_ENUM(CSSPosition) {
    CSSPositionRelative,
    CSSPositionAbsolute,
};

CSS_ENUM(CSSUnit) {
    CSSUnitUndefined,
    CSSUnitPoint,
    CSSUnitPercent,
    CSSUnitAuto,
};

CSS_ENUM(CSSWrap) {
    CSSWrapNoWrap,
    CSSWrapWrap,
    CSSWrapWrapReverse,
};

CSS_ENUM(CSSEdge) {
    CSSEdgeLeft,
    CSSEdgeTop,
    CSSEdgeRight,
    CSSEdgeBottom,
    CSSEdgeStart,
    CSSEdgeEnd,
    CSSEdgeHorizontal,
    CSSEdgeVertical,
    CSSEdgeAll,
};

typedef YGValue CSSValue;
typedef CGSize (^FlexMeasureFunc)(CGFloat width, CGFloat height);
typedef CGFloat (^FlexBaselineFunc)(CGFloat width, CGFloat height);

static const CSSValue CSSValueZero = {0, YGUnitPoint};
static const CSSValue CSSValueUndefined = {YGUndefined, YGUnitUndefined};
static const CSSValue CSSValueAuto = {YGUndefined, YGUnitAuto};
