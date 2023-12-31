//
//  WikiMoreDataProvider.swift
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
import UIKit
import SpaceInterface
import SKWorkspace

class WikiMoreDataProvider: SpaceMoreDataProvider {
    var updater: MoreDataSourceUpdater?
    var outsideControlItems: MoreDataOutsideControlItems?
    var builder: MoreItemsBuilder { spaceMoreBuilder.moreBuilder }
    private lazy var spaceMoreBuilder = setupBuilder()

    private let entry: WikiEntry
    private var permission: WikiTreeNodePermission?
    // 本体权限
    private let entryPermissionRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    private let entryPermissionService: UserPermissionService

    private let disposeBag = DisposeBag()

    private let entryProvider: EntryCommonMoreProvider

    weak var handler: SpaceMoreActionHandler? {
        didSet {
            entryProvider.handler = handler
        }
    }

    init(entry: WikiEntry,
         sourceView: UIView,
         forbiddenItems: [MoreItemType],
         listType: SpaceMoreAPI.ListType) {
        self.entry = entry

        entryPermissionService = SpaceMoreAPI.userPermissionService(for: entry)
        let config = CommonMoreProviderConfig(forbiddenItems: forbiddenItems,
                                              allowItems: nil,
                                              listType: listType)
        let permissionContext = CommonMoreProviderPermissionContext(permissionService: entryPermissionService,
                                                                    permissionRelay: entryPermissionRelay)
        entryProvider = EntryCommonMoreProvider(context: CommonMoreProviderContext(entry: entry,
                                                                                   sourceView: sourceView),
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
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] _ in
                self?.reload()
            })
            .disposed(by: disposeBag)
            entryPermissionService.updateUserPermission().subscribe().disposed(by: disposeBag)
        } else {
            // 本体权限，用 objToken
            SpaceMoreAPI.fetchUserPermission(item: SpaceItem(objToken: entry.objToken, objType: entry.type))
                .subscribe(onSuccess: { [weak self] permission in
                    self?.entryPermissionRelay.accept(permission)
                    self?.reload()
                })
                .disposed(by: disposeBag)
        }

        guard let wikiInfo = entry.wikiInfo else {
            DocsLogger.error("No wiki info for wiki more")
            return
        }
        WikiNetworkManager.shared.getNodePermission(spaceId: wikiInfo.spaceId, wikiToken: wikiInfo.wikiToken)
            .subscribe(onSuccess: { [weak self] permission in
                self?.permission = permission
                self?.reload(force: true)
            })
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

private extension WikiMoreDataProvider {
    func setupBuilder() -> SpaceMoreItemBuilder {
        SpaceMoreItemBuilder {
            SpaceMoreSection(type: .horizontal) {
                entryProvider.share
                moveTo
                entryProvider.createShortcut
                entryProvider.pin
                entryProvider.star
                entryProvider.manualOffline
            }
            SpaceMoreSection(type: .vertical) {
                entryProvider.sensitivtyLabel
                entryProvider.copyLink
                entryProvider.copyFile
                subscribe
            }
            SpaceMoreSection(type: .vertical) {
                entryProvider.delete
            }
        }
    }

    var moveTo: SpaceMoreItem {
        let item = entryProvider.moveTo
        item.enableCheckers.append(contentsOf: [
            BizChecker(disableReason: BundleI18n.SKResource.LarkCCM_CM_MoveDoc_Error_Toast,
                       staticChecker: entry.contentExistInWiki),
            BizChecker(disableReason: BundleI18n.SKResource.Doc_List_MakeMoveForbidden(BundleI18n.SKResource.Doc_Facade_Document),
                       staticChecker: permission?.showMove == true)
        ])
        item.handler = { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .moveTo, reason: reason, entry: self.entry)
                return
            }
            guard let permission = self.permission else { return }
            self.handler?.moveTo(for: self.entry, nodePermission: permission)
        }
        return item
    }


    var subscribe: SpaceMoreItem {
        // 增加一个额外隐藏条件
        let item = entryProvider.subscribe
        // 若内容已不在 wiki 中，需要隐藏
        item.hiddenCheckers.append(BizChecker(disableReason: "", staticChecker: entry.contentExistInWiki))
        return item
    }
}
