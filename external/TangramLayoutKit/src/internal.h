//
//  internal.h
//  TangramLayoutKit
//
//  Created by qihongye on 2021/4/6.
//

#pragma once

#include <optional>
#include <vector>
#include <math.h>
#include "Types.h"

#define LAYOUT_MANUAL                               0
#define LINEAR_FIX_ASPECTRATIO                      1001
#define LINEAR_FIX_GROW_SHRINK                      1002

namespace TangramLayoutKit {

using AnyClass = void*;

struct LayoutContext {
private:
    bool _isNeedMeasure;
    bool _isNeedLayout;
    int _reason;

public:
    LayoutContext() : _isNeedMeasure{false}, _isNeedLayout{false}, _reason{0} {};
    void setNeedLayout() { _isNeedLayout = true; }
    const bool needLayout() const { return _isNeedLayout; }

    void setNeedMeasure() { _isNeedMeasure = true; }
    const bool needMeasure() const { return _isNeedMeasure; }

    int& reason() { return _reason; }
    const char* debugReason() const {
        switch (_reason) {
            case LAYOUT_MANUAL:
                return "Layout with manual.";
            case LINEAR_FIX_ASPECTRATIO:
                return "LinearLayout fix aspectRatio.";
            default: break;
        }
        return "";
    }
};

inline
const bool isUndefined(const float value) {
    return isnan(value);
}

inline
const bool isFloatEqual(const float a, const float b) {
    if (!isUndefined(a) && !isUndefined(b)) {
        return fabs(a - b) < 0.0001f;
    }
    return isUndefined(a) && isUndefined(b);
}

inline
void FixSizeWithoutUndefined(float& width, float& height) {
    if (isUndefined(width)) {
        width = 0;
    }
    if (isUndefined(height)) {
        height = 0;
    }
}

} // namespace TangramLayoutKit

