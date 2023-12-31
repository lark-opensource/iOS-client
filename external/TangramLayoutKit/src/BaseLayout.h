//
//  BaseLayout.h
//  Pods
//
//  Created by Ping on 2023/7/26.
//

#pragma once

#include <stdio.h>
#include "Macros.h"
#include "TLNode.h"
#include "Types.h"
#include "public.h"
#include "Style.h"

struct TL_EXPORT BaseLayoutProps {
private:
    static constexpr size_t _direction = 0;
    static constexpr size_t _orientation = 1;
    static constexpr size_t _mainAxisJustify = 2;
    static constexpr size_t _crossAxisAlign = 3;
    uint8_t _flags[4] = {TLDirectionLTR, TLOrientationRow, TLJustifyStart, TLAlignTop};
    float _mainAxisSpacing = 0;
    float _crossAxisSpacing = 0;
    TLEdges _padding = {};

public:
    const TLDirection direction() const { return (TLDirection)_flags[_direction]; }
    void direction(const TLDirection direction) { _flags[_direction] = direction; }
    const TLOrientation orientation() const { return (TLOrientation)_flags[_orientation]; }
    void orientation(const TLOrientation orientation) { _flags[_orientation] = orientation; }
    const TLJustify mainAxisJustify() const { return (TLJustify)_flags[_mainAxisJustify]; }
    void mainAxisJustify(const TLJustify justify) { _flags[_mainAxisJustify] = justify; }
    const TLAlign crossAxisAlign() const { return (TLAlign)_flags[_crossAxisAlign]; }
    void crossAxisAlign(const TLAlign align) { _flags[_crossAxisAlign] = align; }
    const bool hasMainAxisSpacing() const { return _mainAxisSpacing > 0 && !isUndefined(_mainAxisSpacing); }
    float mainAxisSpacing() const { return _mainAxisSpacing; }
    float& mainAxisSpacing() { return _mainAxisSpacing; }
    const bool hasCrossAxisSpacing() const { return _crossAxisSpacing > 0 && !isUndefined(_crossAxisSpacing); }
    float crossAxisSpacing() const { return _crossAxisSpacing; }
    float& crossAxisSpacing() { return _crossAxisSpacing; }

    const float padding(const TLSide side) const {
        float value = TLGetPadding(_padding, side);
        return isUndefined(value) ? 0 : value;
    }
    const TLEdges padding() const { return _padding; }
    void padding(const float padding, const TLSide side) { TLSetPadding(_padding, padding, side); }
    void padding(const TLEdges padding) { _padding = padding; }

    const bool isBaselineLayout() const;
};

/// MARK: - Function define
void TLCaculateMeansureWithNoWrap(const TLStyleRef style,
                                  const BaseLayoutPropsRef props,
                                  TLNodeVector children,
                                  const float actualContainerMainAxisWidth,
                                  const TLLayoutMode actualContainerMainAxisMode,
                                  const float actualContainerCrossAxisWidth,
                                  const TLLayoutMode actualContainerCrossAxisMode,
                                  float& actualChildrenMainAxisWidth,
                                  float& actualChildrenCrossAxisWidth,
                                  float& ascent,
                                  size_t& displayChildrenCount,
                                  LayoutContext& layoutContext,
                                  AnyClass context);

TLSize TLCaculateMeansureWithGrowOrShrink(const TLStyleRef style,
                                          const BaseLayoutPropsRef props,
                                          const TLNodeVector children,
                                          const float growPriority,
                                          const float shrinkPriority,
                                          const float childrenMainAxisWidth,
                                          const float childrenCrossAxisWidth,
                                          const float containerMainAxisWidth,
                                          const TLLayoutMode containerMainAxisMode,
                                          const float containerCrossAxisWidth,
                                          const TLLayoutMode containerCrossAxisMode,
                                          LayoutContext& layoutContext,
                                          void* context);

void TLBaseLayoutCaculateMainAxisOffset(const BaseLayoutPropsRef props,
                                        TLNodeVector children,
                                        const float actualChildrenMainAxisWidth,
                                        const float actualContainerMainAxisWidth,
                                        const size_t displayChildrenCount);

void TLCaculateMainAxisOffset(const BaseLayoutPropsRef props,
                              TLNodeVector children,
                              const float mainAxisValue,
                              const float actualMainAxisValue,
                              const size_t displayedChildrenCount);

static inline
const float TLCaculateNoWrapCrossAxisOffset(const float childSize,
                                            const TLAlign align,
                                            const float containerSize,
                                            LayoutContext&,
                                            AnyClass context);

static inline
const float TLBaseLayoutPropsGetMainAxisPadding(const BaseLayoutPropsRef props);
static inline
const float TLBaseLayoutPropsGetMainAxisPaddingStart(const BaseLayoutPropsRef props);
static inline
const float TLBaseLayoutPropsGetMainAxisPaddingEnd(const BaseLayoutPropsRef props);
static inline
const float TLBaseLayoutPropsGetCrossAxisPadding(const BaseLayoutPropsRef props);
static inline
const float TLBaseLayoutPropsGetCrossAxisPaddingStart(const BaseLayoutPropsRef props);
static inline
const float TLBaseLayoutPropsGetCrossAxisPaddingEnd(const BaseLayoutPropsRef props);
static inline
const TLSize TLCaculateMeansureWithOrientation(const TLNodeRef node,
                                               const TLOrientation orientation,
                                               const float containerMainAxisWidth,
                                               const float containerCrossAxisWidth,
                                               LayoutContext& layoutContext,
                                               AnyClass context);
static inline
const std::tuple<float, float> TLResolvedAxisWidth(const TLOrientation orientation, const TLSize size);
static inline
void TLFixChildrenSizeModeByPriority(const TLNodeVector children);
static inline
void TLFixSizeByPriority(const TLNodeRef node,
                         const TLOrientation orientation,
                         const float priority,
                         const float diffSize,
                         const float containerMainAxisWidth,
                         const TLLayoutMode containerMainAxisMode,
                         const float containerCrossAxisWidth,
                         const TLLayoutMode containerCrossAxisMode,
                         LayoutContext& layoutContext,
                         void* context);
static inline
void TLSetPosition(const TLNodeRef node, const TLOrientation, const float, const float);
static inline
const float TLGetMainAxisWidth(const TLNodeRef node, const TLOrientation);
static inline
const float TLGetCrossAxisWidth(const TLNodeRef node, const TLOrientation);
static inline
const TLLayoutMode TLGetMainAxisMode(const TLNodeRef node, const TLOrientation orientation);
static inline
const TLLayoutMode TLGetCrossAxisMode(const TLNodeRef node, const TLOrientation orientation);
static inline
void TLSetMainAxisMode(const TLNodeRef node, const TLOrientation orientation, const TLLayoutMode mode);
static inline
void TLSetCrossAxisMode(const TLNodeRef node, const TLOrientation orientation, const TLLayoutMode mode);
static inline
void TLSetMainAxisWidthAndMode(const TLNodeRef node, const TLOrientation, const float, const TLLayoutMode);
static inline
void TLSetCrossAxisWidthAndMode(const TLNodeRef node, const TLOrientation, const float, const TLLayoutMode);
static inline
const TLSize TLGetSizeByOrientation(const TLOrientation ori, const float main, const float cross);
static inline
void TLNodeSetMainAxisOffset(const TLNodeRef node, const TLOrientation orientation, const float offset);
static inline
void TLNodeSetCrossAxisOffset(const TLNodeRef node, const TLOrientation orientation, const float offset);
static inline
const bool TLNodeCanStretch(const TLNodeRef node,
                            const TLLayoutMode containerMainAxisMode,
                            const TLLayoutMode containerCrossAxisMode,
                            const TLOrientation orientation);
static inline
const float TLGetStretchSize(const TLNodeRef node,
                             const TLOrientation orientation,
                             const float aspectRatio,
                             const float childrenMainAxisWidth,
                             const float childrenCrossAxisWidth,
                             const float containerMainAxisWidth,
                             const TLLayoutMode containerMainAxisMode,
                             const float containerCrossAxisWidth,
                             const TLLayoutMode containerCrossAxisMode);
static inline
void TLFixSizeModeByStretch(const TLNodeRef child,
                            const bool childCanStretch,
                            const TLOrientation orientation,
                            const TLLayoutMode containerMainAxisMode);
/// MARK: Function define end

static inline
const float TLBaseLayoutPropsGetMainAxisPadding(const BaseLayoutPropsRef props) {
    return TLBaseLayoutPropsGetMainAxisPaddingStart(props) + TLBaseLayoutPropsGetMainAxisPaddingEnd(props);
}

static inline
const float TLBaseLayoutPropsGetMainAxisPaddingStart(const BaseLayoutPropsRef props) {
    const TLOrientation orientation = props->orientation();
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            return props->padding(TLSideLeft);
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            return props->padding(TLSideTop);
    }
}

static inline
const float TLBaseLayoutPropsGetMainAxisPaddingEnd(const BaseLayoutPropsRef props) {
    const TLOrientation orientation = props->orientation();
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            return props->padding(TLSideRight);
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            return props->padding(TLSideBottom);
    }
}

static inline
const float TLBaseLayoutPropsGetCrossAxisPadding(const BaseLayoutPropsRef props) {
    return TLBaseLayoutPropsGetCrossAxisPaddingStart(props) + TLBaseLayoutPropsGetCrossAxisPaddingEnd(props);
}

static inline
const float TLBaseLayoutPropsGetCrossAxisPaddingStart(const BaseLayoutPropsRef props) {
    const TLOrientation orientation = props->orientation();
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            return props->padding(TLSideTop);
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            return props->padding(TLSideLeft);
    }
}

static inline
const float TLBaseLayoutPropsGetCrossAxisPaddingEnd(const BaseLayoutPropsRef props) {
    const TLOrientation orientation = props->orientation();
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            return props->padding(TLSideBottom);
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            return props->padding(TLSideRight);
    }
}

static inline
const TLSize TLCaculateMeansureWithOrientation(const TLNodeRef node,
                                               const TLOrientation orientation,
                                               const float containerMainAxisWidth,
                                               const float containerCrossAxisWidth,
                                               LayoutContext& layoutContext,
                                               AnyClass context) {
    auto style = node->getStyle();
    if (style.display() == TLDisplayNone) {
        return {0, 0};
    }

    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            return node->caculateMeansure(containerMainAxisWidth, containerCrossAxisWidth, layoutContext, context);
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            return node->caculateMeansure(containerCrossAxisWidth, containerMainAxisWidth, layoutContext, context);
    }
}

static inline
const std::tuple<float, float> TLResolvedAxisWidth(const TLOrientation orientation, const TLSize size) {
    size_t sizeMap[4] = {0, 1, 0, 1};
    float values[2] = {size.width, size.height};
    return std::make_tuple(values[sizeMap[orientation]], values[1 - sizeMap[orientation]]);
}

// set child size mode to undefined if child has grow/shrink
static inline
void TLFixChildrenSizeModeByPriority(const TLNodeVector children) {
    for (const TLNodeRef child : children) {
        if (child->getStyle().growWeight() > 0 || child->getStyle().shrinkWeight() > 0) {
            // Layout嵌套的情况下，child的child也需要置为undefined
            TLDeepSetSizeMode(child, TLLayoutModeUndefined, TLLayoutModeUndefined);
        }
    }
}

/// TLFixSizeByPriority
/// @param node LayoutNode
/// @param priority total priority
/// @param diffSize containerMainAxisWidth - actualMainAxisWidth
/// @param containerCrossAxisWidth container
/// @param context global context
static inline
void TLFixSizeByPriority(const TLNodeRef node,
                         const TLOrientation orientation,
                         const float priority,
                         const float diffSize,
                         const float containerMainAxisWidth,
                         const TLLayoutMode containerMainAxisMode,
                         const float containerCrossAxisWidth,
                         const TLLayoutMode containerCrossAxisMode,
                         LayoutContext& layoutContext,
                         void* context) {
    if (diffSize == 0)
        return;

    float mainAxisWidth = TLGetMainAxisWidth(node, orientation);
    if (diffSize > 0 && node->getStyle().growWeight() > 0) {
        mainAxisWidth += (node->getStyle().growWeight() / priority) * diffSize;
    } else if (diffSize < 0 && node->getStyle().shrinkWeight() > 0) {
        mainAxisWidth += (node->getStyle().shrinkWeight() / priority) * diffSize;
    } else {
        return;
    }
    TLSetMainAxisWidthAndMode(node, orientation, mainAxisWidth, TLLayoutModeExactly);

    auto size = TLGetSizeByOrientation(orientation, mainAxisWidth, containerCrossAxisWidth);
    // @FIXME: 这里会导致回溯，效率还需要再优化，不应该使用递归 @qhy
    layoutContext.reason() = LINEAR_FIX_GROW_SHRINK;
    node->caculateMeansure(size.width, size.height, layoutContext, context);
}

static inline
void TLSetPosition(const TLNodeRef node,
                   const TLOrientation orientation,
                   const float mainAxisX,
                   const float crossAxisX) {
    const float axis[2] = {mainAxisX, crossAxisX};
    node->setPosition({axis[orientation / 2], axis[1 - orientation / 2]});
}

static inline
const float TLGetMainAxisWidth(const TLNodeRef node, const TLOrientation orientation) {
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            return node->width();
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            return node->height();
    }
}

static inline
const float TLGetCrossAxisWidth(const TLNodeRef node, const TLOrientation orientation) {
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            return node->height();
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            return node->width();
    }
}

static inline
const TLLayoutMode TLGetMainAxisMode(const TLNodeRef node, const TLOrientation orientation) {
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            return node->widthMode();
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            return node->heightMode();
    }
}

static inline
const TLLayoutMode TLGetCrossAxisMode(const TLNodeRef node, const TLOrientation orientation) {
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            return node->heightMode();
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            return node->widthMode();
    }
}

static inline
void TLSetMainAxisMode(const TLNodeRef node, const TLOrientation orientation, const TLLayoutMode mode) {
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            node->widthMode(mode);
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            node->heightMode(mode);
    }
}

static inline
void TLSetCrossAxisMode(const TLNodeRef node, const TLOrientation orientation, const TLLayoutMode mode) {
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            node->heightMode(mode);
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            node->widthMode(mode);
    }
}

static inline
void TLSetMainAxisWidthAndMode(const TLNodeRef node, const TLOrientation orientation, const float value, const TLLayoutMode mode) {
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            TLSetWidthAndMode(node, value, mode);
            break;
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            TLSetHeightAndMode(node, value, mode);
            break;
    }
}

static inline
void TLSetCrossAxisWidthAndMode(const TLNodeRef node, const TLOrientation orientation, const float value, const TLLayoutMode mode) {
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            TLSetHeightAndMode(node, value, mode);
            break;
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            TLSetWidthAndMode(node, value, mode);
            break;
    }
}

static inline
const TLSize TLGetSizeByOrientation(const TLOrientation ori, const float main, const float cross) {
    switch (ori) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            return {main, cross};
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            return {cross, main};
    }
}

static inline
void TLNodeSetMainAxisOffset(const TLNodeRef node, const TLOrientation orientation, const float offset) {
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            node->x() = offset;
            break;
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            node->y() = offset;
            break;
    }
}

static inline
void TLNodeSetCrossAxisOffset(const TLNodeRef node, const TLOrientation orientation, const float offset) {
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            node->y() = offset;
            break;
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            node->x() = offset;
            break;
    }
}

static inline
const float TLCaculateNoWrapCrossAxisOffset(const float childSize,
                                            const TLAlign align,
                                            const float containerSize,
                                            LayoutContext& layoutContext,
                                            AnyClass context) {
    switch (align) {
        case TLAlignUndefined:
            return 0;
        case TLAlignTop:
            return 0;
        case TLAlignBaseline:
            assertWithLogicMessage("You can not step this with `TLAlignBaseline`.");
            return 0;
        case TLAlignMiddle:
            return (containerSize - childSize) / 2;
        case TLAlignBottom:
            return containerSize - childSize;
        case TLAlignStretch:
            return 0;
    }
}

static inline
const bool TLNodeCanStretch(const TLNodeRef node,
                            const TLLayoutMode containerMainAxisMode,
                            const TLLayoutMode containerCrossAxisMode,
                            const TLOrientation orientation) {
    TLValue crossAxisWidth;
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            crossAxisWidth = node->getStyle().height();
            break;
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            crossAxisWidth = node->getStyle().width();
            break;
    }
    // 子元素辅轴确定：除此外，需要被stretch
    // - 子元素辅轴固定值
    // - 子元素辅轴百分比且父容器辅轴确定
    // - 子元素有LayoutFn且父容器主轴 & 辅轴确定
    return !(crossAxisWidth.unit == TLUnitPixcel ||
             (crossAxisWidth.unit == TLUnitPercentage && containerCrossAxisMode == TLLayoutModeExactly) ||
             (node->hasLayoutFn() && containerMainAxisMode == TLLayoutModeExactly && containerCrossAxisMode == TLLayoutModeExactly));
}

static inline
const float TLGetStretchSize(const TLNodeRef node,
                             const TLOrientation orientation,
                             const float aspectRatio,
                             const float childrenMainAxisWidth,
                             const float childrenCrossAxisWidth,
                             const float containerMainAxisWidth,
                             const TLLayoutMode containerMainAxisMode,
                             const float containerCrossAxisWidth,
                             const TLLayoutMode containerCrossAxisMode) {
    // 辅轴确定，直接用辅轴
    if (containerCrossAxisMode == TLLayoutModeExactly) {
        return containerCrossAxisWidth;
    }
    TLLayoutMode edgesMode;
    float edgesValue;
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse: {
            // 辅轴不确定，表示内容撑开，内容撑开大小需要在容器大小内
            float actualContainerCrossAxisWidth = fmin(childrenCrossAxisWidth, containerCrossAxisWidth);
            // 主轴确定，根据aspectRatio算辅轴；否则根据children撑开的主轴算辅轴
            if (containerMainAxisMode == TLLayoutModeExactly && aspectRatio > 0) {
                actualContainerCrossAxisWidth = fmin(containerCrossAxisWidth, containerMainAxisWidth / aspectRatio);
            } else if (aspectRatio > 0) {
                actualContainerCrossAxisWidth = fmin(containerCrossAxisWidth, childrenMainAxisWidth / aspectRatio);
            }
            auto minHeight = node->getStyle().minHeight();
            edgesValue = TLResolvedValue(minHeight, actualContainerCrossAxisWidth, edgesMode);
            if (edgesMode == TLLayoutModeExactly && edgesValue > childrenCrossAxisWidth) {
                return edgesValue;
            }
            auto maxHeight = node->getStyle().maxHeight();
            edgesValue = TLResolvedValue(maxHeight, actualContainerCrossAxisWidth, edgesMode);
            if (edgesMode == TLLayoutModeExactly && edgesValue < childrenCrossAxisWidth) {
                return edgesValue;
            }
            return actualContainerCrossAxisWidth;
        }
        case TLOrientationColumn:
        case TLOrientationColumnReverse: {
            // 辅轴不确定，表示内容撑开，内容撑开大小需要在容器大小内
            float actualContainerCrossAxisWidth = fmin(childrenCrossAxisWidth, containerCrossAxisWidth);
            // 主轴确定，根据aspectRatio算辅轴；否则根据children撑开大小算辅轴
            if (containerMainAxisMode == TLLayoutModeExactly && aspectRatio > 0) {
                actualContainerCrossAxisWidth = fmin(containerCrossAxisWidth, containerMainAxisWidth * aspectRatio);
            } else if (aspectRatio > 0) {
                actualContainerCrossAxisWidth = fmin(containerCrossAxisWidth, childrenMainAxisWidth * aspectRatio);
            }
            auto minWidth = node->getStyle().minWidth();
            edgesValue = TLResolvedValue(minWidth, actualContainerCrossAxisWidth, edgesMode);
            if (edgesMode == TLLayoutModeExactly && edgesValue > childrenCrossAxisWidth) {
                return edgesValue;
            }
            auto maxWidth = node->getStyle().maxWidth();
            edgesValue = TLResolvedValue(maxWidth, actualContainerCrossAxisWidth, edgesMode);
            if (edgesMode == TLLayoutModeExactly && edgesValue < childrenCrossAxisWidth) {
                return edgesValue;
            }
            return actualContainerCrossAxisWidth;
        }
    }
}

// set child size mode to undefined if node is stretch
static inline
void TLFixSizeModeByStretch(const TLNodeRef child,
                            const bool childCanStretch,
                            const TLOrientation orientation,
                            const TLLayoutMode containerMainAxisMode) {
    const TLLayoutMode childMainAxisMode = TLGetMainAxisMode(child, orientation);
    if (childCanStretch) {
        // Layout嵌套的情况下，child的child也需要置为undefined
        TLDeepSetSizeMode(child, TLLayoutModeUndefined, TLLayoutModeUndefined);
    }
    if (containerMainAxisMode == TLLayoutModeExactly) {
        TLSetMainAxisMode(child, orientation, childMainAxisMode);
    }
}
