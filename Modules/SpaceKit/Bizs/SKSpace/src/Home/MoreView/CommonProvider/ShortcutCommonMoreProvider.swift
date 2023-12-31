//
//  ShortcutCommonMoreProvider.swift
//  SKSpace
//
//  Created by Weston Wu on 2023/5/10.
//

import Foundation
import SKCommon
import SKResource
import SKFoundation
import RxSwift
import RxRelay
import SpaceInterface

class ShortcutMorePermissionContext {
    // shortcut 自身的权限
    let shortcutPermissionService: UserPermissionService
    let shortcutPermissionUpdated: Observable<UserPermissionAbility?>
    // 本体以及父文件夹的权限
    let entryContext: CommonMoreProviderPermissionContext

    init(shortcutPermissionService: UserPermissionService,
         shortcutPermissionUpdated: Observable<UserPermissionAbility?>,
         entryContext: CommonMoreProviderPermissionContext) {
        self.shortcutPermissionService = shortcutPermissionService
        self.shortcutPermissionUpdated = shortcutPermissionUpdated
        self.entryContext = entryContext
    }
}

// 快捷方式通用操作逻辑
class ShortcutCommonMoreProvider {

    private let context: CommonMoreProviderContext
    private let config: CommonMoreProviderConfig
    var entry: SpaceEntry { context.entry }

    // 基于 entryProvider 做包装
    private let entryProvider: EntryCommonMoreProvider

    // shortcut的权限模型
    private let shortcutPermissionService: UserPermissionService
    private let shortcutPermissionUpdated: Observable<UserPermissionAbility?>
    // 本体的权限模型
    private let entryPermissionService: UserPermissionService
    private let entryPermissionRelay: BehaviorRelay<UserPermissionAbility?>
    private var entryPermissionUpdated: Observable<UserPermissionAbility?> { entryPermissionRelay.asObservable() }
    // 容器的权限模型
    private let parentPermissionService: UserPermissionService
    private let parentPermissionUpdated: Observable<UserPermissionAbility?>

    private let reachabilityRelay = BehaviorRelay(value: true)
    private var reachableUpdated: Observable<Bool> { reachabilityRelay.asObservable() }
    // 本体名字，创建副本要用本体名字作为标题
    private let originNameRelay = BehaviorRelay<String?>(value: nil)

    weak var handler: SpaceMoreActionHandler? {
        didSet {
            entryProvider.handler = handler
        }
    }
    var reloadHandler: ((Bool) -> Void)? {
        didSet {
            entryProvider.reloadHandler = reloadHandler
        }
    }

    private let disposeBag = DisposeBag()

    init(context: CommonMoreProviderContext,
         config: CommonMoreProviderConfig,
         permissionContext: ShortcutMorePermissionContext,
         entryProvider: EntryCommonMoreProvider) {
        self.context = context
        self.config = config
        self.entryProvider = entryProvider
        self.shortcutPermissionService = permissionContext.shortcutPermissionService
        self.shortcutPermissionUpdated = permissionContext.shortcutPermissionUpdated
        self.entryPermissionService = permissionContext.entryContext.permissionService
        self.entryPermissionRelay = permissionContext.entryContext.permissionRelay
        self.parentPermissionService = permissionContext.entryContext.parentPermissionService
        self.parentPermissionUpdated = permissionContext.entryContext.parentPermissionUpdated

        setup()
    }

    private func setup() {
        RxNetworkMonitor.networkStatus(observerObj: self)
            .map { $1 }
            .subscribe(onNext: { [weak self] reachable in
                self?.reachabilityRelay.accept(reachable)
                self?.reloadHandler?(false)
            })
            .disposed(by: disposeBag)

        // 获取本体名字
        SpaceMoreAPI.fetchNameFromMeta(objToken: entry.objToken, objType: entry.docsType)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] entryName in
                self?.originNameRelay.accept(entryName)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - 对本体的操作
extension ShortcutCommonMoreProvider {
    // 相比实体的分享，多了 view 权限的判断
    var share: SpaceMoreItem {
        let item = entryProvider.share
        let permissionChecker: EnableChecker
        if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
            permissionChecker = UserPermissionServiceChecker(service: entryPermissionService,
                                                             operation: .view)
        } else {
            permissionChecker = UserPermissionTypeChecker(input: entryPermissionUpdated, permissionType: .view)
        }
        item.enableCheckers.append(permissionChecker)
        return item
    }

    var star: SpaceMoreItem {
        let item = entryProvider.star
        item.hiddenCheckers.append(BizChecker(disableReason: "", staticChecker: !entry.originDeleted))
        let permissionChecker: EnableChecker
        if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
            permissionChecker = UserPermissionServiceChecker(service: entryPermissionService,
                                                             operation: .view)
        } else {
            permissionChecker = UserPermissionTypeChecker(input: entryPermissionUpdated, permissionType: .view)
        }
        item.enableCheckers.append(permissionChecker)
        return item
    }

    var pin: SpaceMoreItem {
        let item = entryProvider.pin
        item.hiddenCheckers.append(BizChecker(disableReason: "", staticChecker: !entry.originDeleted))
        let permissionChecker: EnableChecker
        if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
            permissionChecker = UserPermissionServiceChecker(service: entryPermissionService,
                                                             operation: .view)
            .custom(reason: BundleI18n.SKResource.LarkCCM_Workspace_Menu_NoPermToQuickAccess_Tooltip)
        } else {
            permissionChecker = UserPermissionTypeChecker(input: entryPermissionUpdated, permissionType: .view)
                .custom(reason: BundleI18n.SKResource.LarkCCM_Workspace_Menu_NoPermToQuickAccess_Tooltip)
        }
        item.enableCheckers.append(permissionChecker)
        return item
    }

    var copyLink: SpaceMoreItem { entryProvider.copyLink }

    var importToOnlineDocument: SpaceMoreItem { entryProvider.importToOnlineDocument }

    var exportToLocal: SpaceMoreItem {
        // 这里覆盖下原有的 handler，增加一个 originName 参数
        let item = entryProvider.exportToLocal
        item.handler = { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .exportDocument, reason: reason, entry: self.entry)
                return
            }
            let canEdit: Bool
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                canEdit = self.entryPermissionService.validate(operation: .edit, bizDomain: .ccm).allow
            } else {
                canEdit = self.entryPermissionRelay.value?.canEdit() ?? false
            }
            self.handler?.exportDocument(for: self.entry,
                                         originName: self.originNameRelay.value,
                                         haveEditPermission: canEdit,
                                         sourceView: self.context.sourceView)
        }
        return item
    }

    var retention: SpaceMoreItem { entryProvider.retention }

    var saveToLocal: SpaceMoreItem {
        let item = entryProvider.saveToLocal
        item.handler = { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .saveToLocal, reason: reason, entry: self.entry)
                return
            }
            self.handler?.saveToLocal(for: self.entry, originName: self.originNameRelay.value)
        }
        return item
    }

    var openWithOtherApp: SpaceMoreItem {
        let item = entryProvider.openWithOtherApp
        item.handler = { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .openWithOtherApp, reason: reason, entry: self.entry)
                return
            }
            self.handler?.openWithOtherApp(for: self.entry, originName: self.originNameRelay.value, sourceView: self.context.sourceView)
        }
        return item
    }

    var copyFile: SpaceMoreItem {
        let item = entryProvider.copyFile
        // 这里覆盖下原有的 handler，增加一个 originName 参数
        item.handler = { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .copyFile, reason: reason, entry: self.entry)
                return
            }
            self.handler?.copyFile(for: self.entry, fileSize: nil, originName: self.originNameRelay.value)
        }
        return item
    }

    var createShortcut: SpaceMoreItem {
        let item = entryProvider.createShortcut
        item.hiddenCheckers.append(BizChecker(disableReason: "", staticChecker: !entry.originDeleted))
        let permissionChecker: EnableChecker
        if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
            permissionChecker = UserPermissionServiceChecker(service: entryPermissionService,
                                                             operation: .view)
        } else {
            permissionChecker = UserPermissionTypeChecker(input: entryPermissionUpdated, permissionType: .view)
        }
        item.enableCheckers.append(permissionChecker)

        // 多一个 originName 参数
        item.handler = { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .addShortCut, reason: reason, entry: self.entry)
                return
            }
            self.handler?.addShortCut(for: self.entry, originName: self.originNameRelay.value)
        }

        return item
    }

    var originEntityDeleted: SpaceMoreItem {
        SpaceMoreItem(type: .entityDeleted,
                      hiddenCheckers: {},
                      enableCheckers: {
            BizChecker(disableReason: BundleI18n.SKResource.LarkCCM_Workspace_Menu_OriginalDocumentDeleted_Tooltip, staticChecker: false)
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let forbiddenReason {
                self.handler?.handle(disabledAction: .entityDeleted, reason: forbiddenReason, entry: self.entry)
            }
        }
    }
}

// MARK: - 对 shortcut 的操作
extension ShortcutCommonMoreProvider {
    var deleteShortcut: SpaceMoreItem {
        SpaceMoreItem(type: .deleteShortcut,
                      hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: !config.forbiddenItems.contains(.delete))
        },
                      enableCheckers: {
            NetworkChecker(input: reachableUpdated)
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: shortcutPermissionService,
                                             operation: .moveThisNode)
                UserPermissionServiceChecker(service: parentPermissionService,
                                             operation: .moveSubNode)
                .custom(reason: BundleI18n.SKResource.LarkCCM_Workspace_Menu_NoCurrentFolderPermToDelete_Tooltip)
            } else {
                UserPermissionRoleChecker(input: shortcutPermissionUpdated, roleType: .fullAccess)
                V2FolderPermissionChecker(input: parentPermissionUpdated, permissionType: .moveFrom)
                    .custom(reason: BundleI18n.SKResource.LarkCCM_Workspace_Menu_NoCurrentFolderPermToDelete_Tooltip)
            }
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .delete, reason: reason, entry: self.entry)
                return
            }
            self.handler?.delete(entry: self.entry)
        }
    }

    var moveShortcut: SpaceMoreItem {
        let isSupport: Bool = config.listType.isMySpace || config.listType.isSubFolder
        return SpaceMoreItem(type: .moveTo,
                      hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: isSupport)
        },
                      enableCheckers: {
            NetworkChecker(input: reachableUpdated)
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: shortcutPermissionService,
                                             operation: .moveThisNode)
                .custom(reason: BundleI18n.SKResource.LarkCCM_Workspace_Menu_NoCurrentFolderPermToMove_Tooltip)
                UserPermissionServiceChecker(service: parentPermissionService,
                                             operation: .moveSubNode)
                .custom(reason: BundleI18n.SKResource.LarkCCM_Workspace_Menu_NoCurrentFolderPermToMove_Tooltip)
            } else {
                UserPermissionRoleChecker(input: shortcutPermissionUpdated, roleType: .fullAccess)
                    .custom(reason: BundleI18n.SKResource.LarkCCM_Workspace_Menu_NoCurrentFolderPermToMove_Tooltip)
                V2FolderPermissionChecker(input: parentPermissionUpdated, permissionType: .moveFrom)
                    .custom(reason: BundleI18n.SKResource.LarkCCM_Workspace_Menu_NoCurrentFolderPermToMove_Tooltip)
            }
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .moveTo, reason: reason, entry: self.entry)
                return
            }
            self.handler?.moveTo(for: self.entry)
        }
    }

    var renameShortcut: SpaceMoreItem {
        SpaceMoreItem(type: .rename,
                      hiddenCheckers: {},
                      enableCheckers: {
            NetworkChecker(input: reachableUpdated)
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: shortcutPermissionService,
                                             operation: .edit)
                .custom(reason: BundleI18n.SKResource.LarkCCM_Workspace_Menu_NoCurrentFolderPermToRename_Tooltip)
            } else {
                UserPermissionTypeChecker(input: shortcutPermissionUpdated, permissionType: .edit)
                    .custom(reason: BundleI18n.SKResource.LarkCCM_Workspace_Menu_NoCurrentFolderPermToRename_Tooltip)
            }
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .rename, reason: reason, entry: self.entry)
                return
            }
            self.handler?.rename(entry: self.entry)
        }
    }
}
