//
//  SubFolderDataModelV1.swift
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

extension SubFolderDataModelV1 {
    typealias SortOption = SpaceSortHelper.SortOption
    typealias CommonListError = RecentListDataModel.RecentDataError
    private static let subFolderListPageCount = 100
    static var subFolderNeedUpdate: Notification.Name { PersonalFileDataModel.personalFileNeedUpdate }
    typealias API = V1FolderListAPI

    typealias FolderInfo = SpaceV1FolderInfo
}

// 供 V1 文件夹使用，V2 请使用 SubFolderDataModelV2
class SubFolderDataModelV1 {
    private let disposeBag = DisposeBag()
    private(set) var sortHelper: SpaceSortHelper
    let listContainer: SpaceListContainer
    let interactionHelper: SpaceInteractionHelper
    private let dataManager: SKDataManager
    private let baseModel: SubFolderBaseModel
    private var hasBeenSetup = false
    private let workQueue = DispatchQueue(label: "space.sub-folder-v1.dm.queue")
    var itemChanged: Observable<[SpaceEntry]> {
        listContainer.itemsChanged
    }

    let folderInfo: FolderInfo
    let folderType: FolderType
    var folderToken: FileListDefine.ObjToken { folderInfo.token }
    private let permissionService: UserPermissionService
    // v1 文件夹只关心编辑权限点位
    private let editPermissionRelay: BehaviorRelay<Bool>
    var haveEditPermission: Bool { editPermissionRelay.value }
    var editPermissionChanged: Observable<Bool> {
        editPermissionRelay.asObservable()
    }
    private(set) var folderEntry: FolderEntry?
    var isShareFolder: Bool {
        if let entryValue = folderEntry?.isShareFolder { return entryValue }
        if case .share = folderInfo.folderType { return true }
        return false
    }

    init(folderInfo: FolderInfo) {
        self.folderInfo = folderInfo
        if folderInfo.folderType == .personal {
            folderType = .common
            editPermissionRelay = BehaviorRelay<Bool>(value: true)
        } else {
            folderType = .share
            editPermissionRelay = BehaviorRelay<Bool>(value: false)
        }
        permissionService = DocsContainer.shared.resolve(PermissionSDK.self)!
            .userPermissionService(for: .legacyFolder(info: folderInfo))
        dataManager = SKDataManager.shared
        sortHelper = SpaceSortHelper.subFolder(token: folderInfo.token)
        interactionHelper = SpaceInteractionHelper(dataManager: dataManager)
        listContainer = SpaceListContainer(listIdentifier: folderInfo.token.encryptToken)
        baseModel = SubFolderBaseModel(networkAPI: API.self,
                                       folderToken: folderInfo.token,
                                       pageCount: Self.subFolderListPageCount)
        // 初始化时，尝试从内存读取一次 folderEntry
        dataManager.spaceEntry(token: TokenStruct(token: folderToken)) { [weak self] entry in
            DispatchQueue.main.async {
                self?.folderEntry = entry as? FolderEntry
                self?.checkFolderPermission()
            }
        }
    }

    func setup() {
        guard !hasBeenSetup else {
            DocsLogger.error("space.sub-folder-v1.dm --- skipping re-setup data model")
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
                        self?.checkExternalState()
                    }
                }
            })
            .asCompletable()
    }

    func loadMore() -> Completable {
        guard case let .hasMore(lastLabel) = listContainer.pagingState else {
            DocsLogger.error("space.sub-folder-v1.dm --- cannot load more")
            return .error(CommonListError.unableToLoadMore)
        }
        return baseModel.loadMore(lastLabel: lastLabel, sortOption: sortHelper.selectedOption)
            .do(onSuccess: { [weak self] response in
                guard let self = self else { return }
                self.listContainer.update(pagingState: response.pagingState)
                self.listContainer.update(totalCount: response.totalCount)
                self.dataManager.appendFileList(data: response.dataDiff) { [weak self] _ in
                    self?.checkExternalState()
                }
            }, onError: { error in
                DocsLogger.error("space.my-folder.dm --- load more failed", error: error)
            })
            .asCompletable()
    }

    func update(sortIndex: Int, descending: Bool) {
        sortHelper.update(sortIndex: sortIndex, descending: descending)
        sortHelper.store()
    }

    func update(sortOption: SpaceSortHelper.SortOption) {
        sortHelper.update(selectedOption: sortOption)
        sortHelper.store()
    }

    func removeFromList(nodeToken: FileListDefine.NodeToken) -> Completable {
        interactionHelper.removeFromFolder(nodeToken: nodeToken, folderToken: folderToken).asCompletable()
    }

    func checkFolderPermission() {
        if let folderEntry = folderEntry, folderEntry.ownerIsCurrentUser {
            // 是文件夹 owner 场景，给所有权限
            editPermissionRelay.accept(true)
            return
        }
        checkPermissionWithSDK()
    }

    private func checkPermissionWithSDK() {
        if let tenantID = folderEntry?.ownerTenantID {
            permissionService.update(tenantID: tenantID)
        }
        permissionService.updateUserPermission()
            .subscribe { [weak self] _ in
                guard let self else { return }
                let canCreateSubNode = self.permissionService.validate(operation: .createSubNode, bizDomain: .ccm).allow
                self.editPermissionRelay.accept(canCreateSubNode)
            } onError: { error in
                DocsLogger.error("space.sub-folder-v1.dm --- get share folder permission failed with error", error: error)
            }
            .disposed(by: disposeBag)
    }

    func requestPermission(message: String, roleToRequest: Int) -> Completable {
        API.requestPermission(folderToken: folderToken, message: message, roleToRequest: roleToRequest)
    }

    // 检查文件夹内的文件是否需要展示外部提示
    private func checkExternalState() {
        guard let entry = folderEntry, entry.isOldShareFolder else {
            return
        }
        let items = listContainer.items.compactMap { entry -> SpaceItem? in
            guard entry.type.isBiz else { return nil }
            return SpaceItem(objToken: entry.objToken, objType: entry.type)
        }
        API.fetchExternalInfo(items: items).subscribe { [weak self] state in
            guard let self = self else { return }
            self.dataManager.updateFileExternal(info: state)
        } onError: { error in
            DocsLogger.error("space.sub-folder-v1.dm --- fetch external state failed with error", error: error)
        }
        .disposed(by: disposeBag)
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

extension SubFolderDataModelV1: SKListServiceProtocol {
    func dataChange(data: SKListData, operational: SKOperational) {
        DocsLogger.debug("space.sub-folder-v1.dm --- data changed, operation: \(operational.descriptionInLog), dataCount: \(data.files.count)")
        if operational.isLocalDataForSubFolderList(folderToken: token) {
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

extension SubFolderDataModelV1: FolderPickerDataModel {
    var pickerItems: [SpaceEntry] { listContainer.items }
    var pickerItemChanged: Observable<[SpaceEntry]> { itemChanged }
    var addToCurrentFolderEnabled: Observable<Bool> { editPermissionChanged }

    func resetSortFilterForPicker() {
        sortHelper.update(selectedOption: SortOption(type: .updateTime, descending: true, allowAscending: false))
    }
}
