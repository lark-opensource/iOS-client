//
//  Style.h
//  TangramLayoutKit
//
//  Created by qihongye on 2021/4/7.
//

#pragma once

#include <stdio.h>
#include <stdlib.h>
#include "Macros.h"
#include "Types.h"

struct TL_EXPORT TLStyle {
private:
    static constexpr size_t _display = 0;
    static constexpr size_t _widthUnit = 1;
    static constexpr size_t _heightUnit = 2;
    static constexpr size_t _maxWidthUnit = 3;
    static constexpr size_t _maxHeightUnit = 4;
    static constexpr size_t _minWidthUnit = 5;
    static constexpr size_t _minHeightUnit = 6;
    static constexpr size_t _alignSelf = 7;

    uint8_t _flags[8] = {
        TLDisplayDisplay, TLUnitUndefined, TLUnitUndefined, TLUnitUndefined,
        TLUnitUndefined, TLUnitUndefined, TLUnitUndefined, TLAlignUndefined,
    };
    int _growWeight = 0;
    int _shrinkWeight = 0;
    float _width = 0;
    float _height = 0;
    float _maxWidth = 0;
    float _minWidth = 0;
    float _maxHeight = 0;
    float _minHeight = 0;
    float _aspectRatio = 0;

public:
    TLStyle() {};
    ~TLStyle() = default;

    int32_t& growWeight() { return _growWeight; }
    const int32_t growWeight() const { return _growWeight; }
    int32_t& shrinkWeight() { return _shrinkWeight; }
    const int32_t shrinkWeight() const { return _shrinkWeight; }
    float& aspectRatio() { return _aspectRatio; }
    const float aspectRatio() const { return _aspectRatio; }

    void display(const enum TLDisplay display) { _flags[_display] = display; }
    const TLDisplay display() const { return (TLDisplay)_flags[_display]; }
    void alignSelf(const enum TLAlign alignSelf) { _flags[_alignSelf] = alignSelf; }
    const TLAlign alignSelf() const { return (TLAlign)_flags[_alignSelf]; }

    TLVALUE_GETTER_SETTER_DEF(width)
    TLVALUE_GETTER_SETTER_DEF(height)
    TLVALUE_GETTER_SETTER_DEF(maxWidth)
    TLVALUE_GETTER_SETTER_DEF(maxHeight)
    TLVALUE_GETTER_SETTER_DEF(minWidth)
    TLVALUE_GETTER_SETTER_DEF(minHeight)

    const TLValue getMainAxisWidth(const TLOrientation) const;
    const TLValue getCrossAxisWidth(const TLOrientation) const;
    const TLValue getMainAxisMaxWidth(const TLOrientation) const;
    const TLValue getCrossAxisMaxWidth(const TLOrientation) const;
    const TLValue getMaixAxisMinWidth(const TLOrientation) const;
    const TLValue getCrossAxisMinWidth(const TLOrientation) const;
};
