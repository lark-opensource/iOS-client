//
//  OpenPluginBlockAPI.swift
//  OPBlock
//
//  Created by lixiaorui on 2022/5/24.
//

import Foundation
import LarkOpenAPIModel
import LarkOpenPluginManager
import OPSDK
import OPBlockInterface
import LarkSetting
import LarkContainer

// 技术文档详见https://bytedance.feishu.cn/docx/doxcnsrK8VwEv14e43TVdtY37Nf
public final class OpenPluginBlockAPI: OpenBasePlugin {
    static func setContainerConfig(params: OpenPluginSetContainerConfigRequest,
                                   context: OpenAPIContext,
                                   callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let component: OPBlockWebComponent? = {
            let blockEvent = context.additionalInfo["blockEvent"] as? OPEvent
            var component = blockEvent?.srcNode.parent as? OPBlockWebComponent
            if component == nil {
                component = context.blockContainer?.component as? OPBlockWebComponent
            }
            return component
        }()

        guard let component = component else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("can not find web component")
            context.apiTrace.error("can not find web component")
            callback(.failure(error: error))
            return
        }
        component.contentHeightDidChange(height: params.height)
        callback(.success(data: nil))
    }

    static func setBlockInfo(params: OpenPluginSetBlockInfoRequest,
                             context: OpenAPIContext,
                             callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        guard let container = context.blockContainer else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("can not find container")
            context.apiTrace.error("can not find container")
            callback(.failure(error: error))
            return
        }

        container.setBlockInfo(params: ["blockID": params.blockID,
                                        "blockTypeID": params.blockTypeID,
                                        "sourceMeta": params.sourceMeta,
                                        "sourceData": params.sourceData])
        callback(.success(data: nil))
    }

    static func cancel(params: OpenPluginCancelRequest,
                         context: OpenAPIContext,
                         callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {

        guard let container = context.blockContainer else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("can not find container")
            context.apiTrace.error("can not find container")
            callback(.failure(error: error))
            return
        }
        container.onCancel()
        callback(.success(data: nil))
    }

    static func hideBlockLoading(
        params: OpenAPIBaseParams,
        context: OpenAPIContext,
        callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        guard let container = context.blockContainer else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("can not find container")
            context.apiTrace.error("can not find container")
            callback(.failure(error: error))
            return
        }
        _ = container.hideBlockLoading(callback: { result in
            DispatchQueue.global().async {
                switch result {
                case .success(_):
                    callback(.success(data: nil))
                case .failure(let error):
                    let openAPIError = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("\(error)")
                    callback(.failure(error: openAPIError))
                }
            }
        })
    }

    static func tryHideBlock(
        params: OpenAPIBaseParams,
        context: OpenAPIContext,
        callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        guard let container = context.blockContainer else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("can not find container")
            context.apiTrace.error("can not find container")
            callback(.failure(error: error))
            return
        }
        container.tryHideBlock()
        callback(.success(data: nil))
    }

    static func updateBlockShareEnableStatus(
        params: OpenPluginBlockShareEnableStatusRequest,
        context: OpenAPIContext,
        callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        guard let container = context.blockContainer else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("can not find container")
            context.apiTrace.error("can not find container")
            callback(.failure(error: error))
            return
        }
        container.updateBlockShareEnableStatus(params.enableShare)
        callback(.success(data: nil))
    }

    static func receiveBlockShareInfo(
        params: OpenPluginReceiveBlockShareInfoRequest,
        context: OpenAPIContext,
        callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        guard let container = context.blockContainer else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("can not find container")
            context.apiTrace.error("can not find container")
            callback(.failure(error: error))
            return
        }
        container.receiveBlockShareInfo(OPBlockShareInfo(
            title: params.title,
            imageKey: params.imageKey,
            detailBtnName: params.detailBtnName,
            detailBtnLink: params.detailBtnLink,
            customMainLabel: params.customMainLabel
        ))
        callback(.success(data: nil))
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerAsyncHandler(for: "setContainerConfig", paramsType: OpenPluginSetContainerConfigRequest.self) { (params, context, callback) in
            Self.setContainerConfig(params: params, context: context, callback: callback)
        }
        
        registerAsyncHandler(for: "setBlockInfo", paramsType: OpenPluginSetBlockInfoRequest.self) { (params, context, callback) in
            Self.setBlockInfo(params: params, context: context, callback: callback)
        }
        
        registerAsyncHandler(for: "cancel", paramsType: OpenPluginCancelRequest.self) { (params, context, callback) in
            Self.cancel(params: params, context: context, callback: callback)
        }

        registerAsyncHandler(for: "hideBlockLoading", paramsType: OpenAPIBaseParams.self) { (params, context, callback) in
            Self.hideBlockLoading(params: params, context: context, callback: callback)
        }

        registerAsyncHandler(for: "blockShareEnableStatus", paramsType: OpenPluginBlockShareEnableStatusRequest.self) { (params, context, callback) in
            Self.updateBlockShareEnableStatus(params: params, context: context, callback: callback)
        }

        registerAsyncHandler(for: "receiveBlockShareInfo", paramsType: OpenPluginReceiveBlockShareInfoRequest.self) { (params, context, callback) in
            Self.receiveBlockShareInfo(params: params, context: context, callback: callback)
        }

        registerAsyncHandler(for: "tryHideBlock", paramsType: OpenAPIBaseParams.self) { (params, context, callback) in
            Self.tryHideBlock(params: params, context: context, callback: callback)
        }
    }
}
