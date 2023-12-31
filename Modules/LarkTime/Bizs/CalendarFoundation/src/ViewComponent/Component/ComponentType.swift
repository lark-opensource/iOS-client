//
//  ComponentType.swift
//  ComponentDemo
//
//  Created by Rico on 2021/9/15.
//

import Foundation
import UIKit

public protocol ComponentLifeCycle {

    func componentDidMount()

    func componentDidUnMount()

    func viewDidLoad()

    func viewWillAppear()

    func viewDidAppear()

    func viewDidLayoutSubviews()

    func viewWillDisappear()

    func viewDidDisAppear()
}

extension ComponentLifeCycle {
    func componentDidMount() {}
    func componentDidUnMount() {}
    func viewWillAppear() {}
    func viewDidAppear() {}
    func viewDidLayoutSubviews() {}
    func viewWillDisappear() {}
    func viewDidDisAppear() {}
}

/*
 代表一个独立的Component部分，对View做管理、有独立逻辑部分，可以持有ViewModel、View。

 1. 有一个根View，类似Viewcontroller.view
 2. 可以获取到所属的ViewController
 3. 具备component的生命周期
 */

public protocol ComponentType: AnyObject, ComponentLifeCycle {

    var view: UIView { get }

    var viewLoaded: Bool { get }

    var viewController: UIViewController! { get set }

}
