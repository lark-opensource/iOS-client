//
//  TLNode.h
//  TangramLayoutKit
//
//  Created by qihongye on 2021/4/4.
//

#pragma once

#include <stdio.h>
#include <atomic>
#include "Macros.h"
#include "Types.h"
#include "internal.h"
#include "public.h"
#include "Log.h"
#include "Style.h"
#include "TLNodeOptions.h"

using namespace TangramLayoutKit;

using TLNodeVector = std::vector<TLNodeRef>;

struct TL_EXPORT TLNode {
    TL_ENUM_DEF(TLAxis, X, Y, Width, Height)
    using LayoutFn = TLLayoutFunc;
    using BaselineFn = TLBaselineFunc;

private:
    static constexpr size_t _isDirty = 0;
    static constexpr size_t _hasOptions = 1;
    static constexpr size_t _hasContext = 2;
    static constexpr size_t _hasParent = 3;
    static constexpr size_t _hasLayoutFn = 4;
    static constexpr size_t _hasBaselineFn = 5;
    static constexpr size_t _widthLayoutMode = 0;
    static constexpr size_t _heightLayoutMode = 1;

    bool _flags[6] = {true, true, false, false, false, false};
    TLLayoutMode _sizeMode[2] = {TLLayoutModeUndefined, TLLayoutModeUndefined};

    float _frame[4] = {0, 0, 0, 0};
    float _cachedAscent = 0;
    TLStyle _style = {};
    TLNodeOptionsRef _options = nullptr;
    AnyClass _context = nullptr;
    TLNodeRef _parent = nullptr;
    LayoutFn _layoutFn = nullptr;
    BaselineFn _baselineFn = nullptr;
    TLNodeVector _children = {};

    TLNode& operator=(TLNode&&) = default;

public:
    TLNode() : _options{TLGetDefaultOptions()} {
        if (_options) {
            _options->increaseGlobalNodeCounter();
        }
    };
    explicit TLNode(const TLNodeOptionsRef options) : _options{options} {
        if (_options) {
            _options->increaseGlobalNodeCounter();
            _flags[_hasOptions] = true;
        }
    };

    virtual ~TLNode();

    TLNode(const TLNode& node);

    TLNode(const TLNode& node, TLNodeOptionsRef options);

    TLNode& operator=(const TLNode&) = delete;

    bool isDirty() const { return _flags[_isDirty]; }
    void setDirty(bool dirty) { _flags[_isDirty] = dirty; }

    const TLLayoutMode widthMode() const { return _sizeMode[_widthLayoutMode]; };
    const TLLayoutMode heightMode() const { return _sizeMode[_heightLayoutMode]; };
    void widthMode(const TLLayoutMode mode) { _sizeMode[_widthLayoutMode] = mode; };
    void heightMode(const TLLayoutMode mode) { _sizeMode[_heightLayoutMode] = mode; };

    const TLRect getFrame() const;
    void setFrame(const TLRect frame);

    void setStyle(const TLStyle& style) { _style = style; }
    TLStyle& getStyle() { return _style; }
    const TLStyle& getStyle() const { return _style; }

    bool hasOptions() const { return _flags[_hasOptions]; }
    const TLNodeOptionsRef getOptions() const { return _options; }

    bool hasContext() const { return _flags[_hasContext]; }
    const AnyClass getContext() const { return _context; }
    void setContext(AnyClass context) {
        _context = context;
        _flags[_hasContext] = _context == nullptr;
    }
    void setContext(std::nullptr_t) {
        _context = nullptr;
        _flags[_hasContext] = false;
    }

    bool hasLayoutFn() const { return _flags[_hasLayoutFn]; }
    const LayoutFn getLayoutFn() const { return _layoutFn; }
    void setLayoutFn(LayoutFn layoutFn);
    void setLayoutFn(std::nullptr_t) {
        _layoutFn = nullptr;
        _flags[_hasLayoutFn] = false;
    }

    bool hasBaselineFn() const { return _flags[_hasBaselineFn]; }
    const BaselineFn getBaselineFn() const { return _baselineFn; }
    void setBaselineFn(BaselineFn baselineFn);
    void setBaselineFn(std::nullptr_t) {
        _baselineFn = nullptr;
        _flags[_hasBaselineFn] = false;
    }
    float& cachedAscent() { return _cachedAscent; }
    const float baseline(AnyClass context);

    bool hasParent() const { return _flags[_hasParent]; }
    const TLNodeRef getParent() const { return _parent; }
    void setParent(const TLNodeRef parent) {
        _parent = parent;
        _flags[_hasParent] = _parent == nullptr;
    }
    void setParent(std::nullptr_t) {
        _parent = nullptr;
        _flags[_hasParent] = false;
    }

    bool hasChildren() const { return !_children.empty(); }
    const TLNodeVector getChildren() const { return _children; }
    void setChildren(const TLNodeVector children) { _children = children; }
    const size_t getChildrenCount() const { return _children.size(); }
    void removeAllChildren();
    const bool removeChild(const TLNodeRef node);
    const TLNodeRef getChild(const size_t index) const;

    const bool isDisplayNone() const { return getStyle().display() == TLDisplayNone; }

    float& x();
    float& y();
    float& width();
    float& height();
    void setPosition(const TLOrigin);

    virtual TLSize caculateMeansure(const float, const float, LayoutContext&, AnyClass);
    virtual void caculateLayout(LayoutContext&, AnyClass);
};

template <class T>
typename std::enable_if<std::is_base_of<TLNode, T>::value>::type
static inline TLSetWidthAndMode(T* node, const float width, const TLLayoutMode widthMode) {
    node->width() = width;
    node->widthMode(widthMode);
}

template <class T>
typename std::enable_if<std::is_base_of<TLNode, T>::value>::type
static inline TLSetHeightAndMode(T* node, const float height, const TLLayoutMode heightMode) {
    node->height() = height;
    node->heightMode(heightMode);
}

static inline
void TLSetSizeMode(const TLNodeRef node, const TLLayoutMode widthMode, const TLLayoutMode heightMode) {
    node->widthMode(widthMode);
    node->heightMode(heightMode);
}

static inline
void TLDeepSetSizeMode(const TLNodeRef node, const TLLayoutMode widthMode, const TLLayoutMode heightMode) {
    TLSetSizeMode(node, widthMode, heightMode);
    const auto children = node->getChildren();
    for (const TLNodeRef child : children) {
        TLDeepSetSizeMode(child, widthMode, heightMode);
    }
}

static inline
const float TLResolvedValue(const TLValue value, const float ownerSize, TLLayoutMode& mode) {
    switch (value.unit) {
        case TLUnitAuto:
            mode = TLLayoutModeAuto;
            return ownerSize;
        case TLUnitUndefined:
            mode = TLLayoutModeUndefined;
            return ownerSize;
        case TLUnitPixcel:
            mode = TLLayoutModeExactly;
            return value.value;
        case TLUnitPercentage:
            if (isUndefined(ownerSize)) {
                mode = TLLayoutModeAuto;
                return ownerSize;
            }
            mode = TLLayoutModeExactly;
            return value.value * 0.01f * ownerSize;
    }
}

/// 优先级：min > max > computedSize(计算出的值) > style width/height
static inline
void TLFixActualSize(const TLNodeRef node,
                     const float containerWidth,
                     const float containerHeight,
                     float& actualContainerWidth,
                     TLLayoutMode& actualContainerWidthMode,
                     float& actualContainerHeight,
                     TLLayoutMode& actualContainerHeightMode) {
    TLLayoutMode edgesMode;
    float edgesValue;

    const float computedWidth = node->width();
    const TLLayoutMode computedWidthMode = node->widthMode();
    auto width = node->getStyle().width();
    auto maxWidth = node->getStyle().maxWidth();
    auto minWidth = node->getStyle().minWidth();
    actualContainerWidth = TLResolvedValue(width, containerWidth, actualContainerWidthMode);
    if (computedWidthMode == TLLayoutModeExactly) {
        actualContainerWidth = computedWidth;
        actualContainerWidthMode = TLLayoutModeExactly;
    }
    // 计算出的值也需要受min/max影响
    edgesValue = TLResolvedValue(maxWidth, containerWidth, edgesMode);
    if (edgesMode == TLLayoutModeExactly) {
        actualContainerWidth = fmin(actualContainerWidth, edgesValue);
    }
    edgesValue = TLResolvedValue(minWidth, containerWidth, edgesMode);
    if (edgesMode == TLLayoutModeExactly) {
        actualContainerWidth = fmax(actualContainerWidth, edgesValue);
    }

    const float computedHeight = node->height();
    const TLLayoutMode computedHeightMode = node->heightMode();
    auto height = node->getStyle().height();
    auto maxHeight = node->getStyle().maxHeight();
    auto minHeight = node->getStyle().minHeight();
    actualContainerHeight = TLResolvedValue(height, containerHeight, actualContainerHeightMode);
    if (computedHeightMode == TLLayoutModeExactly) {
        actualContainerHeight = computedHeight;
        actualContainerHeightMode = TLLayoutModeExactly;
    }
    // 计算出的值也需要受min/max影响
    edgesValue = TLResolvedValue(maxHeight, containerHeight, edgesMode);
    if (edgesMode == TLLayoutModeExactly) {
        actualContainerHeight = fmin(actualContainerHeight, edgesValue);
    }
    edgesValue = TLResolvedValue(minHeight, containerHeight, edgesMode);
    if (edgesMode == TLLayoutModeExactly) {
        actualContainerHeight = fmax(actualContainerHeight, edgesValue);
    }
}

static inline
void TLFixSizeByMaxAndMin(float& actualWidth,
                          float& actualHeight,
                          const TLNodeRef node,
                          const float containerWidth,
                          const float containerHeight) {
    TLLayoutMode edgesMode;
    float edgesValue;

    auto maxWidth = node->getStyle().maxWidth();
    auto minWidth = node->getStyle().minWidth();
    edgesValue = TLResolvedValue(maxWidth, containerWidth, edgesMode);
    if (edgesMode == TLLayoutModeExactly) {
        actualWidth = fmin(actualWidth, edgesValue);
    }
    edgesValue = TLResolvedValue(minWidth, containerWidth, edgesMode);
    if (edgesMode == TLLayoutModeExactly) {
        actualWidth = fmax(actualWidth, edgesValue);
    }

    auto maxHeight = node->getStyle().maxHeight();
    auto minHeight = node->getStyle().minHeight();
    // 计算出的值也需要受min/max影响
    edgesValue = TLResolvedValue(maxHeight, containerHeight, edgesMode);
    if (edgesMode == TLLayoutModeExactly) {
        actualHeight = fmin(actualHeight, edgesValue);
    }
    edgesValue = TLResolvedValue(minHeight, containerHeight, edgesMode);
    if (edgesMode == TLLayoutModeExactly) {
        actualHeight = fmax(actualHeight, edgesValue);
    }
}

static inline
void TLFixSizeWithoutUndefined(TLNodeRef node) {
    const float width = node->width();
    const float height = node->height();
    if (isUndefined(width) || node->widthMode() != TLLayoutModeExactly) {
        TLSetWidthAndMode(node, 0, TLLayoutModeExactly);
    }
    if (isUndefined(height) || node->heightMode() != TLLayoutModeExactly) {
        TLSetHeightAndMode(node, 0, TLLayoutModeExactly);
    }
}

static inline
const float TLGetPadding(const TLEdges& padding, const TLSide side) {
    switch (side) {
        case TLSideTop:
            return padding.top;
        case TLSideBottom:
            return padding.bottom;
        case TLSideLeft:
            return padding.left;
        case TLSideRight:
            return padding.right;
    }
}

static inline
void TLSetPadding(TLEdges& padding, const float value, const TLSide side) {
    switch (side) {
        case TLSideTop:
            padding.top = value;
            break;
        case TLSideBottom:
            padding.bottom = value;
            break;
        case TLSideLeft:
            padding.left = value;
            break;
        case TLSideRight:
            padding.right = value;
            break;
    }
}
