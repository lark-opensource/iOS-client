//
//  LoadingComponent.swift
//  TangramUIComponent
//
//  Created by 袁平 on 2022/3/28.
//

import Foundation
import TangramComponent
import UniverseDesignColor
import UniverseDesignLoading
import UIKit

// https://bytedance.feishu.cn/docx/doxcnHZibKQvfabHiC7MkgzrUsg
public final class LoadingComponentProps: Props {
    public var size: CGFloat = 16
    public var color: UIColor = UIColor.ud.primaryContentDefault

    public init() {}

    public func clone() -> LoadingComponentProps {
        let clone = LoadingComponentProps()
        clone.size = size
        clone.color = color.copy() as? UIColor ?? UIColor.ud.primaryContentDefault
        return clone
    }

    public func equalTo(_ old: Props) -> Bool {
        guard let old = old as? LoadingComponentProps else { return false }
        return old.size == size &&
        old.color == color
    }
}

public final class LoadingComponent<C: Context>: RenderComponent<LoadingComponentProps, UDSpin, C> {
    public override var isSelfSizing: Bool {
        return true
    }

    public override func create(_ rect: CGRect) -> UDSpin {
        let view = UDSpin(config: .init(indicatorConfig: .init(size: props.size, color: props.color), textLabelConfig: nil))
        view.frame = rect
        return view
    }

    public override func update(_ view: UDSpin) {
        super.update(view)
        view.update(config: .init(indicatorConfig: .init(size: props.size, color: props.color), textLabelConfig: nil))
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        // Loading组件允许只配置width或height，因此需要通过sizeToFit算大小
        return .init(width: props.size, height: props.size)
    }
}
