//
//  OpenPluginRichTextComponent.swift
//  OPPlugin
//
//  Created by zhysan on 2021/4/26.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LKCommonsLogging
import LarkSetting
import OPPluginBiz
import LarkContainer

final class OpenPluginRichTextComponent: OpenBasePlugin {
    
    private lazy var disableUpdateOpt: Bool = {
        userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.component.customized_input.update_opt.disable")
    }()
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "showRichText", pluginType: Self.self, paramsType: OpenAPIRichTextParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            this.showRichText(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(for: "hideRichText", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            this.hideRichText(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
    
    func showRichText(
        params: OpenAPIRichTextParams,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        guard let vc = gadgetContext.controller, let container = gadgetContext.controller?.view else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setErrno(OpenAPICommonErrno.internalError)
                .setMonitorMessage("controller is nil")
            context.apiTrace.error("controller is nil")
            callback(.failure(error: error))
            return
        }
        
        if let exist = findStickerInputView(in: container) {
            if (disableUpdateOpt) {
                exist.removeFromSuperview()
            } else {
                exist.model = params.inputModel;
                exist.sizeToFit()
                return;
            }
        }
        
        let inputView = TMAStickerInputView(
            frame: CGRect(x: 0, y: 0, width: container.bounds.size.width, height: 0),
            currentViewController: vc,
            model: params.inputModel,
            uniqueID: gadgetContext.uniqueID
        )
        container.addSubview(inputView)
        
        inputView.modelChangedBlock = { [weak inputView] type in
            guard let inputView = inputView else {
                context.apiTrace.warn("nil input view")
                return
            }
            inputView.collectData(with: type, uniqueID: gadgetContext.uniqueID, session: gadgetContext.session, sessionHandler: GadgetSessionFactory.storage(for: gadgetContext).sessionHeader) { [weak inputView] in
                guard let inputView = inputView, let model = inputView.model else {
                    context.apiTrace.warn("nil input view")
                    return
                }
                context.fireEvent(event: model.eventName, data: model.eventData(with: type))
                if type == .hide || type == .publish {
                    inputView.removeFromSuperview()
                }
            }
        }
        inputView.onError = { [weak inputView] errorType, eventType in
            guard let err = OpenAPIComponentCustomizedInputErrno.getErrno(errorType: errorType, eventType: eventType) else {
                context.apiTrace.warn("richtext error not found")
                return
            }
            guard let inputView = inputView, let model = inputView.model else {
                context.apiTrace.warn("nil input view")
                return
            }
            context.fireEvent(event: model.eventName, data: [
                "eventName": "error",
                "data" : [
                    "errno": err.errno(),
                    "errString": err.errString,
                ]
            ])
        }
        
        let w = container.bounds.width
        let h = inputView.heightThatFits()
        let x: CGFloat = 0.0
        let y = container.bounds.height - container.safeAreaInsets.bottom - h
        inputView.frame = CGRect(x: x, y: y, width: w, height: h)
        
        inputView.becomeFirstResponder()
        
        callback(.success(data: nil))
    }
    
    func hideRichText(
        params: OpenAPIBaseParams,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        guard let vc = gadgetContext.controller else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setErrno(OpenAPICommonErrno.internalError)
                .setMonitorMessage("controller is nil")
            context.apiTrace.error("controller is nil")
            callback(.failure(error: error))
            return
        }
        guard let input = findStickerInputView(in: vc.view) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setErrno(OpenAPICommonErrno.internalError)
                .setMonitorMessage("input is nil")
            context.apiTrace.error("input is nil")
            callback(.failure(error: error))
            return
        }
        input.removeFromSuperview()
        callback(.success(data: nil))
    }
}

private func findStickerInputView(in view: UIView) -> TMAStickerInputView? {
    for subview in view.subviews {
        if let input = subview as? TMAStickerInputView {
            return input;
        }
    }
    return nil
}

extension TMAStickerInputEventType {
    func convertToError() -> OpenAPIComponentCustomizedInputErrno? {
        switch self {
        case .hide:
            return .requestOpenIdError(eventType: "hide")
        case .modelSelect:
            return .requestOpenIdError(eventType: "modelSelect")
        case .picSelect:
            return .requestOpenIdError(eventType: "picSelect")
        case .publish:
            return .requestOpenIdError(eventType: "publish")
        default:
            return nil
        }
    }
}

extension OpenAPIComponentCustomizedInputErrno {
    static func getErrno(errorType: TMAStickerInputErrorType, eventType: TMAStickerInputEventType) -> OpenAPIComponentCustomizedInputErrno? {
        if errorType == .requestOpenID {
            return eventType.convertToError()
        }
        return nil
    }
}

fileprivate extension OpenAPIContext {
    func fireEvent(event: String, data: [AnyHashable: Any]?) {
        do {
            let evt = try OpenAPIFireEventParams(
                event: event,
                sourceID: NSNotFound,
                data: data,
                preCheckType: .none
            )
            let _ = self.syncCall(
                apiName: "fireEvent",
                params: evt,
                context: self
            )
        } catch {
            self.apiTrace.error("input fireEvent error: \(error)")
        }
    }
}
