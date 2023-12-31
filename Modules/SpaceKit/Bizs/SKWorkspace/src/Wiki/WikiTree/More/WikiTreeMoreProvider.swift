//
//  WikiTreeMoreProvider.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/7/27.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import SKFoundation
import SKResource
import SKCommon
import UniverseDesignColor
import UniverseDesignActionPanel
import SpaceInterface
import SKInfra

public struct WikiTreeCreateResponse {
    let nodeUID: WikiTreeNodeUID
    let nodeMeta: WikiTreeNodeMeta
    let newNode: WikiServerNode
    // 创建shortcut时，需要originNode
    let originNode: WikiServerNode?
}

public enum WikiTreeMoreAction {
    case upload(parentToken: String, isImage: Bool, completion: DidSelectFileAction)
    case create(response: WikiTreeCreateResponse)
    case move(oldParentToken: String, movedNode: WikiServerNode)
    case delete(meta: WikiTreeNodeMeta, isSingleDelete: Bool)
    case remove(meta: WikiTreeNodeMeta)
    case copy(newNode: WikiServerNode)
    case shortcut(newNode: WikiServerNode)
    case toggleClip(meta: WikiTreeNodeMeta, setClip: Bool)
    case toggleExplorerStar(meta: WikiTreeNodeMeta, setStar: Bool)
    case toggleExplorerPin(meta: WikiTreeNodeMeta, setPin: Bool)
    case updateTitle(wikiToken: String, newTitle: String)
}

public protocol WikiTreeMoreProvider: AnyObject {
    var spaceInput: PublishRelay<WikiSpace?> { get }
    var spacePermissionInput: PublishRelay<WikiSpacePermission> { get }
    var actionSignal: Signal<WikiTreeViewAction> { get }
    var moreActionSignal: Signal<WikiTreeMoreAction> { get }
    // 获取 parentToken
    var parentProvider: ((String) -> String?)? { get set }
    // 获取children数量
    var childCountProvider: ((String) -> Int?)? { get set }
    // 判断节点的置顶状态
    var clipChecker: ((String) -> Bool)? { get set }

    func createOnRootNode(rootMeta: WikiTreeNodeMeta, sourceView: UIView)
    func configSlideAction(meta: WikiTreeNodeMeta, node: TreeNode) -> [TreeSwipeAction]?
    // 侧滑 cell 时提供预加载权限的时机
    func preloadPermission(meta: WikiTreeNodeMeta)
}

public protocol WikiTreeMoreActionProxy: AnyObject {
    /// 刷新目录树（目前 HomeTreeSectionDataProvider 实现，用于 Wiki 移动到 Space 后刷新目录树）
    func refreshForMoreAction()
}

public class WikiMainTreeMoreProvider: WikiTreeMoreProvider {

    public let spaceInput = PublishRelay<WikiSpace?>()
    private let spaceRelay = BehaviorRelay<WikiSpace?>(value: nil)
    var spaceInfo: WikiSpace? { spaceRelay.value }

    public let spacePermissionInput = PublishRelay<WikiSpacePermission>()
    private let spacePermissionRelay = BehaviorRelay<WikiSpacePermission>(value: WikiSpacePermission(canEditFirstLevel: false, isWikiMember: false, isWikiAdmin: false))
    var spacePermission: WikiSpacePermission { spacePermissionRelay.value }

    let actionInput = PublishRelay<WikiTreeViewAction>()
    public var actionSignal: Signal<WikiTreeViewAction> { actionInput.asSignal() }

    let moreActionInput = PublishRelay<WikiTreeMoreAction>()
    public var moreActionSignal: Signal<WikiTreeMoreAction> { moreActionInput.asSignal() }
    private let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!

    // 外部传进来的闭包，查询 parent 用
    public var parentProvider: ((String) -> String?)?
    // 获取children数量
    public var childCountProvider: ((String) -> Int?)?
    // 外部传进来的闭包，查询置顶状态用
    public var clipChecker: ((String) -> Bool)?

    // 节点 cache 缓存，限制在主线程读写
    var nodePermissionStorage: [String: WikiTreeNodePermission] = [:]
    let interactionHelper: WikiInteractionHandler
    var requestUUID: String? { interactionHelper.synergyUUID }
    var networkAPI: WikiTreeNetworkAPI { interactionHelper.networkAPI }
    // 权限更新时触发，如果有正在展示的创建面板、more 面板，可以监听事件后刷新一下
    private let permissionUpdatedInput = PublishRelay<Void>()
    var onPermissionUpdated: Signal<Void> { permissionUpdatedInput.asSignal() }

    public weak var moreActionProxy: WikiTreeMoreActionProxy?

    let disposeBag = DisposeBag()

    public init(interactionHelper: WikiInteractionHandler) {
        self.interactionHelper = interactionHelper
        spaceInput.bind(to: spaceRelay)
            .disposed(by: disposeBag)
        spacePermissionInput.bind(to: spacePermissionRelay)
            .disposed(by: disposeBag)
    }

    public func configSlideAction(meta: WikiTreeNodeMeta, node: TreeNode) -> [TreeSwipeAction]? {
        return [
            moreAction(meta: meta, node: node),
            createAction(meta: meta, node: node)
        ].compactMap { $0 }
    }

    public func preloadPermission(meta: WikiTreeNodeMeta) {
        interactionHelper.fetchPermission(wikiToken: meta.wikiToken, spaceID: meta.spaceID)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] permission in
                guard let self = self else { return }
                self.nodePermissionStorage[meta.wikiToken] = permission
                self.permissionUpdatedInput.accept(())
            } onError: { error in
                DocsLogger.error("fetch permission for node failed", error: error)
            }
            .disposed(by: disposeBag)
    }
}


// MARK: - Create Action
extension WikiMainTreeMoreProvider {

    public func createOnRootNode(rootMeta: WikiTreeNodeMeta, sourceView: UIView) {
        // 做一些关于主节点的上报操作
        let rootNodeUID = WikiTreeNodeUID(wikiToken: rootMeta.wikiToken, section: .mainRoot, shortcutPath: "")
        showCreatePanel(meta: rootMeta, nodeUID: rootNodeUID, sourceView: sourceView, completion: nil)
    }

    private func createAction(meta: WikiTreeNodeMeta, node: TreeNode) -> TreeSwipeAction? {
        if meta.originIsExternal {
            // 本体在外部时，禁止创建
            return nil
        }
        return TreeSwipeAction(normalImage: TreeSwipeAction.normalAddImage,
                               normalBackgroundColor: UDColor.colorfulBlue,
                               disabledImage: TreeSwipeAction.disabledAddImage,
                               disabledBackgroundColor: UDColor.B300) { [weak self] sourceView, completion, _, _ in
            self?.didClickCreateAction(meta: meta,
                                       node: node,
                                       sourceView: sourceView,
                                       completion: completion)
        }
    }

    // 只考虑权限
    private func createEnableByPermission(meta: WikiTreeNodeMeta) -> Bool {
        if meta.nodeType == .mainRoot {
            guard spacePermissionRelay.value.canEditFirstLevel else {
                DocsLogger.info("create on main root block by permission")
                return false
            }
        } else {
            guard let permission = nodePermissionStorage[meta.wikiToken] else {
                DocsLogger.info("create on node block by no permission cache")
                return false
            }
            if meta.isShortcut {
                guard let canCreate = permission.originCanCreate,
                      canCreate else {
                    DocsLogger.info("create on shortcut node block by permission")
                    return false
                }
            } else {
                guard permission.canCreate else {
                    DocsLogger.info("create on normal node block by permission")
                    return false
                }
            }
        }
        return true
    }

    private func createEnable(meta: WikiTreeNodeMeta, type: WikiInteractionHandler.CreateType) -> Bool {
        guard DocsNetStateMonitor.shared.isReachable else {
            // 离线情况下Wiki创建面板的选项是否enable通过各自类型的FG控制
            switch type {
            case let .document(objType, _):
                return objType.offlineCreateInWikiEnable
            default:
                return false
            }
        }
        guard createEnableByPermission(meta: meta) else { return false }
        if case .upload = type {
            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                let request = PermissionRequest(token: "", type: .file, operation: .upload, bizDomain: .ccm, tenantID: nil)
                let response = permissionSDK.validate(request: request)
                return response.allow
            } else {
                let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmFileUpload, fileBizDomain: .ccm, docType: .file, token: nil)
                guard result.allow else {
                    DocsLogger.info("upload on node block by admin control")
                    return false
                }
            }
        }
        return true
    }

    public func didClickCreateAction(meta: WikiTreeNodeMeta, node: TreeNode, sourceView: UIView, completion: @escaping (Bool) -> Void) {
        let isFavorites = node.section == .favoriteRoot
        WikiStatistic.clickWikiTree(click: .add,
                                    isFavorites: isFavorites,
                                    target: DocsTracker.EventType.wikiTreeAddView.rawValue,
                                    meta: meta)
        guard DocsNetStateMonitor.shared.isReachable else { return }
        // 实现创建逻辑
        WikiStatistic.treeAddView(meta: meta)
        showCreatePanel(meta: meta, nodeUID: node.diffId, sourceView: sourceView, completion: completion)
    }

    private func showCreatePanel(meta: WikiTreeNodeMeta,
                                 nodeUID: WikiTreeNodeUID,
                                 sourceView: UIView,
                                 completion: ((Bool) -> Void)?) {
        let controller = interactionHelper.makeCreatePicker { type in
            createEnable(meta: meta, type: type)
        } handler: { [weak self] type in
            self?.createPickerDidClick(meta: meta, nodeUID: nodeUID, type: type, completion: completion)
        }
        controller.dismissCallback = {
            completion?(true)
        }
        controller.setupPopover(sourceView: sourceView, direction: [.up, .down])
        controller.dismissalStrategy = [.larkSizeClassChanged]
        actionInput.accept(.present(provider: { _ in
            controller
        }))
        onPermissionUpdated.emit(onNext: { [weak self, weak controller] in
            guard let self = self, let controller = controller else { return }
            self.interactionHelper.updateCreatePicker(picker: controller) { type in
                self.createEnable(meta: meta, type: type)
            } handler: { [weak self] type in
                self?.createPickerDidClick(meta: meta, nodeUID: nodeUID, type: type, completion: completion)
            }

        }).disposed(by: controller.updateBag)
    }

    private func createPickerDidClick(meta: WikiTreeNodeMeta,
                                      nodeUID: WikiTreeNodeUID,
                                      type: WikiInteractionHandler.CreateType,
                                      completion: ((Bool) -> Void)?) {
        switch type {
        case let .document(objType, template):
            guard createEnable(meta: meta, type: type) else { return }
            confirmCreate(meta: meta, nodeUID: nodeUID, type: objType, template:template)
            completion?(true)
        case let .upload(isImage):
            // TODO: PermissionSDK FG 移除后在这里调用一下 response.didTriggerOperation
            guard createEnable(meta: meta, type: type) else {
                let isReachable = DocsNetStateMonitor.shared.isReachable
                if createEnableByPermission(meta: meta) && isReachable {
                    if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                        let request = PermissionRequest(token: "", type: .file, operation: .upload, bizDomain: .ccm, tenantID: nil)
                        let response = permissionSDK.validate(request: request)
                        actionInput.accept(.customAction(compeletion: { controller in
                            guard let controller else {
                                spaceAssertionFailure("show permissionSDK failed to get controller")
                                return
                            }
                            response.didTriggerOperation(controller: controller)
                        }))
                    } else {
                        let validateResult = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmFileUpload, fileBizDomain: .ccm, docType: .file, token: nil)
                        switch validateResult.validateSource {
                        case .fileStrategy:
                            CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmFileUpload, fileBizDomain: .ccm, docType: .file, token: nil)
                        case .securityAudit:
                            // drive 因为 admin 管控被禁用时，需要给个 toast
                            actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast)))
                        case .dlpDetecting, .dlpSensitive, .ttBlock, .unknown:
                            DocsLogger.info("unknown type or dlp type")
                        }
                    }
                }
                return
            }
            confirmUpload(meta: meta, nodeUID: nodeUID, isImage: isImage, completion: completion)
        }
    }

    private func confirmUpload(meta: WikiTreeNodeMeta, nodeUID: WikiTreeNodeUID, isImage: Bool, completion: ((Bool) -> Void)?) {
        moreActionInput.accept(.upload(parentToken: meta.originWikiToken ?? meta.wikiToken, isImage: isImage, completion: {
            completion?(true)
        }))
        let event = WikiStatistic.TreeAddEvent(wikiToken: "null",
                                               fileId: "null",
                                               fileType: isImage ? "upload_picture" : "upload_file",
                                               isFavorites: nodeUID.section == .favoriteRoot,
                                               target: DocsTracker.EventType.noneTargetView.rawValue,
                                               meta: meta,
                                               triggerLocation: .wikiTree)
        WikiStatistic.clickWikiTreeAdd(event: event)
    }

    private func confirmCreate(meta: WikiTreeNodeMeta, nodeUID: WikiTreeNodeUID, type: DocsType, template: TemplateModel? = nil) {
        actionInput.accept(.showHUD(.customLoading(BundleI18n.SKResource.Doc_Wiki_CreateDialog)))
        DocsLogger.info("did confirm create \(type)")
        interactionHelper.confirmCreate(meta: meta, template: template, type: type)
            .subscribe { [weak self] node, originNode in
                self?.actionInput.accept(.hideHUD)
                DocsLogger.info("create wiki node success")
                let response = WikiTreeCreateResponse(nodeUID: nodeUID, nodeMeta: meta, newNode: node, originNode: originNode)
                self?.moreActionInput.accept(.create(response: response))
                let event = WikiStatistic.TreeAddEvent(
                    wikiToken: node.meta.wikiToken,
                    fileId: node.meta.objToken,
                    fileType: template == nil ? node.meta.objType.name : template?.fileType() ?? "",
                    isFavorites: nodeUID.section == .favoriteRoot,
                    target: DocsTracker.EventType.docsPageView.rawValue,
                    meta: meta,
                    triggerLocation: WikiStatistic.eventTriggerLocation(meta: meta, nodeUID: nodeUID))
                WikiStatistic.clickWikiTreeAdd(event: event)
            } onError: { [weak self] error in
                DocsLogger.error("create wiki node failed", error: error)
                guard let self = self else { return }
                let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                self.actionInput.accept(.showHUD(.failure(error.addErrorDescription)))
            }
            .disposed(by: disposeBag)
    }
}

// MARK: - More Action
extension WikiMainTreeMoreProvider {
    func moreAction(meta: WikiTreeNodeMeta, node: TreeNode) -> TreeSwipeAction? {
        TreeSwipeAction(normalImage: TreeSwipeAction.normalMoreImage,
                        normalBackgroundColor: UDColor.N500,
                        disabledImage: TreeSwipeAction.disabledMoreImage,
                        disabledBackgroundColor: UDColor.N400) { [weak self] sourceView, completion, _, _ in
            self?.didClickMoreAction(meta: meta, node: node, sourceView: sourceView, completion: completion)
        }
    }

    private func didClickMoreAction(meta: WikiTreeNodeMeta, node: TreeNode, sourceView: UIView, completion: @escaping (Bool) -> Void) {
        let isFavorites = node.section == .favoriteRoot
        WikiStatistic.clickWikiTree(click: .more,
                                    isFavorites: isFavorites,
                                    target: DocsTracker.EventType.wikiTreeMoreView.rawValue,
                                    meta: meta)
        guard DocsNetStateMonitor.shared.isReachable else { return }
        // 实现 more 逻辑
        if meta.secretKeyDeleted == true {
            actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidCanNotOperate)))
            return
        }
        WikiStatistic.treeMoreView(meta: meta)
        var forbiddenItems: [MoreItemType] = []
        var showCopyToCurrent: Bool = true
        switch node.section {
        case .documentRoot, .homeSharedRoot:
            guard node.level == 1 else {
                break
            }
            // MVP新首页置顶-云文档部分：一级节点more面板隐藏「移动到」
            forbiddenItems = [.moveTo]

            if UserScopeNoChangeFG.ZYP.spaceMoveToEnable {
                // 开放一级节点"移动到"功能
                forbiddenItems.removeAll(where: { $0 == .moveTo })
            }
            // 一级节点隐藏移快复picker创建到当前位置
            showCopyToCurrent = false
        case .mainRoot, .favoriteRoot, .mutilTreeRoot, .sharedRoot:
            break
        }
        let permission = nodePermissionStorage[meta.wikiToken]
        let moreClickTracker = ListMoreItemClickTracker(isShareFolder: false, type: meta.objType, originInWiki: !meta.originIsExternal)
        let moreProviderConfig = WikiTreeMoreDataProviderConfig(sourceView: sourceView, shouldShowCopyToCurrent: showCopyToCurrent)
        let moreProvider = WikiTreeMoreDataProvider(meta: meta,
                                                    config: moreProviderConfig,
                                                    spaceInfo: spaceInfo,
                                                    permission: permission,
                                                    clipChecker: clipChecker,
                                                    forbiddenItems: forbiddenItems)
        moreProvider.handler = self
        let moreVM = MoreViewModel(dataProvider: moreProvider, docsInfo: meta.transform(), moreItemClickTracker: moreClickTracker)
        let moreVC = MoreViewControllerV2(viewModel: moreVM)

        actionInput.accept(.present(provider: { _ in
            moreVC
        }, popoverConfig: { controller in
            controller.modalPresentationStyle = .popover
            controller.popoverPresentationController?.sourceView = sourceView
            controller.popoverPresentationController?.sourceRect = sourceView.bounds
            controller.popoverPresentationController?.permittedArrowDirections = .any
        }))
    }
}

// MARK: - Convenience method to show HUD
extension WikiMainTreeMoreProvider {
    func showSuccess(with: String) {
        self.actionInput.accept(.showHUD(.success(with)))
    }
    
    func showFailure(with: String) {
        self.actionInput.accept(.showHUD(.failure(with)))
    }

    func showTips(with: String) {
        self.actionInput.accept(.showHUD(.tips(with)))
    }
}
