//
//  OpenPluginDriveCloudAPI.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/9/1.
//

import Foundation
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LarkOpenPluginManager
import RxSwift
import LarkContainer
import LarkSetting

// MARK: -
final class OpenPluginDriveCloudAPI: OpenBasePlugin {
    let progressInternal: CGFloat = 100
    
    enum APIName: String {
        case downloadFileFromCloud
        case uploadFileToCloud
        case openFileFromCloud
        case uploadFileToCloudAbort
        case downloadFileFromCloudAbort
        case onUploadFileToCloudUpdate
        case onDownloadFileFromCloudUpdate
        case onOpenFileFromCloudDownloadComplete
    }
    
    typealias OpenPluginNetworkError = OpenPluginNetwork.OpenPluginNetworkError
    
    let disposeBag: DisposeBag = DisposeBag()
    @InjectedSafeLazy var downloader: OpenPluginDriveDownloadProxy // Global
    @InjectedSafeLazy var uploader: OpenPluginDriveUploadProxy // Global
    @InjectedSafeLazy var previewProxy: OpenPluginDrivePreviewProxy // Global
    
    private static let gadgetDriveApiKey = UserSettingKey.make(userKeyLiteral: "gadget_drive_api")
    @RawSetting(key: gadgetDriveApiKey)
    private var settingConfig: [String: Any]?

    let container = OpenPluginDriveCloudAPIContainer()

    private func privateDownloadFileFromCloud(
        params: OpenPluginDownloadFileFromCloudRequest,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginDownloadFileFromCloudResponse>) -> Void) {
            context.apiTrace.info("downloadFileFromCloud API call start")
            
            guard apiEnable(apiName: .downloadFileFromCloud, with: gadgetContext.uniqueID.appID, trace: context.apiTrace) else {
                let error = OpenAPIError(errno: OpenAPICommonErrno.unable)
                callback(.failure(error: error))
                return
            }
            downloadFileFromCloud(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            context.apiTrace.info("downloadFileFromCloud API call end")
    }
    
    private func privateUploadFileToCloud(
        params: OpenPluginUploadFileToCloudRequest,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginUploadFileToCloudResponse>) -> Void) {
            context.apiTrace.info("uploadFileToCloud API call start")
            
            guard apiEnable(apiName: .uploadFileToCloud, with: gadgetContext.uniqueID.appID, trace: context.apiTrace) else {
                let error = OpenAPIError(errno: OpenAPICommonErrno.unable)
                callback(.failure(error: error))
                return
            }
            uploadFileToCloud(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            context.apiTrace.info("uploadFileToCloud API call end")
    }
    
    private func privateOpenFileFromCloud(
        params: OpenPluginOpenFileFromCloudRequest,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            context.apiTrace.info("openFileFromCloud API call start")
            
            guard apiEnable(apiName: .openFileFromCloud, with: gadgetContext.uniqueID.appID, trace: context.apiTrace) else {
                let error = OpenAPIError(errno: OpenAPICommonErrno.unable)
                callback(.failure(error: error))
                return
            }
            openFileFromCloud(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            context.apiTrace.info("openFileFromCloud API call end")
    }
    
    private func apiEnable(apiName: APIName, with appId: String, trace: OPTrace) -> Bool {
        guard let config = settingConfig?[apiName.rawValue] as? [String: AnyHashable] else {
            trace.error("apiName: \(apiName.rawValue) get no setting")
            return false
        }
        if let appIdValue = config[appId] as? Bool {
            trace.info("apiName: \(apiName.rawValue) get stting with appID: \(appId), value: \(appIdValue)")
            return appIdValue
        }
        if let defaultValue = config["default"] as? Bool {
            trace.info("apiName: \(apiName.rawValue) get stting with default value: \(defaultValue)")
            return defaultValue
        }
        trace.error("apiName: \(apiName.rawValue) return default false")
        return false
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: APIName.downloadFileFromCloud.rawValue, pluginType: Self.self, paramsType: OpenPluginDownloadFileFromCloudRequest.self, resultType: OpenPluginDownloadFileFromCloudResponse.self) { (this, params, context, gadgetContext, callback) in
            this.privateDownloadFileFromCloud(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: APIName.uploadFileToCloud.rawValue, pluginType: Self.self, paramsType: OpenPluginUploadFileToCloudRequest.self, resultType: OpenPluginUploadFileToCloudResponse.self) { (this, params, context, gadgetContext, callback) in
            this.privateUploadFileToCloud(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: APIName.openFileFromCloud.rawValue, pluginType: Self.self, paramsType: OpenPluginOpenFileFromCloudRequest.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            this.privateOpenFileFromCloud(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: APIName.uploadFileToCloudAbort.rawValue, pluginType: Self.self, paramsType: OpenPluginUploadFileToCloudAbortRequest.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            context.apiTrace.info("uploadFileToCloudAbort API call start")
            this.uploadFileToCloudAbort(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            context.apiTrace.info("uploadFileToCloudAbort API call end")
        }
        registerInstanceAsyncHandlerGadget(for: APIName.downloadFileFromCloudAbort.rawValue, pluginType: Self.self, paramsType: OpenPluginDownloadFileFromCloudAbortRequest.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            context.apiTrace.info("downloadFileFromCloudAbort API call start")
            this.downloadFileFromCloudAbort(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            context.apiTrace.info("downloadFileFromCloudAbort API call end")
        }
    }

    deinit {
        container.removeAll()
    }
}

