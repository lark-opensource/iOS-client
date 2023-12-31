//
//  SKCommonDependencyImpl.swift
//  SpaceKit
//
//  Created by lijuyou on 2021/1/11.
//  


import Foundation
import SKCommon
import SKBrowser
import SKFoundation
import SKUIKit
import SKWikiV2
import SKSpace
import SKDrive
import RxSwift
import RxRelay
import WebKit
import SpaceInterface
import SKInfra
import SKWorkspace
import LarkContainer

class SKCommonDependencyImpl: SKCommonDependency {
    
    private var userResolver: UserResolver {
        Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
    }
    
    let bag = DisposeBag()
    var currentEditorView: UIView? {
        return EditorManager.shared.currentEditor?.editorView
    }

    /// 用到这里只是为了查询VC栈是否为空，直接使用下面那个就行了，废弃该使用
    /// 如果需要用到这个场景，请找@lizechuang
//    var docsBrowserVCStack: [UIViewController] {
//        return EditorManager.shared.browsersStack
//    }


    var browserViewWidth: CGFloat {
        return EditorManager.shared.currentEditor?.frame.width ?? 0.0
    }
    
    var allDocsWebViews: [DocsWebViewV2] {
        let allWebViews = EditorManager.shared.pool.getAllItems().flatMap {
            let webview = ($0 as? BrowserView)?.editorView as? DocsWebViewV2
            return webview
        }
        return allWebViews
    }

    func changeVConsoleState(_ isOpen: Bool) {
        if let currentEditorView = EditorManager.shared.currentEditor?.editorView {
            if let webView = currentEditorView as? DocsWebViewV2 {
                if isOpen {
                    webView.openVConsole()
                } else {
                    webView.closeVConsole()
                }
            }
        } else {
            EditorManager.shared.drainPoolAndPreload()
        }
    }

    func createDefaultWebViewController(url: URL) -> UIViewController {
        let webVC = WebViewController(url)
        webVC.header = EditorManager.shared.netRequestHeader
        webVC.urlHandler = { [weak webVC] url in
            guard let unWrappedUrl = url else { return .allow }
            guard URLValidator.isDocsURL(unWrappedUrl) else {
                return .allow
            }
            guard let navController = webVC?.navigationController else { return .allow }
            let (viewController, supported) = SKRouter.shared.open(with: unWrappedUrl)
            guard let vc = viewController else {
                spaceAssertionFailure("不能走到这里")
                return .cancel
            }
            if supported {
                navController.pushViewController(vc, animated: true) {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: {
                        // 移除掉这个webvc
                        var navVCs = navController.viewControllers
                        guard let webVCIndex = navVCs.lastIndex(of: webVC!) else {
                            return
                        }
                        navVCs.remove(at: webVCIndex)
                        navController.setViewControllers(navVCs, animated: false)
                    })
                }
                return .cancel
            }
            return .allow
        }
        return webVC
    }

    func createCompleteV2(token: String,
                          type: DocsType,
                          source: FromSource?,
                          ccmOpenType: CCMOpenType?,
                          templateCenterSource: SKCreateTracker.TemplateCenterSource?,
                          templateSource: TemplateCenterTracker.TemplateSource? = nil,
                          moduleDetails: [String: Any]?,
                          templateInfos: [String: Any]?,
                          extra: [String: Any]?) -> UIViewController? {

        return EditorManager.shared.createCompleteV2(token: token,
                                                     type: type,
                                                     source: source,
                                                     ccmOpenType: ccmOpenType,
                                                     templateCenterSource: templateCenterSource,
                                                     templateSource: templateSource,
                                                     moduleDetails: moduleDetails,
                                                     templateInfos: templateInfos,
                                                     extra: extra)
    }

    /// 重置Wiki Storage DB
    func resetWikiDB() {
        guard let wikiSrtorageAPI = try? userResolver.resolve(assert: WikiStorageBase.self) else {
            DocsLogger.error("can not get wikiSrtorageAPI")
            return
        }
        wikiSrtorageAPI.resetDB()
    }

    func getWikiStorageObserver() -> SimpleModeObserver? {
        return userResolver.resolve(WikiStorageBase.self)
    }

    /// 保存WikiNodeMeta信息
    func setWikiMeta(wikiToken: String, completion: @escaping (WikiInfo?, Error?) -> Void) {
        guard let wikiSrtorageAPI = try? userResolver.resolve(assert: WikiStorageBase.self) else {
            completion(nil, WikiError.storageNotInitialized)
            return
        }
        wikiSrtorageAPI.setWikiMeta(wikiToken: wikiToken, completion: completion)
    }

    // 下面两个方法是 SKCommon.OnboardingSyncronizer 为了引用 SKECM.SpaceRustRouter 方法而做的胶水层注入

    func getSKOnboarding() -> Observable<[String: Bool]> {
        return SpaceRustRouter.shared.pullProductGuide(guideScene: .ccm)
    }

    func doneSKOnboarding(keys: [String]) {
        SpaceRustRouter.shared.postUserConsumingGuide(keys: [],
                                                      keyStep: [:],
                                                      context: [:],
                                                      keysDone: keys)
    }
}
