//
//  SlidesModule.swift
//  SKCommon
//
//  Created by majie.7 on 2022/3/3.
//

import Foundation
import SKFoundation
import SKUIKit
import LarkUIKit
import SwiftyJSON
import EENavigator
import UniverseDesignToast
import SKInfra
import SKCommon
import SKBrowser
import LarkContainer

// Slide下线后为了保证slide链接打开可以跳转迁移后的ppt，保留该路由跳转逻辑
public final class SlidesModule: ModuleService {

    public init() {}
    private var request: DocsRequest<JSON>?

    public func setup() {
        DocsLogger.info("SlidesModule setup")
        DocsContainer.shared.register(SlidesModule.self, factory: { _ in
            return self
        }).inObjectScope(.container)
    }

    public func registerURLRouter() {
        //路由拦截器拦截旧版slides
        SKRouter.shared.register(checker: { (resource, _) -> (Bool) in
            if resource.docsType != .slides {
                return false
            }
            if let token = self.getSlidesToken(from: resource) {
                return self.isOldSlides(by: token)
            } else {
                return false
            }
        }, interceptor: { (resource, params) -> (UIViewController?) in
            let source = (params?[SKEntryBody.fromKey] as? FileListStatistics.Module)?.converToDocsFrom() ?? .other
            var newUrl = resource.url.docs.addEncodeQuery(parameters: ["from": source.rawValue])
            
            if let ccmOpenType = (params?[SKEntryBody.fromKey] as? FileListStatistics.Module)?.converToCCMOpenType(),
               ccmOpenType != .unknow {
                newUrl = newUrl.docs.addEncodeQuery(parameters: [CCMOpenTypeKey: ccmOpenType.trackValue])
            }
            let fromVC = self.fromVC(with: params)
            let token = self.getSlidesToken(from: resource)
            let vc = self.open(slideToken: token, slideURL: newUrl, resource: resource, from: fromVC)
            return vc
        })
    }
    
    private func getSlidesToken(from resource: SKRouterResource) -> String? {
        var token: String?
        if let slideUrl = resource as? URL {
            token = DocsUrlUtil.getFileToken(from: slideUrl)
        } else if let file = resource as? SpaceEntry {
            token = file.objToken
        }
        return token
    }
    
    private func open(slideToken: String?, slideURL: URL, resource: SKRouterResource, from: UIViewController) -> UIViewController? {
        guard let token = slideToken else {
            return SKRouterBottomViewController(.unavailable(.defaultView), title: "")
        }
        var handled = false
        // 局部handled变量，加锁保证线程安全
        let markHandled = {
            objc_sync_enter(handled)
            handled = true
            objc_sync_exit(handled)
        }
        let readHandled: (() -> Bool) = {
            objc_sync_enter(handled)
            let flag = handled
            objc_sync_exit(handled)
            return flag
        }
        /// 超时逻辑，超时直接打开失败页面
        let timeout = SettingConfig.isvMetaTimeout ?? 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            guard !readHandled() else {
                return
            }
            markHandled()
            DocsLogger.info("request slide's pptx url timeout:", extraInfo: ["timeout": timeout, "token": slideToken?.encryptToken ?? ""])
            UDToast.removeToast(on: from.view)
            self.showFailView(from: from)
        }
        
        UDToast.showDefaultLoading(on: from.view, disableUserInteraction: true)
        requestPPTToken(token: slideToken) { token in
            UDToast.removeToast(on: from.view)
            guard !readHandled() else {
                return
            }
            markHandled()
            /// 返回空字符串表示没有匹配pptx
            if let pptxToken = token, !pptxToken.isEmpty {
                let url = DocsUrlUtil.url(type: .file, token: pptxToken)
                Navigator.shared.push(url, from: from)
            } else {
                // slide下线后对于链接打开的slide，后端如果没有匹配的pptx直接展示错误页面
                DocsLogger.error("no have the pptx transform from the slide file, token: \(slideToken?.encryptToken ?? "")")
                self.showFailView(from: from)
            }
        }
        return nil
    }
    
    private func isOldSlides(by token: String) -> Bool {
        return token.count == 20 || token.hasPrefix("sld") // 目前后端旧版slide token生成规则
    }
    
    private func showFailView(from: UIViewController) {
        let vc = SKRouterBottomViewController(.unavailable(.defaultView), title: "")
        if SKDisplay.pad {
            Navigator.shared.showDetailOrPush(vc, from: from, animated: true)
        } else {
            Navigator.shared.push(vc, from: from)
        }
    }
    
    private func requestPPTToken(token: String?, completion: @escaping ((String?) -> Void)) {
        guard let token = token else {
            DocsLogger.error("slide file no token, Unable to request")
            completion(nil)
            return
        }
        var pramas = [String: Any]()
        pramas["slide_token"] = token
        request?.cancel()
        
        request = DocsRequest<JSON>(path: OpenAPI.APIPath.queryPPTXToken,
                                    params: pramas)
            .set(method: .GET)
        request?.start(result: { result, error in
            if let error = error {
                DocsLogger.error("request failed: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let json = result,
                  let code = json["code"].int else {
                DocsLogger.error("request failed data invalide")
                completion(nil)
                return
            }
            if code != 0 {
                DocsLogger.error("request failed server code: \(code)")
                completion(nil)
                return
            }
            guard let jsonData = json["data"].dictionaryObject,
                  let pptxToken = jsonData["pptx_token"] as? String else {
                DocsLogger.error("request failed no data")
                completion(nil)
                return
            }
            completion(pptxToken)
        })
    }
    
    private func fromVC(with params: [AnyHashable: Any]?) -> UIViewController {
        if let context = params as? [String: Any],
           let from = context[ContextKeys.from],
           let fromWrapper = from as? NavigatorFromWrapper,
           let fromVC = fromWrapper.fromViewController {
            return fromVC
        } else if let vc = Navigator.shared.mainSceneWindow?.fromViewController {
            return vc
        } else {
            return UIViewController()
        }
    }
}

extension SlidesModule {
    
    public func registerJSServices(type: DocsJSServiceType, ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void) {
        switch type {
        case .individualBusiness:
            register(BlockMenuService(ui: ui, model: model, navigator: navigator))
        default:
            break
        }
    }
    
}
