//
//  WikiTreeMoreDataProvider.swift
//  SKWikiV2
//
//  Created by majie.7 on 2022/9/21.
//

import Foundation
import SKCommon
import SKFoundation
import SKResource
import RxSwift
import RxCocoa
import SKInfra
import SpaceInterface

public class WikiTreeMoreDataProviderConfig {
    public var shouldShowCopyToCurrent: Bool?
    public var showMorePanelSourceView: UIView
    
    public init(sourceView: UIView,
                shouldShowCopyToCurrent: Bool?) {
        self.showMorePanelSourceView = sourceView
        self.shouldShowCopyToCurrent = shouldShowCopyToCurrent
    }
}

public class WikiTreeMoreDataProvider: WikiMoreProvider {
    public var handler: WikiTreeMoreActionHandler?
    public var builder: MoreItemsBuilder { wikiMoreBuilder.moreBuilder }
    private lazy var wikiMoreBuilder = setupBuilder()
    private let disposeBag = DisposeBag()

    public var updater: MoreDataSourceUpdater?

    public var outsideControlItems: MoreDataOutsideControlItems?

    private let meta: WikiTreeNodeMeta
    private var spaceInfo: WikiSpace?
    // 当前所选节点权限
    private var permission: WikiTreeNodePermission?
    // 更新置顶状态
    private var isClipTop: Bool = false
    // 网络状态
    private let reachabilityRelay = BehaviorRelay(value: true)
    // 获取置顶状态
    private let clipStatusCompleteRelay = BehaviorRelay(value: false)
    // 获取drive info
    private var fileInfo: [String: Any]?
    // 获取本体的name供创建副本和 shortcut 使用
    private let metaNameRelay = BehaviorRelay<String?>(value: nil)
    // 置顶状态检查
    private let clipChecker: ((String) -> Bool)?
    // 需要隐藏的item
    private let forbiddenItems: [MoreItemType]

    private let config: WikiTreeMoreDataProviderConfig

    private let permissionSDK: PermissionSDK

    public init(meta: WikiTreeNodeMeta,
                config: WikiTreeMoreDataProviderConfig,
                spaceInfo: WikiSpace?,
                permission: WikiTreeNodePermission?,
                clipChecker: ((String) -> Bool)?,
                forbiddenItems: [MoreItemType] = []) {
        self.meta = meta
        self.config = config
        self.spaceInfo = spaceInfo
        self.permission = permission
        self.clipChecker = clipChecker
        self.forbiddenItems = forbiddenItems
        permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
        setup()
    }

    private func setup() {
        RxNetworkMonitor.networkStatus(observerObj: self)
            .map { $1 }
            .subscribe(onNext: { [weak self] reachable in
                self?.reachabilityRelay.accept(reachable)
                self?.reload()
            })
            .disposed(by: disposeBag)
        
        WikiNetworkManager.shared.getNodePermission(spaceId: meta.spaceID, wikiToken: meta.wikiToken)
            .subscribe(onSuccess: { [weak self] permission in
                self?.permission = permission
                self?.reload()
            })
            .disposed(by: disposeBag)
        
        WikiNetworkManager.shared.getSpace(spaceId: meta.spaceID)
            .subscribe(onNext: { [weak self] spaceInfo in
                self?.spaceInfo = spaceInfo
                self?.reload()
            })
            .disposed(by: disposeBag)
        
        // 外部有传入置顶状态则不需要发送请求获取指定状态
        if let clipChecker {
            isClipTop = clipChecker(meta.wikiToken)
            clipStatusCompleteRelay.accept(true)
        } else {
            WikiMoreAPI.fetchWikiMetaStarStatus(wikiToken: meta.wikiToken)
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] star in
                    self?.isClipTop = star
                    self?.clipStatusCompleteRelay.accept(true)
                    self?.reload()
                })
                .disposed(by: disposeBag)
        }

        WikiMoreAPI.fetchDriveFileInfo(wikiMeta: meta)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] info in
                self?.fileInfo = info
                self?.reload()
            })
            .disposed(by: disposeBag)
        

        if meta.isShortcut {
            WikiMoreAPI.fetchNameFromMeta(objToken: meta.objToken, objType: meta.objType)
                .subscribe { [weak self] title in
                    self?.metaNameRelay.accept(title)
                }
                .disposed(by: disposeBag)
        }
    }

    private func reload() {
        guard let updater = updater else {
            DocsLogger.info("wiki more panel refresh items failed because updator is nil")
            return
        }
        wikiMoreBuilder = setupBuilder()
        updater(builder)
    }
}

private extension WikiTreeMoreDataProvider {
    func setupBuilder() -> SpaceMoreItemBuilder {
        if meta.isShortcut {
            return setupShortcutBuilder()
        } else {
            return setupNodeBuilder()
        }
    }
    // 本体节点
    func setupNodeBuilder() -> SpaceMoreItemBuilder {
        SpaceMoreItemBuilder {
            SpaceMoreSection(type: .horizontal) {
                moveTo
                createShortcut
                pin
                clipTop
                star
                offline
            }
            SpaceMoreSection(type: .vertical) {
                copyLink
                copyFile
                rename
                download
                remove
            }
            SpaceMoreSection(type: .vertical) {
                delete
            }
        }
    }
    // shortcut节点
    func setupShortcutBuilder() -> SpaceMoreItemBuilder {
        var originMoreItems: [SpaceMoreItem] = [copyFile, download]
        if meta.originDeleted {
            originMoreItems = [entityDeleted]
        }
        return SpaceMoreItemBuilder {
            SpaceMoreSection(type: .horizontal) {
                createShortcut
                pin
                clipTop
                star
            }
            SpaceMoreSection(type: .verticalSection(.origin)) {
                originMoreItems
            }
            SpaceMoreSection(type: .verticalSection(.shortcut)) {
                copyLink
                moveTo
                rename
                delete
            }
        }
    }

    var createShortcut: SpaceMoreItem {
        let canAdd = meta.isShortcut ? permission?.originCanAddShortcut : permission?.canAddShortCut
        return SpaceMoreItem(type: .addShortCut,
                             hiddenCheckers: {
                    BizChecker(disableReason: "", staticChecker: meta.objType != .wikiCatalog)
                    BizChecker(disableReason: "", staticChecker: !meta.originDeleted)
                }, enableCheckers: {
                    NetworkChecker(input: reachabilityRelay.asObservable())
                    BizChecker(disableReason: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission, staticChecker: canAdd == true)
                }, handler: { [weak self] _, forbiddenReason in
                    guard let self else { return }
                    if let forbiddenReason = forbiddenReason {
                        self.handler?.disableHandle(reason: forbiddenReason)
                        return
                    }
                    self.handler?.shortcutTarget(with: self.meta,
                                                 originName: self.metaNameRelay.value,
                                                 inClipSection: self.isClipTop)
                })
    }

    var star: SpaceMoreItem {
        let canStar = meta.isShortcut ? permission?.originCanExplorerStar : permission?.canExplorerStar
        return SpaceMoreItem(type: meta.isExplorerStar ? .unStar : .star,
                             hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: !meta.originDeleted)
        }, enableCheckers: {
            NetworkChecker(input: reachabilityRelay.asObservable())
            BizChecker(disableReason: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission, staticChecker: canStar == true)
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let forbiddenReason = forbiddenReason {
                self.handler?.disableHandle(reason: forbiddenReason)
                return
            }
            self.handler?.starInSpaceTarget(with: self.meta)
        }
    }

    var clipTop: SpaceMoreItem {
        SpaceMoreItem(type: isClipTop ? .wikiUnClip : .wikiClipTop,
                      hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: meta.spaceID == spaceInfo?.spaceID)
            // FG 开时，隐藏旧Wiki置顶按钮
            BizChecker(disableReason: "", staticChecker: !UserScopeNoChangeFG.WWJ.newSpaceTabEnable)
        }, enableCheckers: {
            NetworkChecker(input: reachabilityRelay.asObservable())
            RxBizChecker(disableReason: "", input: clipStatusCompleteRelay.asObservable())
            BizChecker(disableReason: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission, staticChecker: permission?.canStar == true)
        }, handler: { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let forbiddenReason = forbiddenReason {
                self.handler?.disableHandle(reason: forbiddenReason)
                return
            }
            self.handler?.clipTarget(with: self.meta,
                                     setClip: !self.isClipTop)
        })
    }

    var copyFile: SpaceMoreItem {
        let canCopy = meta.isShortcut ? permission?.originCanCopy : permission?.canCopy
        return SpaceMoreItem(type: .copyFile,
                             hiddenCheckers: {},
                             enableCheckers: {
            NetworkChecker(input: reachabilityRelay.asObservable())
            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                PermissionSDKChecker(permissionSDK: permissionSDK, request: PermissionRequest(token: meta.objToken,
                                                                                              type: meta.objType,
                                                                                              operation: .createCopy,
                                                                                              bizDomain: .ccm,
                                                                                              tenantID: nil))
            } else {
                SecurityPolicyChecker(permissionType: .createCopy, docsType: meta.objType, token: meta.objToken)
            }
            BizChecker(disableReason: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission, staticChecker: canCopy == true)
        }, handler: { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let forbiddenReason = forbiddenReason {
                self.handler?.disableHandle(reason: forbiddenReason)
                return
            }
            self.handler?.copyTarget(with: self.meta,
                                     showCopyToCurrent: self.config.shouldShowCopyToCurrent ?? true,
                                     originName: self.metaNameRelay.value,
                                     inClipSection: self.isClipTop)
        })
    }

    var moveTo: SpaceMoreItem {
        SpaceMoreItem(type: .moveTo,
                      hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: !forbiddenItems.contains(.moveTo))
        },
                      enableCheckers: {
            NetworkChecker(input: reachabilityRelay.asObservable())
            BizChecker(disableReason: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission,
                       staticChecker: permission?.showMove == true)
        }, handler: { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let forbiddenReason = forbiddenReason {
                self.handler?.disableHandle(reason: forbiddenReason)
                return
            }
            self.handler?.moveTarget(with: self.meta,
                                     permission: self.permission,
                                     inClipSection: self.isClipTop)
        })
    }

    // 移除到space
    var remove: SpaceMoreItem {
        SpaceMoreItem(type: .removeFromWiki,
                      hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: !fromMylibrary)
            BizChecker(disableReason: "", staticChecker: moveToSpaceEnable)
        }, enableCheckers: {
            NetworkChecker(input: reachabilityRelay.asObservable())
            BizChecker(disableReason: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission, staticChecker: permission?.showMove == true)
        }, handler: { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let forbiddenReason = forbiddenReason {
                self.handler?.disableHandle(reason: forbiddenReason)
                return
            }
            self.handler?.removeToSpaceTarget(with: self.meta,
                                              permission: self.permission,
                                              inClipSection: self.isClipTop)
        })
    }

    // 删除节点
    var delete: SpaceMoreItem {
        var disableReason = BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission
        if permission?.hasParentMovePermission == false {
            if permission?.parentIsRoot == true {
                //无空间一级页面可管理权限
                disableReason = BundleI18n.SKResource.LarkCCM_Workspace_DeleteGrayed_SpacePerm_Tooltip
            } else {
                //无父节点可管理权限
                disableReason = BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_ParentPerm_Tooltip
            }
        }
        let visable: Bool
        if UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled {
            visable = permission?.showDelete == true
        } else {
            visable = permission?.nodeCanMovePermission == true
        }
        let itemType: MoreItemType = meta.isShortcut ? .deleteShortcut : .delete
        return SpaceMoreItem(type: itemType,
                             hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: visable)
        }, enableCheckers: {
            NetworkChecker(input: reachabilityRelay.asObservable())
            if !UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled {
                BizChecker(disableReason: disableReason,
                           staticChecker: permission?.canDelete == true)
            }
        }, handler: { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let forbiddenReason = forbiddenReason {
                self.handler?.disableHandle(reason: forbiddenReason)
                return
            }
            self.handler?.deleteTarget(with: self.meta,
                                       permission: self.permission,
                                       inClipSection: self.isClipTop,
                                       sourceView: self.config.showMorePanelSourceView)
        })
    }

    var copyLink: SpaceMoreItem {
        SpaceMoreItem(type: .copyLink,
                      hiddenCheckers: { BizChecker(disableReason: "", staticChecker: UserScopeNoChangeFG.PLF.shareChannelDisable == false) },
                      enableCheckers: {},
                      handler: { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let forbiddenReason = forbiddenReason {
                self.handler?.disableHandle(reason: forbiddenReason)
                return
            }
            self.handler?.copyLink(with: self.meta)
        })
    }

    var rename: SpaceMoreItem {
        SpaceMoreItem(type: .rename,
                      hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: renameEnable)
        },
                      enableCheckers: {
            NetworkChecker(input: reachabilityRelay.asObservable())
            BizChecker(disableReason: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission,
                       staticChecker: permission?.canRename == true)
        }, handler: { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let forbiddenReason = forbiddenReason {
                self.handler?.disableHandle(reason: forbiddenReason)
                return
            }
            self.handler?.rename(with: self.meta)
        })
    }

    // "保存到本地"
    var download: SpaceMoreItem {
        let canDownload = meta.isShortcut ? permission?.originCanDownload : permission?.canDownload
        return SpaceMoreItem(type: .saveToLocal,
                             hiddenCheckers: {
                BizChecker(disableReason: "", staticChecker: meta.objType == .file)
                BizChecker(disableReason: "", staticChecker: DriveFeatureGate.driveEnabled)
            }, enableCheckers: {
                NetworkChecker(input: reachabilityRelay.asObservable())
                if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                    PermissionSDKChecker(permissionSDK: permissionSDK,
                                         request: PermissionRequest(token: meta.objToken,
                                                                    type: meta.objType,
                                                                    operation: .saveFileToLocal,
                                                                    bizDomain: .ccm,
                                                                    tenantID: nil))
                } else {
                    SecurityPolicyChecker(permissionType: .download, docsType: meta.objType, token: meta.objToken)
                }
                BizChecker(disableReason: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission, staticChecker: fileInfo != nil)
                BizChecker(disableReason: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission, staticChecker: canDownload == true)
            }, handler: { [weak self] _, forbiddenReason in
                guard let self else { return }
                if let forbiddenReason = forbiddenReason {
                    self.handler?.disableHandle(reason: forbiddenReason)
                    return
                }
                self.handler?.downloadHandle(with: self.meta, fileInfo: self.fileInfo)
            })
    }

    var entityDeleted: SpaceMoreItem {
        SpaceMoreItem(type: .entityDeleted,
                      hiddenCheckers: {},
                      enableCheckers: {
            BizChecker(disableReason: BundleI18n.SKResource.LarkCCM_Workspace_Menu_OriginalDocumentDeleted_Tooltip, staticChecker: false)
        }, handler: { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let forbiddenReason {
                self.handler?.disableHandle(reason: forbiddenReason)
                return
            }
        })
    }
    
    var pin: SpaceMoreItem {
        let canPin = meta.isShortcut ? permission?.originCanExplorerPin : permission?.canExplorerPin
        return SpaceMoreItem(type: meta.isExplorerPin ? .unPin : .pin,
                             hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: !meta.originDeleted)
        },
                             enableCheckers: {
            NetworkChecker(input: reachabilityRelay.asObservable())
            BizChecker(disableReason: BundleI18n.SKResource.LarkCCM_Workspace_Menu_NoPermToQuickAccess_Tooltip, staticChecker: canPin == true)
        }, handler: { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let forbiddenReason {
                self.handler?.disableHandle(reason: forbiddenReason)
                return
            }
            self.handler?.pinInSpaceTarget(with: self.meta)
        })
    }

    var offline: SpaceMoreItem {
        let entry: SpaceEntry = meta.transformFileEntry()
        let docsInfo = meta.transform()
        let type: MoreItemType = docsInfo.checkIsSetManualOffline() ? .cancelManualOffline : .manualOffline
        return SpaceMoreItem(
            type: type,
            hiddenCheckers: {
                if meta.objType == .file {
                    BizChecker(disableReason: "", staticChecker: DriveFeatureGate.driveEnabled)
                }
                BizChecker(disableReason: "", staticChecker: UserScopeNoChangeFG.CWJ.wikiTreeOfflineEnable)
                BizChecker(disableReason: "", staticChecker: entry.canSetManualOffline)
            },
            enableCheckers: {},
            handler: { [weak self] _, forbiddenReason in
                guard let self = self else {
                    return
                }
                if let forbiddenReason = forbiddenReason {
                    self.handler?.disableHandle(reason: forbiddenReason)
                    return
                }
                self.handler?.offlineAccess(with: self.meta)
            }
        )
    }
}

private extension WikiTreeMoreDataProvider {
    private var moveToSpaceEnable: Bool {
        guard SettingConfig.singleContainerEnable else { return false }
        guard !meta.isShortcut else { return false }
        return true
    }

    private var renameEnable: Bool {
        switch meta.objType {
        case .doc, .docX, .sheet, .bitable, .mindnote, .file, .slides:
            return true
        default:
            return false
        }
    }
    
    private var fromMylibrary: Bool {
        if spaceInfo?.isLibraryOwner == true {
            return true
        }
        if MyLibrarySpaceIdCache.isMyLibrary(meta.spaceID) {
            return true
        }
        return false
    }
}
