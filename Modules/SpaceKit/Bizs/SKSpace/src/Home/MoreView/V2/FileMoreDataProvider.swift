//
//  FileMoreDataProvider.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/11/1.
//
// swiftlint:disable file_length

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

class FileMoreDataProvider: SpaceMoreDataProvider {
    var updater: MoreDataSourceUpdater?
    var outsideControlItems: MoreDataOutsideControlItems?
    var builder: MoreItemsBuilder { spaceMoreBuilder.moreBuilder }
    private lazy var spaceMoreBuilder = setupBuilder()

    private let entry: SpaceEntry
    // 本体权限
    private let entryPermissionRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    private let entryPermissionService: UserPermissionService
    // 父文件夹权限
    private let parentFolderPermissionRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    private let parentFolderPermissionService: UserPermissionService

    private let disposeBag = DisposeBag()
    // 原则上所有普通实体文档的 provider 逻辑都可以下沉到这里
    private let entryProvider: EntryCommonMoreProvider

    weak var handler: SpaceMoreActionHandler? {
        didSet {
            entryProvider.handler = handler
        }
    }

    init(entry: SpaceEntry,
         sourceView: UIView,
         forbiddenItems: [MoreItemType],
         needShowItems: [MoreItemType]? = nil,
         listType: SpaceMoreAPI.ListType) {
        self.entry = entry
        entryPermissionService = SpaceMoreAPI.userPermissionService(for: entry)
        parentFolderPermissionService = SpaceMoreAPI.parentFolderPermissionService(for: entry, listType: listType)

        let context = CommonMoreProviderContext(entry: entry, sourceView: sourceView)
        let config = CommonMoreProviderConfig(forbiddenItems: forbiddenItems,
                                              allowItems: needShowItems,
                                              listType: listType)
        let permissionContext = CommonMoreProviderPermissionContext(permissionService: entryPermissionService,
                                                                    permissionRelay: entryPermissionRelay,
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
        if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
            entryPermissionService.onPermissionUpdated
                .observeOn(MainScheduler.asyncInstance) // 用 asyncInstance 是为了让 item 先刷新再 reload
                .subscribe(onNext: { [weak self] _ in
                self?.reload()
            })
            .disposed(by: disposeBag)
            entryPermissionService.updateUserPermission().subscribe().disposed(by: disposeBag)

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
        // 获取 nodeToken，用于移动操作
        fetchContainerInfo()
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func legacySetupPermission() {
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

    private func fetchContainerInfo() {
        guard entry.nodeToken.isEmpty else { return }
        WorkspaceCrossNetworkAPI.getContainerInfo(objToken: entry.objToken, objType: entry.docsType)
            .subscribe { [weak self] containerInfo, logID in
                guard let self = self else { return }
                guard let nodeToken = containerInfo?.nodeToken else {
                    DocsLogger.error("fetch containerInfo nodeToken is nil", extraInfo: ["log-id": logID as Any])
                    return
                }
                self.entry.update(nodeToken: nodeToken)
                self.reload()
            } onError: { error in
                DocsLogger.error("fetch containerInfo failed with error", error: error)
            }
            .disposed(by: disposeBag)
    }

    // Force 表示需要重新生成 SpaceMoreItems 对象，以刷新 style、type 等属性
    // 目前仅在更新订阅状态后才需要使用
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

private extension FileMoreDataProvider {
    func setupBuilder() -> SpaceMoreItemBuilder {
        SpaceMoreItemBuilder {
            SpaceMoreSection(type: .horizontal) {
                entryProvider.share
                entryProvider.moveTo
                entryProvider.createShortcut
                entryProvider.pin
                entryProvider.star
                entryProvider.manualOffline
            }
            SpaceMoreSection(type: .vertical) {
                entryProvider.sensitivtyLabel
                entryProvider.importToOnlineDocument
                entryProvider.saveToLocal
                entryProvider.openWithOtherApp
                entryProvider.copyLink
                entryProvider.copyFile
                entryProvider.subscribe
                entryProvider.exportToLocal
                entryProvider.retention
            }
            
            SpaceMoreSection(type: .vertical) {
                entryProvider.delete
            }
        }
    }
}
