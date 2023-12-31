//
//  TranslationgShowLoadingService.swift
//  SpaceKit
//
//  Created by LiXiaolin on 2019/6/11.
//  

import UniverseDesignToast
import SKCommon
import SKFoundation

class TranslationLoadingService: BaseJSService {

}

extension TranslationLoadingService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.showTranslationLoding,
                .hideTranslationLoding]
    }

    func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(serviceName)
        switch service {
        case .showTranslationLoding:
            guard let message = params["msg"] as? String else {
                DocsLogger.info("TranslationgShowLoadingService msg parames not right", extraInfo: params, error: nil, component: nil)
                return
            }
            guard params["gravity"] as? String != nil else {
                DocsLogger.info("TranslationgShowLoadingService position parames not right", extraInfo: params, error: nil, component: nil)
                return
            }
            showActivityIndicatiorHUD(message, in: ui!.hostView)
        case .hideTranslationLoding:
            UDToast.removeToast(on: ui!.hostView)

        default:
            DocsLogger.info("TranlateService setUpTranslation enter default", extraInfo: params, error: nil, component: nil)
        }
    }

    @discardableResult
    func showActivityIndicatiorHUD(_ title: String, in view: UIView) -> UDToast {
        return UDToast.showLoading(with: title, on: view, disableUserInteraction: false)
    }
}
