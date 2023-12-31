//
//  QuickAccessDataModel.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/8/16.
//

import Foundation
import RxSwift
import RxRelay
import SKCommon
import SKFoundation

extension QuickAccessDataModel {
    static let quickAccessNeedUpdate = Notification.Name.Docs.quickAccessUpdate
    private static let dataModelIdentifier = "QuickAccess"
    static let listToken = "quickAccessAllList"
    
    public enum QuickAccessApiType {
        case v1
        case v2
        case justFolder
    }
}

public final class QuickAccessDataModel {
    private let disposeBag = DisposeBag()
    let listContainer: SpaceListContainer
    let interactionHelper: SpaceInteractionHelper
    let currentUserID: String
    private let dataManager: SKDataManager
    private var hasBeenSetup = false
    let api: QuickAccessListAPI.Type

    private let workQueue = DispatchQueue(label: "space.quickaccess.dm.queue")

    var itemChanged: Observable<[SpaceEntry]> {
        listContainer.itemsChanged
    }

    public init(userID: String, apiType: QuickAccessApiType) {
        currentUserID = userID
        dataManager = SKDataManager.shared
        interactionHelper = SpaceInteractionHelper(dataManager: dataManager)
        listContainer = SpaceListContainer(listIdentifier: Self.dataModelIdentifier)
        switch apiType {
        case .v1:
            api = V1QuickAccessListAPI.self
        case .v2:
            api = V2QuickAccessListAPI.self
        case .justFolder:
            api = QuickAccessFolderListAPI.self
        }
    }
    
    // nolint: duplicated_code
    func setup() {
        guard !hasBeenSetup else {
            DocsLogger.error("space.quickaccess.dm --- skipping re-setup data model")
            spaceAssertionFailure("re-setup list DM")
            return
        }
        hasBeenSetup = true
        dataManager.addObserver(self)
        // 先发 Action 再调用 loadData，保证 addObserver 后一定能收到一次本地数据回调
        dataManager.loadFolderFileEntries(folderKey: api.folderKey, limit: .max)
        dataManager.loadData(currentUserID) { success in
            if !success {
                spaceAssertionFailure("Load DB 竟然失败了 cc @guoqingping")
            }
        }

        NotificationCenter.default.rx.notification(Self.quickAccessNeedUpdate)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.refresh().subscribe().disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }

    func refresh() -> Completable {
        return api.queryList(extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
            .do(onSuccess: { [weak self] dataDiff in
                guard let self = self else { return }
                let totalCount = dataDiff.pinObjs.count
                self.listContainer.update(pagingState: .noMore)
                self.listContainer.update(totalCount: totalCount)
                self.dataManager.resetPins(data: dataDiff, folderKey: api.folderKey)
            }, onError: { error in
                DocsLogger.error("space.quickaccess.dm --- refresh failed", error: error)
            })
            .asCompletable()
    }
}

private extension SKOperational {
    var isLocalDataForQuickAccessList: Bool {
        switch self {
        case .loadNewDBData:
            return true
        case let .loadSpecialFolder(folderKey):
            return folderKey == .pins || folderKey == .pinFolderList
        default:
            return false
        }
    }

    var isServerDataForQuickAccessList: Bool {
        switch self {
        case .resetPins:
            return true
        default:
            return false
        }
    }
}

extension QuickAccessDataModel: SKListServiceProtocol {
    public func dataChange(data: SKListData, operational: SKOperational) {
        DocsLogger.debug("space.quickaccess.dm.debug --- data changed, operation: \(operational.descriptionInLog), dataCount: \(data.files.count)")
        if operational.isLocalDataForQuickAccessList {
            self.listContainer.restore(localData: data.files)
        } else if operational.isServerDataForQuickAccessList {
            self.listContainer.sync(serverData: data.files)
        } else {
            self.listContainer.update(data: data.files)
        }
    }

    public var type: SKObserverDataType {
        .specialList(folderKey: api.folderKey)
    }

    public var token: String {
        Self.listToken
    }
}
