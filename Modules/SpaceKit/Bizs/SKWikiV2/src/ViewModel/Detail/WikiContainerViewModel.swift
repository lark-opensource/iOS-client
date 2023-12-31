//
//  WikiContainerViewModel.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/9/25.
// swiftlint:disable file_length

import UIKit
import RxSwift
import RxCocoa
import SwiftyJSON
import SKFoundation
import SKCommon
import SKResource
import SKBrowser
import UniverseDesignIcon
import SpaceInterface
import SKInfra
import SKWorkspace
import LarkContainer

// 展示信息
typealias WikiDisplayInfo = (url: URL, docsType: DocsType, objToken: String, params: [AnyHashable: Any]?)
// wikiTree需要的信息
typealias WikiTreeInfo = (wikiToken: String, spaceId: String, treeContext: WikiTreeContext?)

// url: wiki URL
// params: 通过链接路由时代给docsbrowserview的参数，可选
// wikiNodeMeta: 切换节点或者从最近列表进入详情，传wikiNodeMeta，如果节点不存在可以通过homepage信息跳转到wiki主页
// extraInfo: 目前用于传递数据上报信息
typealias WikiChangeInfo = (url: URL,
                            params: [AnyHashable: Any]?,
                            wikiNodeMeta: WikiNodeMeta?,
                            extraInfo: [AnyHashable: Any])
// prepare: 请求wiki meta
// failed: 加载失败
// unsupport: 当前wiki对应的单品类型不支持展示
// success: 成功展示
enum WikiContainerState {
    case prepare
    case failed(error: WikiErrorCode)
    case unsupport(url: URL)
    case success(displayInfo: WikiDisplayInfo, treeInfo: WikiTreeInfo)
}

// WikiContainerViewModel 输出事件
protocol WikiContainerVMOutput {
    var viewStateEvent: Driver<WikiContainerState> { get }
    var showWikiTreeEvent: Driver<WikiTreeInfo> { get }
    var enableOpenTreeItem: Driver<Bool> { get }
    var redirectEvent: Signal<(URL, [AnyHashable: Any]?)> { get }
    var createWikiMainTreeViewModelEvent: Driver<WikiTreeInfo> { get }
    var hiddenOpenTreeItem: Driver<Bool> { get }
}

// WikiContainerViewModel 输入事件
protocol WikiContainerVMInput {
    var wikiInfoChangeAction: AnyObserver<WikiChangeInfo> { get }
    var retryAction: AnyObserver<()> { get }
    var showWikiTreeAction: AnyObserver<()> { get }
    var createWikiMainTreeViewModelAction: AnyObserver<()> { get }
}

class WikiContainerViewModel: NSObject, WikiContainerVMOutput {

    let synergyUUID: String = UUID().uuidString

    private(set) var wikiURL: URL
    private(set) var wikiNode: WikiNodeMeta? {
        didSet {
            self.checkHiddenTreeItemIfNeed()
        }
    }
    private var treeContext: WikiTreeContext?
    // 埋点用参数，不做逻辑，不解析内容
    private(set) var extraInfo: [AnyHashable: Any]
    // 业务参数，透传给 browserView
    private var params: [AnyHashable: Any]?
    private let otherError = WikiError.dataParseError
    private let deletedEror = WikiError.getWikiNodeNotExist
    private var browseReportTask: DocsRequest<JSON>?
    private var userPermissionsRequest: DocsRequest<JSON>?
    private let bag = DisposeBag()

    var wikiToken: String {
        DocsUrlUtil.getFileToken(from: wikiURL) ?? wikiNode?.wikiToken ?? ""
    }

    // internal input
    private let _wikiInfoChangeAction: BehaviorSubject<WikiChangeInfo>
    private let _retryAction = PublishSubject<()>()
    private let _showWikiTreeAction = PublishSubject<()>()
    private let _crateWikiTreeViewModelAction = PublishSubject<()>()
    private let _wikiInfoUpdate = PublishSubject<WikiContainerState>()
    // 前端是否设置了wikitree入口enable
    private let _jsEnableWikiTree = BehaviorRelay<Bool>(value: true)
    let _hiddenTreeItem = BehaviorRelay<Bool>(value: false)

    // public input
    var input: WikiContainerVMInput { return self }

    private lazy var startLoad: Observable<WikiChangeInfo> = {
        let triger = _retryAction.withLatestFrom(_wikiInfoChangeAction).debug("WikiContainerState triger")
        return Observable.merge([triger, _wikiInfoChangeAction]).debug("WikiContainerState startLoad")
    }()

    // output
    var output: WikiContainerVMOutput { return self }
    lazy var isHistory: Bool = {
        return wikiURL.absoluteString.contains("#history")
    }()
    lazy var isFromVC: Bool = {
        return wikiURL.absoluteString.contains("vcFollow")
    }()
    lazy var isFromDocComponent: Bool = {
        return wikiURL.docs.isDocComponentUrl
    }()
    
    lazy var viewStateEvent: Driver<WikiContainerState> = {
        let normalState = startLoad.do(onNext: {[weak self] (newInfo) in
            self?.wikiURL = newInfo.url
            self?.params = newInfo.params
            self?.wikiNode = newInfo.wikiNodeMeta
            self?.extraInfo = newInfo.extraInfo
            if let nodeMeta = newInfo.wikiNodeMeta {
                self?.userResolver.docs.wikiStorage?.update(wikiNodeMeta: nodeMeta)
            }
        }).flatMap({[weak self] (newInfo) -> Observable<WikiContainerState> in
            guard let self = self else { return Observable.empty() }
            return self.handleNewInfo(newInfo).flatMap { [weak self ] (state) -> Observable<WikiContainerState> in
                guard let self = self else { return Observable.empty() }
                return .just(self.addWikiParamsInDrive(state: state))
            }
        }).do(onNext: { [weak self] state in
            guard case .success = state else { return }
            self?.reportBrowserIfNeed()
        })
        // 成功不需要重新触发，失败时需要处理更新UI，所以只关注失败的事件
        let displayErrorState = _wikiInfoUpdate.filter { (result) -> Bool in
            if case .failed = result {
                return true
            }
            return false
        }
        return Observable.merge(normalState, displayErrorState)
            .asDriver(onErrorJustReturn: .failed(error: .networkError))
    }()

    lazy var showWikiTreeEvent: Driver<WikiTreeInfo> = {
        return _showWikiTreeAction.flatMap {[weak self] (_) -> Observable<WikiTreeInfo> in
            guard let self = self else { return Observable.empty() }
            if let node = self.wikiNode {
                // 点击node进入
                return Observable.just((wikiToken: node.wikiToken, spaceId: node.spaceID, treeContext: self.treeContext))
            } else {
                spaceAssertionFailure("cannot get wikiNode")
                return Observable.empty()
            }
        }.asDriver(onErrorRecover: {_ in
            return Driver.empty()
        })
    }()
    
    lazy var createWikiMainTreeViewModelEvent: Driver<WikiTreeInfo> = {
        return _crateWikiTreeViewModelAction.flatMap {[weak self] (_) -> Observable<WikiTreeInfo> in
            guard let self = self else { return Observable.empty() }
            if let node = self.wikiNode {
                return Observable.just((wikiToken: node.wikiToken, spaceId: node.spaceID, treeContext: self.treeContext))
            } else {
                //从链接初次打开一篇wiki时，无法获取wikiNode
                DocsLogger.info("can not get wiki Node --- from link open wiki")
                return Observable.empty()
            }
        }.asDriver(onErrorRecover: {_ in
            return Driver.empty()
        })
    }()

    private let redirectTrigger = PublishRelay<(URL, [AnyHashable: Any]?)>()
    var redirectEvent: Signal<(URL, [AnyHashable: Any]?)> {
        redirectTrigger.asSignal()
    }

    lazy var enableOpenTreeItem: Driver<Bool> = {
        guard !isHistory && !isFromVC && !isFromDocComponent else {
            return Driver.never()
        }
        let viewState = self._wikiInfoUpdate.map { [weak self] (state) -> Bool in
            guard let self = self else { return false }
            if case .failed(let error) = state {
                if case .sourceNotExist = error, self.wikiNode == nil {
                    self._hiddenTreeItem.accept(true)
                    return false
                }
                return DocsUrlUtil.getFileToken(from: self.wikiURL, with: .wiki) != nil
            }
            return true
        }.asDriver(onErrorJustReturn: false).startWith(true).debug("failedState")
        let networkState = RxNetworkMonitor.networkStatus(observerObj: self).map({ (status) -> Bool in
            return status.isReachable
        }).asDriver(onErrorJustReturn: false).debug("networkState")
        let isCache = WikiTreeCacheHandle.shared
            .loadTree(spaceID: wikiNode?.spaceID ?? "", initialWikiToken: wikiNode?.wikiToken)
            .map { _ in true }
            .ifEmpty(default: false)
            .asDriver(onErrorJustReturn: false)
        let jsWikiTreeEnable = _jsEnableWikiTree.asDriver(onErrorJustReturn: true)
        return Driver.combineLatest(viewState, networkState, jsWikiTreeEnable, isCache) {
            return $0 && ($1 || $3) && $2
        }
    }()
    
    lazy var hiddenOpenTreeItem: Driver<Bool> = {
        return _hiddenTreeItem.asDriver(onErrorJustReturn: false)
    }()

    var urlForSuspendable: String {
        if var components = URLComponents(string: self.wikiURL.absoluteString) {
            components.query = nil // 移除所有参数
            if let finalUrl = components.string {
                if let vurl = URL(string: finalUrl), let version = URLValidator.getVersionNum(self.wikiURL) { // 版本需要增加参数
                    return vurl.docs.addQuery(parameters: ["edition_id": version]).absoluteString
                }
                return finalUrl
            }
        }
        return self.wikiURL.absoluteString
    }
    var iconForSuspendable: UIImage {
        guard let inherentType = wikiNode?.docsType else {
            return UDIcon.getIconByKey(.fileRoundUnknowColorful, size: CGSize(width: 48, height: 48))
        }
        return inherentType.iconForSuspendable
        ?? UDIcon.getIconByKey(.fileRoundUnknowColorful, size: CGSize(width: 48, height: 48))
    }
    var initialToken: String? //用于在wiki场景通过目录切换wiki文档时保证identifiler一致性,只有当来自多任务这个值才有"值"且有意义
    var sessionID: String? //Wiki容器打开文档性能埋点上报的sessionId
    
    var isFakeToken: Bool {
        return isFakeWikiUrl(self.wikiURL)
    }
    
    let userResolver: UserResolver

    init(userResolver: UserResolver,
         url: URL,
         params: [AnyHashable: Any]?,
         extraInfo: [AnyHashable: Any]) {
        self.userResolver = userResolver
        self.wikiURL = url.docs.addQuery(parameters: ["wiki_version": "2"])
        self.params = params
        self.extraInfo = extraInfo
        self._wikiInfoChangeAction = BehaviorSubject<WikiChangeInfo>(value: (url: wikiURL,
                                                                             params: params,
                                                                             wikiNodeMeta: nil,
                                                                             extraInfo: extraInfo))
        super.init()
        if let from = extraInfo["from"] as? String, from == "tasklist" { //通过URL打开，且来自tasklist才需要该逻辑
            self.initialToken = self.wikiToken
        }
        observeNotification()
    }

    init(userResolver: UserResolver,
         wikiNode: WikiNodeMeta,
         treeContext: WikiTreeContext?,
         params: [AnyHashable: Any]?,
         extraInfo: [AnyHashable: Any]) {
        self.userResolver = userResolver
        var url = DocsUrlUtil.url(type: .wiki, token: wikiNode.wikiToken)
        url = url.docs.addQuery(parameters: ["wiki_version": "2"])
            
        if let from = params?["from"] as? String {
            url = url.docs.addQuery(parameters: ["from": from])
        }
        if let fragment = params?["fragment"] as? String {
            url = url.append(fragment: fragment)
        }
        self.wikiURL = url
        self.params = params
        self.extraInfo = extraInfo
        self._wikiInfoChangeAction = BehaviorSubject<WikiChangeInfo>(value: (url: wikiURL,
                                                                             params: params,
                                                                             wikiNodeMeta: wikiNode,
                                                                             extraInfo: extraInfo))
        self.wikiNode = wikiNode
        self.treeContext = treeContext
        super.init()
        observeNotification()
    }

    private func observeNotification() {
        // 跨库移动
        NotificationCenter.default
            .rx
            .notification(Notification.Name.Docs.wikiAcross)
            .subscribe(onNext: {[weak self] noti in
                guard let self = self,
                      let wikiInfo = noti.object as? WikiInfo else {
                    spaceAssertionFailure("wikiAcross not contain wikiInfo")
                    return
                }
                let wikiNode = WikiNodeMeta(wikiToken: wikiInfo.wikiToken,
                                             objToken: wikiInfo.objToken,
                                             docsType: wikiInfo.docsType,
                                             spaceID: wikiInfo.spaceId)
                self.wikiNode = wikiNode
                self.userResolver.docs.wikiStorage?.update(wikiNodeMeta: wikiNode)
                self._wikiInfoChangeAction.onNext((url: self.wikiURL, params:self.params, wikiNodeMeta: wikiNode, extraInfo: self.extraInfo))
            })
            .disposed(by: bag)
        
        observableUpdateInfo()
    }
    
    private func reportBrowserIfNeed() {
        guard let node = wikiNode, node.docsType == .file || node.docsType == .wikiCatalog else {
            DocsLogger.info("wiki type is not file or catalog")
            return
        }
        
        WikiNetworkManager.shared
            .reportBrowser(wikiToken: node.wikiToken)
            .subscribe()
            .disposed(by: bag)
    }
    
    public func updateVersion(version: String, from: FromSource?) -> (WikiDisplayInfo, WikiTreeInfo) {
        var sourceURL: URL
        if version.isEmpty {
            sourceURL = self.wikiURL.docs.deleteQuery(key: "edition_id")
        } else {
            
            sourceURL = self.wikiURL.docs.addOrChangeQuery(parameters: ["edition_id": version, "versionfrom": from?.rawValue ?? "unknown"])
        }
        self.wikiURL = sourceURL
        return (WikiDisplayInfo(url: self.wikiURL,
                                docsType: wikiNode?.docsType ?? .wiki,
                                objToken: wikiNode?.objToken ?? "",
                                params: self.params),
                (wikiToken: wikiToken,
                           spaceId: wikiNode?.spaceID ?? "",
                           treeContext: nil))
    }
    
    public func checkHiddenTreeItemIfNeed() {
        if let type = self.wikiNode?.docsType,
           type.supportVersionInfo,
           self.wikiURL.isVersion {
            self._hiddenTreeItem.accept(true)
        }
    }
}

// MARK: - utils
extension WikiContainerViewModel {
    private func prepareWikiMeta(with url: URL) -> Observable<WikiContainerState> {
        guard let token = DocsUrlUtil.getFileToken(from: url, with: .wiki) else {
            spaceAssertionFailure("illegal wiki url")
            return .just(.unsupport(url: url))
        }
        // cache
        if let nodeMeta = self.userResolver.docs.wikiStorage?.getWikiNodeMeta(token) {
            self.wikiNode = nodeMeta
        }
        // network
        WikiNetworkManager.shared
            .getWikiObjInfo(wikiToken: token)
            .subscribe { [weak self] objInfo, logID in
                guard let self = self else { return }
                switch objInfo {
                case let .inWiki(meta):
                    self.handleServerMeta(meta: meta)
                case let .inSpace(info):
                    self.handleRedirectToSpace(info: info, logID: logID)
                }
            } onError: { [weak self] error in
                self?.handleMetaError(error: error)
            }
            .disposed(by: bag)

        if let node = self.wikiNode {
            guard node.docsType.isSupportedWikiType else {
                return Observable.just(.unsupport(url: url))
            }
            return .just(.success(displayInfo: (url: self.wikiURL,
                                                docsType: node.docsType,
                                                objToken: node.objToken,
                                                params: self.params),
                                  treeInfo: (wikiToken: node.wikiToken, spaceId: node.spaceID, treeContext: nil)))
        } else {
            return .just(.prepare)
        }
    }

    private func handleServerMeta(meta: WikiNodeMeta) {
        if let currentNode = wikiNode {
            // 有缓存时，要检查下 spaceID 有没有变
            guard currentNode.spaceID != meta.spaceID else {
                return
            }
            self.wikiNode = meta
            // spaceID 变了，需要更新下缓存
            self._wikiInfoChangeAction.onNext((url: self.wikiURL,
                                               params: self.params,
                                               wikiNodeMeta: meta,
                                               extraInfo: self.extraInfo))
            _crateWikiTreeViewModelAction.onNext(())
        } else {
            // 没缓存，更新下 UI
            self._wikiInfoChangeAction.onNext((url: self.wikiURL,
                                               params: self.params,
                                               wikiNodeMeta: meta,
                                               extraInfo: self.extraInfo))
            self.wikiNode = meta
        }
    }

    private func handleRedirectToSpace(info: WikiObjInfo.SpaceInfo, logID: String?) {
        DocsLogger.info("prepare redirect wiki to space",
                        extraInfo: ["logID": logID],
                        component: LogComponents.workspace)
        // 重定向到 space，并更新路由表
        let redirectURL: URL
        if let originComponents = URLComponents(url: wikiURL, resolvingAgainstBaseURL: false),
           var spaceComponents = URLComponents(url: info.url, resolvingAgainstBaseURL: false) {
            // 只继承 query 和 fragment
            spaceComponents.percentEncodedQuery = originComponents.percentEncodedQuery
            spaceComponents.percentEncodedFragment = originComponents.percentEncodedFragment
            redirectURL = spaceComponents.url ?? info.url
        } else {
            spaceAssertionFailure("failed to convert wikiURL or spaceURL to components")
            redirectURL = info.url
        }
        let record = WorkspaceCrossRouteRecord(wikiToken: info.wikiToken,
                                               objToken: info.objToken,
                                               objType: info.docsType,
                                               inWiki: false,
                                               logID: logID)
        DispatchQueue.main.async {
            // 在主线程调用更新缓存接口
            DocsContainer.shared.resolve(WorkspaceCrossRouteStorage.self)?.notifyRedirect(record: record)
        }
        var newParams = params ?? [:]
        newParams[WorkspaceCrossRouter.skipRouterKey] = true
        redirectTrigger.accept((redirectURL, params))
    }

    private func checkNeedToRedirectToSpace(wikiToken: String) {
        WikiNetworkManager.shared
            .getWikiObjInfo(wikiToken: wikiToken)
            .subscribe { [weak self] objInfo, logID in
                guard let self = self else { return }
                switch objInfo {
                case .inWiki:
                    return
                case let .inSpace(info):
                    self.handleRedirectToSpace(info: info, logID: logID)
                }
            } onError: { [weak self] error in
                DocsLogger.error("failed to check if need to redirect to space", error: error)
                self?.handleMetaError(error: error)
            }
            .disposed(by: bag)
    }

    private func handleNewInfo(_ info: WikiChangeInfo) -> Observable<WikiContainerState> {
        sessionID = OpenFileRecord.generateNewOpenSession()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // wiki文档拉取wikiInfo耗时
            OpenFileRecord.startRecordTimeConsumingFor(sessionID: self.sessionID, stage: OpenFileRecord.Stage.pullWikiInfo.rawValue, parameters: nil)
        }
        
        // 离线创建打开 mock成功流程
        if isFakeWikiUrl(info.url), let wikiNode = praseFakeWikiMeta(info.url) {
            self.wikiNode = wikiNode
            self._jsEnableWikiTree.accept(false)
            self.userResolver.docs.wikiStorage?.update(wikiNodeMeta: wikiNode)
            return .just(.success(displayInfo: (url: self.wikiURL,
                                                docsType: wikiNode.docsType,
                                                objToken: wikiNode.objToken,
                                                params: self.params),
                                  treeInfo: (wikiToken: wikiNode.wikiToken, spaceId: wikiNode.spaceID, treeContext: nil)))
        }
        
        guard let wikiNodeMeta = info.wikiNodeMeta else {
            return self.prepareWikiMeta(with: info.url)
        }
        // 已经有 meta 的情况下，也需要检查一下 moveToSpace 状态，如从 space 列表打开脏数据场景
        checkNeedToRedirectToSpace(wikiToken: wikiNodeMeta.wikiToken)

        guard wikiNodeMeta.docsType.isSupportedWikiType else {
            return Observable.just(.unsupport(url: info.url))
        }
        return Observable.just(.success(displayInfo: WikiDisplayInfo(url: info.url,
                                                                     docsType: wikiNodeMeta.docsType,
                                                                     objToken: wikiNodeMeta.objToken,
                                                                     params: info.params),
                                        treeInfo: (wikiToken: wikiNodeMeta.wikiToken, spaceId: wikiNodeMeta.spaceID, treeContext: nil)))
    }

    private func handleMetaError(error: Error) {
        DocsLogger.error("get_type error \(error)")
        let code: Int
        if let wikiError = error as? WikiError,
           case let .serverError(serverCode) = wikiError {
            code = serverCode
        } else {
            code = (error as NSError).code
        }
        let error = getWikiError(with: code)
        switch error {
        case .sourceNotExist:
            userResolver.docs.wikiStorage?.cleanWikiNodeMeta(wikiToken: wikiToken)
            _wikiInfoUpdate.onNext(.failed(error: error))
        default:
            if wikiNode == nil {
                _wikiInfoUpdate.onNext(.failed(error: error))
            }
        }
    }
    
    private func addWikiParamsInDrive(state: WikiContainerState) -> WikiContainerState {
        guard case let .success(displayInfo, treeInfo) = state else {
            return state
        }
        var newParams = displayInfo.params ?? [:]
        if displayInfo.docsType == .file {
            newParams.merge(other: ["from": "wiki", "wikiToken": wikiToken])
        }
        let info = WikiDisplayInfo(url: displayInfo.url,
                                   docsType: displayInfo.docsType,
                                   objToken: displayInfo.objToken,
                                   params: newParams)
        return .success(displayInfo: info, treeInfo: treeInfo)
    }
}

extension WikiContainerViewModel: WikiContainerVMInput {
    var wikiInfoChangeAction: AnyObserver<(url: URL, params: [AnyHashable: Any]?, wikiNodeMeta: WikiNodeMeta?, extraInfo: [AnyHashable: Any])> {
        return _wikiInfoChangeAction.asObserver()
    }
    var retryAction: AnyObserver<()> {
        return _retryAction.asObserver()
    }
    var showWikiTreeAction: AnyObserver<()> {
        return _showWikiTreeAction.asObserver()
    }
    var createWikiMainTreeViewModelAction: AnyObserver<()> {
        return _crateWikiTreeViewModelAction.asObserver()
    }
}

// report
extension WikiContainerViewModel {
    func reportEnterDetail() {
        let from = extraInfo["from"] as? String
        WikiStatistic.wikiDetailEnter(from: from)
    }
}

extension WikiContainerViewModel: WikiJSEventHandler {
    func handle(event: WikiJSEvent, params: [String: Any]) {
        DocsLogger.info("[wiki] wikiEvent \(event)")
        switch event {
        case .setWikiInfo:
            handleSetWikiInfo(params: params)
        case .titleChanged:
            handleTitleChanged(params: params)
        case .setWikiTreeEnable:
            handleWikiTreeEnable(params: params)
        case .permissionChanged:
            handleWikiPermissionChanged(params: params)
        }
    }

    private func handleSetWikiInfo(params: [String: Any]) {
        guard let wikiInfo = params["wiki_info"] as? [String: Any] else {
            DocsLogger.error("[wiki] no wiki info")
            return
        }
        if let code = wikiInfo["code"] as? Int,
           code != 0 {
            if let error = WikiErrorCode(rawValue: code) {
                switch error {
                case .nodePermFailCode, .spacePermFail:
                    //不在Wiki容器处理的错误码，直接走文档的处理流程
                    DocsLogger.error("[wiki] set wiki info code error, start handle wiki not exist if need\(code)")
                    return
                default:
                    DocsLogger.error("[wiki] set wiki info code error, start handle wiki not exist if need\(code)")
                    handleLoadWikiFailed(wikiInfo: wikiInfo)
                    return
                }
            } else {
                DocsLogger.error("[wiki] set wiki info code error, 未知错误码\(code)")
                handleLoadWikiFailed(wikiInfo: wikiInfo)
                return
            }
        }
        DocsLogger.info("set wiki info success")
        _wikiInfoUpdate.onNext(.success(displayInfo: WikiDisplayInfo(url: self.wikiURL,
                                                                     docsType: wikiNode?.docsType ?? .wiki,
                                                                     objToken: wikiNode?.objToken ?? "",
                                                                     params: self.params),
                                        treeInfo: (wikiToken: wikiToken,
                                                   spaceId: wikiNode?.spaceID ?? "",
                                                   treeContext: nil)))
    }

    private func handleTitleChanged(params: [String: Any]) {
        var _params = params
        // TODO: 这里需要区分 wiki shortcut 重命名本体的场景，拿到本体 token 用于重命名
        if let wikiToken = wikiNode?.wikiToken, let newName = params["newName"] as? String {
            _params["updateForOrigin"] = true
            _params["wikiToken"] = wikiToken
            DispatchQueue.global().async {
                let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
                dataCenterAPI?.rename(objToken: wikiToken, with: newName)
            }
        }
        NotificationCenter.default.post(name: Notification.Name.Docs.wikiTitleUpdated, object: nil, userInfo: _params)
    }

    private func handleLoadWikiFailed(wikiInfo: [String: Any]) {
        guard let code = wikiInfo["code"] as? Int else {
            DocsLogger.error("[wiki] wiki info code not exist")
            return
        }
        DocsLogger.error("handle wiki failed code: \(code)", component: LogComponents.wiki)
        let wikiError = getWikiError(with: code)
        _wikiInfoUpdate.onNext(.failed(error: wikiError))
    }

    private func getWikiError(with code: Int) -> WikiErrorCode {
        WikiErrorCode(rawValue: code) ?? .networkError
    }

    private func handleWikiTreeEnable(params: [String: Any]) {
        guard let enable = params["enable"] as? Bool else {
            DocsLogger.error("[wiki] wiki tree enable params invalid", extraInfo: params)
            return
        }
        _jsEnableWikiTree.accept(enable)
    }
    
    private func handleWikiPermissionChanged(params: [String: Any]) {
        guard let code = params["code"] as? Int else {
            DocsLogger.info("[wiki] wiki document permission dictionary have not code")
            return
        }
        if code == DocsNetworkError.Code.success.rawValue {
            self._hiddenTreeItem.accept(false)
        }
        //前端权限变化推送错误码 4 为无权限
        if code == 4 {
            self._hiddenTreeItem.accept(true)
        }
        self.checkHiddenTreeItemIfNeed()
    }
}

// 离线创建打开相关
extension WikiContainerViewModel {
    func isFakeWikiUrl(_ url: URL) -> Bool {
        guard let fakeToken = DocsUrlUtil.getFileToken(from: url) else {
            DocsLogger.error("wiki.container.vm: get fake wiki token failed from fake wiki url")
            return false
        }
        return fakeToken.starts(with: "fake_")
    }
    
    func praseFakeWikiMeta(_ url: URL) -> WikiNodeMeta? {
        // 如果打开的fakeNode在初始化时已经构建好，则直接返回
        if let wikiNode = self.wikiNode {
            return self.wikiNode
        }
        let dic = url.queryParameters
        guard let wikiToken = DocsUrlUtil.getFileToken(from: url),
              let objTypeString = dic["objType"],
              let objType = Int(objTypeString),
              let spaceID = dic["spaceId"],
              let title = dic["title"] else {
            DocsLogger.error("wiki.container.vm: parase fake wiki node meta without params")
            return nil
        }
        let meta = WikiTreeNodeMeta(wikiToken: wikiToken, spaceId: spaceID, objToken: wikiToken, docsType: DocsType(rawValue: objType), title: title)
        userResolver.docs.wikiStorage?.insertFakeNodeForLibrary(wikiNode: meta.transformWikiNode())
        let wikiNode = WikiNodeMeta(wikiToken: wikiToken, objToken: wikiToken, docsType: DocsType(rawValue: objType), spaceID: spaceID)
        return wikiNode
    }
    
    func observableUpdateInfo() {
        NotificationCenter.default.rx
            .notification(Notification.Name.Docs.updateFakeWikiInfo)
            .subscribe(onNext: { [weak self] notification in
                guard let self else { return }
                guard let wikiInfo = notification.object as? WikiInfo else {
                    DocsLogger.error("wiki.container.vm: update real wiki info replace old fake wiki info")
                    return
                }
                let wikiNode = WikiNodeMeta(wikiToken: wikiInfo.wikiToken,
                                            objToken: wikiInfo.objToken,
                                            docsType: wikiInfo.docsType,
                                            spaceID: wikiInfo.spaceId)
                // 创建成功协同事件过来，更新wikiInfo信息
                self.wikiNode = wikiNode
                self.wikiURL = DocsUrlUtil.url(type: .wiki, token: wikiInfo.wikiToken)
                //self._wikiInfoChangeAction.onNext((url: self.wikiURL, params: self.params, wikiNodeMeta: self.wikiNode, extraInfo: self.extraInfo))
                self._crateWikiTreeViewModelAction.onNext(())
                self._jsEnableWikiTree.accept(true)
                // 更新目录树缓存
            }, onError: { error in
                DocsLogger.error("wiki.container.vm: update real wiki info error: \(error)")
            })
            .disposed(by: bag)
    }
}
