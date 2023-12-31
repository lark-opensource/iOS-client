//
//  BitableHomeWrapperDataManager.swift
//  SKSpace
//
//  Created by zoujie on 2022/12/8.
//

import Foundation
import SKCommon
// 直接通过上层过滤来实现 Bitable 筛选，以支持 Wiki@Bitable 的显示，因此下方数据管理器暂不需要
/*
class BitableHomeWrapperDataManager: SpaceRecentListDataProvider {
    let dataManager: SKDataManager = .shared
    
    func appendFileList(data: FileDataDiff, callback: ((ResourceState) -> Void)?) {
        dataManager.appendFileList(data: data, callback: callback)
    }
    
    func setRootFile(data: FileDataDiff, callback: ((ResourceState) -> Void)?) {
        dataManager.setRootFile(data: data, callback: callback)
    }
    
    func addObserver(_ observer: SKListServiceProtocol) {
        dataManager.addObserver(observer)
    }
    
    func loadFolderFileEntries(folderKey: DocFolderKey, limit: Int) {
        dataManager.loadFolderFileEntries(folderKey: folderKey, limit: limit)
    }
    
    func loadData(_ userID: String, _ completion: @escaping (Bool) -> Void) {
        dataManager.loadData(userID, completion)
    }
    
    func getFilterCacheTokens(listID: String, filterType: SKCommon.FilterItem.FilterType, sortType: SKCommon.SortItem.SortType, isAscending: Bool, completion: @escaping ([String]?) -> Void) {
        dataManager.getFilterCacheTokens(listID: listID, filterType: filterType, sortType: sortType, isAscending: isAscending, completion: completion)
    }
    
    func save(filterCacheTokens tokens: [String], listID: String, filterType: SKCommon.FilterItem.FilterType, sortType: SKCommon.SortItem.SortType, isAscending: Bool) {
        dataManager.save(filterCacheTokens: tokens, listID: listID, filterType: filterType, sortType: sortType, isAscending: isAscending)
    }
    
    func resetRecentFileListOld(data: FileDataDiff, callback: ((ResourceState) -> Void)?) {
        dataManager.resetBitaleRecentFileListOld(data: data, callback: callback)
    }
    
    func appendRecentFileListOld(data: FileDataDiff, callback: ((ResourceState) -> Void)?) {
        dataManager.appendBitaleRecentFileListOld(data: data, callback: callback)
    }
    
    func mergeRecentFiles(data: FileDataDiff, callback: ((ResourceState) -> Void)?) {
        dataManager.mergeBitaleRecentFiles(data: data, callback: callback)
    }
    
    func resetRecentFilesByTokens(tokens: [String]) {
        dataManager.resetBitaleRecentFilesByTokens(tokens: tokens)
    }
    
    func deleteRecentFile(tokens: [String]) {
        dataManager.deleteRecentFile(tokens: tokens)
    }
}
*/
