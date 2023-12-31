//
//  BadgeObservable.swift
//  LarkBadge
//
//  Created by KT on 2019/4/18.
//

import UIKit
import Foundation
import ThreadSafeDataStructure

private var badgeControllerKey: Void?

extension Badge: BadgeObservable where Base: BadgeAddable {

    // 监听路径
    public func observe(for path: Path, onChanged: OnChanged<ObserverNode, BadgeNode>? = nil) {
        guard enable(path: path) else { return }
        self._badgeController.addObserver(path.nodeNames, onChanged: onChanged, primiry: true)
    }

    // 自身是ABC的路径， 同时监测PQM的路径
    public func combine(to targetPath: Path) {
        guard let viewPath = self._badgeController.viewPath else {
            assert(false, "Call `observePath` first")
            return
        }
        self._badgeController.addObserver(targetPath.nodeNames)

        ObserveTrie.combine(targetPath: targetPath.nodeNames, viewPath: viewPath)
    }

    public func removeObserver(of path: Path) {
        self._badgeController.removeObserver(path.nodeNames)
    }

    // 移除View绑定的所有观察者
    public func removeAllObserver() {
        self._badgeController._unObserveAll()
    }

    // 当前View监听的路径(先调用observePath后获取)
    public var viewPath: [NodeName]? {
        return self._badgeController.viewPath
    }

    // 本地初始化配置信息
    var initialInfo: NodeInfo {
        get { return self._badgeController.locoalInfo }
        set { self._badgeController.locoalInfo = newValue }
    }

    private var _badgeController: BadgeController {
        get {
            guard let observed = objc_getAssociatedObject(base, &badgeControllerKey) as? BadgeController else {
                let newObserved = BadgeController(base)
                self._badgeController = newObserved
                return newObserved
            }
            return observed
        }
        set {
            objc_setAssociatedObject(base,
                                     &badgeControllerKey,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 判断路径是否合法
    ///
    /// - Parameter path: Path
    /// - Returns: 是否合法
    private func enable(path: Path) -> Bool {
        #if DEBUG
        guard let dependancy = BadgeManager.shared.dependancy else {
            assert(false, "未设置外部依赖 - BadgeManager.setDependancy(_:)")
            return false
        }

        loop: for node in path.nodeNames {
            if dependancy.whiteLists.contains(node) { continue loop }
            for prefix in dependancy.prefixWhiteLists {
                if node.hasPrefix(prefix) { continue loop }
            }
            assert(false, "\(node) 不是有效节点名称 - BadgeManager.shared.dependancy?.whiteLists")
            return false
        }
        return true
        #else
        return true
        #endif
    }
}

// 利用class的生命周期，自动释放observer对象
final class BadgeController: Equatable {
    /// weak 持有 target
    weak var target: BadgeAddable?
    /// 被观察者内存储了观察者，用于判断重复、deinit时移除observer
    var observers: SafeArray<Observer> = [] + .recursiveLock
    /// 本地样式配置
    var locoalInfo: NodeInfo = NodeInfo(.none)

    var viewPath: [NodeName]? {
        return self.observers.first { $0.primiry }?.path
    }

    // MARK: - life cycle
    required init(_ observer: BadgeAddable) {
        self.target = observer
        self.locoalInfo.configPriorty = .initial
    }

    deinit { _unObserveAll() }

    // MARK: - add
    func addObserver(_ path: [NodeName], onChanged: OnChanged<ObserverNode, BadgeNode>? = nil, primiry: Bool = false) {
        let observer = Observer(path, controller: self, primiry: primiry, callback: onChanged)
        self.addObserver(observer)
    }

    func addObserver(_ observer: Observer) {
        guard !observers.contains(observer) else { return }
        observers.append(observer)
        guard let path = observer.primiry ? observer.path : viewPath else { return }
        ObserveTrie.addObserve(path, with: observer)
    }

    // MARK: - remove
    func removeObserver(_ path: [NodeName]) {
        let observer = Observer(path, controller: self)
        self.removeObserver(observer)
    }

     func removeObserver(_ observer: Observer) {
        guard observers.contains(observer) else { return }
        ObserveTrie.removeObserve(observer.path, with: observer)
    }

    // remove all by deinit()
    fileprivate func _unObserveAll() {
        observers.forEach { removeObserver($0) }
        observers.removeAll()
    }

    static func == (lhs: BadgeController, rhs: BadgeController) -> Bool {
        return lhs.target as? UIView == rhs.target as? UIView
    }
}
