//
//  ComponentManager.swift
//  ComponentDemo
//
//  Created by Rico on 2021/9/15.
//

import Foundation
import UIKit

public enum ComponentLifeCycleStage {
    case mount
    case viewLoad
    case willAppear
    case didAppear
    case didLayoutSubviews
    case willDisappear
    case didDisappear
    case unMount
}

/*
 专门用来管理Components，分发Components的生命周期等事件

 1. 提供当前components数组
 2. 分发生命周期事件
 */

public protocol ComponentManagerType {

    var components: [ComponentType] { get }

    func dispatchLifeCycle(_ cycleStage: ComponentLifeCycleStage)
}

extension ComponentManagerType {

    public func dispatchLifeCycle(_ cycleStage: ComponentLifeCycleStage) {
        components.forEach { (component) in
            switch cycleStage {
            case .mount: component.componentDidMount()
            case .viewLoad: if !component.viewLoaded { component.viewDidLoad() }
            case .willAppear: component.viewWillAppear()
            case .didAppear: component.viewDidAppear()
            case .didLayoutSubviews: component.viewDidLayoutSubviews()
            case .willDisappear: component.viewWillDisappear()
            case .didDisappear: component.viewDidDisAppear()
            case .unMount: component.componentDidUnMount()
            }
        }
    }
}
