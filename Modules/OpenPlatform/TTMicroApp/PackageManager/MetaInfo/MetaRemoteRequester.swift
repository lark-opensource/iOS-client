//
//  MetaRemoteRequester.swift
//  Timor
//
//  Created by houjihu on 2020/6/8.
//

import Foundation
import LarkOPInterface
import LarkFeatureGating
import OPFoundation
import RustSDK
import RustPB
import RxSwift
import LarkRustClient
import LarkSetting
import LKCommonsLogging
import OPSDK

fileprivate let logger = Logger.oplog(OPContainerAbilitiesGray.self, category: "GadgetContainerReloadConfig")

struct OPContainerAbilitiesGray: SettingDecodable {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "open_container_abilities_gray")
    let gadgetRemoteMeta: GagetRemoteMeta
}

struct GagetRemoteMeta: Decodable {
    let allowList: [String]
    let denyList: [String]
}

extension OPContainerAbilitiesGray {
    func enableRustHttpInPKM(uniqueID: BDPUniqueID) -> Bool {
        guard uniqueID.appType == .gadget else {
            logger.warn("app id:\(uniqueID.fullString) is not gadget")
            return false
        }
        //如果 deny_list 有 appID，则不允许开启
        if gadgetRemoteMeta.denyList.contains(uniqueID.appID) {
            logger.info("app id in deny list, feature disable")
            return false
        }
        //如果allow_list 有 appID，或包含*，则开启
        if gadgetRemoteMeta.allowList.contains(uniqueID.appID) ||
            gadgetRemoteMeta.allowList.contains("*") {
            logger.info("app id in allow list, feature enable")
            return true
        }
        logger.info("return default value")
        return false
    }
}

/// meta远端请求器
class MetaRemoteRequester {

    /// Meta能力提供对象，例如组装meta请求和组装meta实体
    private let provider: MetaProviderProtocol&MetaTTCodeProtocol

    /// 应用类型
    private let type: BDPType

    /// meta 请求器
    private let metaFetcher: MetaFetcher
    
    private let disposeBag = DisposeBag()
    
    @ProviderSetting(key: UserSettingKey.make(userKeyLiteral: "open_container_abilities_gray"))
    private var abilitiesGray: OPContainerAbilitiesGray?

    /// 初始化meta远端请求器
    /// - Parameter provider: meta能力对象
    init(
        provider: MetaProviderProtocol&MetaTTCodeProtocol,
        appType: BDPType
    ) {
        self.provider = provider
        type = appType
        metaFetcher =   MetaFetcher(
            config: MetaFetcherConfiguration(
            shouldReuseSameRequest: true,
            timeoutIntervalForRequest: 15   //  对齐逻辑
        ),
        appType: appType)
    }
    
    deinit {
        metaFetcher.invalidateSession()
    }
    /// 从网络获取meta信息，成功则进行持久化
    /// - Parameters:
    ///   - context: meta请求上下文
    ///   - success: 成功回调
    ///   - failure: 失败回调
    ///   - saveMeta: save meta block
    func requestRemoteMeta(
        with context: MetaContext,
        success: ((AppMetaProtocol) -> Void)?,
        failure: ((OPError) -> Void)?
    ) {
        let requestTrace = BDPTracingManager.sharedInstance().generateTracing(withParent: context.trace)
        var requestAndTTCode: MetaRequestAndTTCode
        do {
            requestAndTTCode = try provider.getMetaRequestAndTTCode(with: context)
        } catch {
            let opError = error.newOPError(monitorCode: CommonMonitorCodeMeta.invalid_params, message: "getMetaRequestAndTTCode failed")
            failure?(opError)
            assertionFailure(opError.description)
            return
        }
        
        if let abilitiesGray = self.abilitiesGray,
           abilitiesGray.enableRustHttpInPKM(uniqueID: context.uniqueID),
           let client = OPApplicationService.current.resolver?.resolve(RustService.self) {
            var getAppMetaRequest = Openplatform_V1_GetAppRemoteMetaRequest()
            getAppMetaRequest.ttcode = requestAndTTCode.ttcode.ttcode
            getAppMetaRequest.appid = context.uniqueID.appID
            getAppMetaRequest.appType = "gadget"
            getAppMetaRequest.versionType = context.uniqueID.versionType == .current ? "current" : "preview"
            getAppMetaRequest.traceID = context.trace.traceId
            //设置预览的 token
            if let token = context.token {
                getAppMetaRequest.token = token
            }
            client.sendAsyncRequest(getAppMetaRequest).subscribe(
                onNext: {  (response: Openplatform_V1_GetAppRemoteMetaResponse) in
                    if response.hasErrorMessage || response.hasErrorCode {
                        let errorMesssage = "rust error with msg:\(response.errorMessage) code:\(response.errorCode)"
                        let opError = OPError.error(monitorCode:CommonMonitorCodeMeta.meta_response_invalid, message:errorMesssage)
                        failure?(opError)
                    } else {
                        var meta: AppMetaProtocol
                        guard let data = response.responseBody.data(using: .utf8) else {
                            let errorMesssage = "rust error, data is empty"
                            let opError = OPError.error(monitorCode:CommonMonitorCodeMeta.meta_response_invalid, message:errorMesssage)
                            failure?(opError)
                            return
                        }
                        do {
                            meta = try self.provider.buildMetaModel(with: data, ttcode: requestAndTTCode.ttcode, context: context)
                        } catch {
                            if let opError = error as? OPError {
                                failure?(opError)
                            } else {
                                let opError = error.newOPError(monitorCode: CommonMonitorCodeMeta.meta_response_invalid, message: "buildMetaModel failed due to unknown error")
                                failure?(opError)
                            }
                            return
                        }
                        //  meta组装成功
                        success?(meta)
                    }
                },
                onError: { error in
                    let opError = error.newOPError(monitorCode: CommonMonitorCodeMeta.meta_response_invalid, message: error.localizedDescription)
                    failure?(opError)
                }

            ).disposed(by: disposeBag)
            return
        }
        metaFetcher
            .requestMeta(
                with: requestAndTTCode.request,
                token: getToken(with: context, ttcode: requestAndTTCode.ttcode.ttcode),
                uniqueID: context.uniqueID,
                trace: requestTrace
            ) { [weak self] (data, response, error) in
                guard let `self` = self else { return }
                if let error = error {
                    //  网络请求失败，日志+回调
                    failure?(error)
                    return
                }
                guard let data = data else {
                    //  网络请求没有返回数据，日志+回调
                    let msg = "meta request has no response data"
                    let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_request_error, message: msg)
                    failure?(opError)
                    return
                }
                var meta: AppMetaProtocol
                do {
                    meta = try self.provider.buildMetaModel(with: data, ttcode: requestAndTTCode.ttcode, context: context)
                } catch {
                    if let opError = error as? OPError {
                        failure?(opError)
                    } else {
                        let opError = error.newOPError(monitorCode: CommonMonitorCodeMeta.meta_response_invalid, message: "buildMetaModel failed due to unknown error")
                        failure?(opError)
                    }
                    return
                }
                //  meta组装成功
                success?(meta)
            }
    }
    
    /// 从网络获取meta信息，成功则进行持久化
    /// - Parameters:
    ///   - entieis: [appId: version]
    ///   - success: 成功回调
    ///   - failure: 失败回调
    ///   - saveMeta: save meta block
    func batchRequestRemoteMetaWith(
            _ entities: [String: String],
            scene: BatchLaunchScene,
            success: (([(String, AppMetaProtocol?, OPError?)]) -> Void)?,
            failure: ((OPError) -> Void)?
    ) {
        let requestTrace = BDPTracingManager.sharedInstance().generateTracing()
        var requestAndTTCode: MetaRequestAndTTCode
        
        guard let gadgetProvider = provider as? GadgetMetaProvider else {
            let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_request_error, message: "provider to GadgetMetaProvider failed")
            failure?(opError)
            return
        }
        do {
            requestAndTTCode = try gadgetProvider.getBatchMetaRequestAndTTCodeWith(entities, scene: scene.rawValue)
        } catch {
            let opError = error.newOPError(monitorCode: CommonMonitorCodeMeta.invalid_params, message: "getMetaRequestAndTTCode failed")
            failure?(opError)
            assertionFailure(opError.description)
            return
        }
        let batchUniqueIDIdentifier = entities.keys.joined(separator: ":")
        let batchUniqueID = OPAppUniqueID(appID: "cli_batch_unique_id",
                                          identifier: batchUniqueIDIdentifier, versionType: .current, appType: .gadget)
        let requestToken = "\(batchUniqueID.fullString)_\(requestAndTTCode.ttcode.ttcode)"
        metaFetcher
            .requestMeta(
                with: requestAndTTCode.request,
                token: requestToken,
                uniqueID: batchUniqueID,
                trace: requestTrace
            ) { [weak self] (data, response, error) in
                guard let `self` = self else { return }
                if let error = error {
                    //  网络请求失败，日志+回调
                    failure?(error)
                    return
                }
                guard let data = data else {
                    //  网络请求没有返回数据，日志+回调
                    let msg = "meta request has no response data"
                    let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_request_error, message: msg)
                    failure?(opError)
                    return
                }
                //解析 response data 内部的数据
                do {
                    let tempResponse = try JSONSerialization.jsonObject(with: data)
                    guard let responseDic = tempResponse as? [String: Any],
                          let data = responseDic["data"] as? [String: Any],
                          let metas = data["metas"] as? [String: Any] else {
                        let msg = "build meta model error: response data type error, not [String: Any], response:\(tempResponse)"
                        let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_response_invalid, message: msg)
                        failure?(opError)
                        return
                    }
                    if metas.isEmpty {
                        let msg = "response metas is emtpy, response:\(responseDic), code:\(responseDic["code"]) msg:\(responseDic["msg"])"
                        let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_response_invalid, message: msg)
                        failure?(opError)
                        return
                    }
                    //挨个组装 meta 列表
                    var resultList: [(String, AppMetaProtocol?, OPError?)] = []
                    metas.forEach { appID, value in
                        let uniqueID = OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .gadget)
                        let context = MetaContext(uniqueID: uniqueID, token: nil)
                        var meta: AppMetaProtocol?
                        var opError: OPError?
                        do {
                            meta = try gadgetProvider.buildMetaModelWith(JSONObject: value, ttcode: requestAndTTCode.ttcode, context: context)
                        } catch {
                            if let error = error as? OPError {
                                opError = error
                            } else {
                                opError = error.newOPError(monitorCode: CommonMonitorCodeMeta.meta_response_invalid, message: "buildMetaModel failed due to unknown error")
                            }
                        }
                        resultList.append((appID, meta, opError))
                    }
                    //组装完成，返回真个 resultList
                    success?(resultList)
                } catch {
                    var opError: OPError
                    if let error = error as? OPError {
                        opError = error
                    } else {
                        opError = error.newOPError(monitorCode: CommonMonitorCodeMeta.meta_response_invalid, message: "JSONSerialization.jsonObject due to unknown error")
                    }
                    failure?(opError)
                }
            }
    }
    
}

extension MetaRemoteRequester {
    /// 生成Meta请求唯一标志符
    /// - Parameter context: meta请求上下文
    /// - Returns: Meta请求唯一标志符
    private func getToken(with context: MetaContext ,ttcode:String) -> String {
        return "\(context.uniqueID.fullString)_\(ttcode)_\(context.token ?? "" )"
    }

    //清除所有请求
    public func clearAllRequests() {
        metaFetcher.clearAllTasks()
    }
}
