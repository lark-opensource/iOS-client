//
//  FolderMoreDataProvider.swift
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
import SKInfra
import SpaceInterface

class FolderMoreDataProvider: SpaceMoreDataProvider {
    var updater: MoreDataSourceUpdater?
    var outsideControlItems: MoreDataOutsideControlItems?
    var builder: MoreItemsBuilder { spaceMoreBuilder.moreBuilder }
    private lazy var spaceMoreBuilder = setupBuilder()

    private let entry: FolderEntry
    private let forbiddenItems: [MoreItemType]

    private let reachabilityRelay = BehaviorRelay(value: true)

    private let folderPermissionRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    private let folderPermissionService: UserPermissionService
    private let parentFolderPermissionRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    private let parentFolderPermissionService: UserPermissionService

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
        self.forbiddenItems = forbiddenItems
        self.listType = listType
        folderPermissionService = SpaceMoreAPI.userPermissionService(for: folderEntry)
        parentFolderPermissionService = SpaceMoreAPI.parentFolderPermissionService(for: folderEntry, listType: listType)

        let context = CommonMoreProviderContext(entry: entry, sourceView: sourceView)
        let config = CommonMoreProviderConfig(forbiddenItems: forbiddenItems,
                                              allowItems: nil,
                                              listType: listType)
        let permissionContext = CommonMoreProviderPermissionContext(permissionService: folderPermissionService,
                                                                    permissionRelay: folderPermissionRelay,
                                                                    parentPermissionService: parentFolderPermissionService,
                                                                    parentPermissionUpdated: parentFolderPermissionRelay.asObservable())
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

        if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
            folderPermissionService.onPermissionUpdated
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] _ in
                self?.reload()
            })
            .disposed(by: disposeBag)
            folderPermissionService.updateUserPermission().subscribe().disposed(by: disposeBag)

            parentFolderPermissionService.onPermissionUpdated
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] _ in
                self?.reload()
            })
            .disposed(by: disposeBag)
            parentFolderPermissionService.updateUserPermission().subscribe().disposed(by: disposeBag)
        } else {
            legacySetupPermission()
        }


        // 检查本体文件夹状态（删除、封禁）
        SpaceMoreAPI.fetchFolderStatus(folderToken: entry.objToken, isV2Folder: true)
            .subscribe(onSuccess: { [weak self] (_, complaint) in
                self?.folderComplaintRelay.accept(complaint)
                self?.reload()
            })
            .disposed(by: disposeBag)
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func legacySetupPermission() {
        // 本体权限，用 objToken
        SpaceMoreAPI.fetchV2FolderUserPermission(folderToken: entry.objToken)
            .subscribe(onSuccess: { [weak self] permission in
                self?.folderPermissionRelay.accept(permission)
                self?.reload()
            })
            .disposed(by: disposeBag)

        // 检查所在父文件夹权限
        if let parentToken = entry.parent, !parentToken.isEmpty {
            SpaceMoreAPI.fetchV2FolderUserPermission(folderToken: parentToken)
                .subscribe(onSuccess: { [weak self] permission in
                    self?.parentFolderPermissionRelay.accept(permission)
                    self?.reload()
                })
                .disposed(by: disposeBag)
        } else {
            parentFolderPermissionRelay.accept(UserPermissionMask.mockPermisson())
        }
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

private extension FolderMoreDataProvider {
    func setupBuilder() -> SpaceMoreItemBuilder {
        SpaceMoreItemBuilder {
            SpaceMoreSection(type: .horizontal) {
                share
                entryProvider.moveTo
                if UserScopeNoChangeFG.MJ.quickAccessFolderEnable {
                    quickAccess
                } else {
                    pin
                }
                entryProvider.star
                hidden
            }
            SpaceMoreSection(type: .vertical) {
                entryProvider.rename
                entryProvider.copyLink
            }
            SpaceMoreSection(type: .vertical) {
                entryProvider.delete
            }
        }
    }

    var pin: SpaceMoreItem {
        let item = entryProvider.pin
        item.hiddenCheckers.append(BizChecker(disableReason: "", staticChecker: !UserScopeNoChangeFG.WWJ.newSpaceTabEnable))
        return item
    }
}

// MARK: - 受 forbiddenItems 参数影响的 items
private extension FolderMoreDataProvider {
    var share: SpaceMoreItem {
        let item = entryProvider.share
        item.enableCheckers.append(FolderComplaintChecker(input: folderComplaintRelay.asObservable()))
        return item
    }
    
    var hidden: SpaceMoreItem {
        let isHidden = entry.isHiddenStatus ?? false
        let type: MoreItemType = isHidden ? .setDisplay : .setHidden
        return SpaceMoreItem(type: type,
                             hiddenCheckers: {
            //仅在2.0共享文件夹列表内允许展示
            BizChecker(disableReason: "", staticChecker: SettingConfig.singleContainerEnable && LKFeatureGating.newShareSpace)
            BizChecker(disableReason: "", staticChecker: listType == .shareFolder)
            BizChecker(disableReason: "", staticChecker: !forbiddenItems.contains(.setHidden))
        }, enableCheckers: {
            NetworkChecker(input: reachabilityRelay.asObservable())
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: type, reason: reason, entry: self.entry)
                return
            }
            self.handler?.toggleHiddenStatusV2(for: self.entry)
        }
    }
    
    var quickAccess: SpaceMoreItem {
        let type: MoreItemType = entry.pined ? .unQuickAccessFolder : .quickAccessFolder
        return SpaceMoreItem(type: type,
                             hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: !forbiddenItems.contains(type))
            BizChecker(disableReason: "", staticChecker: UserScopeNoChangeFG.MJ.quickAccessFolderEnable)
        },
                             enableCheckers: {
            NetworkChecker(input: reachabilityRelay.asObservable())
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: type, reason: reason, entry: self.entry)
                return
            }
            self.handler?.toggleQuickAccess(for: self.entry)
        }
    }
}
