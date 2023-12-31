//
//  ObjectDeinitObserver.swift
//  ByteView
//
//  Created by kiri on 2021/5/11.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

#if DEBUG
final class ObjectDeinitObserver {
    @RwAtomic
    static var observers: [WeakRef<ObjectDeinitObserver>] = []
    private static var key: UInt8 = 1
    private let logInfo: LogInfo
    private let tag: Tag
    private init(_ logInfo: LogInfo, tag: Tag = .normal) {
        self.logInfo = logInfo
        self.tag = tag
    }

    static func observe(_ object: Any, logDescription: String? = nil,
                        file: String = #fileID, function: String = #function, line: Int = #line) {
        guard Mirror.init(reflecting: object).displayStyle == .some(.class) else {
            return
        }
        let desc = logDescription ?? "\(object)"
        let logInfo = LogInfo(desc: desc, file: file, function: function, line: line)
        logInfo.log("start")
        let value: ObjectDeinitObserver
        if let view = object as? UIView {
            value = ObjectDeinitObserver(logInfo, tag: .root)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak value, weak view] in
                if let v = view, let observer = value {
                    observer.observeSubviews(v, parent: observer)
                }
            }
        } else if let vc = object as? UIViewController {
            value = ObjectDeinitObserver(logInfo, tag: .root)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak value, weak vc] in
                if let vc = vc, let observer = value {
                    observer.observeSubviews(vc, parent: observer)
                }
            }
        } else {
            value = ObjectDeinitObserver(logInfo)
        }
        objc_setAssociatedObject(object, &ObjectDeinitObserver.key, value, .OBJC_ASSOCIATION_RETAIN)

        observers.removeAll(where: { $0.ref == nil })
        observers.append(.init(value))
    }

    static func dumpExistObjects(_ msg: String = "dump") {
        observers.compactMap { $0.ref?.logInfo }.forEach { (info) in
            info.log(msg)
        }
    }

    deinit {
        switch tag {
        case .root:
            logInfo.log("deinit")
            let children = self.children
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
                children.filter { $0.ref != nil && $0.ref?.parent == nil }
                    .forEach { $0.ref?.logInfo.log("dump child") }
            }
        case .normal:
            logInfo.log("deinit")
        default:
            break
        }
    }

    private struct LogInfo {
        let desc: String
        let file: String
        let function: String
        let line: Int

        func log(_ message: String) {
            Logger.debug.info("[observed] \(message): \(desc)", file: file, function: function, line: line)
        }

        func dup(_ desc: String) -> LogInfo {
            LogInfo(desc: desc, file: file, function: function, line: line)
        }
    }

    private weak var parent: ObjectDeinitObserver?
    private static var childKey: UInt8 = 2
    private var children: [WeakRef<ObjectDeinitObserver>] = []

    private func observeSubviews(_ view: UIView, parent: ObjectDeinitObserver) {
        observeSubviews(view, prefix: typeDescription(of: view), parent: parent)
    }

    private func observeSubviews(_ vc: UIViewController, parent: ObjectDeinitObserver) {
        if let v = vc.view {
            var vcMap: [UIView: UIViewController] = [v: vc]
            findChildVcs(vc, result: &vcMap)
            observeSubviews(v, prefix: typeDescription(of: vc), parent: parent, vcMap: vcMap)
        }
    }

    private func observeSubviews(_ view: UIView, prefix: String, parent: ObjectDeinitObserver,
                                 vcMap: [UIView: UIViewController] = [:]) {
        if view.superview == nil {
            logInfo.log("superview is nil.")
        }
        for (i, v) in view.subviews.enumerated() {
            let childPrefix: String
            let index: String
            if let key = v.accessibilityLabel, !key.isEmpty {
                index = key
            } else if let key = v.accessibilityIdentifier, !key.isEmpty {
                index = key
            } else if v.tag != 0 {
                index = "tag(\(v.tag))"
            } else {
                index = "\(i)"
            }
            let attachObj: Any
            if let vc = vcMap[v] {
                childPrefix = "\(prefix) > \(typeDescription(of: vc)):\(index)"
                attachObj = vc
            } else {
                childPrefix = "\(prefix) > \(typeDescription(of: v)):\(index)"
                attachObj = v
            }
            let logInfo = self.logInfo.dup("\(childPrefix), \(v)")
            let child = ObjectDeinitObserver(logInfo, tag: .child)
            child.parent = parent
            objc_setAssociatedObject(attachObj, &ObjectDeinitObserver.childKey, child, .OBJC_ASSOCIATION_RETAIN)
            children.append(.init(child))
            observeSubviews(v, prefix: childPrefix, parent: child, vcMap: vcMap)
        }
    }

    private func findChildVcs(_ vc: UIViewController, result: inout [UIView: UIViewController]) {
        vc.children.forEach { (child) in
            if let v = child.view {
                result[v] = child
            }
            findChildVcs(child, result: &result)
        }
    }

    private enum Tag: Hashable {
        case normal
        case root
        case child
    }
}
#endif
