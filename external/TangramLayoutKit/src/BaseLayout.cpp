//
//  BaseLayout.cpp
//  TangramLayoutKit
//
//  Created by Ping on 2023/7/26.
//

#include "BaseLayout.h"
#include "Macros.h"
#include "TLNode.h"
#include "public.h"
#include "internal.h"

using namespace TangramLayoutKit;
using namespace TangramLayoutKit::Log;

/// MARK: Function define
static inline
const float TLGetDiffSize(const TLStyleRef style,
                          const TLOrientation orientation,
                          const float childrenMainAxisWidth,
                          const float containerMainAxisWidth,
                          const TLLayoutMode containerMainAxisMode,
                          const float containerCrossAxisWidth,
                          const TLLayoutMode containerCrossAxisMode);
static inline
void TLNodeSetChildrenMainAxisOffsetInternal(const TLNodeVector children,
                                             const TLDirection direction,
                                             const TLOrientation orientation,
                                             const float mainAxisWidth,
                                             const float padding,
                                             const float spacing);
/// MARK: Function define end

/// BaseLayoutProps
const bool BaseLayoutProps::isBaselineLayout() const {
    return (orientation() == TLOrientationRow || orientation() == TLOrientationRowReverse)
    && crossAxisAlign() == TLAlignBaseline;
}

/// 不触发折行逻辑，一个一个排，同时根据shrink/grow压缩/拉伸子元素
/// @param style - container layout node style
/// @param props - container layout node props
/// @param children - children
/// @param actualContainerMainAxisWidth - 减去padding的容器主轴宽
/// @param actualContainerMainAxisMode - 容器主轴模式
/// @param actualContainerCrossAxisWidth - 减去padding的容器辅轴宽
/// @param actualContainerCrossAxisMode - 容器辅轴模式
/// @param actualChildrenMainAxisWidth - 计算出的子元素主轴宽度
/// @param actualChildrenCrossAxisWidth - 计算出的子元素辅轴宽度
/// @param ascent - 计算出的ascent
/// @param displayChildrenCount - 实际展示的子元素数量
/// @param layoutContext - layoutContext
/// @param context - context
void TLCaculateMeansureWithNoWrap(const TLStyleRef style,
                                  const BaseLayoutPropsRef props,
                                  const TLNodeVector children,
                                  const float actualContainerMainAxisWidth,
                                  const TLLayoutMode actualContainerMainAxisMode,
                                  const float actualContainerCrossAxisWidth,
                                  const TLLayoutMode actualContainerCrossAxisMode,
                                  float& actualChildrenMainAxisWidth,
                                  float& actualChildrenCrossAxisWidth,
                                  float& ascent,
                                  size_t& displayChildrenCount,
                                  LayoutContext& layoutContext,
                                  AnyClass context) {
    if (children.empty()) {
        return;
    }
    const TLOrientation orientation = props->orientation();
    const float mainAxisSpacing = props->mainAxisSpacing();
    float growPriority = 0;
    float shrinkPriority = 0;
    displayChildrenCount = 0;
    for (const TLNodeRef child : children) {
        if (child->isDisplayNone()) {
            continue;
        }
        displayChildrenCount++;
        auto size = TLCaculateMeansureWithOrientation(child,
                                                      orientation,
                                                      actualContainerMainAxisWidth,
                                                      actualContainerCrossAxisWidth,
                                                      layoutContext,
                                                      context);
        auto [childMainAxisWidth, childCrossAxisWidth] = TLResolvedAxisWidth(orientation, size);
        actualChildrenMainAxisWidth += childMainAxisWidth + mainAxisSpacing;
        actualChildrenCrossAxisWidth = std::max(actualChildrenCrossAxisWidth, childCrossAxisWidth);

        growPriority += child->getStyle().growWeight();
        shrinkPriority += child->getStyle().shrinkWeight();

        if (props->isBaselineLayout()) {
            ascent = std::max(ascent, child->baseline(context));
        }
    }
    // Last child does not has any spacing right, so fix it.
    if (displayChildrenCount > 0) {
        actualChildrenMainAxisWidth -= mainAxisSpacing;
    }

    auto [tmpChildrenMainAxisWidth, tmpChildrenCrossAxisWidth] = TLCaculateMeansureWithGrowOrShrink(style,
                                                                                                    props,
                                                                                                    children,
                                                                                                    growPriority,
                                                                                                    shrinkPriority,
                                                                                                    actualChildrenMainAxisWidth,
                                                                                                    actualChildrenCrossAxisWidth,
                                                                                                    actualContainerMainAxisWidth,
                                                                                                    actualContainerMainAxisMode,
                                                                                                    actualContainerCrossAxisWidth,
                                                                                                    actualContainerCrossAxisMode,
                                                                                                    layoutContext,
                                                                                                    context);
    actualChildrenMainAxisWidth = tmpChildrenMainAxisWidth;
    actualChildrenCrossAxisWidth = tmpChildrenCrossAxisWidth;
}

/// 拉伸或压缩子元素
///
/// @param style - container layout node style
/// @param props - container layout node props
/// @param children - children
/// @param growPriority - children sum growPriority
/// @param shrinkPriority - children sum shrinkPriority
/// @param childrenMainAxisWidth - childrenMainAxisWidth without padding
/// @param childrenCrossAxisWidth - childrenCrossAxisWidth without padding
/// @param containerMainAxisWidth - containerMainAxisWidth without padding
/// @param containerMainAxisMode - containerMainAxisMode
/// @param containerCrossAxisWidth - containerCrossAxisWidth without padding
/// @param containerCrossAxisMode - containerCrossAxisMode
/// @param layoutContext - layoutContext
/// @param context - context
/// @return TLSize - {actualChildrenMainAxisWidth, actualChildrenCrossAxisWidth} without padding
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
                                          void* context) {
    const TLOrientation orientation = props->orientation();
    const float mainAxisSpacing = props->hasMainAxisSpacing() ? props->mainAxisSpacing() : 0;

    const float diffSize = TLGetDiffSize(style,
                                         orientation,
                                         childrenMainAxisWidth,
                                         containerMainAxisWidth,
                                         containerMainAxisMode,
                                         containerCrossAxisWidth,
                                         containerCrossAxisMode);
    const float priority = diffSize > 0 ? growPriority : shrinkPriority;
    float actualChildrenMainAxisWidth = childrenMainAxisWidth;
    float actualChildrenCrossAxisWidth = childrenCrossAxisWidth;
    // 计算Grow/Shrink
    if (diffSize != 0 && priority > 0) {
        // fix children sizeMode to undefined if child has grow/shrink
        TLFixChildrenSizeModeByPriority(children);
        size_t displayChildrenCount = 0;
        actualChildrenMainAxisWidth = 0;
        actualChildrenCrossAxisWidth = 0;
        for (const TLNodeRef child : children) {
            if (child->isDisplayNone()) {
                continue;
            }
            displayChildrenCount++;
            TLFixSizeByPriority(child,
                                orientation,
                                priority,
                                diffSize,
                                containerMainAxisWidth,
                                containerMainAxisMode,
                                containerCrossAxisWidth,
                                containerCrossAxisMode,
                                layoutContext,
                                context);
            actualChildrenMainAxisWidth += TLGetMainAxisWidth(child, orientation) + mainAxisSpacing;
            actualChildrenCrossAxisWidth = std::max(actualChildrenCrossAxisWidth, TLGetCrossAxisWidth(child, orientation));
        }
        if (displayChildrenCount > 0) {
            actualChildrenMainAxisWidth -= mainAxisSpacing;
        }
    }

    return {actualChildrenMainAxisWidth, actualChildrenCrossAxisWidth};
}

static inline
const float TLGetDiffSize(const TLStyleRef style,
                          const TLOrientation orientation,
                          const float childrenMainAxisWidth,
                          const float containerMainAxisWidth,
                          const TLLayoutMode containerMainAxisMode,
                          const float containerCrossAxisWidth,
                          const TLLayoutMode containerCrossAxisMode) {
    // 主轴确定，直接用主轴
    if (containerMainAxisMode == TLLayoutModeExactly) {
        return containerMainAxisWidth - childrenMainAxisWidth;
    }
    const float aspectRatio = style->aspectRatio();
    TLLayoutMode edgesMode;
    float edgesValue;
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse: {
            // 主轴不确定，表示内容撑开，内容撑开大小需要在container范围内
            float actualContainerMainAxisWidth = fmin(childrenMainAxisWidth, containerMainAxisWidth);
            // 辅轴确定，根据aspectRatio算主轴
            if (containerCrossAxisMode == TLLayoutModeExactly && aspectRatio > 0) {
                actualContainerMainAxisWidth = fmin(containerCrossAxisWidth * aspectRatio, containerMainAxisWidth);
            }
            auto minWidth = style->minWidth();
            edgesValue = TLResolvedValue(minWidth, actualContainerMainAxisWidth, edgesMode);
            if (edgesMode == TLLayoutModeExactly && edgesValue > childrenMainAxisWidth) {
                return edgesValue - childrenMainAxisWidth;
            }
            auto maxWidth = style->maxWidth();
            edgesValue = TLResolvedValue(maxWidth, actualContainerMainAxisWidth, edgesMode);
            if (edgesMode == TLLayoutModeExactly && edgesValue < childrenMainAxisWidth) {
                return edgesValue - childrenMainAxisWidth;
            }
            break;
        }
        case TLOrientationColumn:
        case TLOrientationColumnReverse: {
            // 主轴不确定，表示内容撑开，内容撑开大小需要在container范围内
            float actualContainerMainAxisWidth = fmin(childrenMainAxisWidth, containerMainAxisWidth);;
            // 辅轴确定，根据aspectRatio算主轴
            if (containerCrossAxisMode == TLLayoutModeExactly && aspectRatio > 0) {
                actualContainerMainAxisWidth = fmin(containerCrossAxisWidth / aspectRatio, containerMainAxisWidth);
            }
            auto minHeight = style->minHeight();
            edgesValue = TLResolvedValue(minHeight, actualContainerMainAxisWidth, edgesMode);
            if (edgesMode == TLLayoutModeExactly && edgesValue > childrenMainAxisWidth) {
                return edgesValue - childrenMainAxisWidth;
            }
            auto maxHeight = style->maxHeight();
            edgesValue = TLResolvedValue(maxHeight, actualContainerMainAxisWidth, edgesMode);
            if (edgesMode == TLLayoutModeExactly && edgesValue < childrenMainAxisWidth) {
                return edgesValue - childrenMainAxisWidth;
            }
            break;
        }
    }

    // 外部传入的container size视为prefer max值，因此内容撑开时，若超过容器大小，需要触发shrink，但是小于容器大小，不触发grow
    if (!isUndefined(containerMainAxisWidth) && containerMainAxisWidth < childrenMainAxisWidth) {
        return containerMainAxisWidth - childrenMainAxisWidth;
    }
    return 0;
}

/// https://developer.mozilla.org/zh-CN/docs/Web/CSS/justify-content
void TLCaculateMainAxisOffset(const BaseLayoutPropsRef props,
                              TLNodeVector children,
                              const float mainAxisValue,
                              const float actualMainAxisValue,
                              const size_t displayedChildrenCount) {
    if (displayedChildrenCount <= 0 || children.empty()) {
        return;
    }
    const TLOrientation orientation = props->orientation();
    float spacing = 0;
    float padding = TLBaseLayoutPropsGetMainAxisPaddingStart(props);
    float actualSpacing = 0;
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationColumn:
            break;
        case TLOrientationRowReverse:
        case TLOrientationColumnReverse:
            reverse(children.begin(), children.end());
            break;
    }

    if (props->hasMainAxisSpacing()) {
        spacing = props->mainAxisSpacing();
    }
    switch (props->mainAxisJustify()) {
        case TLJustifyStart:
            TLNodeSetChildrenMainAxisOffsetInternal(children,
                                                    props->direction(),
                                                    orientation,
                                                    mainAxisValue,
                                                    padding,
                                                    spacing);
            break;
        case TLJustifyCenter:
            padding = padding + (mainAxisValue - actualMainAxisValue) / 2;
            TLNodeSetChildrenMainAxisOffsetInternal(children,
                                                    props->direction(),
                                                    orientation,
                                                    mainAxisValue,
                                                    padding,
                                                    spacing);
            break;
        case TLJustifyEnd:
            padding = padding + mainAxisValue - actualMainAxisValue;
            TLNodeSetChildrenMainAxisOffsetInternal(children,
                                                    props->direction(),
                                                    orientation,
                                                    mainAxisValue,
                                                    padding,
                                                    spacing);
            break;
        case TLJustifySpaceEvenly: {
            // 剩余空间（减去spacing和padding之后）平分
            const float freeMainAxisValue = (mainAxisValue - actualMainAxisValue) / (displayedChildrenCount + 1);
            if (freeMainAxisValue <= 0) {
                // 没有剩余空间，直接排
                TLNodeSetChildrenMainAxisOffsetInternal(children,
                                                        props->direction(),
                                                        orientation,
                                                        mainAxisValue,
                                                        padding,
                                                        spacing);
                break;
            }
            actualSpacing = freeMainAxisValue + spacing;
            padding = padding + freeMainAxisValue;
            TLNodeSetChildrenMainAxisOffsetInternal(children,
                                                    props->direction(),
                                                    orientation,
                                                    mainAxisValue,
                                                    padding,
                                                    actualSpacing);
            break;
        }
        case TLJustifySpaceArround: {
            if (children.size() <= 1) {
                /// Same to JustifyCenter
                padding = padding + (mainAxisValue - actualMainAxisValue) / 2;
                TLNodeSetMainAxisOffset(children[0], orientation, padding);
                break;
            }
            // 剩余空间（减去spacing和padding之后）：相邻元素间距离相同，每行第一个元素到行首的距离
            // 和每行最后一个元素到行尾的距离将会是相邻元素之间距离的一半
            const float freeMainAxisValue = (mainAxisValue - actualMainAxisValue) / displayedChildrenCount;
            if (freeMainAxisValue <= 0) {
                // 没有剩余空间，直接排
                TLNodeSetChildrenMainAxisOffsetInternal(children,
                                                        props->direction(),
                                                        orientation,
                                                        mainAxisValue,
                                                        padding,
                                                        spacing);
                break;
            }
            padding = padding + freeMainAxisValue / 2;
            actualSpacing = spacing + freeMainAxisValue;
            TLNodeSetChildrenMainAxisOffsetInternal(children,
                                                    props->direction(),
                                                    orientation,
                                                    mainAxisValue,
                                                    padding,
                                                    actualSpacing);
            break;
        }
        case TLJustifySpaceBetween:
            // 防止下面除0
            if (displayedChildrenCount <= 1) {
                TLNodeSetChildrenMainAxisOffsetInternal(children,
                                                        props->direction(),
                                                        orientation,
                                                        mainAxisValue,
                                                        padding,
                                                        spacing);
                break;
            }
            const float freeMainAxisValue = (mainAxisValue - actualMainAxisValue) / (displayedChildrenCount - 1);
            // 没有剩余空间，直接排
            if (freeMainAxisValue <= 0) {
                TLNodeSetChildrenMainAxisOffsetInternal(children,
                                                        props->direction(),
                                                        orientation,
                                                        mainAxisValue,
                                                        padding,
                                                        spacing);
                break;
            }
            actualSpacing = spacing + freeMainAxisValue;
            TLNodeSetChildrenMainAxisOffsetInternal(children,
                                                    props->direction(),
                                                    orientation,
                                                    mainAxisValue,
                                                    padding,
                                                    actualSpacing);
            break;
    }
}

void TLBaseLayoutCaculateMainAxisOffset(const BaseLayoutPropsRef props,
                                        TLNodeVector children,
                                        const float actualChildrenMainAxisWidth,
                                        const float actualContainerMainAxisWidth,
                                        const size_t displayChildrenCount) {
    const TLOrientation orientation = props->orientation();
    const float mainAxisSpacing = props->hasMainAxisSpacing() ? props->mainAxisSpacing() : 0;
    if (isFloatEqual(actualChildrenMainAxisWidth, actualContainerMainAxisWidth) || actualChildrenMainAxisWidth > actualContainerMainAxisWidth) {
        float offset = TLBaseLayoutPropsGetMainAxisPaddingStart(props);
        switch (orientation) {
            case TLOrientationRow:
            case TLOrientationColumn:
                break;
            case TLOrientationRowReverse:
            case TLOrientationColumnReverse:
                std::reverse(children.begin(), children.end());
                break;
        }
        for (const TLNodeRef child : children) {
            if (child->isDisplayNone()) {
                continue;
            }
            TLNodeSetMainAxisOffset(child, orientation, offset);
            offset += TLGetMainAxisWidth(child, orientation) + mainAxisSpacing;
        }
    } else {
        TLCaculateMainAxisOffset(props,
                                 children,
                                 actualContainerMainAxisWidth,
                                 actualChildrenMainAxisWidth,
                                 displayChildrenCount);
    }
}

static inline
void TLNodeSetChildrenMainAxisOffsetInternal(const TLNodeVector children,
                                             const TLDirection direction,
                                             const TLOrientation orientation,
                                             const float mainAxisWidth,
                                             const float padding,
                                             const float spacing) {
    float mainAxisOffset = padding;
    if (direction == TLDirectionLTR) {
        for (auto child : children) {
            if (child->isDisplayNone()) {
                continue;
            }
            TLNodeSetMainAxisOffset(child, orientation, mainAxisOffset);
            mainAxisOffset += TLGetMainAxisWidth(child, orientation) + spacing;
        }
        return;
    }
    mainAxisOffset = mainAxisWidth - padding;
    for (auto child : children) {
        if (child->isDisplayNone()) {
            continue;
        }
        mainAxisOffset -= TLGetMainAxisWidth(child, orientation);
        TLNodeSetMainAxisOffset(child, orientation, mainAxisOffset);
        mainAxisOffset -= spacing;
    }
}
