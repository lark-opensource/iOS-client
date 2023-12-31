//
//  UtilDocsInfoUpdateService.swift
//  Action
//
//  Created by guotenghu on 2019/7/25.
//
// 复制更新editor 的 DocsInfo

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation
import RxSwift
import UniverseDesignToast
import SKResource
import SpaceInterface
import SKInfra
import LarkTab
import EENavigator
import LarkContainer
import LarkQuickLaunchInterface

final class UtilDocsInfoUpdateService: BaseJSService {
    //上次请求DocsInfo是否成功
    private var hasRequestSucc: Bool = false
    private var wikiInfoReqeustTask: DocsRequest<JSON>?
    private weak var docInfoUpdateReporter: DocsInfoDidUpdateReporter?
    private lazy var docsInfoDetailUpdater = DocsInfoDetailHelper.detailUpdater(for: hostDocsInfo)
    @InjectedSafeLazy var temporaryTabService: TemporaryTabService
    private var disposeBag = DisposeBag()

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        self.docInfoUpdateReporter = model.docsInfoUpateReporter
    }
}

extension UtilDocsInfoUpdateService: BrowserViewLifeCycleEvent {
    public func browserWillClear() {
        debugLog("browserWillClear")
        disposeBag = DisposeBag()
    }
}

extension UtilDocsInfoUpdateService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.utilUpdateDocInfo, .utilWikiFetchToken, .utilCheckSyncState]
    }

    public func handle(params: [String: Any], serviceName: String) {
        DocsContainer.shared.resolve(ListConfigAPI.self)?.excuteWhenSpaceAppearIfNeeded(needAdd: true, block: { [weak self] in
            guard let self = self else { return }
            switch serviceName {
            case DocsJSService.utilWikiFetchToken.rawValue:
                self.onWikiFetchToken(params)
            case DocsJSService.utilUpdateDocInfo.rawValue:
                self.updateDocInfo(params)
            case DocsJSService.utilCheckSyncState.rawValue:
                self.checkSyncStatus(params)
            default:
                spaceAssertionFailure("can not handle service \(serviceName)")
            }
        })
    }

    private func checkSyncStatus(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String else {
            return
        }
        var result: [String: Any] = [:]
        if let token = docsInfo?.token, !token.isFakeToken {
            result["objToken"] = token
            result["isWiki"] = docsInfo?.type == .wiki
            result["wikiToken"] = docsInfo?.wikiInfo?.wikiToken
        }
        self.model?.jsEngine.callFunction(DocsJSCallBack(rawValue: callback), params: result, completion: nil)
    }

    private func updateDocInfo(_ params: [String: Any]) {
        updateDocsInfoV2(params)
    }

    /// 3.11 加载流程，前端直接加载wiki url
    private func updateDocsInfoV2(_ params: [String: Any]) {
        guard let docsInfo = params["docsInfo"] as? DocsInfo else {
            spaceAssertionFailure("can not get docsInfo")
            return
        }
        // fakeToken的Wiki文档不阻塞流程
        guard docsInfo.type != .wiki || docsInfo.objToken.isFakeToken else {
            DocsLogger.info("wiki need to fetch wikiInfo first")
            return
        }
        guard docsInfo.type != .baseAdd else {
            DocsLogger.info("base add don't need to fetch common meta")
            return
        }
        
        debugLog("get docsInfo \(docsInfo.objToken)")
        if docsInfo.objToken.isFakeToken {
            NotificationCenter.default.rx.notification(Notification.Name.Docs.didSyncFakeObjToken(docsInfo.objToken))
                .subscribe { [weak self] notification in
                    self?.didReceivedReplaceFakeTokenNotification(notification: notification)
                }
                .disposed(by: disposeBag)

        } else {
            let forceRequest = (params["forceRequest"] as? Bool) ?? false
            startRequestDetail(docsInfo, forceRequest: forceRequest)
        }
    }

    private func didReceivedReplaceFakeTokenNotification(notification: Notification) {
        if let wikiInfo = notification.object as? WikiInfo {
            // wiki文档离线创建 需要更新 wikiInfo & objToken
            hostDocsInfo?.wikiInfo = wikiInfo
            hostDocsInfo?.type = wikiInfo.docsType
            hostDocsInfo?.urlToken = wikiInfo.wikiToken
            replaceFakeToken(with: wikiInfo.objToken)
            if wikiInfo.docsType != .sheet {
                //更换url需要用wikiToken
                replaceFakeTokenInUrl(with: wikiInfo.wikiToken)
            }
            return
        }
        if let info = notification.userInfo, let objToken = info["objToken"] as? String {
            hostDocsInfo?.urlToken = objToken
            replaceFakeToken(with: objToken)
            if hostDocsInfo?.type != .sheet {
                replaceFakeTokenInUrl(with: hostDocsInfo?.token)
            }
        }
    }

    private func onWikiFetchToken(_ params: [String: Any]) {
        guard let wikiInfo = params["wiki_info"] as? [String: Any],
            let type = wikiInfo["obj_type"] as? Int,
            !DocsType(rawValue: type).isUnknownType,
            let objToken = wikiInfo["obj_token"] as? String else {
                DocsLogger.error("[wiki] no wiki info")
                return
        }
        self.infoLog("get wiki info success")
        let docsType = DocsType(rawValue: type)
        hostDocsInfo?.type = docsType
        hostDocsInfo?.objToken = objToken
        guard let docsInfo = docsInfo else {
            DocsLogger.error("[wiki] no docsInfo after setWikiInfo")
            return
        }
        startRequestDetail(docsInfo)
    }

    func replaceFakeToken(with objToken: String) {
        var params: [String: Any] = [:]
        if hostDocsInfo?.objToken.isFakeToken == false {
            spaceAssertionFailure("objToken has already been real")
        }
        params["fakeToken"] = hostDocsInfo?.objToken
        params["objToken"] = objToken
        params["isWiki"] = hostDocsInfo?.wikiInfo?.wikiToken != nil
        params["wikiToken"] = hostDocsInfo?.wikiInfo?.wikiToken
        self.model?.jsEngine.callFunction(DocsJSCallBack.docSyncSuccess, params: params, completion: nil)
        if let docsInfo = hostDocsInfo {
            infoLog("replaceFakeToken OK, start requeset doc info")
            docsInfo.objToken = objToken
            startRequestDetail(docsInfo)
        } else {
            spaceAssertionFailure("replaceFakeToken notification, docsInfo is nil")
        }
    }

    private func replaceFakeTokenInUrl(with token: String?) {
        guard UserScopeNoChangeFG.LJW.urlUpdateEnabled else { return }
        guard let token, let fakeUrl = model?.hostBrowserInfo.currentURL else {
            spaceAssertionFailure("token|url is nil when replace fake url")
            return
        }
        if let fakeToken = DocsUrlUtil.getFileToken(from: fakeUrl),
           var urlComponent = URLComponents(url: fakeUrl, resolvingAgainstBaseURL: false) {
            let fakePath = urlComponent.path
            urlComponent.path = fakePath.replace(with: token, for: fakeToken)
            model?.hostBrowserInfo.currentURL = urlComponent.url
        } else {
            spaceAssertionFailure("fakeToken is nil or create urlComponent fail when replace fake url")
        }
    }

    private func startRequestDetail(_ docsInfo: DocsInfo, forceRequest: Bool = false) {
        DocsNetStateMonitor.shared.addObserver(self) { [weak self] (_, reachable) in
            guard let self = self else {
                return
            }
            guard !self.hasRequestSucc || forceRequest else {
                self.infoLog("has get doc info success, do not need requeset")
                return
            }
            if reachable {
                if !docsInfo.objToken.isFakeToken {
                    self.docInfoUpdateReporter?.loaderDidUpdateRealTokenAndType(info: docsInfo)
                }
                self.infoLog("start requeset doc info")
                self.requestDocsInfoDetail()
            }
        }
    }

    private func requestDocsInfoDetail() {
        guard !docsInfoDetailUpdater.isRequesting else {
            infoLog("requesting doc info")
            return
        }
        guard let docsInfo = hostDocsInfo else {
            infoLog("request detail failed, docsInfo is nil!")
            return
        }
        requestAggregationInfo()
        fetchContainerInfo()
        docsInfo.requestWatermarkInfo()
        docsInfoDetailUpdater.updateDetail(for: docsInfo, headers: model?.requestAgent.requestHeader ?? [:])
            .subscribe(onSuccess: { [weak self] in
                guard let self = self else { return }
                self.infoLog("fetch docsInfo success")
                self.hasRequestSucc = true
                self.docInfoUpdateReporter?.loaderDidUpdateDocsInfo(stage: .getWholeInfo, error: nil)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                let errmsg: String = {
                    let nsErr = error as NSError
                    return "\(nsErr.code):\(nsErr.domain)"
                }()
                self.infoLog("fetch docsInfo error: \(errmsg)")
                self.hasRequestSucc = false
            })
            .disposed(by: disposeBag)
    }

    private func requestAggregationInfo() {
        guard let docsInfo = hostDocsInfo else {
            infoLog("request aggregation info failed, docsInfo is nil!")
            return
        }
        var objToken = docsInfo.objToken
        var objType = docsInfo.type
        let infoTypes: Set<DocsInfoDetailHelper.AggregationInfoType>
        if let wikiInfo = docsInfo.wikiInfo {
            objToken = wikiInfo.wikiToken
            objType = .wiki
            infoTypes = [.isSubscribed]
        } else {
            infoTypes = [.isSubscribed, .objUrl]
        }
        DocsInfoDetailHelper.getAggregationInfoWithLogID(token: objToken,
                                                         objType: objType,
                                                         infoTypes: infoTypes,
                                                         scence: .objDetail)
            .subscribe( onSuccess: { [weak self] result, logID in
                switch result {
                case let .success(info):
                    if let isSubscribed = info.isSubscribed {
                        docsInfo.subscribed = isSubscribed
                    }
                    if let wikiToken = info.wikiToken {
                        self?.redirectToWikiIfNeeded(wikiToken: wikiToken, objToken: objToken, objType: objType, logID: logID)
                    }
                    if docsInfo.shareUrl == nil, let url = info.url, url.isEmpty == false {
                        docsInfo.shareUrl = url
                    } else if docsInfo.isVersion {
                        if let shareUrl = self?.model?.requestAgent.currentUrl?.absoluteString, let idx = shareUrl.firstIndex(of: "?") {
                            docsInfo.shareUrl = String(shareUrl[..<idx])
                        }
                    }
                    docsInfo.updatePhoenixShareURLIfNeed()
                case .allFailed:
                    DocsLogger.error("get aggregation info all failed")
                case let .partialSuccess(info):
                    DocsLogger.error("get aggregation info partial failed")
                    if let isSubscribed = info.isSubscribed {
                        docsInfo.subscribed = isSubscribed
                    }
                case .invalidParameter:
                    spaceAssertionFailure("get aggregation info failed, please check parameter")
                case .fileNotFound:
                    DocsLogger.error("file not found when get aggregation info")
                case .internalUnknownError:
                    DocsLogger.error("server internal unknown error when get aggregation info")
                }
            }, onError: { (error) in
                DocsLogger.error("fetch aggregationInfo failed with error", error: error)
            }).disposed(by: disposeBag)
    }

    private func fetchContainerInfo() {
        guard let docsInfo = hostDocsInfo else {
            return
        }
        // 如果文档类型不支持wiki或已经在 wiki 中打开，这里不再请求 containerInfo
        if docsInfo.isFromWiki || !docsInfo.originType.isSupportedWikiType {
            return
        }
        // 如果在 base 中嵌入式打开，这里不再请求 containerInfo
        if docsInfo.openDocsFrom == .baseInstructionDocx {
            return
        }
        WorkspaceCrossNetworkAPI.getContainerInfo(objToken: docsInfo.token, objType: docsInfo.inherentType)
            .subscribe { [weak self] containerInfo, logID in
                guard let self = self else { return }
                guard let containerInfo = containerInfo else {
                    DocsLogger.info("fetch containerInfo found is_exist false", extraInfo: ["log-id": logID as Any])
                    return
                }
                if let wikiToken = containerInfo.wikiToken {
                    self.redirectToWikiIfNeeded(wikiToken: wikiToken,
                                                objToken: docsInfo.token,
                                                objType: docsInfo.inherentType,
                                                logID: logID)
                }
                if containerInfo.phoenixToken != nil,
                    !LKFeatureGating.phoenixEnabled {
                    // FG 关，且发现容器是 Phoenix，需要主动重定向一次走到兜底页
                    self.redirectToPhoenixIfNeeded(objToken: docsInfo.token, objType: docsInfo.inherentType)
                }
                self.hostDocsInfo?.update(containerInfo: containerInfo)
                self.hostDocsInfo?.updatePhoenixShareURLIfNeed()
            } onError: { error in
                DocsLogger.error("fetch containerInfo failed with error", error: error)
            }
            .disposed(by: disposeBag)
    }

    private func debugLog(_ msg:@autoclosure () -> String ) {
        DocsLogger.debug(editorIdentity + msg(), component: "hahaah")
    }

    private func infoLog(_ msg:@autoclosure () -> String ) {
        DocsLogger.info(editorIdentity + msg(), component: "DocsInfoUpdate")
    }

    private func redirectToPhoenixIfNeeded(objToken: String, objType: DocsType) {
        // 目前仅在 Phoenix FG 关，且通过去除 URL 中的 workspace 直接打开的情况下才会走到这里
        // 预期是重定向到兜底页
        let url = DocsUrlUtil.url(type: objType, token: objToken, isPhoenixURL: true)

        // 即使在 VC 下，也直接 push，否则目前打开后再重定向在 VC 下会有 bug
        // let browserViewControllerEditor = (self.navigator?.currentBrowserVC as? BrowserViewController)?.editor
        // if browserViewControllerEditor?.isInVideoConference == true {
        //     self.infoLog("move_to_phoenix has been in video conference")
        //     browserViewControllerEditor?.vcFollowDelegate?.follow(onOperate: .vcOperation(value: .openMoveToWikiUrl(wikiUrl: url.absoluteString, originUrl: self.docsInfo?.shareUrl ?? "")))
        //     return
        // }

        guard let vc = SKRouter.shared.open(with: url).0 else {
            spaceAssertionFailure("get phoenix default VC failed when redirect")
            return
        }
        let current = self.navigator?.currentBrowserVC
        let action = {
            let redirectAction = {
                current?.navigationController?.pushViewController(vc, animated: false)
                if let coordinate = current?.navigationController?.transitionCoordinator {
                    coordinate.animate(alongsideTransition: nil) { _ in
                        current?.navigationController?.viewControllers.removeAll(where: { $0 == current })
                    }
                } else {
                    current?.navigationController?.viewControllers.removeAll(where: { $0 == current })
                }
            }

            if let presentedVC = current?.presentedViewController {
                presentedVC.dismiss(animated: false, completion: redirectAction)
            } else {
                redirectAction()
            }
        }

        if let browserVC = current as? BrowserViewController,
           let feedFromInfo = browserVC.fileConfig?.feedFromInfo,
           feedFromInfo.canShowFeedAtively == true {
            // 从 feed 打开场景，需要延迟到 feed panel 打开后再重定向
            // feed 在 viewDidLoad 时立即 present FeedPanelVC，但此时无法读取到 presentedVC，此刻立即 push VC 会失效
            // 这里延迟到 feedPanelVC present 动画完成后再触发重定向逻辑, delay 时间为 present 的动画估时 500 毫秒
            let delay = DispatchQueueConst.MilliSeconds_500
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: action)
        } else {
            action()
        }
    }

    private func redirectToWikiIfNeeded(wikiToken: String, objToken: String, objType: DocsType, logID: String?) {
        DocsLogger.info("prepare redirect space document to wiki",
                        extraInfo: ["logID": logID],
                        component: LogComponents.workspace)
        let record = WorkspaceCrossRouteRecord(wikiToken: wikiToken,
                                               objToken: objToken,
                                               objType: objType,
                                               inWiki: true,
                                               logID: logID)
        DocsContainer.shared.resolve(WorkspaceCrossRouteStorage.self)?.notifyRedirect(record: record)
        // 模板预览的时候不跳
        if let browserVC = self.ui?.hostView.affiliatedViewController as? BrowserViewController, browserVC.isFromTemplatePreview {
            return
        }
        // 该文档被移动到了wiki，进行重新跳转 https://bytedance.feishu.cn/docs/doccnX7tg5U0jPk6KWk4AJahCUf
        var url = DocsUrlUtil.url(type: .wiki, token: wikiToken)
        // 这里显示指明是 wiki 2.0 文档，避免首次打开两跳问题
        url = url.docs.addQuery(parameters: ["wiki_version": "2"])
        
        if let originURLQuery = model?.hostBrowserInfo.currentURL?.queryParameters {
            url = url.docs.addQuery(parameters: originURLQuery)
        }

        if self.isInVideoConference || self.isDocComponent {
            self.infoLog("move_to_wiki has been in video conference or DocComponent")
            OperationInterceptor.interceptMoveToWiki(url.absoluteString,
                                                     originUrl: self.hostDocsInfo?.shareUrl ?? "",
                                                     from: self.navigator?.currentBrowserVC,
                                                     followDelegate: self.model?.vcFollowDelegate)
            return
        }
        
        var parameters: [String: Any] = [SKEntryBody.fromKey: FileListStatistics.Module.moveToWiki,
                                         "from": "move_to_wiki",
                                         WorkspaceCrossRouter.skipRouterKey: true
        ]
        if let routerParams = self.navigator?.routerParams {
            parameters.merge(routerParams) { (current, _) in current }
        }
        guard let vc = SKRouter.shared.open(with: url, params: parameters).0 else {
            spaceAssertionFailure("get wiki VC failed when redirect")
            return
        }
        let current = self.navigator?.currentBrowserVC
        let action = {
            (current as? TabContainable)?.shouldRedirect = true
            let redirectAction = {
                if let viewController = current as? TabContainable, viewController.isTemporaryChild, let currentVC = current {
                    self.temporaryTabService.removeTab(id: viewController.tabContainableIdentifier)
                    self.model?.userResolver.navigator.showTemporary(vc, from: currentVC)
                } else {
                    current?.navigationController?.pushViewController(vc, animated: false)
                }
                if let coordinate = current?.navigationController?.transitionCoordinator {
                    coordinate.animate(alongsideTransition: nil) { _ in
                        current?.navigationController?.viewControllers.removeAll(where: { $0 == current })
                    }
                } else {
                    current?.navigationController?.viewControllers.removeAll(where: { $0 == current })
                }
            }

            if let presentedVC = current?.presentedViewController {
                presentedVC.dismiss(animated: false, completion: redirectAction)
            } else {
                redirectAction()
            }
        }

        if let browserVC = current as? BrowserViewController,
           let feedFromInfo = browserVC.fileConfig?.feedFromInfo,
           feedFromInfo.canShowFeedAtively == true {
            // 从 feed 打开场景，需要延迟到 feed panel 打开后再重定向
            // feed 在 viewDidLoad 时立即 present FeedPanelVC，但此时无法读取到 presentedVC，此刻立即 push VC 会失效
            // 这里延迟到 feedPanelVC present 动画完成后再触发重定向逻辑, delay 时间为 present 的动画估时 500 毫秒
            let delay = DispatchQueueConst.MilliSeconds_500
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: action)
        } else {
            action()
        }
    }
}
