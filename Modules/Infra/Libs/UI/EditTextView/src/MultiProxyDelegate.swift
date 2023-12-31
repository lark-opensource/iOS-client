//
//  MultiProxyDelegate.swift
//  EditTextView
//
//  Created by zc09v on 2020/7/2.
//

import Foundation

protocol MultiProxyDelegate where Self: BaseMultiProxyDelegate {
    //指定要转发的目标delegate类型
    associatedtype D
    //添加一个新的代理
    func add(delegate: D)
    //获取目前已有的所有代理
    var delegates: [D] { get }
}

extension MultiProxyDelegate {
    var delegates: [D] {
        return self.unsafeDelegates().allObjects.compactMap { (object) -> D? in
            object as? D
        }
    }

    func add(delegate: D) {
        self.unsafeAdd(delegate)
    }
}
