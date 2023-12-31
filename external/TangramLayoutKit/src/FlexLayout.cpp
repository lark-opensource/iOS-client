//
//  FlexLayout.cpp
//  Pods
//
//  Created by Ping on 2023/7/26.
//

#include "Macros.h"
#include "TLNode.h"
#include "public.h"
#include "internal.h"
#include "FlexLayout.h"

using namespace TangramLayoutKit;
using namespace TangramLayoutKit::Log;

// tuple = (childrenMainAxisWidth, childrenCrossAxisWidth, growPriority, shrinkPriority, canStretch, children)
using TLNodeLineInfoVector = std::vector<std::tuple<float, float, float, float, bool, TLNodeVector>>;

/// MARK: Function define
TLSize FlexCaculateMeansureImpl(FlexLayoutNodeRef node,
                                const float containerWidth,
                                const float containerHeight,
                                LayoutContext& layoutContext,
                                AnyClass context);
static inline
TLSize FlexCaculateMeansureWithNoWrap(const FlexLayoutNodeRef node,
                                      const float containerMainAxisWidth,
                                      const TLLayoutMode containerMainAxisMode,
                                      const float containerCrossAxisWidth,
                                      const TLLayoutMode containerCrossAxisMode,
                                      LayoutContext& layoutContext,
                                      AnyClass context);
static inline
TLSize FlexCaculateMeansureWithLinearWrap(const FlexLayoutNodeRef node,
                                          const float containerMainAxisWidth,
                                          const TLLayoutMode containerMainAxisMode,
                                          const float containerCrossAxisWidth,
                                          const TLLayoutMode containerCrossAxisMode,
                                          LayoutContext& layoutContext,
                                          AnyClass context);
static inline
TLSize FlexCaculateMeansureWithWrap(const FlexLayoutNodeRef node,
                                    const float containerMainAxisWidth,
                                    const TLLayoutMode containerMainAxisMode,
                                    const float containerCrossAxisWidth,
                                    const TLLayoutMode containerCrossAxisMode,
                                    LayoutContext& layoutContext,
                                    AnyClass context);

static inline
void FlexCaculateLayoutWithWrap(const FlexLayoutPropsRef props,
                                const float containerMainAxisWidth,
                                const float containerCrossAxisWidth,
                                const float childrenCrossAxisWidth,
                                const TLNodeLineInfoVector lines,
                                LayoutContext& layoutContext,
                                AnyClass context);

static inline
const TLAlign TLResolvedCrossAlign(const TLAlign containerAlign, const TLAlign alignSelf);
static inline
const float TLGetSumCrossAxisWidth(const TLNodeVector children,
                                   const TLOrientation orientation,
                                   const float crossAxisSpacing);
static inline
const float TLCaculateLinearWrapCrossAxisOffset(const TLAlign align,
                                                const float containerSize,
                                                const float childrenSize,
                                                LayoutContext&,
                                                AnyClass context);
static inline
const bool TLFlexLayoutCanStretch(const FlexLayoutNodeRef node);
static inline
TLSize FlexCaculateMeansureWithStretch(const FlexLayoutNodeRef node,
                                       const TLNodeVector children,
                                       const bool containerCanStretch,
                                       const float childrenMainAxisWidth,
                                       const float childrenCrossAxisWidth,
                                       const float containerMainAxisWidth,
                                       const TLLayoutMode containerMainAxisMode,
                                       const float containerCrossAxisWidth,
                                       const TLLayoutMode containerCrossAxisMode,
                                       LayoutContext& layoutContext,
                                       AnyClass context);
/// MARK: Function define end

/// MARK: Public functions
const FlexLayoutNodeRef TLFlexLayoutNodeNew(void) {
    return new FlexLayoutNode();
}

const FlexLayoutNodeRef TLFlexLayoutNodeNewithOptions(const TLNodeOptionsRef options) {
    return new FlexLayoutNode(options);
}

TLSize FlexLayoutNode::caculateMeansure(const float containerWidth,
                                              const float containerHeight,
                                              LayoutContext& layoutContext,
                                              AnyClass context) {
    if (isDisplayNone()) {
        return {0, 0};
    }
    if (!isDirty()) {
        return {width(), height()};
    }

    auto containerSize = FlexCaculateMeansureImpl(this,
                                                  containerWidth,
                                                  containerHeight,
                                                  layoutContext,
                                                  context);
    return containerSize;
}

void FlexLayoutNode::caculateLayout(LayoutContext& layoutContext,
                                    AnyClass context) {
    TangramLayoutKit::Log::Log(this,
                               LogLevelInfo,
                               "FlexLayoutNode::caculateLayout(reason: %s)",
                               layoutContext.debugReason());
    const auto orientation = props().orientation();
    const float actualCrossWidth = TLGetCrossAxisWidth(this, orientation) - TLBaseLayoutPropsGetCrossAxisPadding(&this->props());
    const auto crossAlign = props().crossAxisAlign();
    const float crossAxisPaddingStart = TLBaseLayoutPropsGetCrossAxisPaddingStart(&props());
    const float crossAxisSpacing = props().hasCrossAxisSpacing() ? props().crossAxisSpacing() : 0;
    switch (props().flexWrap()) {
        case TLFlexWrapNoWrap: {
            for (const TLNodeRef child : getChildren()) {
                if (child->isDisplayNone()) {
                    continue;
                }
                const TLAlign align = TLResolvedCrossAlign(crossAlign, child->getStyle().alignSelf());
                const float offset = TLCaculateNoWrapCrossAxisOffset(TLGetCrossAxisWidth(child, orientation),
                                                                     align,
                                                                     actualCrossWidth,
                                                                     layoutContext,
                                                                     context);
                TLNodeSetCrossAxisOffset(child, orientation, offset + crossAxisPaddingStart);
                child->caculateLayout(layoutContext, context);
            }
            break;
        }
        case TLFlexWrapLinearWrap: { // LinearWrap时，Child Style中的alignSelf不生效，容器的crossAxisAlign决定子元素整体在辅轴位置
            const float childrenCrossAxisWidth = TLGetSumCrossAxisWidth(getChildren(),
                                                                        orientation,
                                                                        crossAxisSpacing);
            float offset = TLCaculateLinearWrapCrossAxisOffset(crossAlign,
                                                               actualCrossWidth,
                                                               childrenCrossAxisWidth,
                                                               layoutContext,
                                                               context);
            offset += crossAxisPaddingStart;
            for (const TLNodeRef child : getChildren()) {
                if (child->isDisplayNone()) {
                    continue;
                }
                TLNodeSetCrossAxisOffset(child, orientation, offset);
                child->caculateLayout(layoutContext, context);
                offset += TLGetCrossAxisWidth(child, orientation) + crossAxisSpacing;
            }
            break;
        }
        case TLFlexWrapWrap:
        case TLFlexWrapWrapReverse: { // Wrap/WrapReverse时，容器的crossAxisAlign决定子元素整体在辅轴位置，子元素的alignSelf决定子元素在当前行的位置
            // wrap/wrapReverse时子元素位置在meansure阶段确定，layout阶段只需要递归触发即可
            for (const TLNodeRef child : getChildren()) {
                if (child->isDisplayNone()) {
                    continue;
                }
                child->caculateLayout(layoutContext, context);
            }
            break;
        }
        default:
            break;
    }
}

TLSize FlexCaculateMeansureImpl(FlexLayoutNodeRef node,
                                const float containerWidth,
                                const float containerHeight,
                                LayoutContext& layoutContext,
                                AnyClass context) {
    FlexLayoutProps props = node->props();
    float actualContainerMainAxisWidth, actualContainerCrossAxisWidth;
    TLLayoutMode actualContainerMainAxisMode, actualContainerCrossAxisMode;

    TLFixActualSize(node,
                    containerWidth,
                    containerHeight,
                    actualContainerMainAxisWidth,
                    actualContainerMainAxisMode,
                    actualContainerCrossAxisWidth,
                    actualContainerCrossAxisMode);

    switch (props.orientation()) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            break;
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            std::swap(actualContainerMainAxisWidth, actualContainerCrossAxisWidth);
            std::swap(actualContainerMainAxisMode, actualContainerCrossAxisMode);
            break;
    }

    // width = mainAxisWidth; height = crossAxisWidth
    TLSize actualChildrenSize = {};
    switch (props.flexWrap()) {
        case TLFlexWrapNoWrap: // 折叠时和LinearLayout一样
            actualChildrenSize = FlexCaculateMeansureWithNoWrap(node,
                                                                actualContainerMainAxisWidth,
                                                                actualContainerMainAxisMode,
                                                                actualContainerCrossAxisWidth,
                                                                actualContainerCrossAxisMode,
                                                                layoutContext,
                                                                context);
            break;
        case TLFlexWrapLinearWrap:
            // grow/shrink只针对主轴，linearWrap时不生效
            actualChildrenSize = FlexCaculateMeansureWithLinearWrap(node,
                                                                    actualContainerMainAxisWidth,
                                                                    actualContainerMainAxisMode,
                                                                    actualContainerCrossAxisWidth,
                                                                    actualContainerCrossAxisMode,
                                                                    layoutContext,
                                                                    context);
            break;
        case TLFlexWrapWrap:
        case TLFlexWrapWrapReverse:
            actualChildrenSize = FlexCaculateMeansureWithWrap(node,
                                                              actualContainerMainAxisWidth,
                                                              actualContainerMainAxisMode,
                                                              actualContainerCrossAxisWidth,
                                                              actualContainerCrossAxisMode,
                                                              layoutContext,
                                                              context);
            break;
        default:
            break;
    }

    if (actualContainerMainAxisMode != TLLayoutModeExactly) {
        actualContainerMainAxisWidth = fmin(actualChildrenSize.width, actualContainerMainAxisWidth);
        actualContainerMainAxisMode = TLLayoutModeExactly;
    }
    if (actualContainerCrossAxisMode != TLLayoutModeExactly) {
        actualContainerCrossAxisWidth = fmin(actualChildrenSize.height, actualContainerCrossAxisWidth);
        actualContainerCrossAxisMode = TLLayoutModeExactly;
    }

    TLSetMainAxisWidthAndMode(node, props.orientation(), actualContainerMainAxisWidth, actualContainerMainAxisMode);
    TLSetCrossAxisWidthAndMode(node, props.orientation(), actualContainerCrossAxisWidth, actualContainerCrossAxisMode);
    TLFixSizeWithoutUndefined(node);
    return TLNodeGetFrame(node).size;
}

/// 不折叠，一个一个排
/// @return TLSize - 子元素实际占用size；width = mainAxisWidth; height = crossAxisWidth
static inline
TLSize FlexCaculateMeansureWithNoWrap(const FlexLayoutNodeRef node,
                                      const float containerMainAxisWidth,
                                      const TLLayoutMode containerMainAxisMode,
                                      const float containerCrossAxisWidth,
                                      const TLLayoutMode containerCrossAxisMode,
                                      LayoutContext& layoutContext,
                                      AnyClass context) {
    TLNodeVector children = node->getChildren();
    const float mainAxisPadding = TLBaseLayoutPropsGetMainAxisPadding(&node->props());
    const float crossAxisPadding = TLBaseLayoutPropsGetCrossAxisPadding(&node->props());

    float actualChildrenMainAxisWidth = 0;
    float actualChildrenCrossAxisWidth = 0;
    float ascent = 0;
    size_t displayChildrenCount = 0;

    TLCaculateMeansureWithNoWrap(&node->getStyle(),
                                 &node->props(),
                                 children,
                                 containerMainAxisWidth - mainAxisPadding,
                                 containerMainAxisMode,
                                 containerCrossAxisWidth - crossAxisPadding,
                                 containerCrossAxisMode,
                                 actualChildrenMainAxisWidth,
                                 actualChildrenCrossAxisWidth,
                                 ascent,
                                 displayChildrenCount,
                                 layoutContext,
                                 context);

    if (TLFlexLayoutCanStretch(node)) {
        auto [tmpChildrenMainAxisWidth, tmpChildrenCrossAxisWidth] = FlexCaculateMeansureWithStretch(node,
                                                                                                     children,
                                                                                                     node->props().crossAxisAlign() == TLAlignStretch,
                                                                                                     actualChildrenMainAxisWidth,
                                                                                                     actualChildrenCrossAxisWidth,
                                                                                                     containerMainAxisWidth - mainAxisPadding,
                                                                                                     containerMainAxisMode,
                                                                                                     containerCrossAxisWidth - crossAxisPadding,
                                                                                                     containerCrossAxisMode,
                                                                                                     layoutContext,
                                                                                                     context);
        actualChildrenMainAxisWidth = tmpChildrenMainAxisWidth;
        actualChildrenCrossAxisWidth = tmpChildrenCrossAxisWidth;
    }

    actualChildrenMainAxisWidth += mainAxisPadding;
    actualChildrenCrossAxisWidth += crossAxisPadding;

    node->cachedAscent() = ascent;

    TLBaseLayoutCaculateMainAxisOffset(&node->props(),
                                       children,
                                       actualChildrenMainAxisWidth,
                                       (containerMainAxisMode == TLLayoutModeExactly ? containerMainAxisWidth : fmin(actualChildrenMainAxisWidth, containerMainAxisWidth)),
                                       displayChildrenCount);

    return {actualChildrenMainAxisWidth, actualChildrenCrossAxisWidth};
}

/// 线性折叠，子元素主轴方向被拉伸成容器宽，辅轴方向顺排
/// @return TLSize - 子元素实际占用size；width = mainAxisWidth; height = crossAxisWidth
static inline
TLSize FlexCaculateMeansureWithLinearWrap(const FlexLayoutNodeRef node,
                                          const float containerMainAxisWidth,
                                          const TLLayoutMode containerMainAxisMode,
                                          const float containerCrossAxisWidth,
                                          const TLLayoutMode containerCrossAxisMode,
                                          LayoutContext& layoutContext,
                                          AnyClass context) {
    TLNodeVector children = node->getChildren();
    FlexLayoutProps props = node->props();
    const TLOrientation orientation = props.orientation();
    const float mainAxisPaddingStart = TLBaseLayoutPropsGetMainAxisPaddingStart(&props);
    const float mainAxisPadding = TLBaseLayoutPropsGetMainAxisPadding(&props);
    const float crossAxisPadding = TLBaseLayoutPropsGetCrossAxisPadding(&props);
    const float crossAxisSpacing = props.hasCrossAxisSpacing() ? props.crossAxisSpacing() : 0;
    const float actualContainerMainAxisWidth = containerMainAxisWidth - mainAxisPadding;
    const float actualContainerCrossAxisWidth = containerCrossAxisWidth - crossAxisPadding;
    float actualChildrenCrossAxisWidth = 0;
    size_t displayChildrenCount = 0;

    for (const TLNodeRef child : children) {
        if (child->isDisplayNone()) {
            continue;
        }
        displayChildrenCount++;
        TLSetMainAxisWidthAndMode(child, orientation, actualContainerMainAxisWidth, TLLayoutModeExactly);
        auto childSize = TLCaculateMeansureWithOrientation(child,
                                                           orientation,
                                                           actualContainerMainAxisWidth,
                                                           actualContainerCrossAxisWidth,
                                                           layoutContext,
                                                           context);
        auto [_, childCrossAxisWidth] = TLResolvedAxisWidth(orientation, childSize);
        actualChildrenCrossAxisWidth += childCrossAxisWidth + crossAxisSpacing;

        TLNodeSetMainAxisOffset(child, orientation, mainAxisPaddingStart);
    }

    /// 如果有子元素则最后多算了一个spacing
    if (displayChildrenCount > 0) {
        actualChildrenCrossAxisWidth -= crossAxisSpacing;
    }
    actualChildrenCrossAxisWidth += crossAxisPadding;

    return {containerMainAxisWidth, actualChildrenCrossAxisWidth};
}

/// 流式折叠，顺排子元素，排不下自动折行
/// wrapReverse时，主轴排列顺序和wrap时相同，只是辅轴顺序不同，如：
/// wrap时：
/// ------
/// | A B C |
/// | D E     |
/// | F        |
/// ------
/// wrapReverse时：
/// ------
/// | F        |
/// | D E     |
/// | A B C |
/// ------
/// @return TLSize - 子元素实际占用size；width = mainAxisWidth; height = crossAxisWidth
static inline
TLSize FlexCaculateMeansureWithWrap(const FlexLayoutNodeRef node,
                                    const float containerMainAxisWidth,
                                    const TLLayoutMode containerMainAxisMode,
                                    const float containerCrossAxisWidth,
                                    const TLLayoutMode containerCrossAxisMode,
                                    LayoutContext& layoutContext,
                                    AnyClass context) {
    TLNodeVector children = node->getChildren();
    FlexLayoutProps props = node->props();
    const TLOrientation orientation = props.orientation();
    const float mainAxisPadding = TLBaseLayoutPropsGetMainAxisPadding(&props);
    const float crossAxisPadding = TLBaseLayoutPropsGetCrossAxisPadding(&props);
    float actualContainerMainAxisWidth = containerMainAxisWidth - mainAxisPadding;
    float actualContainerCrossAxisWidth = containerCrossAxisWidth - crossAxisPadding;
    const float mainAxisSpacing = props.hasMainAxisSpacing() ? props.mainAxisSpacing() : 0;
    const float crossAxisSpacing = props.hasCrossAxisSpacing() ? props.crossAxisSpacing() : 0;

    TLNodeLineInfoVector lines = TLNodeLineInfoVector();
    // 存储单行子元素
    TLNodeVector line = TLNodeVector();
    float actualChildrenMainAxisWidth = 0;
    float actualChildrenCrossAxisWidth = 0;
    float growPriority = 0;
    float shrinkPriority = 0;
    // 当前行是否有child需要stretch
    bool childrenCanStretch = false;
    // 被子元素撑开的容器大小
    float sumChildrenMainAxisWidth = 0;
    float sumChildrenCrossAxisWidth = 0;

    for (const TLNodeRef child : children) {
        if (child->isDisplayNone()) {
            continue;
        }
        auto childSize = TLCaculateMeansureWithOrientation(child,
                                                           orientation,
                                                           actualContainerMainAxisWidth,
                                                           actualContainerCrossAxisWidth,
                                                           layoutContext,
                                                           context);
        auto [childMainAxisWidth, childCrossAxisWidth] = TLResolvedAxisWidth(orientation, childSize);
        // 如果当前是第一个元素且当前元素宽度超过了容器宽
        if (actualChildrenMainAxisWidth <= 0 && childMainAxisWidth >= actualContainerMainAxisWidth) {
            line.push_back(child);
            lines.push_back(std::make_tuple(childMainAxisWidth,
                                            childCrossAxisWidth,
                                            child->getStyle().growWeight(),
                                            child->getStyle().shrinkWeight(),
                                            child->getStyle().alignSelf() == TLAlignStretch,
                                            line));
            sumChildrenMainAxisWidth = std::max(sumChildrenMainAxisWidth, childMainAxisWidth);
            sumChildrenCrossAxisWidth += childCrossAxisWidth + crossAxisSpacing;

            // reset
            line = TLNodeVector();
            actualChildrenMainAxisWidth = 0;
            actualChildrenCrossAxisWidth = 0;
            growPriority = 0;
            shrinkPriority = 0;
            childrenCanStretch = false;
        } else if (actualChildrenMainAxisWidth > 0 && // 当前非第一个元素且加上当前元素后超过了容器宽度
                   actualChildrenMainAxisWidth + mainAxisSpacing + childMainAxisWidth > actualContainerMainAxisWidth) {
            lines.push_back(std::make_tuple(actualChildrenMainAxisWidth,
                                            actualChildrenCrossAxisWidth,
                                            growPriority,
                                            shrinkPriority,
                                            childrenCanStretch,
                                            line));
            sumChildrenMainAxisWidth = std::max(sumChildrenMainAxisWidth, actualChildrenMainAxisWidth);
            sumChildrenCrossAxisWidth += actualChildrenCrossAxisWidth + crossAxisSpacing;

            // reset
            line = TLNodeVector();
            line.push_back(child);
            actualChildrenMainAxisWidth = childMainAxisWidth;
            actualChildrenCrossAxisWidth = childCrossAxisWidth;
            growPriority = child->getStyle().growWeight();
            shrinkPriority = child->getStyle().shrinkWeight();
            childrenCanStretch = child->getStyle().alignSelf() == TLAlignStretch;
        } else { // 加上当前子元素没有超过容器宽度
            line.push_back(child);
            actualChildrenMainAxisWidth += (actualChildrenMainAxisWidth > 0 ? mainAxisSpacing : 0); // 第一个元素不加spacing
            actualChildrenMainAxisWidth += childMainAxisWidth;
            actualChildrenCrossAxisWidth = std::max(actualChildrenCrossAxisWidth, childCrossAxisWidth);
            growPriority += child->getStyle().growWeight();
            shrinkPriority += child->getStyle().shrinkWeight();
            childrenCanStretch = (childrenCanStretch || child->getStyle().alignSelf() == TLAlignStretch);
        }
    }

    if (!line.empty()) {
        lines.push_back(std::make_tuple(actualChildrenMainAxisWidth,
                                        actualChildrenCrossAxisWidth,
                                        growPriority,
                                        shrinkPriority,
                                        childrenCanStretch,
                                        line));
        sumChildrenMainAxisWidth = std::max(sumChildrenMainAxisWidth, actualChildrenMainAxisWidth);
        sumChildrenCrossAxisWidth += actualChildrenCrossAxisWidth + crossAxisSpacing;
    }

    if (lines.size() > 0) {
        sumChildrenCrossAxisWidth -= crossAxisSpacing;
    }

    // 主轴确定则直接使用指定的大小，否则用子元素撑开的大小；主轴未指定大小时，大小也需要受到max/min约束
    float tmpActualContainerMainAxisWidth = actualContainerMainAxisWidth;
    if (containerMainAxisMode != TLLayoutModeExactly) {
        tmpActualContainerMainAxisWidth = fmin(sumChildrenMainAxisWidth, tmpActualContainerMainAxisWidth);
    }
    // grow/shrink/stretch之后子元素撑开大小需要重新计算
    sumChildrenMainAxisWidth = 0;
    sumChildrenCrossAxisWidth = 0;

    // 布局信息：grow/shrink/stretch之后子元素大小会变，需要重新记录下
    TLNodeLineInfoVector layoutLines = TLNodeLineInfoVector();

    for (auto [childrenMainAxisWidth, childrenCrossAxisWidth, growPriority, shrinkPriority, childrenCanStretch, lineChildren] : lines) {
        // grow/shrink重新计算childrenMainAxisWidth和childrenCrossAxisWidth
        auto [actualChildrenMainAxisWidth, actualChildrenCrossAxisWidth] = TLCaculateMeansureWithGrowOrShrink(&node->getStyle(),
                                                                                                              &props,
                                                                                                              lineChildren,
                                                                                                              growPriority,
                                                                                                              shrinkPriority,
                                                                                                              childrenMainAxisWidth,
                                                                                                              childrenCrossAxisWidth,
                                                                                                              tmpActualContainerMainAxisWidth,
                                                                                                              TLLayoutModeExactly, // 对齐前端，wrap时按exactly计算
                                                                                                              actualContainerCrossAxisWidth, // 应该传容器的辅轴宽
                                                                                                              containerCrossAxisMode,
                                                                                                              layoutContext,
                                                                                                              context);

        if (childrenCanStretch) {
            // wrap/wrapReverse时，子元素的alignSelf生效，alignSelf为stretch时，会拉伸为当前行辅轴宽（注意不是容器辅轴宽）
            auto [tmpChildrenMainAxisWidth, tmpChildrenCrossAxisWidth] = FlexCaculateMeansureWithStretch(node,
                                                                                                         lineChildren,
                                                                                                         false, // wrap/wrapReverse时，容器stretch不生效，因为crossAxisAlign是作用于子元素整体的
                                                                                                         actualChildrenMainAxisWidth,
                                                                                                         actualChildrenCrossAxisWidth,
                                                                                                         actualChildrenMainAxisWidth,
                                                                                                         TLLayoutModeExactly,
                                                                                                         actualChildrenCrossAxisWidth,
                                                                                                         TLLayoutModeExactly,
                                                                                                         layoutContext,
                                                                                                         context);
            actualChildrenMainAxisWidth = tmpChildrenMainAxisWidth;
            actualChildrenCrossAxisWidth = tmpChildrenCrossAxisWidth;
        }

        sumChildrenMainAxisWidth = std::max(sumChildrenMainAxisWidth, actualChildrenMainAxisWidth);
        sumChildrenCrossAxisWidth += actualChildrenCrossAxisWidth + crossAxisSpacing;

        layoutLines.push_back(std::make_tuple(actualChildrenMainAxisWidth,
                                              actualChildrenCrossAxisWidth,
                                              growPriority,
                                              shrinkPriority,
                                              childrenCanStretch,
                                              lineChildren));
    }

    if (lines.size() > 0) {
        sumChildrenCrossAxisWidth -= crossAxisSpacing;
    }

    // grow/shrink/stretch之后需要重新决策容器大小
    if (containerMainAxisMode != TLLayoutModeExactly) {
        actualContainerMainAxisWidth = fmin(sumChildrenMainAxisWidth, actualContainerMainAxisWidth);
    }
    if (containerCrossAxisMode != TLLayoutModeExactly) {
        actualContainerCrossAxisWidth = fmin(sumChildrenCrossAxisWidth, actualContainerCrossAxisWidth);
    }

    sumChildrenMainAxisWidth += mainAxisPadding;
    sumChildrenCrossAxisWidth += crossAxisPadding;
    FlexCaculateLayoutWithWrap(&node->props(),
                               actualContainerMainAxisWidth + mainAxisPadding,
                               actualContainerCrossAxisWidth + crossAxisPadding,
                               sumChildrenCrossAxisWidth,
                               layoutLines,
                               layoutContext,
                               context);

    // 返回子元素撑开大小，外部会和容器指定大小重新决策
    return {sumChildrenMainAxisWidth, sumChildrenCrossAxisWidth};
}

/// Wrap时计算主轴和辅轴位置，会依赖子元素折行，因此在Meansure阶段触发，如果在Layout阶段
/// 触发，则需要重新算一下子元素折行的位置，可能会有精度问题（目前是根据宽度判断是否折行的，当容器被子元素撑开时，
/// 可能有精度问题导致Meansure阶段和Layout阶段计算出的折行位置不相同）
///
/// @param props - container props
/// @param containerMainAxisWidth - 容器主轴宽度，包含padding
/// @param containerCrossAxisWidth - 容器辅轴宽度，包含padding
/// @param actualChildrenCrossAxisWidth - 被子元素撑开的宽度，包含padding
/// @param lines - 子元素折行信息
static inline
void FlexCaculateLayoutWithWrap(const FlexLayoutPropsRef props,
                                const float containerMainAxisWidth,
                                const float containerCrossAxisWidth,
                                const float actualChildrenCrossAxisWidth,
                                TLNodeLineInfoVector lines,
                                LayoutContext& layoutContext,
                                AnyClass context) {
    const TLOrientation orientation = props->orientation();
    const auto crossAlign = props->crossAxisAlign();
    const float crossAxisSpacing = props->crossAxisSpacing();
    const float mainAxisPadding = TLBaseLayoutPropsGetMainAxisPadding(props);
    float crossAxisOffset = TLCaculateNoWrapCrossAxisOffset(actualChildrenCrossAxisWidth,
                                                            crossAlign, // 容器crossAxisAlign决定子元素整体在辅轴位置
                                                            containerCrossAxisWidth,
                                                            layoutContext,
                                                            context);
    crossAxisOffset += TLBaseLayoutPropsGetCrossAxisPaddingStart(props);

    if (props->flexWrap() == TLFlexWrapWrapReverse) {
        std::reverse(lines.begin(), lines.end());
    }
    for (auto [childrenMainAxisWidth, childrenCrossAxisWidth, growPriority, shrinkPriority, childrenCanStretch, lineChildren] : lines) {
        TLBaseLayoutCaculateMainAxisOffset(props,
                                           lineChildren,
                                           childrenMainAxisWidth + mainAxisPadding,
                                           containerMainAxisWidth,
                                           lineChildren.size());
        for (const TLNodeRef child : lineChildren) {
            // 子元素的alignSelf决定在当前行位置
            const float childCrossAxisOffset = TLCaculateNoWrapCrossAxisOffset(TLGetCrossAxisWidth(child, orientation),
                                                                               child->getStyle().alignSelf(),
                                                                               childrenCrossAxisWidth,
                                                                               layoutContext,
                                                                               context);
            TLNodeSetCrossAxisOffset(child, orientation, crossAxisOffset + childCrossAxisOffset);
        }
        crossAxisOffset += crossAxisSpacing + childrenCrossAxisWidth;
    }
}

static inline
const TLAlign TLResolvedCrossAlign(const TLAlign containerAlign, const TLAlign alignSelf) {
    return alignSelf == TLAlignUndefined ? containerAlign : alignSelf;
}

static inline
const float TLGetSumCrossAxisWidth(const TLNodeVector children,
                                   const TLOrientation orientation,
                                   const float crossAxisSpacing) {
    float crossAxisWidth = 0;
    size_t displayChildrenCount = 0;
    for (const TLNodeRef child : children) {
        if (child->isDisplayNone()) {
            continue;
        }
        displayChildrenCount++;
        const float childCrossAxisWidth = TLGetCrossAxisWidth(child, orientation);
        crossAxisWidth += childCrossAxisWidth + crossAxisSpacing;
    }
    if (displayChildrenCount > 0) {
        crossAxisWidth -= crossAxisSpacing;
    }
    return crossAxisWidth;
}

static inline
const float TLCaculateLinearWrapCrossAxisOffset(const TLAlign align,
                                                const float containerSize,
                                                const float childrenSize,
                                                LayoutContext&,
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
            return (containerSize - childrenSize) / 2;
        case TLAlignBottom:
            return containerSize - childrenSize;
        case TLAlignStretch: // LinearWrap下，stretch不生效
            return 0;
    }
}

static inline
const bool TLFlexLayoutCanStretch(const FlexLayoutNodeRef node) {
    if (node->props().crossAxisAlign() == TLAlignStretch) {
        return true;
    }
    const TLNodeVector children = node->getChildren();
    for (const TLNodeRef child : children) {
        if (child->isDisplayNone()) {
            continue;
        }
        if (child->getStyle().alignSelf() == TLAlignStretch) {
            return true;
        }
    }
    return false;
}

/// 计算children stretch后的主轴、辅轴尺寸
/// @param node - 容器
/// @param children - 当前行children
/// @param containerCanStretch - 容器的crossAxisAlign是否为TLAlignStretch；由外部传入是因为wrap/wrapReverse时，
///                             容器的crossAxisAlign为stretch时不生效
/// @param childrenMainAxisWidth - 当前行children主轴宽
/// @param childrenCrossAxisWidth - 当前行children辅轴宽
/// @param containerMainAxisWidth - containerMainAxisWidth
/// @param containerMainAxisMode - containerMainAxisMode
/// @param containerCrossAxisWidth - containerCrossAxisWidth
/// @param containerCrossAxisMode - containerCrossAxisMode
/// @param layoutContext - layoutContext
/// @param context - context
/// @return TLSize - {actualChildrenMainAxisWidth, actualChildrenCrossAxisWidth}；stretch之后children实际主辅轴宽
static inline
TLSize FlexCaculateMeansureWithStretch(const FlexLayoutNodeRef node,
                                       const TLNodeVector children,
                                       const bool containerCanStretch,
                                       const float childrenMainAxisWidth,
                                       const float childrenCrossAxisWidth,
                                       const float containerMainAxisWidth,
                                       const TLLayoutMode containerMainAxisMode,
                                       const float containerCrossAxisWidth,
                                       const TLLayoutMode containerCrossAxisMode,
                                       LayoutContext& layoutContext,
                                       AnyClass context) {
    const TLOrientation orientation = node->props().orientation();
    const float mainAxisSpacing = node->props().hasMainAxisSpacing() ? node->props().mainAxisSpacing() : 0;
    const float stretchSize = TLGetStretchSize(node,
                                               orientation,
                                               node->getStyle().aspectRatio(),
                                               childrenMainAxisWidth,
                                               childrenCrossAxisWidth,
                                               containerMainAxisWidth,
                                               containerMainAxisMode,
                                               containerCrossAxisWidth,
                                               containerCrossAxisMode);

    float actualChildrenMainAxisWidth = 0;
    float actualChildrenCrossAxisWidth = 0;
    size_t displayChildrenCount = 0;
    for (const TLNodeRef child : children) {
        if (child->isDisplayNone()) {
            continue;
        }
        displayChildrenCount++;
        // 如果容器不能stretch且子元素也不能stretch
        if (!containerCanStretch && child->getStyle().alignSelf() != TLAlignStretch) {
            actualChildrenMainAxisWidth += TLGetMainAxisWidth(child, orientation) + mainAxisSpacing;
            actualChildrenCrossAxisWidth = std::max(actualChildrenCrossAxisWidth, TLGetCrossAxisWidth(child, orientation));
            continue;
        }
        const bool childCanStretch = TLNodeCanStretch(child, containerMainAxisMode, containerCrossAxisMode, orientation);
        TLFixSizeModeByStretch(child, childCanStretch, orientation, containerMainAxisMode);
        if (!isFloatEqual(TLGetCrossAxisWidth(child, orientation), stretchSize) && childCanStretch) {
            TLSetCrossAxisWidthAndMode(child, orientation, stretchSize, TLLayoutModeExactly);
            child->caculateMeansure(child->width(), child->height(), layoutContext, context);
        }
        actualChildrenMainAxisWidth += TLGetMainAxisWidth(child, orientation) + mainAxisSpacing;
        actualChildrenCrossAxisWidth = std::max(actualChildrenCrossAxisWidth, TLGetCrossAxisWidth(child, orientation));
    }
    if (displayChildrenCount > 0) {
        actualChildrenMainAxisWidth -= mainAxisSpacing;
    }

    return {actualChildrenMainAxisWidth, actualChildrenCrossAxisWidth};
}
