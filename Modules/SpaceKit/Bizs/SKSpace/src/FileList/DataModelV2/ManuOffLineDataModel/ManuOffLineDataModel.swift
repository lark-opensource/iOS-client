//
//  ManuOffLineDataModel.swift
//  SKSpace
//
//  Created by majie.7 on 2021/10/25.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import SpaceInterface
import LarkContainer


public final class ManuOffLineDataModel {
    
    let userResolver: UserResolver
    let name: DataModelLabel = .manuOffline
    private(set) var sortHelper: SpaceSortHelper
    private(set) var filterHelper: SpaceFilterHelper
    let interactionHelper: SpaceInteractionHelper
    let listContainer: SpaceListContainer
    let dataManager: SKDataManager
    var itemChanged: Observable<[SpaceEntry]> {
        listContainer.itemsChanged
    }

    private var entries = [SpaceEntry]()
    private var disposeBag = DisposeBag()
    private var didTryLoadFromDB: Bool = false /// 判断是否第一次load DB
    private  static var hadNotifyFirstTime: Bool = false
    static let listToken = "MOFilesService"
    static let offLineListPageCount = 100
    
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.sortHelper = SpaceSortHelper.offLine
        self.filterHelper = SpaceFilterHelper.offLine
        self.dataManager = SKDataManager.shared
        self.interactionHelper = SpaceInteractionHelper(dataManager: dataManager)
        self.listContainer = SpaceListContainer(listIdentifier: "MOFilesService")
    }
    
    func setup() {
        guard !didTryLoadFromDB else { return }
        didTryLoadFromDB = true
        sortHelper.restore()
        filterHelper.restore()
        dataManager.addObserver(self)
        dataManager.loadFolderFileEntries(folderKey: .manuOffline, limit: Self.offLineListPageCount)
    }
    
    func update(filterIndex: Int) {
        filterHelper.update(filterIndex: filterIndex)
        filterHelper.store()
    }
    
    func update(sortIndex: Int, descending: Bool) {
        sortHelper.update(sortIndex: sortIndex, descending: descending)
        sortHelper.store()
    }

    func update(sortOption: SpaceSortHelper.SortOption) {
        sortHelper.update(selectedOption: sortOption)
        sortHelper.store()
    }
    
    func refresh() {
        let entries = self.entries
        DispatchQueue.global().async {
            let modifier: SpaceListComplexModifier = [ SpaceListSortModifier(sortOption: self.sortHelper.selectedOption),
                                                       SpaceListFilterModifier(filterOption: self.filterHelper.selectedOption)]
            let result = modifier.handle(entries: entries)
            DispatchQueue.main.async {
                self.listContainer.update(data: result)
            }
        }
    }
}

private extension SKOperational {
    var isLocalDataForManuOffLine: Bool {
        switch self {
        case .loadNewDBData:
            return true
        case let .loadSpecialFolder(folderKey):
            return folderKey == .manuOffline
        default:
            return false
        }
    }
}

extension ManuOffLineDataModel: SKListServiceProtocol {
    public func dataChange(data: SKListData, operational: SKOperational) {
        let modifier: SpaceListComplexModifier = [
            SpaceListFilterModifier(filterOption: filterHelper.selectedOption),
            SpaceListSortModifier(sortOption: sortHelper.selectedOption)
        ]
        self.entries = data.files
        DispatchQueue.global().async {
            let entries = modifier.handle(entries: data.files)
            DispatchQueue.main.async {
                if operational.isLocalDataForManuOffLine {
                    self.listContainer.restore(localData: entries)
                } else {
                    self.listContainer.update(data: entries)
                }
            }
        }
    }
    
//    static func checkToNotifyDownloaders(_ files: [SpaceEntry]) {
//        /// 数据从0 到有的时候，给用户发一次，但是只发一次
//        guard !Self.hadNotifyFirstTime,
//              let moMgr = DocsContainer.shared.resolve(FileManualOfflineManagerAPI.self) else {
//            return
//        }
//        // 第一次，通知给各个业务下载端，用户退出登录时重置为false
//        Self.hadNotifyFirstTime = true
//        
//        guard !files.isEmpty else { return }
//        
//        var array = [ManualOfflineFile]()
//        files.forEach { file in
//            let moFile = ManualOfflineFile(objToken: file.objToken, type: file.type)
//            array.append(moFile)
//        }
//        moMgr.updateOffline(array)
//    }
    
    public var type: SKObserverDataType {
        .specialList(folderKey: .manuOffline)
    }
    
    public var token: String {
        return Self.listToken
    }
}
