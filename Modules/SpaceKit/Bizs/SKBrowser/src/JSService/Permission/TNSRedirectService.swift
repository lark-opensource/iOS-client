//
//  TNSRedirectService.swift
//  SKBrowser
//
//  Created by Weston Wu on 2023/6/27.
//

import Foundation
import WebBrowser
import SpaceInterface
import SKCommon
import SKFoundation
import EENavigator

class TNSRedirectService: BaseJSService {
    private var redirectReady = false
    private var redirectInfo: TNSRedirectInfo?
    private var canRedirect = true

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension TNSRedirectService: BrowserViewLifeCycleEvent {
    // 由于 MagicShare 场景的 Controller 复用机制，从小窗恢复会直接将 browser 展示出来，需要在这里再次触发重定向
    func browserDidChangeFloatingWindow(isFloating: Bool) {
        guard !isFloating else { return }
        guard let redirectInfo else { return }
        DocsLogger.error("redirect to tns H5 within browser after resume VC full window")
        performTNSRedirect(info: redirectInfo)
    }

    func browserDidAppear() {
        redirectReady = true
        guard let redirectInfo else { return }
        // didAppear 后也有概率出现立即 push 不生效的问题，加一个小的延时绕过一下
        // nolint-next-line: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) { [weak self] in
            guard let self,
                  self.canRedirect,
                  self.redirectReady else {
                return
            }
            DocsLogger.error("redirect to tns H5 within browser after browser did appear")
            self.performTNSRedirect(info: redirectInfo)
        }
    }

    func browserWillDismiss() {
        redirectReady = false
    }

    func browserWillClear() {
        // 避免延迟释放导致潜在的污染下一篇文档问题
        canRedirect = false
        redirectInfo = nil
    }
}

extension TNSRedirectService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.notifyBlockByTNS]
    }

    func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(serviceName)
        switch service {
        case .notifyBlockByTNS:
            notifyBlockByTNS(params: params)
        default:
            break
        }
    }

    private func notifyBlockByTNS(params: [String: Any]) {
        guard canRedirect else { return }
        DocsLogger.info("UpdateUserPermissionService notify block by tns", component: LogComponents.permission)
        guard let urlString = params["url"] as? String,
              let url = URL(string: urlString) else {
            DocsLogger.error("failed to parse url from params")
            return
        }
        let inVideoConference = model?.vcFollowDelegate != nil
        let info: TNSRedirectInfo
        if let docsInfo = model?.browserInfo.docsInfo {
            info = TNSRedirectInfo(meta: SpaceMeta(objToken: docsInfo.token,
                                                   objType: docsInfo.inherentType),
                                   redirectURL: url,
                                   module: docsInfo.inherentType.module?.rawValue ?? "unknown",
                                   appForm: inVideoConference ? .inVideoConference : .standard,
                                   subModule: nil,
                                   creatorID: docsInfo.creatorID,
                                   ownerID: docsInfo.ownerID,
                                   ownerTenantID: docsInfo.tenantID)
        } else {
            DocsLogger.error("failed to get docsInfo when parsing tns redirect event")
            info = TNSRedirectInfo(meta: SpaceMeta(objToken: "", objType: .unknownDefaultType),
                                   redirectURL: url,
                                   module: "unknown",
                                   appForm: inVideoConference ? .inVideoConference : .standard)
        }
        redirectInfo = info
        // 要等到 push 动画结束才能触发重定向
        guard redirectReady else { return }
        DocsLogger.info("redirect to tns H5 within browser after notified by FE", component: LogComponents.permission)
        performTNSRedirect(info: info)
    }

    private func performTNSRedirect(info: TNSRedirectInfo) {
        guard let from = navigator?.navigatorFromVC,
              var hostController = navigator?.currentBrowserVC else {
            spaceAssertionFailure("unable to perform TNS redirect, controller not found")
            return
        }
        // 找到最接近 navigationController 的 Controller
        while let parent = hostController.parent, !parent.isKind(of: UINavigationController.self) {
            hostController = parent
        }
        let action = { [weak self] in
            // hideShowMore 参数内部实际没有生效，要依赖 TNS 前端去隐藏 More
            let body = WebBody(url: info.finalURL, hideShowMore: true)
            self?.model?.userResolver.navigator.push(body: body, from: hostController, animated: false) { _, _ in
                hostController.navigationController?.viewControllers.removeAll(where: { $0 == hostController })
            }
        }

        if let browserVC = navigator?.currentBrowserVC as? BrowserViewController,
           let feedFromInfo = browserVC.fileConfig?.feedFromInfo,
           feedFromInfo.canShowFeedAtively == true {
            // 从 feed 打开场景，需要延迟到 feed panel 打开后再重定向
            // feed 在 viewDidLoad 时立即 present FeedPanelVC，但此时无法读取到 presentedVC，此刻立即 push VC 会失效
            // 这里延迟到 feedPanelVC present 动画完成后再触发重定向逻辑, delay 时间为 present 的动画估时 500 毫秒
            
            let delay = DispatchQueueConst.MilliSeconds_500
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if let presentedVC = hostController.presentedViewController {
                    presentedVC.dismiss(animated: false, completion: action)
                } else {
                    action()
                }
            }
        } else {
            action()
        }
    }
}
