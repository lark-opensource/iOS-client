//
//  DKSpaceNaviBarModule.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/23.

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import EENavigator
import SpaceInterface
import SKResource
import UniverseDesignBadge
import LarkDocsIcon
import LarkContainer

class DKSpaceNaviBarModule: DKBaseSubModule {
    // 当前生命周期是否打开过shareVC
    var hasShownShareVC: Bool = false
    /// 业务方配置的导航栏按钮，如“更多”
    private let naviBarItemsRelay = BehaviorRelay<[DKNaviBarItem]>(value: [])
    /// 预览业务配置的额外的导航栏按钮，如“PPT 演示模式”
    private let additionRightNaviBarItemsRelay = BehaviorRelay<[DKNaviBarItem]>(value: [])
    private let additionLeftNaviBarItemsRelay = BehaviorRelay<[DKNaviBarItem]>(value: [])
    /// 文件标题
    private let titleRelay: BehaviorRelay<String>

    // item控制
    let moreItemEnable = BehaviorRelay<Bool>(value: false)
    let moreItemVisable = BehaviorRelay<Bool>(value: false)
    let feedItemEnable = BehaviorRelay<Bool>(value: false)
    let feedItemVisable = BehaviorRelay<Bool>(value: false)
    let shareItemEnable = BehaviorRelay<Bool>(value: false)
    let shareItemVisable = BehaviorRelay<Bool>(value: false)
    let sensitivityItemVisable = BehaviorRelay<Bool>(value: false) //展示密级入口
    let wikiNodeIsDeleted = BehaviorRelay<Bool>(value: false)
    
    let myAIItemEnable = BehaviorRelay<Bool>(value: false) // My AI分会话入口
    let myAIItemVisable = BehaviorRelay<Bool>(value: false) // My AI分会话入口

    private var naviBarViewModel: DKNaviBarViewModel
    // 避免密钥删除场景下，moreItem刷新信号触发后重新展示
    private var fileKeyHasBeenDelete: Bool = false
    
    // 文件状态
    private let _isLegal = BehaviorSubject<DriveAuditState>(value: (result: .legal, reason: .none))
    private let _isDeleted = BehaviorRelay<Bool>(value: false)
    private let _isKeyDeleted = BehaviorSubject<Bool>(value: false)
    /// 最大的小红点数字
    private static let maxBadgeNum = 999

    deinit {
        DocsLogger.driveInfo("DKSpaceNaviBarModule -- deinit")
    }
    override init(hostModule: DKHostModuleType) {
        titleRelay = BehaviorRelay<String>(value: hostModule.fileInfoRelay.value.name)
        
        // 导航栏按钮配置
        let leftBarItemsChanged = Observable<[DKNaviBarItem]>.combineLatest(BehaviorRelay<[DKNaviBarItem]>(value: []), additionLeftNaviBarItemsRelay, resultSelector: +)
        let rightBarItemsChanged = Observable<[DKNaviBarItem]>.combineLatest(naviBarItemsRelay, additionRightNaviBarItemsRelay, resultSelector: +)
        let naviBarDependencyImpl = DKNaviBarDependencyImpl(titleRelay: titleRelay,
                                                            fileDeleted: _isDeleted,
                                                            leftBarItems: leftBarItemsChanged,
                                                            rightBarItems: rightBarItemsChanged)
        self.naviBarViewModel = DKNaviBarViewModel(dependency: naviBarDependencyImpl)
        naviBarViewModel.shouldShowTexts = (hostModule.commonContext.previewFrom != .groupTab)
        hostModule.subModuleActionsCenter.accept(.updateNaviBar(vm: naviBarViewModel))
        super.init(hostModule: hostModule)
        self.setupNaviBarItems()
    }
    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        guard let host = hostModule else { return self }
        host.fileInfoRelay.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] info in
            guard let self = self else { return }
            self.titleRelay.accept(info.name)
        }).disposed(by: bag)
        
        host.fileInfoErrorOb
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] err in
            guard let self = self else { return }
            guard let error = err else {
                self._isLegal.onNext(DriveAuditState(result: .legal, reason: .none))
                self._isDeleted.accept(false)
                return
            }
            switch error {
            case let .serverError(code):
                self._isDeleted.accept(code == DriveFileInfoErrorCode.fileDeletedOnServerError.rawValue
                                    || code == DriveFileInfoErrorCode.fileNotFound.rawValue)
                self._isKeyDeleted.onNext(code == DriveFileInfoErrorCode.fileKeyDeleted.rawValue)
                if code == DriveFileInfoErrorCode.machineAuditFailureError.rawValue
                    || code == DriveFileInfoErrorCode.humanAuditFailureError.rawValue {
                    self._isLegal.onNext(DriveAuditState(result: .collaboratorIllegal, reason: .none))
                } else {
                    self._isLegal.onNext(DriveAuditState(result: .legal, reason: .none))
                }
            default:
                break
            }
        }).disposed(by: bag)
        
        host.subModuleActionsCenter.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] action in
            switch action {
            case let .updateAdditionNavibarItem(leftItems, rightItems):
                self?.additionLeftNaviBarItemsRelay.accept(leftItems)
                self?.additionRightNaviBarItemsRelay.accept(rightItems)
            case .clearNaviBarItems:
                DocsLogger.driveInfo("DKSpaceNaviBarModule -- recive clear navibar items")
                self?.naviBarItemsRelay.accept([])
            case .refreshNaviBarItemsDots:
                self?.refreshNavibarDots()
            case .fileDidDeleted:
                self?._isDeleted.accept(true)
            case let .wikiNodeDeletedStatus(isDelete):
                self?.wikiNodeIsDeleted.accept(isDelete)
            default:
                break
            }
        }).disposed(by: bag)

        struct NaviBarPermission {
            let canPerceive: Bool
            let blockByCAC: Bool
            let viewBlockByAudit: Bool
            let canView: Bool
            let canCopy: Bool
        }

        let permission: Observable<NaviBarPermission>
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            permission = host.permissionService.onPermissionUpdated.map { [weak host] _ in
                guard let service = host?.permissionService else {
                    return NaviBarPermission(canPerceive: false, blockByCAC: false, viewBlockByAudit: false, canView: false, canCopy: false)
                }
                let canPerceive = service.validate(operation: .perceive).allow
                let blockByCAC = service.containerResponse?.container?.shareControlByCAC ?? false
                let viewBlockByAudit = service.containerResponse?.container?.viewBlockByAudit ?? false
                let canView = service.validate(operation: .view).allow
                let canCopy = service.validate(operation: .copyContent).allow
                return NaviBarPermission(canPerceive: canPerceive,
                                         blockByCAC: blockByCAC,
                                         viewBlockByAudit: viewBlockByAudit,
                                         canView: canView,
                                         canCopy: canCopy)
            }
        } else {
            permission = host.permissionRelay.map { permissionInfo in
                NaviBarPermission(canPerceive: permissionInfo.userPermissions?.canPerceive() == true,
                                  blockByCAC: permissionInfo.userPermissions?.shareControlByCAC() == true,
                                  viewBlockByAudit: false,
                                  canView: permissionInfo.isReadable,
                                  canCopy: permissionInfo.canCopy)
            }
        }
    
        Observable.combineLatest(host.reachabilityChanged,
                                 _isLegal,
                                 permission,
                                 _isDeleted,
                                 _isKeyDeleted,
                                 wikiNodeIsDeleted,
                                 host.docsInfoRelay.asObservable(),
                                 host.fileInfoRelay.asObservable())
        .subscribe(onNext: { [weak self] reachable, auditStatue, naviBarPermission, deleted, keyDeleted, wikiDeleted, docsInfoValid, fileInfo in
                                guard let self = self, let host = self.hostModule else { return }
                                 // 是否展示
                                DocsLogger.driveInfo("DKSpaceNaviBarModule -- permission info \(naviBarPermission)")

                                if keyDeleted || wikiDeleted { //密钥删除或Wiki删除报错所有item隐藏
                                    DocsLogger.driveInfo("DKSpaceNaviBarModule -- key delelted")
                                    self.setupFileKeyHasBeenDeleteState()
                                    return
                                }

                                // 是否展示
                                ///“文件预览与查看”精细化权限管控 需求特化  https://bytedance.feishu.cn/docx/doxcn4XolgYkfA9P4FNFWAPAKfe
                                let canPerceive = naviBarPermission.canPerceive
                                /// 条件访问控制cac管控
                                let cacBlocked = naviBarPermission.blockByCAC
                                // 审计预览管控时，需要隐藏导航栏各按钮
                                let auditBlock = naviBarPermission.viewBlockByAudit
                                let visable = !cacBlocked && canPerceive && !deleted && (auditStatue.result != .collaboratorIllegal) && !auditBlock

                                let inVCFollow = host.commonContext.isInVCFollow
                                let isHistory = (host.commonContext.previewFrom == .history)
                                let MyAIEnable = visable
                                                    && self.aiServiceEnable
                                                    && UserScopeNoChangeFG.ZH.enablePDFMyAIEntrance
                                                    && !inVCFollow
                                                    && !isHistory
                                                    && fileInfo.fileType == .pdf
        
                                self.moreItemVisable.accept(visable)
                                self.feedItemVisable.accept(visable && naviBarPermission.canView)
                                self.shareItemVisable.accept(visable)
                                
                                // MS/历史纪录版本不需要暂时AI
                                self.myAIItemVisable.accept(MyAIEnable)

                                // 是否置灰
                                let enable = reachable && docsInfoValid.ownerName != nil && !host.commonContext.isGuest
                                self.moreItemEnable.accept(enable)
                                self.feedItemEnable.accept(enable)
                                self.shareItemEnable.accept(enable && auditStatue.result != .ownerIllegal)
                                self.myAIItemEnable.accept(enable && MyAIEnable)
                                }).disposed(by: bag)
        
        return self
    }
    
    private func setupNaviBarItems() {
        guard let host = hostModule, !fileKeyHasBeenDelete else {
            DocsLogger.driveInfo("hostModule not found")
            return
        }
        let sensitivityItem = DKSensitivtyItemViewModel(visable: sensitivityItemVisable.asObservable())
        
        let feedItem = DKFeedItemViewModel(enable: feedItemEnable.asObservable(),
                                           visable: feedItemVisable.asObservable(),
                                           isReachable: host.reachabilityChanged)
        let shareItem = DKShareItemViewModel(enable: shareItemEnable.asObservable(),
                                             visable: shareItemVisable.asObservable(),
                                             isReachable: host.reachabilityChanged)
        shareItem.itemDidClickAction = { [weak self] in
            self?.hasShownShareVC = true
        }
        
        /// My AI分会话
        let MyAIItem = DKMyAIItemViewModel(enable: myAIItemEnable.asObservable(),
                                           visable: myAIItemVisable.asObservable(),
                                           isReachable: host.reachabilityChanged)
        
        let moreItem = DKSpaceMoreItemViewModel(enable: moreItemEnable.asObservable(),
                                                visable: moreItemVisable.asObservable(),
                                                isReachable: host.reachabilityChanged)
        let blockByAdmin: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            blockByAdmin = host.permissionService.containerResponse?.container?.previewBlockByAdmin ?? false
        } else {
            blockByAdmin = permissionInfo.userPermissions?.adminBlocked() == true
        }
        if host.commonContext.previewFrom == .history {
            naviBarItemsRelay.accept([feedItem])
            feedItemVisable.accept(!blockByAdmin)
        } else if host.commonContext.previewFrom == .groupTab {
            let items: [DKNaviBarItem] = [moreItem, shareItem]
            naviBarItemsRelay.accept(items.map { self.shouldShowBadge(item: $0) })
            shareItemVisable.accept(true)
            moreItemVisable.accept(true)
        } else {
            let items: [DKNaviBarItem] = [moreItem, MyAIItem , shareItem, feedItem, sensitivityItem]
            naviBarItemsRelay.accept(items.map { self.shouldShowBadge(item: $0) })
            feedItemVisable.accept(!blockByAdmin)
            shareItemVisable.accept(true)
            moreItemVisable.accept(true)
        }
    }
    
    private func refreshNavibarDots() {
        let items = naviBarItemsRelay.value
        naviBarItemsRelay.accept(items.map { self.shouldShowBadge(item: $0) })
    }
    
    /// MyAI 分会话
    private var aiServiceEnable: Bool {
        if let service = try? Container.shared.resolve(assert: CCMAIService.self) {
            return service.enable.value
        }
        return false
    }

    private func shouldShowBadge(item: DKNaviBarItem) -> DKNaviBarItem {
        // 判断是否需要显示小红点
        var newItem = item
        DocsLogger.driveInfo("DriveMainViewController.shouldShowBadge: importToOnlneFileEnabled: \(importToOnlneFileEnabled())")
        DocsLogger.driveInfo("DriveMainViewController.shouldShowBadge: needShowRedGuide: \(DriveConvertFileConfig.needShowRedGuide())")
        if case .more = item.naviBarButtonID, (importToOnlneFileEnabled() && DriveConvertFileConfig.needShowRedGuide()) {
            newItem.badgeStyle = .dot
        }
        if case .feed = item.naviBarButtonID {
            let num = hostModule?.commentManager?.messageUnreadCount.value ?? 0
            if num != 0 {
                newItem.badgeStyle = UDBadgeConfig(type: .number, number: num, maxNumber: Self.maxBadgeNum)
            } else {
                newItem.badgeStyle = nil
            }
        }
        if case .share = item.naviBarButtonID {
            newItem.badgeStyle = nil
        }
        return newItem
    }
    
    func importToOnlneFileEnabled() -> Bool {
        // 类型是否支持
        let type = DriveFileType(fileExtension: fileInfo.type)
        let typeEnabled = type.canImportAsDocs || type.canImportAsSheet || type.canImportAsMindnote
        // 是否开启fg
        let fgEnabled = DriveConvertFileConfig.isFeatureGatingEnabled()
        // 是否可以导出
        let canExport: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            // 这里只有无用户权限才返回 false, more 面板内另外有 enable 的判断
            // 考虑补一个豁免 case 来实现
            if let response = hostModule?.permissionService.validate(operation: .importToOnlineDocument) {
                switch response.result {
                case .allow:
                    canExport = true
                case let .forbidden(denyType, _):
                    if case .blockByUserPermission = denyType {
                        canExport = false
                    } else {
                        canExport = true
                    }
                }
            } else {
                canExport = false
            }
        } else {
            canExport = permissionInfo.canExport
        }
        return fgEnabled && canExport && typeEnabled
    }
    
    // 设置密钥被删除后顶部状态栏状态
    private func setupFileKeyHasBeenDeleteState() {
        naviBarItemsRelay.accept([])
        naviBarViewModel.titleVisableRelay.accept(false)
        fileKeyHasBeenDelete = true
    }
}
