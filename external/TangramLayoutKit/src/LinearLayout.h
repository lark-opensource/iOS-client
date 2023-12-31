//
//  LinearLayout.h
//  TangramLayoutKit
//
//  Created by qihongye on 2021/4/5.
//

#pragma once

#include <stdio.h>
#include "Macros.h"
#include "TLNode.h"
#include "Types.h"
#include "public.h"
#include "Style.h"
#include "BaseLayout.h"

struct TL_EXPORT LinearLayoutProps: BaseLayoutProps {
private:
    float _wrapWidth = 0;

public:
    const bool hasWrapWidth() const { return _wrapWidth > 0 && !isUndefined(_wrapWidth); }
    float wrapWidth() const { return _wrapWidth; }
    float& wrapWidth() { return _wrapWidth; }
    // 对于Linear来说，主轴辅轴spacing一样，取主轴即可
    const bool hasSpacing() const { return hasMainAxisSpacing(); }
    float spacing() const { return mainAxisSpacing(); }
};

struct TL_EXPORT LinearLayoutNode: TLNode {
private:
    LinearLayoutProps _props = {};
public:
    explicit LinearLayoutNode(const LinearLayoutProps props,
                              const TLStyle style,
                              const TLNodeOptionsRef options)
        : TLNode{options}, _props{props} {
            setStyle(style);
        };

    explicit LinearLayoutNode(const LinearLayoutProps props,
                              const TLNodeOptionsRef options)
        : TLNode{options}, _props{props} {};

    explicit LinearLayoutNode(const LinearLayoutProps props)
        : TLNode{TLGetDefaultOptions()}, _props{props} {};

    explicit LinearLayoutNode(const TLNodeOptionsRef options)
        : TLNode{options} {};

    explicit LinearLayoutNode() : TLNode{TLGetDefaultOptions()} {};

    ~LinearLayoutNode() = default;

    LinearLayoutProps& props() { return _props; }

    const bool isMatchWrapWidth(const float) const;

    TLSize caculateMeansure(const float, const float, LayoutContext&, AnyClass) override;
    void caculateLayout(LayoutContext&, AnyClass) override;

    const bool needReverseChildren() const;
};

TL_EXPORT
const LinearLayoutProps TLLinearLayoutNodeGetProps(const LinearLayoutNodeRef);
