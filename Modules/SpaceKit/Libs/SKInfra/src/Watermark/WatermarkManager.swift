//
//  WatermarkManager.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/4/11.
//  

import SKFoundation
import SwiftyJSON

/// 监听水印请求回调
public protocol WatermarkUpdateListener: AnyObject {
    /// 水印更新数据
    func didUpdateWatermarkEnable()
}

public struct WatermarkKey: Codable, Hashable {
    let objToken: String
    let type: Int

    public init(objToken: String, type: Int) {
        self.objToken = objToken
        self.type = type
    }
}

extension WatermarkKey: DocsParamConvertible {
    public var params: Params {
        return ["obj_type": type, "obj_token": objToken]
    }
}

public final class WatermarkManager: NSObject {
    private let path: SKFilePath = {
        let rootPath = SKFilePath.globalSandboxWithLibrary.appendingRelativePath("WaterMark")
        let resultPath = rootPath.appendingRelativePath("config.json")
        do {
            try rootPath.createDirectory(withIntermediateDirectories: true)
            _ = resultPath.createFileIfNeeded(with: nil)
        } catch let error {
            DocsLogger.error("[SKFilePath] create directory for cache fail", extraInfo: ["dest": rootPath], error: error, component: nil)
        }

        return resultPath
    }()

    private var configs = ThreadSafeDictionary<WatermarkKey, Bool>()
    var listeners: ObserverContainer = ObserverContainer<WatermarkUpdateListener>()

    public static let shared: WatermarkManager = {
//        spaceAssert(Thread.isMainThread)
        let manger = WatermarkManager()
        do {
            let data = try Data.read(from: manger.path)
            manger.configs.safeDict = try JSONDecoder().decode([WatermarkKey: Bool].self, from: data)
        } catch {
            DocsLogger.info("[SKFilePath] get data fail", component: LogComponents.watermark)
        }
        return manger
    }()

    public func shouldShowWatermarkFor(_ key: WatermarkKey) -> Bool {
        spaceAssert(Thread.isMainThread)
        #if DEBUG
        if key.objToken == "doccnfa1wzNtvMqBiNnYHtnf8Yc" {
            return false
        } else if key.objToken == "doccnC2HcqAukcHmU2SI5l9ZPld" {
            return true
        }
        #endif
        return configs.value(ofKey: key) ?? true
    }

    private func setShouldShowWatermarkFor(_ key: WatermarkKey) {
        spaceAssert(Thread.isMainThread)
        configs.updateValue(true, forKey: key)
        trySave()
    }

    private func setShouldHideWatermarkFor(_ key: WatermarkKey) {
        spaceAssert(Thread.isMainThread)
        configs.updateValue(false, forKey: key)
        trySave()
    }

    public func requestWatermarkInfo(_ key: WatermarkKey) {
        DocsRequest<JSON>(path: OpenAPI.API.getDocsConfig, paramConvertible: key).set(method: .GET)
            .makeSelfReferenced().start { (json, error) in
                guard error == nil else {
                    let errmsg: String = {
                        let nsErr = error! as NSError
                        return "\(nsErr.code):\(nsErr.domain)"
                    }()
                    DocsLogger.error("get watermark info Error: \(errmsg)", component: LogComponents.watermark)
                    return
                }
                json.map {
                    let enableWatermark = $0["data"]["enable_watermark"].boolValue
                    if enableWatermark {
                        WatermarkManager.shared.setShouldShowWatermarkFor(key)
                    } else {
                        WatermarkManager.shared.setShouldHideWatermarkFor(key)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) {
                        self.notifyWatermarkUpdate()
                    }
                }
            }
    }
    
    private func notifyWatermarkUpdate() {
        listeners.all.forEach { $0.didUpdateWatermarkEnable() }
    }
    
    private func trySave() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(save), object: nil)
        self.perform(#selector(save), with: nil, afterDelay: 10)
    }

    @objc
    private func save() {
        DispatchQueue.global().async {
            let data = try? JSONEncoder().encode(self.configs.all())
            do {
                try data?.write(to: self.path)
                DocsLogger.info("[SKFilePath] save Watermark config to cache success.")
            } catch {
                DocsLogger.error("[SKFilePath] save Watermark config to cache failed.")
            }
        }
    }
}

extension WatermarkManager {
    public func addListener(_ listener: WatermarkUpdateListener) {
        listeners.add(listener)
    }
    
    public func removeListener(_ listener: WatermarkUpdateListener) {
        listeners.remove(listener)
    }
}
