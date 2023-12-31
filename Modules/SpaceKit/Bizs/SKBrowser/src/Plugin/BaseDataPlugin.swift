//
//  BaseDataPlugin.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/13.
//  

import SKFoundation
import SKCommon
import SpaceInterface
import SKUIKit

struct SKBaseDataPluginConfig {
    weak var model: BrowserModelConfig?
    let cacheService: SKCacheService
    init(cacheService: SKCacheService, model: BrowserModelConfig?) {
        self.cacheService = cacheService
        self.model = model
    }
}

protocol BaseDataPluginProtocol: SKExecJSFuncService {
    func plugin(_ plugin: BaseDataPlugin, setNeedSync needSync: Bool, for objToken: String, type: DocsType)

    var currentIdentifier: String? { get }

    func markFetchNativeClientVarStartIfNeeded(_ key: String, path: String)

    func markFetchNativeClientVarEndIfNeeded(_ key: String, path: String)

    func setFetchClientVarCacheMetaInfoIfNeededFor(key: String, objToken: String, result fetchedData: Any)
}

class BaseDataPlugin: JSServiceHandler {
    var logPrefix: String = ""
    private let config: SKBaseDataPluginConfig
    let dataHandleQueue = DispatchQueue(label: "com.bytedance.doc.dataHandleQueue")
    let throttle = SKThrottle(interval: 60)
    weak var pluginProtocol: BaseDataPluginProtocol?
    init(_ config: SKBaseDataPluginConfig) {
        self.config = config
    }
    var handleServices: [DocsJSService] {
        return [.utilSetData, .utilGetData, .collectData]
    }
    func handle(params: [String: Any], serviceName: String) {
        guard let dataParam = DataParams(params) else {
            skInfo(logPrefix + "handle \(serviceName) fail, params not ok")
            skAssertionFailure()
            return
        }
        let currentSessionId = self.pluginProtocol?.currentIdentifier
        switch serviceName {
        case DocsJSService.utilSetData.rawValue:
//            print("set data from webview \(params)")
            handleSetData(dataParam, for: currentSessionId)
        case DocsJSService.utilGetData.rawValue:
            handleGetData(dataParam, for: currentSessionId)
        case DocsJSService.collectData.rawValue:
            handleCollectData(dataParam, for: currentSessionId)
        default:
            skAssertionFailure(logPrefix + "can not handle \(serviceName)")
        }
    }

    func handleSetData(_ dataParam: DataParams, for currentSessionId: String?) {
        let objToken = dataParam.objToken
        let key = dataParam.key
        let cache = config.cacheService
        let prefix = logPrefix
        if dataParam.checkError, let nativeToken = config.model?.hostBrowserInfo.docsInfo?.token, nativeToken != objToken {
            let trackBlock = {
                let trackParams: [String: String] = [
                    "web_token": objToken.encryptToShort,
                    "native_token": nativeToken.encryptToShort,
                    "key": key.encryptToShort
                ]
                DocsTracker.newLog(enumEvent: .tokenInconsistency, parameters: trackParams)
            }
            throttle.schedule(trackBlock, jobId: objToken)
        }
        let resultHandler: NewCacheDataHandler = { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if currentSessionId != self.pluginProtocol?.currentIdentifier {
                    skVerbose(self.logPrefix + "openRecord identifier has changed")
                    return
                }
                var params: [String: Any] = ["code": 0, "data": "", "message": ""]
                switch result {
                case .failure(let error):
                    let nsError = error as NSError
                    params["code"] = nsError.code
                    params["message"] = nsError.domain
                default:
                    break
                }
                self.pluginProtocol?.callFunction(DocsJSCallBack(dataParam.callback), params: params, completion: nil)
            }
        }
        dataHandleQueue.async {
            autoreleasepool {
                // 写入/删除数据
                if dataParam.isClientVarService {
                    if let stringVAR = dataParam.data as? String, stringVAR.isEmpty {
                        DocsLogger.error("handleSetData, empty, string, objToken=\(objToken.encryptToken)")
                    }
                    cache.setH5Record(dataParam.getH5DataRecord(), needLog: true, completion: nil)
                } else if dataParam.imageData != nil { // 处理图片上传
                    cache.setH5Record(dataParam.getH5DataRecord())
                    skDebug(prefix + "set image data for key: \(key), path: \(objToken)")
                } else if dataParam.checkError, UserScopeNoChangeFG.LJW.checkErrorEnabled {
                    cache.setH5Record(dataParam.getH5DataRecord(), needLog: true, completion: resultHandler)
                } else {
                    cache.setH5Record(dataParam.getH5DataRecord(), needLog: true, completion: nil)
                }
                if dataParam.checkError != true || !UserScopeNoChangeFG.LJW.checkErrorEnabled {
                    resultHandler(.success(()))
                }
            }
        }
    }

    func handleGetData(_ dataParam: DataParams, for currentSessionId: String?) {
        let objToken = dataParam.objToken
        let key = dataParam.key
        self.pluginProtocol?.markFetchNativeClientVarStartIfNeeded(key, path: objToken)

        dataHandleQueue.async {
            autoreleasepool {
                let data: Any = self.config.cacheService.object(forKey: objToken, subKey: key) ?? ""
                skDebug(self.logPrefix + "get data: for key:\(key) path:\(objToken)")
                let dict: [String: Any] = ["code": 0, "message": "", "data": data]
                
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    if currentSessionId != self.pluginProtocol?.currentIdentifier {
                        skVerbose(self.logPrefix + "openRecord identifier has changed")
                        return
                    }
                    if dataParam.isClientVarService {
                        self.pluginProtocol?.setFetchClientVarCacheMetaInfoIfNeededFor(key: key, objToken: objToken, result: data)
                    }
                    self.pluginProtocol?.markFetchNativeClientVarEndIfNeeded(key, path: objToken)
                    
                    self.pluginProtocol?.callFunction(DocsJSCallBack(dataParam.callback), params: dict, completion: nil)
                }
            }
        }
    }
    
    func handleCollectData(_ dataParam: DataParams, for currentSessionId: String?) {
        let cache = config.cacheService
        let token = dataParam.objToken
        let key = dataParam.key
        dataHandleQueue.async {
            autoreleasepool {
                let data = cache.collectData(token: token, for: key)
                let dict: [String: Any] = ["code": 0, "message": "", "data": data]
                DispatchQueue.main.async { [weak self] in
                    self?.pluginProtocol?.callFunction(DocsJSCallBack(dataParam.callback), params: dict, completion: nil)
                }
            }
        }
    }
    
}

extension BaseDataPlugin {
    struct DataParams {
        let objToken: String
        let key: String
        let callback: String
        let needSync: Bool
        let data: NSCoding?
        let imageData: Data?
        let checkError: Bool
        var type: DocsType?

        init?(_ params: [String: Any]) {
            guard let objToken = params["objToken"] as? String else {
                skInfo("cannot get objtoken ")
                return nil
            }
            guard let key = params["key"] as? String else {
                skInfo("can not get key")
                return nil
            }
            guard let callback = params["callback"] as? String else {
                skInfo("can not get call back")
                return nil
            }
            self.objToken = objToken
            self.key = key
            self.callback = callback
            self.checkError = params["checkError"] as? Bool ?? false
            self.needSync = params["needSync"] as? Bool ?? false
            self.data = params["data"] as? NSCoding
            if let typeRaw = params["type"] as? Int {
                self.type = DocsType(rawValue: typeRaw)
            }

            if let type = params["type"] as? String,
                type == "image_base64",
                let base64 = params["data"] as? String,
                let originImage = UIImage.docs.image(base64: base64, scale: 1),
                let image = originImage.sk.rotate(radians: 0) {
                imageData = image.data(quality: 1, limitSize: 2 * 1024 * 1024)
            } else {
                imageData = nil
            }
        }

        func getH5DataRecord() -> H5DataRecord {
            if imageData != nil {
                return H5DataRecord(objToken: objToken, key: key, needSync: needSync, payload: imageData! as NSCoding, type: nil)
            } else {
                return H5DataRecord(objToken: objToken, key: key, needSync: needSync, payload: data, type: key.isClientVarKey ? type : nil, cacheFrom: .cacheFromWeb)
            }
        }

        var isClientVarService: Bool {
            return key.isClientVarKey
        }
    }
}
