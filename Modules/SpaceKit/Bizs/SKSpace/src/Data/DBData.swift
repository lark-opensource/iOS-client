//
//  DBData.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/7/10.
//  从数据库里读写时，用的数据

import Foundation
import SKFoundation
import SKCommon

struct DBData {
    var specialTokens = SpecialTokens()
    var users = [UserInfo]()
    var fileEntry = [SpaceEntry]()
    var nodeToObjTokenMap = [TokenStruct: FileListDefine.ObjToken]()
    var nodeTokensMap = [FileListDefine.NodeToken: [TokenStruct]]()
    func logInfo() {
        DocsLogger.info("alldbData info start ===")
//        DocsLogger.info("file Entry \(fileEntry.count), \(fileEntry)")
        DocsLogger.info("file Entry \(fileEntry.count)")
        DocsLogger.info("nodeToObjTokenMap: node \(nodeToObjTokenMap.keys.count), objToken: \(Set(nodeToObjTokenMap.values).count)")
        DocsLogger.info("nodeTokensMap: \(nodeToObjTokenMap.values.map { "\($0.count)" }.joined(separator: "**"))")
        specialTokens.logInfo()
        DocsLogger.info("alldbData info end ===")
    }
}

struct DBDataDiff {
    //update or increase
    var specialTokensDiff = SpecialTokensDiff()
    var users = [UserInfo]()
    var fileEntry = [SpaceEntry]()
    var shortCutFileEntry = [SpaceEntry]()
    var nodeToObjTokenMap = [TokenStruct: FileListDefine.ObjToken]()
    var nodeTokensMap = [FileListDefine.NodeToken: [TokenStruct]]()
    //need delete
    var deleteUsers = [UserInfo]()
    var deleteFileEntry = [SpaceEntry]()
    var shortCutDeleteFileEntry = [SpaceEntry]()
    var deleteNodeToObjTokenMap = [TokenStruct: FileListDefine.ObjToken]()
    var deleteNodeTokensMap = [FileListDefine.NodeToken: [TokenStruct]]()

    var isAllEmpty: Bool {
        guard specialTokensDiff.isAllEmpty,
            users.isEmpty,
            fileEntry.isEmpty,
            nodeToObjTokenMap.isEmpty,
            nodeTokensMap.isEmpty,
            deleteUsers.isEmpty,
            deleteFileEntry.isEmpty,
            deleteNodeToObjTokenMap.isEmpty,
            deleteNodeTokensMap.isEmpty else {
            return false
        }
        return true
    }

    func checkStatus() {
        specialTokensDiff.checkStatus()
    }
}

public struct SpecialTokens {

    public private(set) var storages: [DocFolderKey: [TokenStruct]] = [:]

    public subscript(key: DocFolderKey) -> [TokenStruct] {
        get {
            storages[key] ?? []
        }
        set {
            storages[key] = newValue
        }
    }

    public mutating func replaceObjToken(old: TokenStruct, objToken: TokenStruct, nodeToken: TokenStruct?) {
        var newStorages: [DocFolderKey: [TokenStruct]] = [:]
        storages.forEach { folderKey, tokens in
            guard let index = tokens.firstIndex(of: old) else {
                newStorages[folderKey] = tokens
                return
            }
            var newTokens = tokens
            if folderKey.mixUsingObjTokenAndNodeToken, let nodeToken {
                // 混用的列表，要区分下 nodeToken 和 objToken
                newTokens[index] = nodeToken
            } else {
                newTokens[index] = objToken
            }
            newStorages[folderKey] = newTokens
        }
        storages = newStorages
    }

    public mutating func deleteFromAllByToken(_ tokenNode: TokenStruct) {
        storages = storages.mapValues { tokens in
            var newTokens = tokens
            newTokens.removeAll { $0 == tokenNode }
            return newTokens
        }
    }

    public mutating func addToken(_ token: String, folderKey: DocFolderKey, nodeType: Int) {
        let tokenNode = TokenStruct(token: token, nodeType: nodeType)
        var newTokens = storages[folderKey] ?? []
        newTokens.append(tokenNode)
        storages[folderKey] = newTokens
    }
    
    public func tokens(by folderKey: DocFolderKey) -> [TokenStruct] {
        storages[folderKey] ?? []
    }

    public func checkStatus() {
        storages.forEach { folderKey, tokens in
            spaceAssert(tokens.count == Set(tokens).count, "\(folderKey) found repeated token")
        }
    }

    public func logInfo() {
        storages.forEach { folderKey, tokens in
            DocsLogger.info("key: \(folderKey), count: \(tokens.count)")
        }
    }
}

struct SpecialTokensDiff {

    private(set) var storages: [DocFolderKey: [TokenStruct]] = [:]

    subscript(key: DocFolderKey) -> [TokenStruct] {
        get {
            storages[key] ?? []
        }
        set {
            storages[key] = newValue
        }
    }

    var isAllEmpty: Bool {
        storages.isEmpty
    }

    func checkStatus() {
        storages.forEach { folderKey, tokens in
            spaceAssert(tokens.count == Set(tokens).count, "\(folderKey) found repeated token")
        }
    }
}
