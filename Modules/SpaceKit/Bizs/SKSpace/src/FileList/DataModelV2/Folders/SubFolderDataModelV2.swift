//
//  SubFolderDataModelV2.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/10/27.
//

import Foundation
import RxSwift
import RxRelay
import SKCommon
import SKFoundation
import SKInfra
import SpaceInterface

protocol FolderPermissionProvider {
    func update(tenantID: String)
    func checkCanCreate(folderToken: String) -> Single<Bool>
}

class V2FolderPermissionService: FolderPermissionProvider {

    private let permissionService: UserPermissionService

    convenience init(folderToken: String) {
        let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
        let permissionService = permissionSDK.userPermissionService(for: .folder(token: folderToken))
        self.init(permissionService: permissionService)
    }

    init(permissionService: UserPermissionService) {
        self.permissionService = permissionService
    }

    func update(tenantID: String) {
        permissionService.update(tenantID: tenantID)
    }

    func checkCanCreate(folderToken: String) -> Single<Bool> {
        permissionService.updateUserPermission().map { [weak self] response in
            guard let self else { return false }
            guard case .success = response else { return false }
            return self.permissionService.validate(operation: .createSubNode, bizDomain: .ccm).allow
        }
    }
}

extension SubFolderDataModelV2 {
    typealias SortOption = SpaceSortHelper.SortOption
    typealias CommonListError = RecentListDataModel.RecentDataError
    private static let subFolderListPageCount = 100
    static var subFolderNeedUpdate: Notification.Name { PersonalFileDataModel.personalFileNeedUpdate }
}

// 供 V1 文件夹使用，V2 请使用 SubFolderDataModelV2
class SubFolderDataModelV2 {
    private let disposeBag = DisposeBag()
    private(set) var sortHelper: SpaceSortHelper
    let listContainer: SpaceListContainer
    let interactionHelper: SpaceInteractionHelper
    private let permissionProvider: FolderPermissionProvider
    private let dataManager: SpaceFolderListDataProvider
    private let baseModel: SubFolderBaseModel
    private let networkAPI: FolderListAPI.Type
    private var hasBeenSetup = false
    private let workQueue = DispatchQueue(label: "space.sub-folder-v2.dm.queue")
    var itemChanged: Observable<[SpaceEntry]> {
        listContainer.itemsChanged
    }

    let folderToken: FileListDefine.ObjToken
    let folderType: FolderType
    let isShareFolder: Bool
    //文件夹内创建
    let createPermRelay = BehaviorRelay<Bool>(value: false)

    private(set) var folderEntry: FolderEntry?

    convenience init(folderToken: FileListDefine.ObjToken, isShareFolder: Bool) {
        let permissionProvider = V2FolderPermissionService(folderToken: folderToken)
        let dataManager = SKDataManager.shared
        self.init(folderToken: folderToken,
                  isShareFolder: isShareFolder,
                  dataManager: dataManager,
                  sortHelper: SpaceSortHelper.subFolder(token: folderToken),
                  interactionHelper: SpaceInteractionHelper(dataManager: dataManager),
                  listContainer: SpaceListContainer(listIdentifier: folderToken.encryptToken),
                  permissionProvider: permissionProvider,
                  networkAPI: V2FolderListAPI.self)
    }

    init(folderToken: FileListDefine.ObjToken,
         isShareFolder: Bool,
         dataManager: SpaceFolderListDataProvider,
         sortHelper: SpaceSortHelper,
         interactionHelper: SpaceInteractionHelper,
         listContainer: SpaceListContainer,
         permissionProvider: FolderPermissionProvider,
         networkAPI: FolderListAPI.Type) {
        self.folderToken = folderToken
        self.isShareFolder = isShareFolder
        folderType = isShareFolder ? .v2Shared : .v2Common
        self.dataManager = dataManager
        self.sortHelper = sortHelper
        self.interactionHelper = interactionHelper
        self.listContainer = listContainer
        self.permissionProvider = permissionProvider
        self.networkAPI = networkAPI
        baseModel = SubFolderBaseModel(networkAPI: networkAPI,
                                       folderToken: folderToken,
                                       pageCount: Self.subFolderListPageCount)

        // 初始化时，尝试从内存读取一次 folderEntry
        dataManager.spaceEntry(token: TokenStruct(token: folderToken)) { [weak self] entry in
            self?.folderEntry = entry as? FolderEntry
            self?.checkFolderPermission()
        }
    }

    func setup() {
        guard !hasBeenSetup else {
            DocsLogger.error("space.sub-folder-v2.dm --- skipping re-setup data model")
            spaceAssertionFailure("re-setup list DM")
            return
        }
        hasBeenSetup = true
        sortHelper.restore()
        dataManager.addObserver(self)
        dataManager.loadSubFolderEntries(nodeToken: folderToken)

        NotificationCenter.default.rx.notification(Self.subFolderNeedUpdate)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.refresh().subscribe().disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }

    func refresh() -> Completable {
        baseModel.refresh(sortOption: sortHelper.selectedOption)
            .do(onSuccess: { [weak self] response in
                guard let self = self else { return }
                self.listContainer.update(pagingState: response.pagingState)
                self.listContainer.update(totalCount: response.totalCount)
                self.dataManager.setRootFile(data: response.dataDiff) { [weak self] _ in
                    guard let self = self else { return }
                    self.dataManager.spaceEntry(token: TokenStruct(token: self.folderToken)) { [weak self] entry in
                        if let folderEntry = entry as? FolderEntry {
                            self?.folderEntry = folderEntry
                        }
                    }
                }
            })
            .asCompletable()
    }

    func loadMore() -> Completable {
        guard case let .hasMore(lastLabel) = listContainer.pagingState else {
            DocsLogger.error("space.sub-folder-v2.dm --- cannot load more")
            return .error(CommonListError.unableToLoadMore)
        }
        return baseModel.loadMore(lastLabel: lastLabel, sortOption: sortHelper.selectedOption)
            .do(onSuccess: { [weak self] response in
                guard let self = self else { return }
                self.listContainer.update(pagingState: response.pagingState)
                self.listContainer.update(totalCount: response.totalCount)
                self.dataManager.appendFileList(data: response.dataDiff)
            }, onError: { error in
                DocsLogger.error("space.my-folder-v2.dm --- load more failed", error: error)
            })
            .asCompletable()
    }

    func deleteAllChildren() {
        dataManager.deleteSubFolderEntries(nodeToken: folderToken)
    }

    func update(sortIndex: Int, descending: Bool) {
        sortHelper.update(sortIndex: sortIndex, descending: descending)
        sortHelper.store()
    }

    func update(sortOption: SpaceSortHelper.SortOption) {
        sortHelper.update(selectedOption: sortOption)
        sortHelper.store()
    }

    func checkFolderPermission() {
        if let folderEntry = folderEntry, folderEntry.ownerIsCurrentUser {
            // 是文件夹 owner 场景，给所有权限
            updateAllPermission(havePermission: true)
            return
        }
        if let tenantID = folderEntry?.ownerTenantID {
            permissionProvider.update(tenantID: tenantID)
        }
        permissionProvider.checkCanCreate(folderToken: folderToken)
            .subscribe { [weak self] canCreate in
                self?.createPermRelay.accept(canCreate)
            } onError: { error in
                DocsLogger.error("permission provider return error", error: error)
            }
            .disposed(by: disposeBag)
    }

    private func updateAllPermission(havePermission: Bool) {
        createPermRelay.accept(havePermission)
    }

    func requestPermission(message: String, roleToRequest: Int) -> Completable {
        networkAPI.requestPermission(folderToken: folderToken, message: message, roleToRequest: roleToRequest)
    }
}

private extension SKOperational {

    func isLocalDataForSubFolderList(folderToken: String) -> Bool {
        switch self {
        case .openNoCacheFolderLink:
            return true
        case let .loadSubFolder(nodeToken):
            return nodeToken == folderToken
        default:
            return false
        }
    }

    var isServerDataForSubFolderList: Bool {
        switch self {
        case .setRootFile,
                .appendFileList:
            return true
        default:
            return false
        }
    }
}

extension SubFolderDataModelV2: SKListServiceProtocol {
    func dataChange(data: SKListData, operational: SKOperational) {
        DocsLogger.debug("space.sub-folder-v2.dm --- data changed, operation: \(operational.descriptionInLog), dataCount: \(data.files.count)")
        if operational.isLocalDataForSubFolderList(folderToken: folderToken) {
            listContainer.restore(localData: data.files)
        } else if operational.isServerDataForSubFolderList {
            listContainer.sync(serverData: data.files)
        } else {
            listContainer.update(data: data.files)
        }
    }

    var type: SKObserverDataType {
        .subFolder
    }

    var token: String {
        folderToken
    }
}

extension SubFolderDataModelV2: FolderPickerDataModel {
    var pickerItems: [SpaceEntry] { listContainer.items }
    var pickerItemChanged: Observable<[SpaceEntry]> { itemChanged }
    var addToCurrentFolderEnabled: Observable<Bool> { createPermRelay.asObservable() }

    func resetSortFilterForPicker() {
        sortHelper.update(selectedOption: SortOption(type: .updateTime, descending: true, allowAscending: false))
    }
}
