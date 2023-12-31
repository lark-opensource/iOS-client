//
//  LayoutEngine.swift
//  DetailDemo
//
//  Created by Rico on 2021/3/14.
//

import Foundation
import UIKit

/*
 用来管理一个Space下的视图布局、View获取等

 1. 保存RootView
 2. 对外提供view的获取方式
 3. 布局Component之间的约束
 */

public protocol LayoutEngineType: AnyObject {

    associatedtype ViewSharableKey: Hashable

    var rootView: UIView? { get set }

    func view(for key: ViewSharableKey, in components: [ComponentType]) -> UIView?

    func layout(with views: [UIView])

    func resolveRootView(_ rootView: UIView?, on componentsView: [UIView])

}

extension LayoutEngineType {

    public func resolveRootView(_ rootView: UIView?, on componentsView: [UIView]) {
        guard let rootView = rootView else {
            assertionFailure("Could not get root view")
            return
        }
        self.rootView = rootView
        componentsView.forEach {
            $0.removeFromSuperview()
            rootView.addSubview($0)
        }
        layout(with: componentsView)
    }
}
