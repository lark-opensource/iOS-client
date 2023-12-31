//
//  FileShortcutMoreDataProvider.swift
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

class FileShortcutMoreDataProvider: SpaceMoreDataProvider {
    var updater: MoreDataSourceUpdater?
    var outsideControlItems: MoreDataOutsideControlItems?
    var builder: MoreItemsBuilder { spaceMoreBuilder.moreBuilder }
    private lazy var spaceMoreBuilder = setupBuilder()

    private let entry: SpaceEntry

    // shortcut 权限
    private let shortcutPermissionRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    private let shortcutPermissionService: UserPermissionService
    // 本体权限
    private let entryPermissionRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    private let entryPermissionService: UserPermissionService
    // 父文件夹权限
    private let parentFolderPermissionRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    private let parentPermissionService: UserPermissionService

    private let disposeBag = DisposeBag()

    private let shortcutProvider: ShortcutCommonMoreProvider

    weak var handler: SpaceMoreActionHandler? {
        didSet {
            shortcutProvider.handler = handler
        }
    }

    init(entry: SpaceEntry,
         sourceView: UIView,
         forbiddenItems: [MoreItemType],
         listType: SpaceMoreAPI.ListType) {
        self.entry = entry
        let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
        shortcutPermissionService = permissionSDK.userPermissionService(for: .document(token: entry.nodeToken, type: .spaceShortcut))
        if let tenantID = entry.ownerTenantID {
            shortcutPermissionService.update(tenantID: tenantID)
        }
        entryPermissionService = permissionSDK.userPermissionService(for: entry.userPermissionEntity)
        parentPermissionService = permissionSDK.userPermissionService(for: .folder(token: entry.parent ?? ""))

        let context = CommonMoreProviderContext(entry: entry, sourceView: sourceView)
        let config = CommonMoreProviderConfig(forbiddenItems: forbiddenItems,
                                              allowItems: nil,
                                              listType: listType)
        let permissionContext = CommonMoreProviderPermissionContext(permissionService: entryPermissionService,
                                                                    permissionRelay: entryPermissionRelay,
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
            [entryPermissionService, shortcutPermissionService, parentPermissionService].forEach { service in
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
            SpaceMoreAPI.fetchUserPermission(item: SpaceItem(objToken: entry.objToken, objType: entry.type))
                .subscribe(onSuccess: { [weak self] permission in
                    self?.entryPermissionRelay.accept(permission)
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
                // 我的空间根目录默认有所有权限
                parentFolderPermissionRelay.accept(UserPermissionMask.mockPermisson())
            }
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

private extension FileShortcutMoreDataProvider {
    func setupBuilder() -> SpaceMoreItemBuilder {
        var originMoreItems: [SpaceMoreItem] = [
            shortcutProvider.importToOnlineDocument,
            shortcutProvider.saveToLocal,
            shortcutProvider.openWithOtherApp,
            shortcutProvider.copyLink,
            shortcutProvider.copyFile,
            shortcutProvider.exportToLocal,
            shortcutProvider.retention
        ]
        if entry.originDeleted {
            originMoreItems = [shortcutProvider.originEntityDeleted]
        }
        return SpaceMoreItemBuilder {
            SpaceMoreSection(type: .horizontal) {
                shortcutProvider.share
                shortcutProvider.createShortcut
                shortcutProvider.pin
                shortcutProvider.star
                shortcutProvider.deleteShortcut
            }
            SpaceMoreSection(type: .verticalSection(.origin)) {
                originMoreItems
            }
            SpaceMoreSection(type: .verticalSection(.shortcut)) {
                shortcutProvider.moveShortcut
                shortcutProvider.renameShortcut
            }
        }
    }
}
