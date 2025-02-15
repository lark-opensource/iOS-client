//
//  OpenPluginOnSubmitInputAPI.swift
//  LarkOpenApis
//
//  GENERATED BY ANYCODE on 2023/4/18 08:52:55
//

import Foundation
import LarkOpenAPIModel
import Lynx
import EENavigator
import LarkNavigator
import LarkAlertController
import LarkOpenPluginManager
import LarkContainer

// MARK: - OpenPluginOnSubmitInputAPI
final class OpenPluginOnSubmitInputAPI: OpenBasePlugin {
    
    enum APIName: String {
        case onSubmitInput
    }
    // 消息卡片 Input 组件接口
    private func onSubmitInputAPI(
        params: OpenPluginOnSubmitInputRequest,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            context.apiTrace.info("onSubmitInputAPI API call start")
            guard let msgContext = context.additionalInfo["msgContext"] as? MessageCardLynxContext,
                  let bizContext = msgContext.bizContext as? MessageCardContainer.Context,
                  let actionService = bizContext.dependency?.actionService else {
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                context.apiTrace.error("onSubmitInputAPI API: action service is nil")
                return
            }
            // 如果存在 confirm 则先弹窗由用户确认
            if let confirm = params.confirm, !confirm.title.isEmpty && !confirm.text.isEmpty {
                let alert = LarkAlertController()
                alert.setTitle(text: confirm.title ?? "")
                alert.setContent(text: confirm.text ?? "")
                alert.addSecondaryButton(text: BundleI18n.LarkMessageCard.Lark_Legacy_Cancel, dismissCompletion:  {
                   callback(.continue(event: "", data: OpenAPIMessageCardResult(.fail, resultCode: .userCancel) ))
                })
                alert.addPrimaryButton(text: BundleI18n.LarkMessageCard.Lark_Legacy_Sure, dismissCompletion:  {
                   self.sendInputValue(params: params, context: context, callback: callback, service: actionService, msgContext: msgContext)
                   context.apiTrace.info("onSubmitInputAPI API: send action with comfirm")
                   callback(.continue(event: "", data: OpenAPIMessageCardResult(.success, resultCode: .success) ))
                })
                self.presentController(vc: alert, context: context)
                context.apiTrace.info("onSubmitInputAPI API call end")
            } else {
                // 调用接口发送 Input 的值
                self.sendInputValue(params: params, context: context, callback: callback, service: actionService, msgContext: msgContext)
                callback(.success(data: OpenAPIMessageCardResult(.success, resultCode: .success)))
            }
    }
    
    // 弹出确认窗口
    private func presentController(vc: UIViewController, context: OpenAPIContext) {
        guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else {
            context.apiTrace.error("onSubmitInputAPI API: fromVC is nil")
            return
        }
        Navigator.shared.present(vc, wrap: nil, from: fromVC, prepare: { controller in
            #if canImport(CryptoKit)
            if #available(iOS 13.0, *) {
                if controller.modalPresentationStyle == .automatic {
                    controller.modalPresentationStyle = .fullScreen
                }
            }
            #endif
        })
    }
    
    // 发送 Input 值
    private func sendInputValue(
        params: OpenPluginOnSubmitInputRequest,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void,
        service: MessageCardActionService,
        msgContext: MessageCardLynxContext
    ) {
        let actionContext = MessageCardActionContext(
            elementTag: params.tag,
            elementID: params.elementID,
            bizContext: msgContext.bizContext,
            actionFrom: nil
        )
        let lynxView = MsgCardAPIUtils.getLynxView(context: context)
        let updateActionState = { [weak lynxView] (_ newState: ActionState) in
            guard let lynxView = lynxView else {
                context.apiTrace.error("showMsgCardOverflow API: lynxView is nil")
                return
            }
            // 向 Lynx 发送消息,更新卡片状态
            lynxView.updateCardState(
                elementID: params.elementID,
                eventName: newState.rawValue,
                params: params.params?.toDict()
            )
            context.apiTrace.info("doMsgCardAction API: send event")
        }
        updateActionState(.actionStart)
        // 调用接口, 向服务端更新 Input 数据
        service.sendAction(context: actionContext,
                           actionID: params.actionID,
                           params: params.params?.toDict(),
                           isMultiAction: false,
                           updateActionState: updateActionState,
                           callback: nil
        )
            
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: APIName.onSubmitInput.rawValue, pluginType: Self.self, paramsType: OpenPluginOnSubmitInputRequest.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            this.onSubmitInputAPI(params: params, context: context, callback: callback)
        }
    }
}

extension OpenPluginOnSubmitInputRequest.ParamsObject {
    public func toDict() -> [String: String] {
        var dict: [String: String] = ["input_value":input_value]
        if (name != nil){ dict["name"] = name }
        return dict
    }
}
