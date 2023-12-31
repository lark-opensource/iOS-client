//
//  V1FolderMoreDataProvider.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/11/1.
//

import Foundation
import SKCommon
import RxSwift
import RxCocoa
import SKResource
import SKFoundation
import SwiftyJSON
import UIKit
import SpaceInterface

class V1FolderMoreDataProvider: SpaceMoreDataProvider {
    var updater: MoreDataSourceUpdater?
    var outsideControlItems: MoreDataOutsideControlItems?
    var builder: MoreItemsBuilder { spaceMoreBuilder.moreBuilder }
    private lazy var spaceMoreBuilder = setupBuilder()

    private let entry: FolderEntry
    private let sourceView: UIView
    private let forbiddenItems: [MoreItemType]

    private let reachabilityRelay = BehaviorRelay(value: true)
    // 对正在操作的文件夹是否有编辑权限
    private let editPermissionRelay = BehaviorRelay(value: false)
    private let permissionService: UserPermissionService

    private let folderDeletedRelay = BehaviorRelay(value: false)
    private let folderComplaintRelay = BehaviorRelay(value: false)
    private let disposeBag = DisposeBag()
    private let listType: SpaceMoreAPI.ListType

    private let entryProvider: EntryCommonMoreProvider

    weak var handler: SpaceMoreActionHandler? {
        didSet {
            entryProvider.handler = handler
        }
    }

    init(folderEntry: FolderEntry,
         sourceView: UIView,
         forbiddenItems: [MoreItemType],
         listType: SpaceMoreAPI.ListType) {
        self.entry = folderEntry
        self.sourceView = sourceView
        self.forbiddenItems = forbiddenItems
        self.listType = listType
        self.permissionService = SpaceMoreAPI.userPermissionService(for: folderEntry)
        let context = CommonMoreProviderContext(entry: entry, sourceView: sourceView)
        let config = CommonMoreProviderConfig(forbiddenItems: forbiddenItems,
                                              allowItems: nil,
                                              listType: listType)
        // 1.0 文件夹的权限模型差异太大，这里自行处理
        let permissionContext = CommonMoreProviderPermissionContext(permissionService: permissionService,
                                                                    permissionRelay: BehaviorRelay(value: nil))
        entryProvider = EntryCommonMoreProvider(context: context,
                                                config: config,
                                                permissionContext: permissionContext)
        entryProvider.reloadHandler = { [weak self] force in
            self?.reload(force: force)
        }
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

        // 检查本体文件夹状态（删除、封禁）
        SpaceMoreAPI.fetchFolderStatus(folderToken: entry.objToken, isV2Folder: false)
            .subscribe(onSuccess: { [weak self] (deleted, complaint) in
                self?.folderDeletedRelay.accept(deleted)
                self?.folderComplaintRelay.accept(complaint)
                self?.reload()
            })
            .disposed(by: disposeBag)

        if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
            permissionService.onPermissionUpdated
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] _ in
                self?.reload()
            }).disposed(by: disposeBag)
            permissionService.updateUserPermission().subscribe().disposed(by: disposeBag)
        } else {
            setupEditPermission()
        }
    }
    // 检查被操作的文件夹权限
    private func setupEditPermission() {
        guard entry.isShareFolder else {
            editPermissionRelay.accept(true)
            return
        }
        if entry.ownerIsCurrentUser {
            editPermissionRelay.accept(true)
            return
        }
        guard let spaceID = entry.shareFolderInfo?.spaceID else {
            spaceAssertionFailure()
            return
        }
        SpaceMoreAPI.fetchV1FolderEditPermission(folderToken: entry.objToken, spaceID: spaceID)
            .subscribe(onSuccess: { [weak self] haveEditPermission in
                self?.editPermissionRelay.accept(haveEditPermission)
                self?.reload()
            })
            .disposed(by: disposeBag)
    }

    private func reload(force: Bool = false) {
        guard let updater = updater else {
            DocsLogger.info("refresh items failed because updater is nil")
            return
        }
        if force {
            spaceMoreBuilder = setupBuilder()
        }
        updater(builder)
    }
}

private extension V1FolderMoreDataProvider {
    func setupBuilder() -> SpaceMoreItemBuilder {
        SpaceMoreItemBuilder {
            SpaceMoreSection(type: .horizontal) {
                share
                moveTo
                entryProvider.star
                entryProvider.pin
                hidden
                delete
            }
            SpaceMoreSection(type: .vertical) {
                rename
                entryProvider.copyLink
            }
        }
    }

    var hidden: SpaceMoreItem {
        let isHidden = entry.isHiddenStatus ?? false
        let type: MoreItemType = isHidden ? .setDisplay : .setHidden
        return SpaceMoreItem(type: type,
                             hiddenCheckers: {
            // 仅在共享文件夹根目录内，且允许展示
            BizChecker(disableReason: "", staticChecker: listType == .shareFolder)
            BizChecker(disableReason: "", staticChecker: !forbiddenItems.contains(.setHidden))
        },
                             enableCheckers: {
            NetworkChecker(input: reachabilityRelay.asObservable())
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: type, reason: reason, entry: self.entry)
                return
            }
            self.handler?.toggleHiddenStatus(for: self.entry)
        }
    }

    var rename: SpaceMoreItem {
        SpaceMoreItem(type: .rename,
                      hiddenCheckers: {},
                      enableCheckers: {
            NetworkChecker(input: reachabilityRelay.asObservable())
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: permissionService,
                                             operation: .edit)
                .custom(reason: BundleI18n.SKResource.Doc_Facade_MoreRenameTips(entry.type.i18Name))
            } else {
                RxBizChecker(disableReason: BundleI18n.SKResource.Doc_Facade_MoreRenameTips(entry.type.i18Name),
                             input: editPermissionRelay.asObservable())
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

    var moveTo: SpaceMoreItem {
        let isSupport: Bool = listType.isMySpace || listType == .myFolder || listType.isSubFolder
        return SpaceMoreItem(type: .moveTo,
                             hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: isSupport)
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: permissionService,
                                             operation: .moveThisNode)
            } else {
                RxBizChecker(disableReason: "", input: editPermissionRelay.asObservable())
            }
            if entry.isShareRoot {
                BizChecker(disableReason: "", staticChecker: entry.ownerIsCurrentUser)
            }
        },
                             enableCheckers: {
            NetworkChecker(input: reachabilityRelay.asObservable())
            FolderComplaintChecker(input: folderComplaintRelay.asObservable())
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .moveTo, reason: reason, entry: self.entry)
                return
            }
            self.handler?.moveTo(for: self.entry)
        }
    }
}

// MARK: - 受 forbiddenItems 参数影响的 items
private extension V1FolderMoreDataProvider {
    var share: SpaceMoreItem {
        let item = entryProvider.share
        item.enableCheckers.append(FolderComplaintChecker(input: folderComplaintRelay.asObservable()))
        return item
    }

    var delete: SpaceMoreItem {
        // type 用 removeFromList 是因为文案不是删除，而是移除
        SpaceMoreItem(type: .removeFromList,
                      hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: !forbiddenItems.contains(.delete))
            if listType == .shareFolder {
                BizChecker(disableReason: "", staticChecker: entry.ownerIsCurrentUser)
            } else if listType == .shareToMe {
                // 与我共享列表要隐藏
                BizChecker(disableReason: "", staticChecker: false)
            }
        },
                      enableCheckers: {
            NetworkChecker(input: reachabilityRelay.asObservable())
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: permissionService,
                                             operation: .edit)
            } else {
                RxBizChecker(disableReason: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission, input: editPermissionRelay.asObservable())
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
}
