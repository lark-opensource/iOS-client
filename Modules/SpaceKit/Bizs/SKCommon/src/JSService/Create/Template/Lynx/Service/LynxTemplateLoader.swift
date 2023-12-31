//
//  LynxTemplateLoader.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/10/16.
//  


import SKFoundation
import Foundation
import RxSwift
import UIKit
import SKResource
import BDXResourceLoader
import LarkEnv
import BDXLynxKit
import SKInfra

class LynxTemplateLoader {
    typealias FetchCompletion = (Data?) -> Void
    
    static let shared = LynxTemplateLoader()
    
    private let serialQueue = DispatchQueue(label: "com.lark.ccm.lynx_template_loader.serial_queue")
    private lazy var serialScheduler: SchedulerType = {
        SerialDispatchQueueScheduler(queue: serialQueue, internalSerialQueueName: "com.lark.ccm.lynx_template_loader.serial_scheduler")
    }()
    
    private var taskTable: [String: Task] = [:]
    private let bag = DisposeBag()
    
    func register(with params: Params) {
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            let key = self.keyFor(bizId: params.bizId, channel: params.channel)
            if self.taskTable[key] != nil {
                DocsLogger.info("has been registered: bizId=\(params.bizId),channel=\(params.channel)", component: LogComponents.lynx)
                return
            }
            let task = Task(params: params)
            self.taskTable[key] = task
        }
    }
    
    func fetchTemplate(at path: String, bizId: String, channel: String, hotfixLoadStrategy: LynxGeckoLoadStrategy = .localFirstOrWaitRemote, completion: FetchCompletion?) {
        serialQueue.async {
            self._fetchTemplate(at: path, bizId: bizId, channel: channel, completion: completion)
        }
    }
    
    func fetchInfoOfCurrentUsedPkg(bizId: String, channel: String, completion: @escaping (String?) -> Void) {
        serialQueue.async {
            self._fetchInfoOfCurrentUsedPkg(bizId: bizId, channel: channel, completion: completion)
        }
    }
    
    private func _fetchInfoOfCurrentUsedPkg(bizId: String, channel: String, completion: @escaping (String?) -> Void) {
        let key = self.keyFor(bizId: bizId, channel: channel)
        guard let task = self.taskTable[key] else {
            completion(nil)
            return
        }
        task.pkgForUse()?.observeOn(MainScheduler.instance)
            .subscribe({ event in
                if case let .next(pkg) = event {
                    let msg = String(describing: pkg)
                    completion(msg)
                } else {
                    completion(nil)
                }
            })
            .disposed(by: bag)
    }
    
    private func _fetchTemplate(at path: String, bizId: String, channel: String, completion: FetchCompletion?) {
        let key = self.keyFor(bizId: bizId, channel: channel)
        guard let task = self.taskTable[key] else {
            DocsLogger.error("need register before fetch", component: LogComponents.lynx)
            DispatchQueue.main.async {
                completion?(nil)
            }
            return
        }
        
        if let pkgForUse = task.pkgForUse() {
            pkgForUse
                .flatMap({ $0.getData(from: path) })
                .observeOn(MainScheduler.instance)
                .subscribe({ event in
                    if case let .next(data) = event {
                        completion?(data)
                    } else if case let .error(error) = event {
                        DocsLogger.error("fetch lynx template data fail", error: error, component: LogComponents.lynx)
                        completion?(nil)
                    }
                })
                .disposed(by: bag)
        } else {
            DispatchQueue.main.async {
                completion?(nil)
            }
        }
    }
    
    private func keyFor(bizId: String, channel: String) -> String {
        return "\(bizId):\(channel)"
    }
}

extension LynxTemplateLoader {
    struct Params {
        let bizId: String
        let channel: String
        let accessKey: String?
        let buildInZipURL: SKFilePath?
        let buildInVersionURL: SKFilePath?
        let customPkgUnzipURL: SKFilePath?
        
        static let `default`: Params = {
            var customPkgUnzipURL: SKFilePath?
            if LynxCustomPkgManager.shared.shouldUseCustomPkg {
                customPkgUnzipURL = LynxCustomPkgManager.shared.savePathOfCustomPkg(with: LynxEnvManager.channel)
            }
            
            var buildInZipURL: SKFilePath?
            if let url = I18n.resourceBundle.url(forResource: "Lynx/docs_lynx_channel", withExtension: "7z") {
                buildInZipURL = SKFilePath(absUrl: url)
            }
            
            var buildInVersionURL: SKFilePath?
            if let url = I18n.resourceBundle.url(forResource: "Lynx/current_revision", withExtension: "") {
                buildInVersionURL = SKFilePath(absUrl: url)
            }
            
            let params = Params(
                bizId: LynxEnvManager.bizID,
                accessKey: OpenAPI.DocsDebugEnv.geckoAccessKey,
                channel: LynxEnvManager.channel,
                buildInZipURL: buildInVersionURL,
                buildInVersionURL: buildInVersionURL,
                customPkgUnzipURL: customPkgUnzipURL
            )
            return params
        }()
        
        init(bizId: String,
             accessKey: String?,
             channel: String,
             buildInZipURL: SKFilePath?,
             buildInVersionURL: SKFilePath?,
             customPkgUnzipURL: SKFilePath? = nil) {
            self.bizId = bizId
            self.accessKey = accessKey
            self.channel = channel
            self.buildInZipURL = buildInZipURL
            self.buildInVersionURL = buildInVersionURL
            self.customPkgUnzipURL = customPkgUnzipURL
        }
    }
}

extension LynxTemplateLoader {
    fileprivate class Task {
        private let params: Params
        private var customPkgSource: LynxCustomPkgSource?
        private var buildInPkgSource: LynxBuildInPkgSource?
        private var hotfixPkgSource: LynxHotfixPkgSource?
        init(params: Params) {
            self.params = params
            if let buildInZipURL = params.buildInZipURL, let buildInVersionURL = params.buildInVersionURL {
                buildInPkgSource = LynxBuildInPkgSource(
                    bizId: params.bizId,
                    channel: params.channel,
                    buildInZipURL: buildInZipURL,
                    buildInVersionURL: buildInVersionURL
                )
            }
            if let accessKey = params.accessKey {
                hotfixPkgSource = LynxHotfixPkgSource(
                    bizId: params.bizId,
                    channel: params.channel,
                    accessKey: accessKey
                )
            }
            if let customPkgUnzipURL = params.customPkgUnzipURL {
                customPkgSource = LynxCustomPkgSource(localURL: customPkgUnzipURL)
            }
        }
        fileprivate func pkgForUse() -> Observable<LynxResourcePkg>? {
            if let customPkgSource = customPkgSource {
                return customPkgSource.fetchPkg()
            }
            var pkgSources: [LynxPkgSource] = []
            if let buildInSource = buildInPkgSource {
                pkgSources.append(buildInSource)
            }
            if let hotfixSource = hotfixPkgSource {
                pkgSources.append(hotfixSource)
            }
            return biggestVersionPkg(of: pkgSources)
        }
        fileprivate func biggestVersionPkg(of pkgSources: [LynxPkgSource]) -> Observable<LynxResourcePkg>? {
            let observables = pkgSources.map({ $0.fetchPkg().materialize() })
            return zip(observables: observables)
        }
        private func zip(observables: [Observable<Event<LynxResourcePkg>>]) -> Observable<LynxResourcePkg>? {
            guard observables.count > 0 else { return nil }
            if observables.count == 1 {
                return observables[0].flatMap({ $0.toObservable() })
            }
            var final = observables[0]
            observables[1..<observables.count].forEach { observable in
                final = Observable.zip(final, observable) {
                    if case .next(let pkg0) = $0, case .next(let pkg1) = $1 {
                        return pkg0.version.isBig(than: pkg1.version) ? $0 : $1
                    } else if case .completed = $0, case .completed = $1 {
                        return .completed
                    } else if case .next(_) = $0 {
                        return $0
                    } else if case .next(_) = $1 {
                        return $1
                    } else {
                        return .error(LynxPkgSourceError.pkgNotExist)
                    }
                }
            }
            return final.flatMap({ $0.toObservable() })
        }
    }
}

extension Event {
    func toObservable() -> Observable<Element> {
        switch self {
        case .next(let element): return .just(element)
        case .error(let error): return .error(error)
        case .completed: return .never()
        @unknown default:
            spaceAssertionFailure()
            return .never()
        }
    }
}

final class SKTemplateInfoRecorder {
    static let shared = SKTemplateInfoRecorder()
    // 主线程操作，不加锁
    private var pkgInfos: [String: String] = [:]
    fileprivate func recordResource(_ resource: BDXResourceProtocol, for relativePath: String) {
        if let localResource = resource as? LynxLocalResource, let pkg = localResource.pkg {
            self.pkgInfos[relativePath] = "\(pkg.version)(\(pkg.type))"
        }
    }
    func currentUsingResourceInfo() -> String {
        var infos: [String] = []
        for (key, value) in pkgInfos {
            infos.append("\(key): \(value)\n")
        }
        return infos.joined(separator: "\n")
    }
}

final class SKTemplateProvider: NSObject, LynxTemplateProvider {
    private let params: LynxTemplateLoader.Params
    private let loader = BDXResourceLoader()
    private var customPkgProcessor: LynxPkgProcessor
    private var buildInPkgProcessor: LynxPkgProcessor
    private var hotfixPkgProcessor: LynxHotfixPkgProcessor
    private let hotfixLoadStrategy: LynxGeckoLoadStrategy
    
    init(params: LynxTemplateLoader.Params, hotfixLoadStrategy: LynxGeckoLoadStrategy) {
        self.params = params
        self.hotfixLoadStrategy = hotfixLoadStrategy
        let buildInPkgSource = LynxBuildInPkgSource(
            bizId: params.bizId,
            channel: params.channel,
            buildInZipURL: params.buildInZipURL,
            buildInVersionURL: params.buildInVersionURL
        )
        buildInPkgProcessor = LynxPkgProcessor(
            pkgSource: buildInPkgSource,
            name: "SKLynxBuildInPkgProcessor"
        )
        let customPkgSource = LynxCustomPkgSource(localURL: params.customPkgUnzipURL)
        customPkgProcessor = LynxPkgProcessor(
            pkgSource: customPkgSource,
            name: "SKLynxCustomPkgProcessor"
        )
        hotfixPkgProcessor = LynxHotfixPkgProcessor(
            bizId: params.bizId, channel: params.channel,
            accessKey: params.accessKey,
            buildInVersionURL: params.buildInVersionURL
        )
        let loaderConfig = BDXResourceLoaderConfig()
        loaderConfig.disableGurd = true
        loaderConfig.disableGurdUpdate = true
        loader.update(loaderConfig)
    }
    
    func loadTemplate(withUrl url: String?, onComplete callback: LynxTemplateLoadBlock?) {
        guard let url = url,
              let bundleName = getBundleName(from: url, channelName: params.channel) else {
            callback?(nil, nil)
            return
        }
        let taskConfig = BDXResourceLoaderTaskConfig()
        taskConfig.channelName = params.channel
        taskConfig.bundleName = bundleName
        taskConfig.disableBuildin = true
        taskConfig.disableGurd = true
        taskConfig.disableGurdUpdate = true
        taskConfig.dynamic = NSNumber(value: hotfixLoadStrategy.rawValue)
        let processorConfig = BDXResourceLoaderProcessorConfig()
        let hotfixPkgProcessor = self.hotfixPkgProcessor
        let hotfixPkgProcessorProvider = { hotfixPkgProcessor }
        let buildInPkgProcessor = self.buildInPkgProcessor
        let buildinPkgProcessorProvider = { buildInPkgProcessor }
        processorConfig.lowProcessorProviderArray = [
            hotfixPkgProcessorProvider,
            buildinPkgProcessorProvider
        ]
        let customPkgProcessor = self.customPkgProcessor
        let customPkgProcessorProvider = { customPkgProcessor }
        processorConfig.highProcessorProviderArray = [customPkgProcessorProvider]
        processorConfig.disableDefaultProcessors = true
        taskConfig.processorConfig = processorConfig

        loader.fetchResource(withURL: url, container: nil, taskConfig: taskConfig) { resource, error in
            guard let resource = resource else {
                DocsLogger.error("Lynx Resource Loader fetch error", error: error, component: LogComponents.lynx)
                callback?(nil, error)
                return
            }
            DocsLogger.info("Lynx Resource Loader fetch resource type:\(resource.resourceType())", component: LogComponents.lynx)
            callback?(resource.resourceData(), error)
            SKTemplateInfoRecorder.shared.recordResource(resource, for: bundleName)
        }
    }
    private func getBundleName(from urlString: String, channelName: String) -> String? {
        let components = urlString.components(separatedBy: "/\(channelName)/")
        guard let bundleName = components.last, bundleName.hasSuffix("template.js") else {
            return nil
        }
        return bundleName
    }
}

public enum LynxGeckoLoadStrategy: Int {
    case onlyLocal = 0 //只读取已下载到本地的gecko包
    case localFirstOrWaitRemote //先读取本地gecko包，有则返回成功，没有则尝试下载，并等待下载结果
    case onlyRemote //直接尝试下载gecko包
    case localFirstNotWaitRemote //先读取本地gecko包，有则返回成功，没有则返回失败，并尝试下载
}
