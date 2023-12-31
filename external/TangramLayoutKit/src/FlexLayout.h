//
//  FlexLayout.h
//  TangramLayoutKit
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
#include "BaseLayout.h"

struct TL_EXPORT FlexLayoutProps: BaseLayoutProps {
private:
    static constexpr size_t _flexWrap = 0;
    uint8_t _flags[1] = {TLFlexWrapNoWrap};

public:
    const TLFlexWrap flexWrap() const { return (TLFlexWrap)_flags[_flexWrap]; }
    void flexWrap(const TLFlexWrap flexWrap) { _flags[_flexWrap] = flexWrap; }
};

struct TL_EXPORT FlexLayoutNode: TLNode {
private:
    FlexLayoutProps _props = {};
public:
    explicit FlexLayoutNode(const FlexLayoutProps props,
                            const TLStyle style,
                            const TLNodeOptionsRef options)
    : TLNode{options}, _props{props} {
        setStyle(style);
    };

    explicit FlexLayoutNode(const FlexLayoutProps props,
                            const TLNodeOptionsRef options)
        : TLNode{options}, _props{props} {};

    explicit FlexLayoutNode(const FlexLayoutProps props)
        : TLNode{TLGetDefaultOptions()}, _props{props} {};

    explicit FlexLayoutNode(const TLNodeOptionsRef options)
        : TLNode{options} {};

    explicit FlexLayoutNode() : TLNode{TLGetDefaultOptions()} {};

    ~FlexLayoutNode() = default;

    FlexLayoutProps& props() { return _props; }

    TLSize caculateMeansure(const float, const float, LayoutContext&, AnyClass) override;
    void caculateLayout(LayoutContext&, AnyClass) override;
};
