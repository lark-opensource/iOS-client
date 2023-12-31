//
//  FileData.swift
//  FileResource
//
//  Created by weidong fu on 24/1/2018.
//

import Foundation
import SwiftyJSON
import SKCommon



//https://wiki.bytedance.net/pages/viewpage.action?pageId=145986898
final class FileData {
    static let pinFilesPathKey = "pinFilesPathKey"

    // MARK: - nodeTokens
    /// [node token: [key: value]]
    var nodes = [FileListDefine.NodeToken: [FileListDefine.Key: Any]]()
    /// [user id : ["name": userName]]
    var users = [FileListDefine.UserID: [FileListDefine.Key: Any]]()
    /// [folder token: [tokens of files]]
    var folders = [FileListDefine.NodeToken: [FileListDefine.NodeToken]]()
    /// 共享文件夹的objToken们
    var shareFoldersObjs = [FileListDefine.NodeToken]()
    /// [foler token: PaingInfos]
    var filePaingInfos = [FileListDefine.NodeToken: PagingInfo]()

    // MARK: - objTokens
    //  [tokens of recent file]
    var recentObjs = [FileListDefine.ObjToken]()
    var personalFileObjs = [FileListDefine.ObjToken]()

    /// 与我共享的文件objToken们
    var shareObjs = [FileListDefine.ObjToken]()
    /// 收藏 objToken
    // https://docs.bytedance.net/doc/G8PlpTSUR5CMKCHkfqYvbh
    var starObjs = [FileListDefine.ObjToken]() // 收藏列表 node 的排序
    /// Pins objToken
    // https://docs.bytedance.net/doc/T9ORHifWSUeC3qQYkBUePh
    var pinObjs = [FileListDefine.ObjToken]() // Pin列表 node 的排序

    /// [objTokens: [key: value]].
    var objsInfos = [FileListDefine.ObjToken: [FileListDefine.Key: Any]]()
    init() { }
}

extension FileData {
    var basicInfo: String {
        var info: String = ""
        info.append("==\(ObjectIdentifier(self))nodetokens====\n")
        info.append("nodeCount \(nodes.count)\n")
        info.append("foldersCount \(folders.count)\n")
        info.append("shareFoldersCount \(shareFoldersObjs.count)\n")
        info.append("==objtokens====\n")
        info.append("objToken 个数  \(objsInfos.count)\n")
        info.append("recentCount \(recentObjs.count)\n")
        info.append("与我共享个数 \(shareObjs.count)\n")
        info.append("收藏个数  \(starObjs.count)\n")
        info.append("pin个数 \(pinObjs.count)\n")
        info.append("personalFileObjsCount \(personalFileObjs.count)\n")
        return info
    }
}
