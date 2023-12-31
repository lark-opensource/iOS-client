//
//  FolderShortcutMoreDataProvider.swift
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
import SKInfra

class FolderShortcutMoreDataProvider: SpaceMoreDataProvider {
    var updater: MoreDataSourceUpdater?
    var outsideControlItems: MoreDataOutsideControlItems?
    var builder: MoreItemsBuilder { spaceMoreBuilder.moreBuilder }
    private lazy var spaceMoreBuilder = setupBuilder()

    private let entry: FolderEntry

    private let shortcutPermissionRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    private let shortcutPermissionService: UserPermissionService

    private let folderPermissionRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    private let folderPermissionService: UserPermissionService

    private let parentFolderPermissionRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    private let parentPermissionService: UserPermissionService

    private let folderDeletedRelay = BehaviorRelay(value: false)
    private let folderComplaintRelay = BehaviorRelay(value: false)
    private let disposeBag = DisposeBag()

    private let shortcutProvider: ShortcutCommonMoreProvider

    weak var handler: SpaceMoreActionHandler?

    init(folderEntry: FolderEntry,
         sourceView: UIView,
         forbiddenItems: [MoreItemType],
         listType: SpaceMoreAPI.ListType) {
        self.entry = folderEntry

        let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
        shortcutPermissionService = permissionSDK.userPermissionService(for: .document(token: entry.nodeToken, type: .spaceShortcut))
        if let tenantID = entry.ownerTenantID {
            shortcutPermissionService.update(tenantID: tenantID)
        }
        folderPermissionService = permissionSDK.userPermissionService(for: entry.userPermissionEntity)
        parentPermissionService = permissionSDK.userPermissionService(for: .folder(token: entry.parent ?? ""))

        let context = CommonMoreProviderContext(entry: entry, sourceView: sourceView)
        let config = CommonMoreProviderConfig(forbiddenItems: forbiddenItems,
                                              allowItems: nil,
                                              listType: listType)
        let permissionContext = CommonMoreProviderPermissionContext(permissionService: folderPermissionService,
                                                                    permissionRelay: folderPermissionRelay,
                                                                    parentPermissionService: parentPermissionService,
                                                                    parentPermissionUpdated: parentFolderPermissionRelay.asObservable())
        let shortcutPermissionContext = ShortcutMorePermissionContext(shortcutPermissionService: shortcutPermissionService,
                                                                      shortcutPermissionUpdated: shortcutPermissionRelay.asObservable(),
                                                                      entryContext: permissionContext)
        let entryProvider = EntryCommonMoreProvider(context: context,
                                                    config: config,
                                                    permissionContext: permissionContext)
        shortcutProvider = ShortcutCommonMoreProvider(context: context, config: config, permissionContext: shortcutPermissionContext, entryProvider: entryProvider)
        shortcutProvider.reloadHandler = { [weak self] force in
            self?.reload(force: force)
        }
        setup()
    }

    private func setup() {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
            [folderPermissionService, shortcutPermissionService, parentPermissionService].forEach { service in
                service.onPermissionUpdated
                    .observeOn(MainScheduler.asyncInstance)
                    .subscribe(onNext: { [weak self] _ in
                    self?.reload()
                })
                .disposed(by: disposeBag)
                service.updateUserPermission().subscribe().disposed(by: disposeBag)
            }
        } else {
            // shortcut 权限
            SpaceMoreAPI.fetchUserPermission(item: SpaceItem(objToken: entry.nodeToken, objType: .spaceShortcut))
                .subscribe(onSuccess: { [weak self] permission in
                    self?.shortcutPermissionRelay.accept(permission)
                    self?.reload()
                })
                .disposed(by: disposeBag)

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

        // 检查本体文件夹状态（删除、封禁）
        SpaceMoreAPI.fetchFolderStatus(folderToken: entry.objToken, isV2Folder: true)
            .subscribe(onSuccess: { [weak self] (deleted, complaint) in
                self?.folderDeletedRelay.accept(deleted)
                self?.folderComplaintRelay.accept(complaint)
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

private extension FolderShortcutMoreDataProvider {
    func setupBuilder() -> SpaceMoreItemBuilder {
        SpaceMoreItemBuilder {
            SpaceMoreSection(type: .horizontal) {
                share
                pin
                star
                shortcutProvider.deleteShortcut
            }
            SpaceMoreSection(type: .vertical) {
                shortcutProvider.renameShortcut
                shortcutProvider.moveShortcut
                shortcutProvider.copyLink
            }
        }
    }

    var star: SpaceMoreItem {
        let item = shortcutProvider.star
        item.enableCheckers.append(FolderDeletedChecker(input: folderDeletedRelay.asObservable()))
        return item
    }

    var pin: SpaceMoreItem {
        let item = shortcutProvider.pin
        item.enableCheckers.append(FolderDeletedChecker(input: folderDeletedRelay.asObservable()))
        return item
    }

    var share: SpaceMoreItem {
        let item = shortcutProvider.share
        let extraCheckers: [EnableChecker] = [
            FolderDeletedChecker(input: folderDeletedRelay.asObservable()),
            FolderComplaintChecker(input: folderComplaintRelay.asObservable())
        ]
        item.enableCheckers.append(contentsOf: extraCheckers)
        return item
    }
}
