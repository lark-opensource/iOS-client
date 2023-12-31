//
//  SpaceListDataProvider.swift
//  SKSpace
//
//  Created by Weston Wu on 2022/9/29.
//

import Foundation
import SKCommon

// 对 SKDataManager 的抽象，以便单测 mock 使用
protocol SpaceListDataProvider {
    func addObserver(_ observer: SKListServiceProtocol)
    func loadFolderFileEntries(folderKey: DocFolderKey, limit: Int)
    func loadData(_ userID: String, _ completion: @escaping (Bool) -> Void)
    func setRootFile(data: FileDataDiff, callback: ((ResourceState) -> Void)?)
    func appendFileList(data: FileDataDiff, callback: ((ResourceState) -> Void)?)

    func getFilterCacheTokens(listID: String,
                              filterType: FilterItem.FilterType,
                              sortType: SortItem.SortType,
                              isAscending: Bool,
                              completion: @escaping ([String]?) -> Void)
    func save(filterCacheTokens tokens: [String],
              listID: String,
              filterType: FilterItem.FilterType,
              sortType: SortItem.SortType,
              isAscending: Bool)
}

extension SpaceListDataProvider {
    func setRootFile(data: FileDataDiff) {
        setRootFile(data: data, callback: nil)
    }

    func appendFileList(data: FileDataDiff) {
        appendFileList(data: data, callback: nil)
    }
}

// 文件夹列表使用的额外接口
protocol SpaceFolderListDataProvider: SpaceListDataProvider {
    func spaceEntry(token: TokenStruct, callBack: @escaping (SpaceEntry?) -> Void)

    func loadSubFolderEntries(nodeToken: String)
    func deleteSubFolderEntries(nodeToken: String)
}

protocol SubordinateRecentListDataProvider: SpaceListDataProvider {
    func loadSubordinateRecentEntries(subordinateID: String)
    func userInfoFor(subordinateID: String, callBack: @escaping (UserInfo?) -> Void)
}

protocol SpaceRecentListDataProvider: SpaceListDataProvider {
    func resetRecentFileListOld(data: FileDataDiff, folderKey: DocFolderKey, callback: ((ResourceState) -> Void)?)
    func appendRecentFileListOld(data: FileDataDiff, folderKey: DocFolderKey, callback: ((ResourceState) -> Void)?)
    func mergeRecentFiles(data: FileDataDiff, folderKey: DocFolderKey, callback: ((ResourceState) -> Void)?)
    func resetRecentFilesByTokens(tokens: [String], folderKey: DocFolderKey)
    func deleteRecentFile(tokens: [String])
}

extension SpaceRecentListDataProvider {
    func resetRecentFileListOld(data: FileDataDiff, folderKey: DocFolderKey) {
        resetRecentFileListOld(data: data, folderKey: folderKey, callback: nil)
    }
    func appendRecentFileListOld(data: FileDataDiff, folderKey: DocFolderKey) {
        appendRecentFileListOld(data: data, folderKey: folderKey, callback: nil)
    }
    func mergeRecentFiles(data: FileDataDiff, folderKey: DocFolderKey) {
        mergeRecentFiles(data: data, folderKey: folderKey, callback: nil)
    }
}

extension SKDataManager: SpaceFolderListDataProvider {}
extension SKDataManager: SpaceRecentListDataProvider {}
extension SKDataManager: SubordinateRecentListDataProvider {}
