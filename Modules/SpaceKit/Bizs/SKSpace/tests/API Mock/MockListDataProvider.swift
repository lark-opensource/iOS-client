//
//  MockListDataProvider.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/9/29.
//

import Foundation
@testable import SKSpace
import SKCommon

class MockListDataProvider: SpaceListDataProvider {

    var loadFolderFileEntriesCalled: [DocFolderKey] = []
    func loadFolderFileEntries(folderKey: DocFolderKey, limit: Int) {
        loadFolderFileEntriesCalled.append(folderKey)
    }

    var loadDataCalled: [String] = []
    var loadDataSuccess = true
    func loadData(_ userID: String, _ completion: @escaping (Bool) -> Void) {
        loadDataCalled.append(userID)
        completion(loadDataSuccess)
    }

    var observers: [SKListServiceProtocol] = []
    func addObserver(_ observer: SKListServiceProtocol) {
        observers.append(observer)
    }

    var appendFileListCalled: [FileDataDiff] = []
    func appendFileList(data: FileDataDiff, callback: ((ResourceState) -> Void)?) {
        appendFileListCalled.append(data)
    }

    var setRootFileCalled: [FileDataDiff] = []
    func setRootFile(data: FileDataDiff, callback: ((ResourceState) -> Void)?) {
        setRootFileCalled.append(data)
        callback?(ResourceState())
    }

    var filterCacheTokenMap: [String: [String]] = [:]
    func getFilterCacheTokens(listID: String,
                              filterType: FilterItem.FilterType,
                              sortType: SortItem.SortType,
                              isAscending: Bool,
                              completion: @escaping ([String]?) -> Void) {
        let key = Self.filterCacheKey(listID: listID,
                                      filterType: filterType,
                                      sortType: sortType,
                                      isAscending: isAscending)
        completion(filterCacheTokenMap[key])
    }

    func save(filterCacheTokens tokens: [String],
              listID: String,
              filterType: FilterItem.FilterType,
              sortType: SortItem.SortType,
              isAscending: Bool) {
        let key = Self.filterCacheKey(listID: listID,
                                      filterType: filterType,
                                      sortType: sortType,
                                      isAscending: isAscending)
        filterCacheTokenMap[key] = tokens
    }

    static func filterCacheKey(listID: String, filterType: FilterItem.FilterType, sortType: SortItem.SortType, isAscending: Bool) -> String {
        "\(listID)-\(filterType.rawValue)-\(sortType.rawValue)-\(isAscending)"
    }
}

class MockListData: SKListData {
    var folderNodeToken: String
    var files: [SpaceEntry] = []
    var isHasMore: Bool?
    var lastLabel: String?
    var total: Int = 0

    init(folderToken: String) {
        folderNodeToken = folderToken
    }
}
