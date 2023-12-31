//
//  OpenPluginMsgCardShowSelectMenuAPI.swift
//  LarkMessageCard
//
//  Created by zhangjie.alonso on 2023/10/24.
//

import Foundation
import LarkOpenAPIModel
import LarkOpenPluginManager
import LarkNavigator
import EENavigator
import LarkContainer
import UniversalCardInterface
import LarkFoundation
import ECOProbe

// MARK: - OpenPluginUniversalCardSendClientMessageAPI
final class OpenPluginUniversalCardSendClientMessageAPI: UniversalCardAPIPlugin {


    private var publishService: CardClientMessagePublishService?

    enum APIName: String {
        case universalCardSendClientMessage
    }

    private func sendClientMessage(
        params: OpenPluginUniversalCardSendClientMessageRequest,
        context: UniversalCardAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            context.apiTrace.info("sendClientMessage API call start")
            context.apiTrace.info("universalCardSendClientMessage API:\ntag:\(params.tag)\nchannel:\(params.channel)\nactionParams:\(params.value)\nelementID:\(params.elementID)\nname:\(params.name)\nplatformConfig:\(params.platformConfig)\nexpiredTime:\(params.expiredTime)\nexpiredTips:\(params.expiredTips)")
            let start = Date()
            guard let actionService = context.cardContext.dependency?.actionService else {
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                context.apiTrace.error("universalCardSendClientMessage API: action service is nil")
                reportAction(code: EPMClientOpenPlatformCardCode.card_client_message_unknown_error, context: context.cardContext, start: nil, componentTag: params.name, errorMsg: "get actionService failed")
                return
            }

            guard let publishService = publishService else {
                context.apiTrace.error("sendClientMessage API: publishService is nil")
                reportAction(code: EPMClientOpenPlatformCardCode.card_client_message_unknown_error, context: context.cardContext, start: nil, componentTag: params.name, errorMsg: "publishService is nil")
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                return
            }

            let showToastHandler = { text in
                let actionContext = UniversalCardActionContext(
                    trace: context.cardContext.renderingTrace?.subTrace() ?? context.cardContext.trace.subTrace(),
                    elementTag: params.tag,
                    elementID: params.elementID,
                    bizContext: nil,
                    actionFrom: nil
                )
                actionService.showToast(context: actionContext, type: .error, text: text, on: nil)
            }

            guard self.checkPermission(params: params, context: context, showToastHandler: showToastHandler) else {
                let error = OpenAPIError(errno: OpenAPICommonErrno.authenFail)
                callback(.failure(error: error))
                return
            }

            if(!publishService.publish(channel: params.channel, value: params.value)) {
                context.apiTrace.error("sendClientMessage channel: \(params.channel) not find handler")
                let fallbackToast = params.platformConfig?["fallbackToast"] as? String ?? BundleI18n.UniversalCardBase.OpenPlatform_UniversalCard_ClientMsgNotSupport
                showToastHandler(fallbackToast)
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                reportAction(code: EPMClientOpenPlatformCardCode.card_client_message_error, context: context.cardContext, start: nil, componentTag: params.name, errorMsg: "no handler")
                return
            }
            reportAction(code: EPMClientOpenPlatformCardCode.card_client_message_success, context: context.cardContext, start: start, componentTag: params.name, errorMsg: nil)
            callback(.success(data: nil))
            context.apiTrace.info("sendClientMessage API call end")
    }

    private func checkPermission(
        params: OpenPluginUniversalCardSendClientMessageRequest,
        context: UniversalCardAPIContext,
        showToastHandler: (String) -> Void) -> Bool {

            guard let platformConfig = params.platformConfig else {
                context.apiTrace.warn("sendClientMessage platformConfig is nil")
                showToastHandler(BundleI18n.UniversalCardBase.OpenPlatform_UniversalCard_ClientMsgNotSupport)
                reportAction(code: EPMClientOpenPlatformCardCode.card_client_message_error, context: context.cardContext, start: nil, componentTag: params.name, errorMsg: "platform not support")
                return false
            }
            let fallbackToast = platformConfig["fallbackToast"] as? String
            //端类型校验
            guard let support = platformConfig["support"] as? Bool, support else {
                context.apiTrace.warn("sendClientMessage not support current os")
                showToastHandler(fallbackToast ?? BundleI18n.UniversalCardBase.OpenPlatform_UniversalCard_ClientMsgNotSupport)
                reportAction(code: EPMClientOpenPlatformCardCode.card_client_message_error, context: context.cardContext, start: nil, componentTag: params.name, errorMsg: "platform not support")
                return false
            }
            //appVersion 校验
            guard let minVersion = platformConfig["minVersion"] as? String,
                  Utils.appVersion >= minVersion else {
                context.apiTrace.warn("sendClientMessage min_version failed: cur: \(Utils.appVersion) param: \(platformConfig["min_version"] as? String ?? "")")
                showToastHandler(BundleI18n.UniversalCardBase.OpenPlatform_UniversalCard_ClientMsgUpdateNote())
                reportAction(code: EPMClientOpenPlatformCardCode.card_client_message_error, context: context.cardContext, start: nil, componentTag: params.name, errorMsg: "version not match")
                return false
            }
            //时间戳校验
            if let expiredTimeStr = params.expiredTime,
               let expiredTime = UInt64(expiredTimeStr),
               UInt64(Date().timeIntervalSince1970) > expiredTime {
                if let expiredTips = params.expiredTips {
                    showToastHandler(expiredTips)
                }
                reportAction(code: EPMClientOpenPlatformCardCode.card_client_message_error, context: context.cardContext, start: nil, componentTag: params.name, errorMsg: "action is expired")
                context.apiTrace.warn("sendClientMessage expiredTime failed: expiredTime: \(expiredTime) cur:  \(UInt64(Date().timeIntervalSince1970) )")
                return false
            }
            context.apiTrace.info("sendClientMessage checkPermission success")
            return true
    }

    private func reportAction(
        code: OPMonitorCodeProtocol,
        context: UniversalCardContext,
        start: Date?,
        componentTag: String?,
        errorMsg: String?
    ){
        let monitor = OPMonitor(name: "op_open_card",code: code)
            .tracing(context.renderingTrace?.subTrace())
        if let cardID = context.sourceData?.cardID {
            monitor.addCategoryValue("card_id", cardID)
        }
        if let componentTag = componentTag {
            monitor.addCategoryValue("component_tag", componentTag)
        }
        if let renderBusinesstype = context.renderBizType {
            monitor.addCategoryValue("render_business_type", renderBusinesstype)
        }
        if let errorMsg = errorMsg {
            monitor.setErrorMessage(errorMsg)
        }
        if let start = start {
            monitor.setDuration(Date().timeIntervalSince(start))
        }
        monitor.flush()
    }

    required public init(resolver: UserResolver) {
        super.init(resolver: resolver)
        self.publishService = try? resolver.resolve(assert: CardClientMessagePublishService.self)
        registerCardAsyncHandler(
            for: APIName.universalCardSendClientMessage.rawValue,
            pluginType: Self.self,
            paramsType: OpenPluginUniversalCardSendClientMessageRequest.self,
            resultType: OpenAPIBaseResult.self
        ) { (this, params, context, callback) in
            this.sendClientMessage(params: params, context: context, callback: callback)
        }
    }

}
