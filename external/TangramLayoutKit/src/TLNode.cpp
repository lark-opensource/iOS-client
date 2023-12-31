//
//  TLNode.cpp
//  TangramLayoutKit
//
//  Created by qihongye on 2021/4/4.
//

#include "TLNode.h"

using namespace TangramLayoutKit;
using namespace TangramLayoutKit::Log;

TLSize TLNodeCaculateMeansureImp(TLNodeRef node,
                                 const float containerWidth,
                                 const float containerHeight,
                                 LayoutContext& layoutContext,
                                 AnyClass context);

TLNode::TLNode(const TLNode& node) {
    _context = node._context;
    std::memcpy(_flags, node._flags, sizeof(node._flags));
    std::memcpy(_frame, node._frame, 4);
    _cachedAscent = node._cachedAscent;
    _options = node._options;
    _style = node._style;
    _layoutFn = node._layoutFn;
    _baselineFn = node._baselineFn;
    _children = {};
    if (_options) {
        _options->increaseGlobalNodeCounter();
    }
}

TLNode::TLNode(const TLNode& node, const TLNodeOptionsRef options) : TLNode{node} {
    _options = options;
    _flags[_hasOptions] = true;
}

TLNode::~TLNode() {
    if (_options) {
        _options->decreaseGlobalNodeCounter();
    }
}

const float TLNode::baseline(AnyClass context) {
    if (!hasBaselineFn()) {
        Log::Log(this, LogLevelWarning, "Call baseline() without BaselineFn.", nullptr);
        return _cachedAscent = height();
    }
    return _cachedAscent = getBaselineFn()(this, width(), height(), context);
}

const bool TLNode::removeChild(const TLNodeRef node) {
    auto p = std::find(_children.begin(), _children.end(), node);
    if (p != _children.end()) {
        _children.erase(p);
        return true;
    }
    return false;
}

const TLNodeRef TLNode::getChild(const size_t index) const {
    return _children.at(index);
}

void TLNode::removeAllChildren() {
    _children.clear();
    _children.shrink_to_fit();
}

const TLRect TLNode::getFrame() const {
    return TLRect{
        {_frame[TLAxisX], _frame[TLAxisY]},
        {_frame[TLAxisWidth], _frame[TLAxisHeight]}
    };
}

void TLNode::setFrame(const TLRect frame) {
    _frame[TLAxisX] = frame.origin.x;
    _frame[TLAxisY] = frame.origin.y;
    _frame[TLAxisWidth] = frame.size.width;
    _frame[TLAxisHeight] = frame.size.height;
}

float& TLNode::x() {
    return _frame[TLAxisX];
}

float& TLNode::y() {
    return _frame[TLAxisY];
}

float& TLNode::width() {
    return _frame[TLAxisWidth];
}

float& TLNode::height() {
    return _frame[TLAxisHeight];
}

void TLNode::setBaselineFn(BaselineFn baselineFn) {
    if (hasChildren()) {
        return;
    }
    _baselineFn = baselineFn;
    _flags[_hasBaselineFn] = _baselineFn != nullptr;
}

void TLNode::setLayoutFn(LayoutFn layoutFn) {
    if (hasChildren()) {
        return;
    }
    _layoutFn = layoutFn;
    _flags[_hasLayoutFn] = _layoutFn != nullptr;
}

TLSize TLNode::caculateMeansure(const float containerWidth,
                                const float containerHeight,
                                LayoutContext& layoutContext,
                                AnyClass context) {
    if (isDisplayNone()) {
        return {0, 0};
    }
    // if not dirty, then return the cache size; default is true
    if (!isDirty()) {
        return {width(), height()};
    }
    TangramLayoutKit::Log::Log(this, LogLevelInfo,
                               "TLNode::caculateMeansure(reason: %s, containerSize: {%f, %f})\n",
                               layoutContext.debugReason(),
                               containerWidth, containerHeight);

    auto size = TLNodeCaculateMeansureImp(this,
                                          containerWidth,
                                          containerHeight,
                                          layoutContext,
                                          context);
    return size;
}

void TLNode::caculateLayout(LayoutContext& layoutContext, AnyClass context) {
    if (isDisplayNone()) {
        return;
    }
    TangramLayoutKit::Log::Log(this, LogLevelInfo,
                               "TLNode::caculateLayout(reason: %s)\n",
                               layoutContext.debugReason());
    float x = 0;
    for (auto child : getChildren()) {
        child->setPosition(TLOrigin{x, 0});
        x += child->width();
        child->caculateLayout(layoutContext, context);
    }
}

void TLNode::setPosition(const TLOrigin origin) {
    _frame[TLAxisX] = origin.x;
    _frame[TLAxisY] = origin.y;
}

TLSize TLNodeCaculateMeansureImp(TLNodeRef node,
                                 const float containerWidth,
                                 const float containerHeight,
                                 LayoutContext& layoutContext,
                                 AnyClass context) {
    float actualWidth, actualHeight;
    TLLayoutMode actualWidthMode, actualHeightMode;

    TLFixActualSize(node,
                    containerWidth,
                    containerHeight,
                    actualWidth,
                    actualWidthMode,
                    actualHeight,
                    actualHeightMode);
    float actualContainerWidth = actualWidth, actualContainerHeight = actualHeight;

    // replace width/height which is not exactly by LayoutFunc size
    if (node->hasLayoutFn()) {
        auto actualSize = node->getLayoutFn()(node,
                                              actualWidth, actualWidthMode,
                                              actualHeight, actualHeightMode,
                                              context);
        if (actualWidthMode != TLLayoutModeExactly) {
            actualWidth = actualSize.width;
            actualWidthMode = TLLayoutModeExactly;
        }
        if (actualHeightMode != TLLayoutModeExactly) {
            actualHeight = actualSize.height;
            actualHeightMode = TLLayoutModeExactly;
        }
    }
    // trigger children caculateMeansure, and fix width/height which is not exactly
    if (node->hasChildren()) {
        float maxW = 0;
        float maxH = 0;
        for (auto child : node->getChildren()) {
            auto size = child->caculateMeansure(actualWidth,
                                                actualHeight,
                                                layoutContext,
                                                context);
            // fmax will always return exactly value even if there is a `nan`
            maxW = fmax(maxW, size.width);
            maxH = fmax(maxH, size.height);
        }
        if (actualWidthMode != TLLayoutModeExactly) {
            actualWidth = maxW;
            actualWidthMode = TLLayoutModeExactly;
        }
        if (actualHeightMode != TLLayoutModeExactly) {
            actualHeight = maxH;
            actualHeightMode = TLLayoutModeExactly;
        }
    }
    const float aspectRatio = node->getStyle().aspectRatio();
    if (aspectRatio > 0 && actualWidthMode == TLLayoutModeExactly && actualHeightMode != TLLayoutModeExactly) {
        actualHeight = actualWidth / aspectRatio;
        actualHeightMode = TLLayoutModeExactly;
    } else if (aspectRatio > 0 && actualWidthMode != TLLayoutModeExactly && actualHeightMode == TLLayoutModeExactly) {
        actualWidth = actualHeight * aspectRatio;
        actualWidthMode = TLLayoutModeExactly;
    }

    TLFixSizeByMaxAndMin(actualWidth,
                         actualHeight,
                         node,
                         actualContainerWidth,
                         actualContainerHeight);
    TLSetWidthAndMode(node, actualWidth, actualWidthMode);
    TLSetHeightAndMode(node, actualHeight, actualHeightMode);
    // default fix width/height to 0 which is undefined
    TLFixSizeWithoutUndefined(node);
    return TLNodeGetFrame(node).size;
}
