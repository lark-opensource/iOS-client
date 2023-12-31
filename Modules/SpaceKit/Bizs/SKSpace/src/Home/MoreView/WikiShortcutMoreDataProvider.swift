//
//  WikiShortcutMoreDataProvider.swift
//  SKSpace
//
//  Created by majie.7 on 2022/9/20.
//

import Foundation
import SKCommon
import RxSwift
import RxCocoa
import SKResource
import SwiftyJSON
import UIKit
import SKFoundation
import SpaceInterface
import SKInfra

class WikiShortcutMoreDataProvider: SpaceMoreDataProvider {
    var builder: MoreItemsBuilder { spaceMoreBuilder.moreBuilder }
    private lazy var spaceMoreBuilder = setupBuilder()
    var updater: MoreDataSourceUpdater?
    var outsideControlItems: MoreDataOutsideControlItems?

    // shortcut 权限
    private let shortcutPermissionRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    private let shortcutPermissionService: UserPermissionService
    // 本体权限
    private let entryPermissionRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    private let entryPermissionService: UserPermissionService
    // 父文件夹权限
    private let parentFolderPermissionRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    private let parentPermissionService: UserPermissionService

    private let entry: SpaceEntry
    private let disposeBag = DisposeBag()

    private let shortcutProvider: ShortcutCommonMoreProvider

    weak var handler: SpaceMoreActionHandler? {
        didSet {
            shortcutProvider.handler = handler
        }
    }

    init(entry: SpaceEntry,
         wikiToken: String,
         sourceView: UIView,
         forbiddenItems: [MoreItemType],
         listType: SpaceMoreAPI.ListType) {
        self.entry = entry

        let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
        shortcutPermissionService = permissionSDK.userPermissionService(for: .document(token: entry.nodeToken,
                                                                                       type: .spaceShortcut))
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
            legacySetupPermission()
        }
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func legacySetupPermission() {
        // 本体权限，用 objToken, objToken非本体的wikiToken，不做替换是因为两者权限点位相同
        SpaceMoreAPI.fetchUserPermission(item: SpaceItem(objToken: entry.objToken, objType: entry.type))
            .subscribe(onSuccess: { [weak self] permission in
                self?.entryPermissionRelay.accept(permission)
                self?.reload()
            })
            .disposed(by: disposeBag)

        // shortcut权限
        SpaceMoreAPI.fetchUserPermission(item: SpaceItem(objToken: entry.nodeToken, objType: .spaceShortcut))
            .subscribe(onSuccess: {[weak self] permission in
                self?.shortcutPermissionRelay.accept(permission)
                self?.reload()
            })
            .disposed(by: disposeBag)

        // 检查所在父文件夹权限
        if let parentToken = entry.parent, !parentToken.isEmpty {
            SpaceMoreAPI.fetchV2FolderUserPermission(folderToken: parentToken)
                .subscribe(onSuccess: {[weak self] permission in
                    self?.parentFolderPermissionRelay.accept(permission)
                    self?.reload()
                })
                .disposed(by: disposeBag)
        } else {
            // 我的空间根目录默认有所有权限
            parentFolderPermissionRelay.accept(UserPermissionMask.mockPermisson())
        }
    }

    private func reload(force: Bool = false) {
        guard let updater = updater else {
            DocsLogger.info("refresh items failed because updator is nil")
            return
        }
        if force {
            spaceMoreBuilder = setupBuilder()
        }
        updater(builder)
    }
}

private extension WikiShortcutMoreDataProvider {
    func setupBuilder() -> SpaceMoreItemBuilder {
        var originMoreItems: [SpaceMoreItem] = [
            shortcutProvider.saveToLocal,
            shortcutProvider.openWithOtherApp,
            shortcutProvider.copyLink,
            shortcutProvider.copyFile,
            shortcutProvider.exportToLocal
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
