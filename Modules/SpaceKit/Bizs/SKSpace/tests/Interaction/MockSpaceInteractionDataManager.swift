//
//  MockSpaceInteractionDataManager.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/6/10.
//

import Foundation
@testable import SKSpace
import SKCommon

struct MockSpaceStorage {
    var starMap: [String: Bool] = [:]
    var pinMap: [String: Bool] = [:]
    var hiddenMap: [String: Bool] = [:]
    var nameMap: [String: String] = [:]
    var parentMap: [String: String] = [:]
    var personTokens: Set<String> = []
    var shareTokens: Set<String> = []
    var entryMap: [String: SpaceEntry] = [:]
    var childMap: [String: Set<String>] = [:]
    var secretLabelMap: [String: String] = [:]
}

class MockSpaceInteractionDataManager: SpaceInteractionHelperDataManager {

    var storage = MockSpaceStorage()

    func updateFileStarValueInAllList(objToken: FileListDefine.ObjToken, isStared: Bool, callback: ((ResourceState) -> Void)?) {
        storage.starMap[objToken] = isStared
    }
    func updatePin(objToken: FileListDefine.ObjToken, isPined: Bool, callback: ((ResourceState) -> Void)?) {
        storage.pinMap[objToken] = isPined
    }
    func updateHiddenV2(objToken: String, hidden: Bool, callback: ((ResourceState) -> Void)?) {
        storage.hiddenMap[objToken] = hidden
    }
    // TODO: renameFile 和 rename 应该可以合并
    func renameFile(objToken: String, newName: String, callback: ((ResourceState) -> Void)?) {
        storage.nameMap[objToken] = newName
    }
    func rename(objToken: FileListDefine.ObjToken, with newName: String) {
        storage.nameMap[objToken] = newName
    }
    func moveFile(file: FileListDefine.NodeToken, from: FileListDefine.NodeToken, to: FileListDefine.NodeToken, callback: ((ResourceState) -> Void)?) {
        storage.parentMap[file] = to
        var fromChild = storage.childMap[from] ?? []
        fromChild.remove(file)
        storage.childMap[from] = fromChild

        var toChild = storage.childMap[to] ?? []
        toChild.insert(file)
        storage.childMap[to] = toChild
    }
    func deletePersonFile(nodeToken: FileListDefine.NodeToken, callback: ((ResourceState) -> Void)?) {
        storage.parentMap[nodeToken] = nil
        storage.personTokens.remove(nodeToken)
    }
    func deleteFileByToken(token: TokenStruct, callback: ((ResourceState) -> Void)?) {
        storage.personTokens.remove(token.token)
    }
    func spaceEntry(objToken: FileListDefine.ObjToken) -> SpaceEntry? {
        storage.entryMap[objToken]
    }
    func deleteFile(nodeToken: FileListDefine.NodeToken, parent: FileListDefine.NodeToken, callback: ((ResourceState) -> Void)?) {
        var childTokens = storage.childMap[parent] ?? []
        childTokens.remove(nodeToken)
        storage.childMap[parent] = childTokens
    }
    func spaceEntry(token: TokenStruct) -> SpaceEntry? {
        storage.entryMap[token.token]
    }
    func deleteShareWithMeFile(nodeToken: FileListDefine.NodeToken, callback: ((ResourceState) -> Void)?) {
        storage.shareTokens.remove(nodeToken)
    }

    func updateSecurity(objToken: String, newSecurityName: String) {
        storage.secretLabelMap[objToken] = newSecurityName
    }
}
