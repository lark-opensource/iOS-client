//
//  BaseComponent.swift
//  ComponentDemo
//
//  Created by Rico on 2021/9/15.
//

import Foundation
import UIKit
import LarkContainer

/*
 Component的基类

 1. 自带创建View
 2. 提供ViewController的获取
 */

open class Component: ComponentType {

    open func viewDidLoad() {
        viewLoaded = true
    }

    open func componentDidMount() {}
    open func componentDidUnMount() {}
    open func viewWillAppear() {}
    open func viewDidAppear() {}
    open func viewWillDisappear() {}
    open func viewDidDisAppear() {}
    open func viewDidLayoutSubviews() {}

    private weak var _viewController: UIViewController?
    public var viewLoaded: Bool = false

    public weak var viewController: UIViewController! {
        get {
            guard let vc = self._viewController else {
                assertionFailure("component must have a related viewController")
                return UIViewController()
            }
            return vc
        }
        set {
            self._viewController = newValue
        }
    }

    public var view: UIView

    public init() {
        view = UIView()
    }
}

open class UserContainerComponent: Component, UserResolverWrapper {

    public let userResolver: UserResolver

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init()
    }

}
