//
//  public.cpp
//  TangramLayoutKit
//
//  Created by qihongye on 2021/4/6.
//

#include <mutex>
#include "public.h"
#include "TLNodeOptions.h"
#include "Log.h"
#include "LinearLayout.h"
#include "FlexLayout.h"

using namespace TangramLayoutKit;
using namespace TangramLayoutKit::Log;

const TLNodeOptionsRef TLGetDefaultOptions() {
    static TLNodeOptionsRef defaultOptions;
    static std::once_flag initialFlag;

    std::call_once(initialFlag, [](){
        defaultOptions = new TLNodeOptions(&DefaultLogInfo, &DefaultLogWarning, &DefaultLogError, &DefaultLogFatal);
    });
    return defaultOptions;
}

const float TLOptionsGetPointScaleFactor(const TLNodeOptionsRef options) {
    return options->pointScaleFactor;
}

void TLOptionsSetPointScaleFactor(const TLNodeOptionsRef options, const float pointScaleFactor) {
    options->pointScaleFactor = pointScaleFactor;
}

const TLNodeOptionsRef TLOptionsNew(const float pointScaleFactor,
                                    const TLLogger info,
                                    const TLLogger warning,
                                    const TLLogger error,
                                    const TLLogger fatal) {
    return new TLNodeOptions(pointScaleFactor, info, warning, error, fatal);
}

void TLNodeOptionsFree(const TLNodeOptionsRef options) {
    delete options;
}

const TLNodeRef TLNodeNew(void) {
    return new TLNode;
}

const TLNodeRef TLNodeClone(const TLNodeRef node) {
    return new TLNode(*node);
}

const TLNodeRef TLNodeCloneWithOptions(const TLNodeRef node, const TLNodeOptionsRef options) {
    return new TLNode(*node, options);
}

const TLNodeRef TLNodeDeepClone(const TLNodeRef node) {
    const TLNodeOptionsRef options = new TLNodeOptions{*(node->getOptions())};
    const TLNodeRef clone = new TLNode(*node, options);

    TLNodeVector vec = TLNodeVector();
    vec.reserve(node->getChildrenCount());
    TLNodeRef child;
    for (auto c : node->getChildren()) {
        child = TLNodeDeepClone(c);
        child->setParent(clone);
        vec.push_back(child);
    }
    clone->setChildren(std::move(vec));

    return clone;
}

const TLNodeRef TLNodeNewWithOptions(const TLNodeOptionsRef options) {
    return new TLNode(options);
}

const size_t TLNodeGetChildrenCount(const TLNodeRef node) {
    return node->getChildrenCount();
}

const TLNodeRef TLNodeGetParent(const TLNodeRef node) {
    if (!node)
        return nullptr;
    return node->getParent();
}

const TLNodeRef TLNodeGetChild(const TLNodeRef node, const size_t index) {
    if (index < node->getChildrenCount() && index >= 0) {
        return node->getChild(index);
    }
    return nullptr;
}

void TLNodeSetChildren(const TLNodeRef node,
                       const std::vector<TLNodeRef>& children) {
    if (!node)
        return;
    if (children.size() == 0 && node->hasChildren()) {
        for (auto child: node->getChildren()) {
            child->setParent(nullptr);
            child->setStyle(TLStyle());
        }
        node->setChildren(TLNodeVector());
        node->setDirty(true);
        return;
    }
    if (children.size() > 0) {
        for (auto oldChild : node->getChildren()) {
            if (std::find(children.begin(), children.end(), oldChild) == children.end()) {
                oldChild->setStyle(TLStyle());
                oldChild->setParent(nullptr);
            }
        }
    }
    node->setChildren(children);
    for (auto child : children) {
        child->setParent(node);
    }
    node->setDirty(true);
}

void TLNodeSetChildren(const TLNodeRef node,
                       const TLNodeRef c[],
                       uint32_t count) {
    const std::vector<TLNodeRef> children = {c, c + count};
    TLNodeSetChildren(node, children);
}

void TLNodeSetContext(const TLNodeRef node, void* context) {
    node->setContext(context);
}

void* TLNodeGetContext(const TLNodeRef node) {
    return node->getContext();
}

const TLNodeOptionsRef TLNodeGetOptions(const TLNodeRef node) {
    return node->getOptions();
}

void TLNodeSetLayoutFunc(const TLNodeRef node, TLLayoutFunc layout) {
    node->setLayoutFn(layout);
}

void TLNodeSetBaselineFunc(const TLNodeRef node, TLBaselineFunc baseline) {
    node->setBaselineFn(baseline);
}

void TLNodeFree(const TLNodeRef node) {
    if (auto parent = node->getParent()) {
        parent->removeChild(node);
        node->setParent(nullptr);
    }
    for (auto child : node->getChildren()) {
        child->setParent(nullptr);
    }
    node->removeAllChildren();
    delete node;
}

void TLNodeDeepFree(const TLNodeRef root) {
    for (auto child : root->getChildren()) {
        if (child->getParent() == root) {
            root->removeChild(child);
            TLNodeDeepFree(child);
        }
    }
    if (root->hasOptions()
        && root->getOptions() != TLGetDefaultOptions()
        && root->getOptions() != nullptr) {
        TLNodeOptionsFree(root->getOptions());
    }
    TLNodeFree(root);
}

void TLNodeMarkDirty(const TLNodeRef node) {
    node->setDirty(true);
}

/// TLCaculateLayout
/// @param node LayoutNode
/// @param containerWidth prefer max layout width
/// @param containerHeight prefer max layout height
/// @param context global context
TLSize TLCaculateLayout(const TLNodeRef node,
                        const float containerWidth,
                        const float containerHeight,
                        AnyClass context) {
    if (!node) {
        return { 0, 0 };
    }
    TLDeepSetSizeMode(node, TLLayoutModeUndefined, TLLayoutModeUndefined);
    LayoutContext layoutContext;
    TLSize size;
    do {
        size = node->caculateMeansure(containerWidth, containerHeight, layoutContext, context);
    } while (layoutContext.needMeasure());
    do {
        node->caculateLayout(layoutContext, context);
    } while (layoutContext.needLayout());
    return size;
}

const TLRect TLNodeGetFrame(const TLNodeRef node) {
    return node->getFrame();
}

const enum TLDisplay TLNodeGetStyleDisplay(const TLNodeRef node) {
    return node->getStyle().display();
}

void TLNodeSetStyleDisplay(const TLNodeRef node, const enum TLDisplay display) {
    node->getStyle().display(display);
}

const int32_t TLNodeGetStyleGrowWeight(const TLNodeRef node) {
    return node->getStyle().growWeight();
}

void TLNodeSetStyleGrowWeight(const TLNodeRef node, const int32_t value) {
    node->getStyle().growWeight() = value;
}

const int32_t TLNodeGetStyleShrinkWeight(const TLNodeRef node) {
    return node->getStyle().shrinkWeight();
}

void TLNodeSetStyleShrinkWeight(const TLNodeRef node, const int32_t value) {
    node->getStyle().shrinkWeight() = value;
}

const TLValue TLNodeGetStyleWidth(const TLNodeRef node) {
    return node->getStyle().width();
}

void TLNodeSetStyleWidth(const TLNodeRef node, const TLValue value) {
    node->getStyle().width(value);
}

const TLValue TLNodeGetStyleHeight(const TLNodeRef node) {
    return node->getStyle().height();
}

void TLNodeSetStyleHeight(const TLNodeRef node, const TLValue value) {
    node->getStyle().height(value);
}

const TLValue TLNodeGetStyleMaxWidth(const TLNodeRef node) {
    return node->getStyle().maxWidth();
}

void TLNodeSetStyleMaxWidth(const TLNodeRef node, const TLValue value) {
    node->getStyle().maxWidth(value);
}

const TLValue TLNodeGetStyleMaxHeight(const TLNodeRef node) {
    return node->getStyle().maxHeight();
}

void TLNodeSetStyleMaxHeight(const TLNodeRef node, const TLValue value) {
    node->getStyle().maxHeight(value);
}

const TLValue TLNodeGetStyleMinWidth(const TLNodeRef node) {
    return node->getStyle().minWidth();
}

void TLNodeSetStyleMinWidth(const TLNodeRef node, const TLValue value) {
    node->getStyle().minWidth(value);
}

const TLValue TLNodeGetStyleMinHeight(const TLNodeRef node) {
    return node->getStyle().minHeight();
}

void TLNodeSetStyleMinHeight(const TLNodeRef node, const TLValue value) {
    node->getStyle().minHeight(value);
}

const enum TLAlign TLNodeGetStyleAlignSelf(const TLNodeRef node) {
    return node->getStyle().alignSelf();
}

void TLNodeSetStyleAlignSelf(const TLNodeRef node, const enum TLAlign alignSelf) {
    node->getStyle().alignSelf(alignSelf);
}

const float TLNodeGetStyleAspectRatio(const TLNodeRef node) {
    return node->getStyle().aspectRatio();
}

void TLNodeSetStyleAspectRatio(const TLNodeRef node, const float value) {
    node->getStyle().aspectRatio() = value;
}

const enum TLDirection TLNodeGetLinearLayoutPropsDirection(const LinearLayoutNodeRef node) {
    return node->props().direction();
}

void TLNodeSetLinearLayoutPropsDirection(const LinearLayoutNodeRef node, const TLDirection direction) {
    node->props().direction(direction);
}

const enum TLOrientation TLNodeGetLinearLayoutPropsOrientation(const LinearLayoutNodeRef node) {
    return node->props().orientation();
}

void TLNodeSetLinearLayoutPropsOrientation(const LinearLayoutNodeRef node, const TLOrientation orientation) {
    node->props().orientation(orientation);
}

const enum TLJustify TLNodeGetLinearLayoutPropsMainAxisJustify(const LinearLayoutNodeRef node) {
    return node->props().mainAxisJustify();
}

void TLNodeSetLinearLayoutPropsMainAxisJustify(const LinearLayoutNodeRef node, const TLJustify justify) {
    node->props().mainAxisJustify(justify);
}

const enum TLAlign TLNodeGetLinearLayoutPropsCrossAxisAlign(const LinearLayoutNodeRef node) {
    return node->props().crossAxisAlign();
}

void TLNodeSetLinearLayoutPropsCrossAxisAlign(const LinearLayoutNodeRef node, const TLAlign align) {
    node->props().crossAxisAlign(align);
}

const float TLNodeGetLinearLayoutPropsPaddingOfSide(const LinearLayoutNodeRef node, const enum TLSide side) {
    return node->props().padding(side);
}

const TLEdges TLNodeGetLinearLayoutPropsPadding(const LinearLayoutNodeRef node) {
    return node->props().padding();
}

void TLNodeSetLinearLayoutPropsPaddingOfSide(const LinearLayoutNodeRef node, const float padding, const enum TLSide side) {
    node->props().padding(padding, side);
}

void TLNodeSetLinearLayoutPropsPadding(const LinearLayoutNodeRef node, const TLEdges padding) {
    node->props().padding(padding);
}

const float TLNodeGetLinearLayoutPropsWrapWidth(const LinearLayoutNodeRef node) {
    return node->props().wrapWidth();
}
void TLNodeSetLinearLayoutPropsWrapWidth(const LinearLayoutNodeRef node, const float wrapWidth) {
    node->props().wrapWidth() = wrapWidth;
}

const float TLNodeGetLinearLayoutPropsSpacing(const LinearLayoutNodeRef node) {
    return node->props().spacing();
}

void TLNodeSetLinearLayoutPropsSpacing(const LinearLayoutNodeRef node, const float spacing) {
    node->props().mainAxisSpacing() = spacing;
    node->props().crossAxisSpacing() = spacing;
}

// FlexLayout暂不支持设置Direction，默认LTR
//const enum TLDirection TLNodeGetFlexLayoutPropsDirection(const LinearLayoutNodeRef node) {
//    return node->props().direction();
//}
//
//void TLNodeSetFlexLayoutPropsDirection(const LinearLayoutNodeRef node, const TLDirection direction) {
//    node->props().direction(direction);
//}

const enum TLOrientation TLNodeGetFlexLayoutPropsOrientation(const FlexLayoutNodeRef node) {
    return node->props().orientation();
}

void TLNodeSetFlexLayoutPropsOrientation(const FlexLayoutNodeRef node,
                                         const enum TLOrientation orientation) {
    node->props().orientation(orientation);
}

const enum TLJustify TLNodeGetFlexLayoutPropsMainAxisJustify(const FlexLayoutNodeRef node) {
    return node->props().mainAxisJustify();
}

void TLNodeSetFlexLayoutPropsMainAxisJustify(const FlexLayoutNodeRef node,
                                             const enum TLJustify justify) {
    node->props().mainAxisJustify(justify);
}

const enum TLAlign TLNodeGetFlexLayoutPropsCrossAxisAlign(const FlexLayoutNodeRef node) {
    return node->props().crossAxisAlign();
}

void TLNodeSetFlexLayoutPropsCrossAxisAlign(const FlexLayoutNodeRef node,
                                            const enum TLAlign align) {
    node->props().crossAxisAlign(align);
}

const enum TLFlexWrap TLNodeGetFlexLayoutPropsFlexWrap(const FlexLayoutNodeRef node) {
    return node->props().flexWrap();
}

void TLNodeSetFlexLayoutPropsFlexWrap(const FlexLayoutNodeRef node,
                                      const enum TLFlexWrap flexWrap) {
    node->props().flexWrap(flexWrap);
}

const float TLNodeGetFlexLayoutPropsPaddingOfSide(const FlexLayoutNodeRef node, const enum TLSide side) {
    return node->props().padding(side);
}

void TLNodeSetFlexLayoutPropsPaddingOfSide(const FlexLayoutNodeRef node, const float padding, const enum TLSide side) {
    node->props().padding(padding, side);
}

const TLEdges TLNodeGetFlexLayoutPropsPadding(const FlexLayoutNodeRef node) {
    return node->props().padding();
}

void TLNodeSetFlexLayoutPropsPadding(const FlexLayoutNodeRef node, const TLEdges padding) {
    node->props().padding(padding);
}

const float TLNodeGetFlexLayoutPropsMainAxisSpacing(const FlexLayoutNodeRef node) {
    return node->props().mainAxisSpacing();
}

void TLNodeSetFlexLayoutPropsMainAxisSpacing(const FlexLayoutNodeRef node, const float mainAxisSpacing) {
    node->props().mainAxisSpacing() = mainAxisSpacing;
}

const float TLNodeGetFlexLayoutPropsCrossAxisSpacing(const FlexLayoutNodeRef node) {
    return node->props().crossAxisSpacing();
}

void TLNodeSetFlexLayoutPropsCrossAxisSpacing(const FlexLayoutNodeRef node, const float crossAxisSpacing) {
    node->props().crossAxisSpacing() = crossAxisSpacing;
}
