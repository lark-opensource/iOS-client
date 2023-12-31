//
//  OpenPluginShowModalTip.swift
//  OPPlugin
//
//  Created by yi on 2021/2/19.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOProbe
import ECOInfra
import LarkContainer

final class OpenPluginShowModalTip: OpenBasePlugin {

    func getShowModalTipInfo(context: OpenAPIContext, showModalTipExtension: OpenAPIShowModalTipInfoExtension, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let name = showModalTipExtension.applicationName()
        let uniqueDescription = showModalTipExtension.commonExtension.uniqueDescription()
        
        let title = BundleI18n.OPPlugin.continue_show_modal_tip.replacingOccurrences(of: "%@", with: name)
        let cancelText = BundleI18n.OPPlugin.continue_show_modal_no
        let confirmText = BundleI18n.OPPlugin.continue_show_modal_exit
        if title.isEmpty || cancelText.isEmpty || confirmText.isEmpty {
            let msg = "get show modal tip info failed, app=\(uniqueDescription), titleLength=\(title.count), cancelText=\(cancelText), confirmText=\(confirmText)"
            context.apiTrace.error(msg)
            let error = OpenAPIError(code: GetShowModalTipInfoErrorCode.failed)
                .setMonitorMessage(msg)
            callback(.failure(error: error))
            return
        }
        let info = OpenAPIShowModalTipResult(title: title, cancelText: cancelText, confirmText: confirmText)
        callback(.success(data: info))
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerAsync(
            for: "getShowModalTipInfo",
            registerInfo: .init(pluginType: Self.self),
            extensionInfo: .init(type: OpenAPIShowModalTipInfoExtension.self, defaultCanBeUsed: true)) {
                Self.getShowModalTipInfo($0)
            }
    }
}
