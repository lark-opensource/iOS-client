//
//  BaseLayoutEngine.swift
//  ComponentDemo
//
//  Created by Rico on 2021/9/15.
//

import Foundation
import UIKit

open class BaseLayoutEngine<ViewSharableKey: Hashable>: LayoutEngineType {

    open func view(for key: ViewSharableKey, in components: [ComponentType]) -> UIView? {
        assertionFailure("must be override")
        return nil
    }

    public var rootView: UIView?

    open func layout(with views: [UIView]) {
        assertionFailure("layout must be override")
    }

    public init() { }
}
