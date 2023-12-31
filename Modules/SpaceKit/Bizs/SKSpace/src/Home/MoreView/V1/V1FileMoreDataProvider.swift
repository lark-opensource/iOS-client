//
//  V1FileMoreDataProvider.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/11/1.
//

import Foundation
import SKCommon
import RxSwift
import RxRelay
import RxCocoa
import SKResource
import SKFoundation
import SwiftyJSON
import UIKit
import SKInfra
import SpaceInterface

class V1FileMoreDataProvider: SpaceMoreDataProvider {
    var updater: MoreDataSourceUpdater?
    var outsideControlItems: MoreDataOutsideControlItems?
    var builder: MoreItemsBuilder { spaceMoreBuilder.moreBuilder }
    private lazy var spaceMoreBuilder = setupBuilder()

    private let entry: SpaceEntry
    private let forbiddenItems: [MoreItemType]
    private let needShowItems: [MoreItemType]? //白名单
    private let reachabilityRelay = BehaviorRelay(value: true)
    private let listType: SpaceMoreAPI.ListType

    private let entryPermissionRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    private let entryPermissionService: UserPermissionService
    private let parentFolderEditPermissionRelay = BehaviorRelay(value: false)
    private let parentFolderPermissionService: UserPermissionService

    private let disposeBag = DisposeBag()

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
        self.forbiddenItems = forbiddenItems
        self.needShowItems = needShowItems
        self.listType = listType
        entryPermissionService = SpaceMoreAPI.userPermissionService(for: entry)
        parentFolderPermissionService = SpaceMoreAPI.parentFolderPermissionService(for: entry, listType: listType)

        let context = CommonMoreProviderContext(entry: entry, sourceView: sourceView)
        let config = CommonMoreProviderConfig(forbiddenItems: forbiddenItems,
                                              allowItems: needShowItems,
                                              listType: listType)
        // 1.0 的父节点权限判断逻辑和 2.0 差异太大，不在统一的 provider 里处理
        let permissionContext = CommonMoreProviderPermissionContext(permissionService: entryPermissionService,
                                                                    permissionRelay: entryPermissionRelay)
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
            entryPermissionService.onPermissionUpdated
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] _ in
                self?.reload()
            }).disposed(by: disposeBag)
            entryPermissionService.updateUserPermission().subscribe().disposed(by: disposeBag)
            parentFolderPermissionService.onPermissionUpdated
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] _ in
                self?.reload()
            }).disposed(by: disposeBag)
            parentFolderPermissionService.updateUserPermission().subscribe().disposed(by: disposeBag)
        } else {
            SpaceMoreAPI.fetchUserPermission(item: SpaceItem(objToken: entry.objToken, objType: entry.type))
                .subscribe(onSuccess: { [weak self] permission in
                    self?.entryPermissionRelay.accept(permission)
                    self?.reload()
                })
                .disposed(by: disposeBag)

            if let parent = entry.parent, !parent.isEmpty, case let .subFolder(type) = listType, case let .v1Share(spaceID) = type {
                SpaceMoreAPI.fetchV1FolderEditPermission(folderToken: parent, spaceID: spaceID)
                    .subscribe(onSuccess: { [weak self] haveEditPermission in
                        self?.parentFolderEditPermissionRelay.accept(haveEditPermission)
                        self?.reload()
                    })
                    .disposed(by: disposeBag)
            } else {
                // 在文件夹外创建副本，默认创建到我的空间
                // 我的空间默认有权限
                parentFolderEditPermissionRelay.accept(true)
            }
        }
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

private extension V1FileMoreDataProvider {
    func setupBuilder() -> SpaceMoreItemBuilder {
        SpaceMoreItemBuilder {
            SpaceMoreSection(type: .horizontal) {
                entryProvider.share
                moveTo
                entryProvider.addTo
                entryProvider.star
                entryProvider.pin
                entryProvider.manualOffline
                delete
            }
            SpaceMoreSection(type: .vertical) {
                entryProvider.importToOnlineDocument
                entryProvider.saveToLocal
                entryProvider.openWithOtherApp
                entryProvider.copyLink
                entryProvider.copyFile
                entryProvider.subscribe
                entryProvider.exportToLocal
                entryProvider.retention
            }
        }
    }

    // 以下操作涉及到父节点权限，1.0 父节点权限与 2.0 差异较大，单独处理下

    var moveTo: SpaceMoreItem {
        SpaceMoreItem(type: .moveTo,
                      hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: listType.isSubFolder)
            // 无所在共享文件夹的编辑权限，隐藏 moveTo 选项
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: parentFolderPermissionService,
                                             operation: .moveSubNode)
            } else {
                RxBizChecker(disableReason: "", input: parentFolderEditPermissionRelay.asObservable())
            }
            BizChecker(disableReason: "", staticChecker: needShowItems?.contains(.moveTo) ?? true)
        },
                      enableCheckers: {
            NetworkChecker(input: reachabilityRelay.asObservable())
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .moveTo, reason: reason, entry: self.entry)
                return
            }
            self.handler?.moveTo(for: self.entry)
        }
    }

    var delete: SpaceMoreItem {
        let type: MoreItemType
        if listType == .mySpaceV1 {
            type = .delete
        } else {
            type = .removeFromList
        }
        return SpaceMoreItem(type: type,
                             hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: !forbiddenItems.contains(.delete))
            BizChecker(disableReason: "", staticChecker: listType != .shareToMe) // 与我共享列表要隐藏
        },
                             enableCheckers: {
            // 离线列表跳过网络判断
            if listType != .offline {
                NetworkChecker(input: reachabilityRelay.asObservable())
            }
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: parentFolderPermissionService,
                                             operation: .moveSubNode)
            } else {
                RxBizChecker(disableReason: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission,
                             input: parentFolderEditPermissionRelay.asObservable())
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
