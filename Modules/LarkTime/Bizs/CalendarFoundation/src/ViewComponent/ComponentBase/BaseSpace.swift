//
//  BaseSpace.swift
//  ComponentDemo
//
//  Created by Rico on 2021/9/15.
//

import Foundation
import UIKit

open class BaseSpace<M: ComponentManagerType, L: LayoutEngineType>: ViewSpaceType {

    public typealias ViewSharableKey = L.ViewSharableKey

    public var manager: M
    public var layoutEngine: L

    public weak var viewController: UIViewController?

    open func loadComponents() {
        assertionFailure("\(#function) method need override")
    }

    public init(manager: M, layoutEngine: L, viewController: UIViewController) {
        self.manager = manager
        self.layoutEngine = layoutEngine
        self.viewController = viewController
    }
}
