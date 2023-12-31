//
//  OPCountDetector.swift
//  OPFoundation
//
//  Created by 尹清正 on 2021/3/19.
//

import Foundation
import ECOInfra
import LKCommonsLogging

fileprivate let logger = Logger.oplog(OPCountDetector.self, category: "performanceMonitor")

@objcMembers
public final class OPCountDetector: NSObject {

    /// singleton
    public static let shared = OPCountDetector()
    private override init() {}

    /// 用于上传对象数量超限事件的上传器
    private let uploader = OPMemoryInfoUploader(with: .objectOvercount)

    /// 存储各个类型对象实例的弱引用
    private var objectStorage: [String: [WeakReference<OPMemoryMonitoredObjectType>]] = [:]

    /// 记录每个类型是否已经发生过了overcount告警
    private var objectOvercounted: [String: Bool] = [:]

    /// 线程安全锁
    private var semaphore = DispatchSemaphore(value: 1)

    /// 某个类型对象被初始化
    func notifyInitWith(object: OPMemoryMonitoredObjectType) {
        // 是否实现了overcount属性，如果没有实现就无法接入数量检测机制
        guard let overcountNumber = type(of: object).overcountNumber else {
            logger.info("object without overcountNumber implementation connect to OPCountDetect")
            return
        }

        logger.info("notify init with object: \(object)")

        let typeIdentifier = type(of: object).typeIdentifier
        semaphore.wait()
        defer { semaphore.signal() }

        var objectList = objectStorage[typeIdentifier] ?? []
        objectList.removeAll { $0.value == nil }

        if !objectList.contains(where: {
            guard let oldObject = $0.value else { return false }
            return oldObject == object
        }) {
            objectList.append(.init(value: object))
        }

        objectStorage[typeIdentifier] = objectList

        // 检查是否超出指定的最大数量
        if objectList.count > overcountNumber {
            // 日志
            logger.warn("the number of \(typeIdentifier) object has overcounted!")
            // 执行第一次超限才会执行的逻辑
            let overcounted = objectOvercounted[typeIdentifier] ?? false
            if !overcounted {
                objectOvercounted[typeIdentifier] = true
                execActionWhenFirstOvercount(object)
            }
        }
    }

    /// 获取任意一个类型当前所有的对象实例
    public func getCurrentObjectsWith(typeIdentifier: String) -> [WeakReference<OPMemoryMonitoredObjectType>] {
        var objectList = objectStorage[typeIdentifier] ?? []

        // 去除已经被释放掉的
        objectList.removeAll { $0.value == nil }

        return objectList
    }

    /// 某个类型对象第一次发生数量超限之后要执行的操作
    private func execActionWhenFirstOvercount(_ target: NSObject) {
        // 埋点上报
        uploader.uploadLeakInfo(with: target)
        // 如果在Debug模式下就针对此次泄漏弹窗提示
        #if DEBUG
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Object Overcounted!", message: "Object: \(target) leads the excess of limited number", preferredStyle: .alert)
            let action = UIAlertAction(title: "Confirm", style: .cancel)
            alertController.addAction(action)
            OPWindowHelper.fincMainSceneWindow()?.rootViewController?.present(alertController, animated: true)
        }
        #endif
    }
}
