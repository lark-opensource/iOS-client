//
//  ListConfig.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/7/29.
//

import Foundation
import SwiftyJSON
import SKInfra

public protocol ListConfigAPI {
    func excuteWhenSpaceAppearIfNeeded(needAdd: Bool, block: @escaping (() -> Void))
    func excuteAllDelayedBlocks()
    func clearDelayedBlocks()
}
public final class ListConfig {
    public static var requestTimeOut: Int {
        var timeout = 15
        if let timeoutLo = SettingConfig.listRequestTimeout, timeoutLo > 0 {
            timeout = timeoutLo
        }
        return timeout
    }

    private var delayedBlocks: [(() -> Void)] = []
    private let lock = NSLock()

}

extension ListConfig: ListConfigAPI {

    public static var needDelayLoadListData: Bool {
        return true
    }

    private static let lock = NSLock()

    public static var needDelayLoadDB: Bool {
        // 单品内不延迟加载列表数据
        if DocsSDK.isInLarkDocsApp { return false }
        return true
    }

    public func excuteWhenSpaceAppearIfNeeded(needAdd: Bool = true, block: @escaping (() -> Void)) {
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        let dbLoaded = dataCenterAPI?.hadLoadDBForCurrentUser ?? true
        if !ListConfig.needDelayLoadDB || dbLoaded {
            block()
        } else if needAdd {
            lock.lock()
            delayedBlocks.append(block)
            lock.unlock()
        }
    }


    public func excuteAllDelayedBlocks() {
        guard ListConfig.needDelayLoadDB else { return }
        lock.lock(); defer { lock.unlock() }
        while !delayedBlocks.isEmpty {
            let block = delayedBlocks.removeFirst()
            block()
        }
        DispatchQueue.main.async {
            let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
            dataCenterAPI?.notifyStartExecuteDelayBlock()
        }
    }

    public func clearDelayedBlocks() {
        guard ListConfig.needDelayLoadDB else { return }
        lock.lock(); defer { lock.unlock() }
        delayedBlocks.removeAll()
    }

}


public enum ThumbnailUrlConfig {

    /// 列表页滑动的时候，为了避免同一个url短时间内重复拉多次，加个时间间隔控制一下，单位: 秒
    static var updateCheckTimeinterval: TimeInterval {
        300
    }

    /// 图片下载尺寸选择逻辑
    static var sizePolicy: Int {
        1
    }
    
    public static func add(_ imgSize: CGSize, to params: [String: Any]) -> [String: Any] {
        let extraParams = thumbnailParams(size: imgSize)
        return params.merging(extraParams, uniquingKeysWith: { $1 })
    }

    public static func thumbnailParams(size: CGSize) -> [String: Any] {
        return [
            "thumbnail_width": Int(size.width),
            "thumbnail_height": Int(size.height),
            "thumbnail_policy": sizePolicy
        ]
    }

}
