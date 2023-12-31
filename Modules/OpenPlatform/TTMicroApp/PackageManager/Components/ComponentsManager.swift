//
//  ComponentsManager.swift
//  Timor
//
//  Created by Limboy on 2020/9/5.
//

import Foundation
import ECOInfra

/// 跟 JSSDK Config 里的 Component 数据结构对应，同时加上了 name，以保证完整性
/// "components": {
///     "editor": {
///         "url": "xxx",
///         "version": "1.2.3",
///         "md5": "abc"
///     }
/// }
@objcMembers
public final class ComponentModel: NSObject {
    public let url: String
    public let version: String
    public let md5: String
    public let name: String
    public var localPath: String?

    public init?(name: String, meta: [String:String]) {
        guard let url = meta["url"],
              let version = meta["version"],
              let md5 = meta["md5"]
        else {
            return nil;
        }

        self.url = url
        self.version = version
        self.md5 = md5
        self.name = name
        self.localPath = meta["localPath"]
        super.init()
    }

    public func toJSONData() throws -> Data {
        var jsonDict = [
            "url": url,
            "version": version,
            "md5": md5,
            "name": name
        ]

        if let localPath = localPath {
            jsonDict["localPath"] = localPath
        }

        let data = try JSONSerialization.data(withJSONObject: jsonDict)
        return data
    }
}

@objcMembers
public final class ComponentsManager: NSObject {
    @objc public static let shared = ComponentsManager()

    private var componentConfigModels: [BDPType:[String:ComponentModel]] = [:]

    // 创建一个 Serial Queue 用于处理下载的文件
    private let fileHandlerQueue = DispatchQueue(label: "componentsmanager.microappsdk.lark")

    private override init() {

    }

    /// completion 里的 bool 表示本地是否已经存在
    public func loadComponent(_ componentName: String, uniqueID: BDPUniqueID, completion: @escaping (Bool, NSError?) -> Void) {
        // 如果能获取到本地版本，说明大组件已经 Ready 了
        if localModelOfComponent(componentName, appType: uniqueID.appType) != nil {
            BDPLogInfo(tag: .appLoad, "[BIG_COMPONENTS] component \(componentName) already installed")
            BDPExecuteOnMainQueue {
                completion(true, nil)
            }
            return
        }

        install(componentName:componentName, appType: uniqueID.appType, uniqueID: uniqueID) { (response, error) in
            if let error = error {
                BDPLogError(tag: .appLoad, "[BIG_COMPONENTS] component \(componentName) install failed")
            } else {
                BDPLogInfo(tag: .appLoad, "[BIG_COMPONENTS] component \(componentName) download success. url: \(response?.url)")
            }
            BDPExecuteOnMainQueue {
                completion(false, error)
            }
        }
    }

    /// 加载大组件们，只有全部组件加载完，才算 OK，有一个出错就算 Fail
    public func loadComponents(_ components:Array<String>, uniqueID: BDPUniqueID, completion: ((NSError?) -> Void)?) {
        let totalCompleteCount = components.count
        /// 失败的组件列表
        var failedComponents = [String]()
        /// 当前已完成下载的数量
        var currentCompletedCount = 0;
        /// 本地已存在的组件数量
        var existsCount = 0;

        /// 加载回调时，加一把锁
        let semaphoreSignal = DispatchSemaphore(value: 1)

        if (components.count <= 0) {
            BDPLogWarn(tag: .appLoad, "[BIG_COMPONENTS] components to load is empty")
            BDPExecuteOnMainQueue {
                completion?(nil)
            }
            return
        }

        components.forEach { (componentName) in
            self.loadComponent(componentName, uniqueID: uniqueID) { (exists, error) in
                semaphoreSignal.wait()
                currentCompletedCount += 1

                if (error == nil) {
                    if (exists) {
                        existsCount += 1
                    }
                    BDPLogInfo(tag: .appLoad, "[BIG_COMPONENTS] component \(componentName) load successful. exists: \(exists)")
                } else {
                    failedComponents.append(componentName)
                    BDPLogError(tag: .appLoad, "[BIG_COMPONENTS] component \(componentName) load failed.")
                }

                /// 全部下载完成了
                if (currentCompletedCount >= totalCompleteCount) {
                    if (failedComponents.count == 0) {
                        BDPLogInfo(tag: .appLoad, "[BIG_COMPONENTS] all required components(\(components)) loaded")

                        OPMonitor(kEventName_op_common_component_status)
                            .addTag(.appLoad)
                            .setUniqueID(uniqueID)
                            /// 都是从本地加载的话为 1，不然就为 0
                            .addCategoryValue("components_exist", existsCount >= totalCompleteCount ? 1 : 0)
                            .flush()

                        BDPExecuteOnMainQueue {
                            completion?(nil)
                        }
                    } else {
                        OPMonitor(kEventName_op_common_component_app_start_failed)
                            .addTag(.appLoad)
                            .setUniqueID(uniqueID)
                            .setError(error)
                            .addCategoryValue("components", components.joined(separator: ","))
                            .flush()

                        BDPExecuteOnMainQueue {
                            completion?(error)
                        }
                    }
                }
                semaphoreSignal.signal()
            }
        }
    }

    public func setComponentsConfig(_ config: [String:[String:String]]?, forAppType appType: BDPType) {
        if let config = config {
            BDPLogInfo(tag: .componentsManager, "[BIG_COMPONENTS] set components config: \(config)")
            // 写入 componentConfigModels 加把锁，存在多线程读写的可能性
            objc_sync_enter(self)
            for (componentName, componentMeta) in config {
                if let model = ComponentModel(name: componentName, meta: componentMeta) {
                    componentConfigModels[appType, default: [:]][componentName] = model
                } else {
                    OPError.error(monitorCode: CommonMonitorCodeComponent.invalid_component_content, message: "[BIG_COMPONENTS] componentName:\(componentName), componentMeta:\(componentMeta)")
                }
            }
            objc_sync_exit(self)
        } else {
            BDPLogError(tag: .componentsManager, "[BIG_COMPONENTS] config is nil")
            componentConfigModels[appType] = [:]
        }
    }

    /// 这些大组件是否都已经下载完了，只要有一个没有下载完就返回 false
    public func hasComponentsDownloaded(_ components: [String], appType: BDPType) -> Bool {
        var hasDownloaded = true
        components.forEach { (componentName) in
            if localModelOfComponent(componentName, appType: appType) == nil {
                hasDownloaded = false
            }
        }
        return hasDownloaded
    }

    public func localModelsOfComponents(_ components: [[String:Any]], appType: BDPType) -> [String:ComponentModel] {
        var result = [String:ComponentModel]()

        components.forEach { (component) in
            guard let componentName = component["name"] as? String else {
                BDPLogError(tag: .componentsManager, "[BIG_COMPONENTS] can't find name in component \(component)")
                return;
            }
            if let model = localModelOfComponent(componentName, appType: appType) {
                result[componentName] = model
            } else {
                BDPLogError(tag: .componentsManager, "[BIG_COMPONENTS] get component(\(component)) model failed")
            }
        }
        return result
    }

    public func localModelOfComponent(_ componentName: String, appType: BDPType) -> ComponentModel? {
        let metaPath = metaPathForComponent(componentName, appType: appType).path
        let componentPath = pathForComponent(componentName, appType: appType).path
        var model: ComponentModel? = nil

        if LSFileSystem.fileExists(filePath: metaPath) {
            do {
                model = try getDownloadedModelByComponentName(componentName, appType: appType)
            } catch {
                let opError = error.newOPError(monitorCode: CommonMonitorCodeComponent.component_meta_read_failed)
                BDPLogError(tag: .componentsManager, "[BIG_COMPONENTS] \(opError.description)")
            }
        } else {
            BDPLogInfo(tag: .componentsManager, "[BIG_COMPONENTS] \(componentName) model does not exist")
        }

        /// 如果本地文件 Ready，一并附上 path
        if let model = model, LSFileSystem.fileExists(filePath: componentPath) {
            model.localPath = componentPath
        }

        return model
    }

    public func removeLocalComponent(_ componentName: String, appType: BDPType) -> NSError? {
        let componentName = componentName.trimmingCharacters(in: .whitespacesAndNewlines)
        if (componentName.count == 0 || componentName.firstIndex(of: "/") != nil) {
            let message = "[BIG_COMPONENTS] invalid component: \(componentName)"
            BDPLogError(tag: .componentsManager, message)
            return NSError(domain: message, code: 0, userInfo: nil)
        }
        
        let componentPath = componentDirectoryPath(componentName, appType: appType)
        do {
            try FileManager.default.removeItem(at: componentPath)
        } catch {
            return error.newOPError(monitorCode: CommonMonitorCodeComponent.remove_component_failed)
        }
        BDPLogInfo(tag: .componentsManager, "[BIG_COMPONENTS] successfully removed component: \(componentName)")
        return nil
    }

    public func install(componentName: String, appType: BDPType, uniqueID: BDPUniqueID?, completion: ((URLResponse?, NSError?) -> Void)?) {
        install(componentName: componentName,
                componentVersion: "",
                appType: appType,
                uniqueID: uniqueID,
                completion: completion)
    }

    public func install(componentName: String, componentVersion: String, appType: BDPType, uniqueID: BDPUniqueID?, completion: ((URLResponse?, NSError?) -> Void)?) {
        // 读取 componentConfigModels 加把锁，存在多线程读写的可能性
        objc_sync_enter(self)
        guard let model = componentConfigModels[appType, default: [:]][componentName] else {
            objc_sync_exit(self)
            let errorMessage = "[BIG_COMPONENTS] component(\(componentName)) model does not exist"
            let opError = OPError.error(monitorCode: CommonMonitorCodeComponent.no_component_to_download, message: errorMessage)
            BDPExecuteOnMainQueue {
                completion?(nil, opError)
            }
            return;
        }
        objc_sync_exit(self)

        if let url = URL(string: model.url) {
            BDPLogInfo(tag: .componentsManager, "[BIG_COMPONENTS] start downloading component(\(componentName)) with url: \(url)")
            let request = URLRequest(url: url)
            let requestIdentifier = model.url
            let loadType: ComponentDownloader.LoadType = uniqueID == nil ? .jssdk : .meta

            ComponentDownloader.shared.download(with: request, requestIdentifier: requestIdentifier, componentName: componentName, componentVersion: componentVersion, appType: appType, uniqueID: uniqueID, loadType: loadType) { [weak self] (data, response, error) in
                guard let `self` = self else {
                    let message = "[BIG_COMPONENTS] self does not exist when download component(\(componentName)) finished"
                    let error = NSError(domain: message, code: 0, userInfo: nil)
                    BDPLogError(tag: .componentsManager, message)
                    BDPExecuteOnMainQueue {
                        completion?(nil, error)
                    }
                    return
                }

                if let data = data, error == nil {
                    self.fileHandlerQueue.async {
                        // 描述安装状态，方便后面处理 Error
                        enum WriteStatus {
                            case start
                            case dataWriten
                            case metaConverted
                            case metaWriten
                        }
                        var writeStatus: WriteStatus = .start

                        func generateMonitor(eventName: String) -> OPMonitor {
                            let monitor = OPMonitor(eventName)
                                .addTag(.componentsManager)
                                .setUniqueID(uniqueID)
                                .addCategoryValue("component", componentName)
                                .addCategoryValue("componentVersion", componentVersion)
                            return monitor
                        }

                        generateMonitor(eventName: kEventName_op_common_component_install_start).flush()
                        let resultMonitor = generateMonitor(eventName: kEventName_op_common_component_install_result)

                        do {
                            let calculatedMD5 = (data as NSData).bdp_md5String()
                            if calculatedMD5 == model.md5 {
                                /// 顺序很重要，确保 meta 最后被写入
                                try LSFileSystem.main.write(data: data, to: self.pathForComponent(componentName, appType: appType).path)
                                writeStatus = .dataWriten
                                let metaData = try model.toJSONData()
                                writeStatus = .metaConverted
                                try LSFileSystem.main.write(data: metaData, to: self.metaPathForComponent(componentName, appType: appType).path)
                                writeStatus = .metaWriten

                                BDPExecuteOnMainQueue {
                                    completion?(response, nil)
                                }

                                BDPLogInfo(tag: .componentsManager, "[BIG_COMPONENTS] install component(\(componentName)) successful")
                                resultMonitor
                                    .setMonitorCode(CommonMonitorCodeComponent.component_install_success)
                                    .setResultTypeSuccess()
                                    .flush()
                            } else {
                                let error = OPError.error(monitorCode: CommonMonitorCodeComponent.component_download_md5_verify_failed, message: "[BIG_COMPONENTS] calculated: \(calculatedMD5), expected: \(model.md5)")

                                BDPExecuteOnMainQueue {
                                    completion?(response, error)
                                }

                                resultMonitor.setError(error).flush()
                            }
                        }
                        catch {
                            let message = error.localizedDescription
                            var monitorCode = CommonMonitorCodeComponent.component_install_failed
                            switch writeStatus {
                            /// meta 写入失败有一个专门的 event，不包含在 install failed 里
                            case .metaConverted:
                                monitorCode = CommonMonitorCodeComponent.component_meta_write_failed
                            default:
                                break
                            }
                            let error = OPError.error(monitorCode: monitorCode, message: message)

                            BDPExecuteOnMainQueue {
                                completion?(response, error)
                            }

                            resultMonitor.setError(error)
                            resultMonitor.flush()
                        }
                    }
                } else {
                    BDPLogError(tag: .componentsManager, "[BIG_COMPONENTS] download component(\(componentName)) failed. url: \(url), error: \(error)")
                    BDPExecuteOnMainQueue {
                        completion?(response, error)
                    }
                }
            }
        } else {
            let message = "[BIG_COMPONENTS] invalid download url \(model.url)"
            let opError = OPError.error(monitorCode: CommonMonitorCodeComponent.invalid_component_url, message: message)

            /// invalid url 也挂到 download result event 上
            OPMonitor(kEventName_op_common_component_download_result)
                .addTag(.componentDownloader)
                .addCategoryValue("component", componentName)
                .addCategoryValue("component_url", model.url)
                .setError(opError)
                .flush()

            BDPExecuteOnMainQueue {
                completion?(nil, opError)
            }
        }
    }
}

extension ComponentsManager {
    func metaPathForComponent(_ componentName: String, appType:BDPType) -> URL {
        let componentDirectory = componentDirectoryPath(componentName, appType: appType)
        return componentDirectory.appendingPathComponent("meta.json")
    }

    func pathForComponent(_ componentName: String, appType:BDPType) -> URL {
        let componentDirectory = componentDirectoryPath(componentName, appType: appType)
        return componentDirectory.appendingPathComponent("\(componentName).js")
    }

    func componentDirectoryPath(_ componentName: String, appType:BDPType) -> URL {
        let componentsPath = BDPLocalFileManager.sharedInstance(for: appType).path(for: BDPLocalFilePathType.components)
        let componentPath = URL(fileURLWithPath: componentsPath).appendingPathComponent(componentName)
        createDirectoryIfNeeded(componentPath.path)
        return componentPath
    }

    func createDirectoryIfNeeded(_ directory: String) {
        if (!LSFileSystem.fileExists(filePath: directory)) {
            do {
                try LSFileSystem.main.createDirectory(atPath: directory, withIntermediateDirectories: true)
            } catch {
                BDPLogError(tag: .componentsManager, "[BIG_COMPONENTS] create directory(\(directory)) failed. \(error)")
            }
        }
    }

    func getDownloadedModelByComponentName(_ componentName: String, appType:BDPType) throws -> ComponentModel {
        let metaPath = metaPathForComponent(componentName, appType: appType)
        var errorMessage: String = ""
        if let data = LSFileSystem.main.contents(filePath: metaPath.path) {
            do {
                if let meta = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:String] {
                    if let model = ComponentModel(name: componentName, meta: meta) {
                        return model
                    } else {
                        errorMessage = "[BIG_COMPONENTS] convert meta data to model failed \(meta)"
                    }
                } else {
                    errorMessage = "[BIG_COMPONENTS] unable to parse to [String:String]"
                }
            } catch {
                errorMessage = "[BIG_COMPONENTS] json serialization failed, \(error)"
            }
        } else {
            errorMessage = "[BIG_COMPONENTS] \(componentName) file exists, but read failed"
        }
        throw NSError(domain: errorMessage, code: 0, userInfo: nil)
    }
}
