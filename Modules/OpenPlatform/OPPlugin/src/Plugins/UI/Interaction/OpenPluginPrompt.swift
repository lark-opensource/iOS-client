//
//  OpenPluginPrompt.swift
//  OPPlugin
//
//  Created by yi on 2021/4/6.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LKCommonsLogging
import LarkContainer

final class OpenPluginPrompt: OpenBasePlugin {

    func showPrompt(params: OpenAPIShowPromptParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIShowPromptResult>) -> Void) {
        guard let controller = (context.gadgetContext)?.controller else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("controller is nil, has gadgetContext? \(context.gadgetContext != nil)")
            callback(.failure(error: error))
            return
        }

        guard let topVC = OPNavigatorHelper.topMostAppController(window: controller.view.window) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("Can not find a view controller to show prompt")
            callback(.failure(error: error))
            return
        }
        let placeholder = params.placeholder.isEmpty ? BundleI18n.OPPlugin.show_prompt_placeholder : params.placeholder
        var maxLength = params.maxLength.intValue
        if (maxLength == -1) {
            maxLength = LONG_MAX
        }
        let confirmText = params.confirmText.isEmpty ? BundleI18n.OPPlugin.show_prompt_ok : params.confirmText
        let cancelText = params.cancelText.isEmpty ? BundleI18n.OPPlugin.cancel : params.cancelText

        context.apiTrace.info("showPromptWithTitle")
        let window = topVC.view.window ?? OPWindowHelper.fincMainSceneWindow()
        let config = EMAAlertControllerConfig()
        config.alertWidth = min(window?.bdp_width ?? 0.0 * 0.808, 303)
        config.titleAligment = .left
        config.textviewEdgeInsets = UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 0)
        config.textviewHeight = 128
        config.textviewMaxLength = maxLength
        config.supportedInterfaceOrientations = topVC.supportedInterfaceOrientations
        if let alert = EMAAlertController(title: params.title, textviewPlaceholder: placeholder, preferredStyle: .alert, config: config) {
            alert.addAction(EMAAlertAction(title: cancelText, style: .cancel, handler: { (action) in

                let ret = OpenAPIShowPromptResult(confirm: false, cancel: true, inputValue: nil)
                callback(.success(data: ret))
            }))
            alert.addAction(EMAAlertAction(title: confirmText, style: .default, handler: { (action) in
                let ret = OpenAPIShowPromptResult(confirm: true, cancel: false, inputValue: alert.textview.text)
                callback(.success(data: ret))
            }))

            topVC.present(alert, animated: true, completion: nil)
        } else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("alert is nil")
            callback(.failure(error: error))
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "showPrompt", pluginType: Self.self, paramsType: OpenAPIShowPromptParams.self, resultType: OpenAPIShowPromptResult.self) { (this, params, context, callback) in
            
            this.showPrompt(params: params, context: context, callback: callback)
        }

    }
}
