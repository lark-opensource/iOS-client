//
//  ComponentSpace.swift
//  DetailDemo
//
//  Created by Rico on 2021/3/14.
//

import Foundation
import UIKit

/*
 代表一组Components所属域，作为一个整体单位和上层VC交互，内部可以有自己的事件分发、生命周期等。

 1. 持有space域的context
 2. 持有Manager
 3. 持有LayoutEngine
 4. 是VC操纵Components的入口，对VC封装
 */

public protocol ViewSpaceType: AnyObject {

    associatedtype Manager: ComponentManagerType
    associatedtype LayoutEngine: LayoutEngineType
    associatedtype ViewSharableKey where ViewSharableKey == LayoutEngine.ViewSharableKey

    var manager: Manager { get }
    var layoutEngine: LayoutEngine { get }

    /// 决议RootView， 内部会触发所有Component的view加载方法（viewDidLoad）
    func resolveRootView(_ view: UIView)

    func loadComponents()
}

extension ViewSpaceType {

    public func resolveRootView(_ view: UIView) {
        resolveRootView(view, dispatchViewLoad: true)
    }

    public func resolveRootView(_ view: UIView, dispatchViewLoad: Bool) {
        layoutEngine.resolveRootView(view, on: manager.components.map { $0.view })
        if dispatchViewLoad {
            manager.dispatchLifeCycle(.viewLoad)
        }
    }

    public func view(for key: ViewSharableKey) -> UIView? {
        layoutEngine.view(for: key, in: manager.components)
    }
}
