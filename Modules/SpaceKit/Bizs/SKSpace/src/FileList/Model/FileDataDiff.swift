//
//  FileDataDiff.swift
//  SpaceKit
//
//  Created by Webster on 2019/7/3.
//

import Foundation
import SKCommon
import SKFoundation

public struct FileDataDiff {

    // MARK: - nodeTokens
    /// [node token: [key: value]]
    var nodes = [TokenStruct: [FileListDefine.Key: Any]]()
    /// [user id : ["name": userName]]
    var users = [FileListDefine.UserID: [FileListDefine.Key: Any]]()
    /// [folder token: [tokens of files]]
    var folders = [FileListDefine.NodeToken: [TokenStruct]]()
    /// [objTokens: [key: value]].
    var objsInfos = [TokenStruct: [FileListDefine.Key: Any]]()
    /// 共享文件夹的objToken们
    var shareFoldersObjs = [TokenStruct]()
    /// [foler token: PaingInfos]
    var filePaingInfos = [FileListDefine.NodeToken: PagingInfo]()

    // MARK: - objTokens
    //  [tokens of recent file]
    var recentObjs = [TokenStruct]()
    var personalFileObjs = [TokenStruct]()

    /// 与我共享的文件objToken们
    var shareObjs = [TokenStruct]()
    /// 收藏 objToken
    // https://docs.bytedance.net/doc/G8PlpTSUR5CMKCHkfqYvbh
    var starObjs = [TokenStruct]() // 收藏列表 node 的排序
    /// Pins objToken
    // https://docs.bytedance.net/doc/T9ORHifWSUeC3qQYkBUePh
    var pinObjs = [TokenStruct]() // Pin列表 node 的排序


    // MARK: - Pagings
    var sharePagingInfo = PagingInfo(hasMore: false, total: 0, pageTitle: nil, lastLabel: nil)
    var starPagingInfo: PagingInfo = PagingInfo(hasMore: false, total: 0, pageTitle: nil, lastLabel: nil)
    public var shareFolderPagingInfo = PagingInfo(hasMore: false, total: 0, pageTitle: nil, lastLabel: nil)
    var recentPagingInfo = PagingInfo(hasMore: false, total: 0, pageTitle: nil, lastLabel: nil)
    public var personalFilesPagingInfo = PagingInfo(hasMore: false, total: 0, pageTitle: nil, lastLabel: nil)

    public init() { }

    var debugInfo: String {
        var dic = [String: String]()
        dic["nodes"] = nodes.extractKeys()
        dic["users"] = users.extractKeys()
        dic["folders"] = folders.extractKeys()
        dic["shareFoldersObjs"] = shareFoldersObjs.extractKeys()
        dic["filePaingInfos"] = filePaingInfos.extractKeys()
        dic["recentObjs"] = recentObjs.extractKeys()
        dic["personalFileObjs"] = personalFileObjs.extractKeys()
        dic["shareObjs"] = shareObjs.extractKeys()
        dic["starObjs"] = starObjs.extractKeys()
        dic["pinObjs"] = pinObjs.extractKeys()
        dic["objsInfos"] = objsInfos.extractKeys()
        dic["sharePagingInfo"] = sharePagingInfo.debugInfo
        dic["starPagingInfo"] = starPagingInfo.debugInfo
        dic["shareFolderPagingInfo"] = shareFolderPagingInfo.debugInfo
        dic["recentPagingInfo"] = recentPagingInfo.debugInfo
        dic["personalFilesPagingInfo"] = personalFilesPagingInfo.debugInfo
        dic["recentPagingInfo"] = recentPagingInfo.debugInfo
        return "FileDataDiff + \(dic.description)"
    }
}

extension Dictionary where Key == String {
    func extractKeys() -> String {
        var s = ""
        forEach { (key, _) in
            s += DocsTracker.encrypt(id: key) + ", "
        }
        s += "count = \(keys.count)"
        return s
    }
}

extension Array where Element == TokenStruct {
    func extractKeys() -> String {
        var s = ""
        forEach { key in
            s += DocsTracker.encrypt(id: key.token) + ", "
        }
        s += "count = \(count)"
        return s
    }
}
extension Dictionary where Key == TokenStruct {
    func extractKeys() -> String {
        var s = ""
        forEach { (key, _) in
            s += DocsTracker.encrypt(id: key.token) + ", "
        }
        s += "count = \(keys.count)"
        return s
    }
}
