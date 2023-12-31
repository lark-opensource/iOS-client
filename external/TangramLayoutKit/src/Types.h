//
//  Types.h
//  TangramLayoutKit
//
//  Created by qihongye on 2021/4/5.
//

#pragma once

#include "Macros.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

TL_EXTERN_C_BEGIN

#ifndef NAN
static const uint32_t __nan = ;
#define NAN (*(const float*) 0x7fc00000)
#endif

#define TLUndefined NAN
#define TLAuto NAN

typedef struct TLOrigin {
    float x;
    float y;
} TLOrigin;

typedef struct TLSize {
    float width;
    float height;
} TLSize;

typedef struct TLRect {
    TLOrigin origin;
    TLSize size;
} TLRect;

typedef struct TLEdges {
    float top;
    float right;
    float bottom;
    float left;
} TLEdges;

TL_ENUM_DEF(TLUnit, Undefined, Auto, Pixcel, Percentage)

typedef struct TLValue {
    float value;
    enum TLUnit unit;
} TLValue;

const TLValue TLValueZero = {0, TLUnitPixcel};
const TLValue TLValueUndefined = {TLUndefined, TLUnitUndefined};
const TLValue TLValueAuto = {TLUndefined, TLUnitAuto};

TL_ENUM_DEF(TLDisplay, Display, None)
TL_ENUM_DEF(TLDirection, LTR, RTL)
TL_ENUM_DEF(TLOrientation, Row, Column, RowReverse, ColumnReverse)
TL_ENUM_DEF(TLAlign, Undefined, Top, Middle, Bottom, Stretch, Baseline)
TL_ENUM_DEF(TLJustify, Start, Center, End, SpaceBetween, SpaceArround, SpaceEvenly)
TL_ENUM_DEF(TLLayoutMode, Auto, Undefined, Exactly)
TL_ENUM_DEF(TLSide, Top, Right, Bottom, Left)
TL_ENUM_DEF(TLFlexWrap, NoWrap, Wrap, WrapReverse, LinearWrap)

typedef struct TLNode* TLNodeRef;
typedef const struct TLNode* TLNodeConstRef;

typedef struct LinearLayoutNode* LinearLayoutNodeRef;

typedef struct FlexLayoutNode* FlexLayoutNodeRef;

typedef struct TLStyle* TLStyleRef;

typedef struct TLNodeOptions* TLNodeOptionsRef;

typedef struct LinearLayoutProps* LinearLayoutPropsRef;

typedef struct FlexLayoutProps* FlexLayoutPropsRef;

typedef struct BaseLayoutProps* BaseLayoutPropsRef;

typedef struct TLSize* TLSizeRef;

typedef int (*TLLogger)(TLNodeConstRef node,
                        const char* format,
                        va_list args
                        );

typedef TLSize (*TLLayoutFunc)(TLNodeConstRef, float, enum TLLayoutMode, float, enum TLLayoutMode, void*);
typedef float (*TLBaselineFunc)(TLNodeConstRef, float, float, void*);

TL_EXTERN_C_END
