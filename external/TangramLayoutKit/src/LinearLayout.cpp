//
//  LinearLayout.cpp
//  TangramLayoutKit
//
//  Created by qihongye on 2021/4/5.
//

#include "LinearLayout.h"
#include "Macros.h"
#include "TLNode.h"
#include "public.h"
#include "internal.h"
#include "BaseLayout.h"
#include "Types.h"

using namespace TangramLayoutKit;
using namespace TangramLayoutKit::Log;

/// Function defined.
static inline
void TLNodeSetMainAxisOffset(const TLNodeRef, const TLOrientation, const float);
static inline
void TLNodeSetCrossAxisOffset(const TLNodeRef, const TLOrientation, const float);
TLSize LinearCaculateMeansureImpl(LinearLayoutNodeRef node,
                                  const float containerWidth,
                                  const float containerHeight,
                                  LayoutContext& layoutContext,
                                  AnyClass context);
TLSize LinearCaculateMeansureByWrapWidth(LinearLayoutNodeRef node,
                                         const float containerMainAxisWidth,
                                         const TLLayoutMode containerMainAxisMode,
                                         const float containerCrossAxisWidth,
                                         const TLLayoutMode containerCrossAxisMode,
                                         LayoutContext& layoutContext,
                                         AnyClass context);
/// Function define end

/// LinearLayoutNode
const bool LinearLayoutNode::isMatchWrapWidth(const float width) const {
    if (!_props.hasWrapWidth()) {
        return false;
    }
    switch (_props.orientation()) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            return _props.wrapWidth() >= width;
        default:
            return false;
    }
}

const bool LinearLayoutNode::needReverseChildren() const {
    const bool isReverse = _props.orientation() > 1;
    const bool isR2L = _props.direction() == TLDirectionRTL;
    return isReverse != isR2L;
}

TLSize LinearLayoutNode::caculateMeansure(const float containerWidth,
                                          const float containerHeight,
                                          LayoutContext& layoutContext,
                                          AnyClass context) {
    if (isDisplayNone()) {
        return {0, 0};
    }
    if (!isDirty()) {
        return {width(), height()};
    }

    auto containerSize = LinearCaculateMeansureImpl(this,
                                                    containerWidth,
                                                    containerHeight,
                                                    layoutContext,
                                                    context);
    return containerSize;
}

void LinearLayoutNode::caculateLayout(LayoutContext& layoutContext,
                                      AnyClass context) {
        // Caculate cross axis offset for each child.
    if (isMatchWrapWidth(TLGetMainAxisWidth(this, props().orientation()))) {
        for (const TLNodeRef child: getChildren()) {
            if (child->isDisplayNone()) {
                continue;
            }
            child->caculateLayout(layoutContext, context);
        }
        return;
    }
    TangramLayoutKit::Log::Log(this,
                               LogLevelInfo,
                               "LinearLayoutNode::caculateLayout(reason: %s)",
                               layoutContext.debugReason());
    const float crossAxisPaddingStart = TLBaseLayoutPropsGetCrossAxisPaddingStart(&this->props());
    if (props().isBaselineLayout()) {
        for (const TLNodeRef child: getChildren()) {
            if (child->isDisplayNone()) {
                continue;
            }
            child->y() = cachedAscent() - child->cachedAscent() + crossAxisPaddingStart;
            child->caculateLayout(layoutContext, context);
        }
    } else {
        const auto orientation = props().orientation();
        const float actualCrossWidth = TLGetCrossAxisWidth(this, orientation) - TLBaseLayoutPropsGetCrossAxisPadding(&this->props());
        const auto crossAlign = props().crossAxisAlign();
        for (const TLNodeRef child : getChildren()) {
            if (child->isDisplayNone()) {
                continue;
            }
            const float offset = TLCaculateNoWrapCrossAxisOffset(TLGetCrossAxisWidth(child, orientation),
                                                                 crossAlign,
                                                                 actualCrossWidth,
                                                                 layoutContext,
                                                                 context);
            TLNodeSetCrossAxisOffset(child, orientation, offset + crossAxisPaddingStart);
            child->caculateLayout(layoutContext, context);
        }
    }
}

TLSize LinearCaculateMeansureImpl(LinearLayoutNodeRef node,
                                  const float containerWidth,
                                  const float containerHeight,
                                  LayoutContext& layoutContext,
                                  AnyClass context) {
    LinearLayoutProps props = node->props();
    const float mainAxisPadding = TLBaseLayoutPropsGetMainAxisPadding(&node->props());
    const float crossAxisPadding = TLBaseLayoutPropsGetCrossAxisPadding(&node->props());
    const float spacing = props.hasSpacing() ? props.spacing() : 0;
    const TLOrientation orientation = props.orientation();
    TLNodeVector children = node->getChildren();

    float actualContainerMainAxisWidth, actualContainerCrossAxisWidth;
    TLLayoutMode actualContainerMainAxisMode, actualContainerCrossAxisMode;

    TLFixActualSize(node,
                    containerWidth,
                    containerHeight,
                    actualContainerMainAxisWidth,
                    actualContainerMainAxisMode,
                    actualContainerCrossAxisWidth,
                    actualContainerCrossAxisMode);

    if (node->isMatchWrapWidth(actualContainerMainAxisWidth)) {
        return LinearCaculateMeansureByWrapWidth(node,
                                                 actualContainerMainAxisWidth,
                                                 actualContainerMainAxisMode,
                                                 actualContainerCrossAxisWidth,
                                                 actualContainerCrossAxisMode,
                                                 layoutContext,
                                                 context);
    }

    // 其他情况，主轴、纵轴独立计算
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            break;
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            std::swap(actualContainerMainAxisWidth, actualContainerCrossAxisWidth);
            std::swap(actualContainerMainAxisMode, actualContainerCrossAxisMode);
            break;
    }

    actualContainerMainAxisWidth -= mainAxisPadding;
    actualContainerCrossAxisWidth -= crossAxisPadding;
    float actualChildrenMainAxisWidth = 0;
    float actualChildrenCrossAxisWidth = 0;
    float ascent = 0;
    size_t displayChildrenCount = 0;

    TLCaculateMeansureWithNoWrap(&node->getStyle(),
                                 &props,
                                 children,
                                 actualContainerMainAxisWidth,
                                 actualContainerMainAxisMode,
                                 actualContainerCrossAxisWidth,
                                 actualContainerCrossAxisMode,
                                 actualChildrenMainAxisWidth,
                                 actualChildrenCrossAxisWidth,
                                 ascent,
                                 displayChildrenCount,
                                 layoutContext,
                                 context);

    // fix size with stretch
    if (props.crossAxisAlign() == TLAlignStretch) {
        const float stretchSize = TLGetStretchSize(node,
                                                   orientation,
                                                   node->getStyle().aspectRatio(),
                                                   actualChildrenMainAxisWidth,
                                                   actualChildrenCrossAxisWidth,
                                                   actualContainerMainAxisWidth,
                                                   actualContainerMainAxisMode,
                                                   actualContainerCrossAxisWidth,
                                                   actualContainerCrossAxisMode);
        actualChildrenMainAxisWidth = 0;
        actualChildrenCrossAxisWidth = 0;
        ascent = 0;

        for (const TLNodeRef child : children) {
            if (child->isDisplayNone()) {
                continue;
            }
            const bool childCanStretch = TLNodeCanStretch(child, actualContainerMainAxisMode, actualContainerCrossAxisMode, orientation);
            TLFixSizeModeByStretch(child, childCanStretch, orientation, actualContainerMainAxisMode);
            if (!isFloatEqual(TLGetCrossAxisWidth(child, orientation), stretchSize) && childCanStretch) {
                TLSetCrossAxisWidthAndMode(child, orientation, stretchSize, TLLayoutModeExactly);
                child->caculateMeansure(child->width(), child->height(), layoutContext, context);
            }
            actualChildrenMainAxisWidth += TLGetMainAxisWidth(child, orientation) + spacing;
            actualChildrenCrossAxisWidth = std::max(actualChildrenCrossAxisWidth, TLGetCrossAxisWidth(child, orientation));
            if (props.isBaselineLayout()) {
                ascent = std::max(ascent, child->baseline(context));
            }
        }
        if (displayChildrenCount > 0) {
            actualChildrenMainAxisWidth -= spacing;
        }
    }

    actualChildrenMainAxisWidth += mainAxisPadding;
    actualChildrenCrossAxisWidth += crossAxisPadding;
    actualContainerMainAxisWidth += mainAxisPadding;
    actualContainerCrossAxisWidth += crossAxisPadding;
    if (actualContainerMainAxisMode != TLLayoutModeExactly) {
        actualContainerMainAxisWidth = fmin(actualChildrenMainAxisWidth, actualContainerMainAxisWidth);
        actualContainerMainAxisMode = TLLayoutModeExactly;
    }
    if (actualContainerCrossAxisMode != TLLayoutModeExactly) {
        actualContainerCrossAxisWidth = fmin(actualChildrenCrossAxisWidth, actualContainerCrossAxisWidth);
        actualContainerCrossAxisMode = TLLayoutModeExactly;
    }

    node->cachedAscent() = ascent;

    TLBaseLayoutCaculateMainAxisOffset(&props,
                                       children,
                                       actualChildrenMainAxisWidth,
                                       actualContainerMainAxisWidth,
                                       displayChildrenCount);

    TLSetMainAxisWidthAndMode(node, orientation, actualContainerMainAxisWidth, actualContainerMainAxisMode);
    TLSetCrossAxisWidthAndMode(node, orientation, actualContainerCrossAxisWidth, actualContainerCrossAxisMode);
    TLFixSizeWithoutUndefined(node);
    return TLNodeGetFrame(node).size;
}

TLSize LinearCaculateMeansureByWrapWidth(LinearLayoutNodeRef node,
                                         const float containerMainAxisWidth,
                                         const TLLayoutMode containerMainAxisMode,
                                         const float containerCrossAxisWidth,
                                         const TLLayoutMode containerCrossAxisMode,
                                         LayoutContext& layoutContext,
                                         AnyClass context) {
#if DEBUG
    if (!node->isMatchWrapWidth(containerMainAxisWidth)) {
        assertWithLogicMessage("not wrapped!");
        return node->getFrame().size;
    }
#endif
    const auto props = node->props();
    const float mainAxisPadding = TLBaseLayoutPropsGetMainAxisPadding(&node->props());
    const float crossAxisPadding = TLBaseLayoutPropsGetCrossAxisPadding(&node->props());
    const float mainAxisPaddingStart = TLBaseLayoutPropsGetMainAxisPaddingStart(&node->props());
    const float crossAxisPaddingStart = TLBaseLayoutPropsGetCrossAxisPaddingStart(&node->props());
    const float spacing = props.hasSpacing() ? props.spacing() : 0;
    const auto children = node->getChildren();
    size_t displayChildrenCount = 0;

    float actualContainerMainAxisWidth = containerMainAxisWidth;
    float actualContainerCrossAxisWidth = containerCrossAxisWidth;
    // 计算实际子元素布局时的mainAxisWidth需要考虑padding
    actualContainerMainAxisWidth -= mainAxisPadding;
    // 计算实际子元素布局时的crossAxisWidth需要考虑padding
    actualContainerCrossAxisWidth -= crossAxisPadding;
    float childMainAxisWidth = 0;
    float childCrossAxisWidth = 0;
    for (const TLNodeRef child : children) {
        if (child->isDisplayNone()) {
            continue;
        }
        displayChildrenCount++;
        TLSetWidthAndMode(child, actualContainerMainAxisWidth, TLLayoutModeExactly);
        auto childSize = child->caculateMeansure(actualContainerMainAxisWidth,
                                                 actualContainerCrossAxisWidth - childCrossAxisWidth,
                                                 layoutContext,
                                                 context);
        childMainAxisWidth = std::max(childMainAxisWidth, childSize.width);
        child->x() = mainAxisPaddingStart;
    }
    /// Child fill parent width default, so fix them.
    for (auto child : children) {
        if (child->isDisplayNone()) {
            continue;
        }
        child->y() = childCrossAxisWidth + crossAxisPaddingStart;
        childCrossAxisWidth += child->height() + spacing;
    }
    /// 如果有子元素则最后多算了一个spacing
    if (displayChildrenCount > 0) {
        childCrossAxisWidth -= spacing;
    }
    /// Set position for reverse
    if (node->needReverseChildren()) {
        float y = 0;
        for (auto start = children.rbegin(); start != children.rend(); ++start) {
            auto child = *start;
            if (child->isDisplayNone()) {
                continue;
            }
            child->y() = y + crossAxisPaddingStart;
            y += child->height() + spacing;
        }
    }
    // 计算完实际的的mainAxisWidth，再把padding加回来，得出容器的mainAxisWidth
    actualContainerMainAxisWidth += mainAxisPadding;
    actualContainerCrossAxisWidth = fmin(actualContainerCrossAxisWidth, childCrossAxisWidth) + crossAxisPadding;

    TLSetWidthAndMode(node, actualContainerMainAxisWidth, TLLayoutModeExactly);
    TLSetHeightAndMode(node, actualContainerCrossAxisWidth, TLLayoutModeExactly);
    TLFixSizeWithoutUndefined(node);
    return node->getFrame().size;
}

/// MARK: Public functions
const LinearLayoutProps TLLinearLayoutNodeGetProps(const LinearLayoutNodeRef node) {
    return node->props();
}

const LinearLayoutNodeRef TLLinearLayoutNodeNewWithOptions(const TLNodeOptionsRef options) {
    return new LinearLayoutNode(options);
}

const LinearLayoutNodeRef TLLinearLayoutNodeNew() {
    return new LinearLayoutNode();
}
