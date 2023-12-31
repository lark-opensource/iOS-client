//
//  PreloadHtmlServices.swift
//  SpaceKit
//
//  Created by LiXiaolin on 2019/8/7.
//  直出html完成之后web会调用这里
import SKCommon
import SKFoundation

class PreloadHtmlServices: BaseJSService {

//    weak var translationViewController: TranslationOrignalViewController?
//    private lazy var orignalAdapter: WebTranslationOrigAdapter = WebTranslationOrigAdapter(self)

}

extension PreloadHtmlServices: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.preLoadHtmlFinish]
    }

    func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(serviceName)
        DocsLogger.info("preload HtmlServices preLoadHtmlFinish")
        switch service {
        case .preLoadHtmlFinish:
            guard let type = params["type"] as? String else {
                return
            }
            guard let token = params["token"] as? String else {
                return
            }
            guard let result = params["success"] as? Bool else {
                return
            }
            let encryToken = DocsTracker.encrypt(id: token)
            NotificationCenter.default.post(name: Notification.Name.Docs.preloadDocsHtmlFinished, object: nil, userInfo: ["token": token])
            DocsLogger.info("preLoad HtmlFinish,type:\(type),token:\(encryToken),isSuccess:\(result)")
        default:
            DocsLogger.info("preload HtmlServices enter default")
        }
    }
}
