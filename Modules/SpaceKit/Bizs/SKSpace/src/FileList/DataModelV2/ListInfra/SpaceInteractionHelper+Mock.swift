//
//  SpaceInteractionHelper+Mock.swift
//  SKSpace
//
//  Created by Weston Wu on 2022/6/9.
//

import Foundation
import SKCommon

protocol SpaceInteractionHelperDataManager {
    func updateFileStarValueInAllList(objToken: FileListDefine.ObjToken, isStared: Bool, callback: ((ResourceState) -> Void)?)
    func updatePin(objToken: FileListDefine.ObjToken, isPined: Bool, callback: ((ResourceState) -> Void)?)
    func updateHiddenV2(objToken: String, hidden: Bool, callback: ((ResourceState) -> Void)?)
    // TODO: renameFile 和 rename 应该可以合并
    func renameFile(objToken: String, newName: String, callback: ((ResourceState) -> Void)?)
    func rename(objToken: FileListDefine.ObjToken, with newName: String)
    func moveFile(file: FileListDefine.NodeToken, from: FileListDefine.NodeToken, to: FileListDefine.NodeToken, callback: ((ResourceState) -> Void)?)
    func deletePersonFile(nodeToken: FileListDefine.NodeToken, callback: ((ResourceState) -> Void)?)
    func deleteFileByToken(token: TokenStruct, callback: ((ResourceState) -> Void)?)
    func spaceEntry(objToken: FileListDefine.ObjToken) -> SpaceEntry?
    func deleteFile(nodeToken: FileListDefine.NodeToken, parent: FileListDefine.NodeToken, callback: ((ResourceState) -> Void)?)
    func spaceEntry(token: TokenStruct) -> SpaceEntry?
    func deleteShareWithMeFile(nodeToken: FileListDefine.NodeToken, callback: ((ResourceState) -> Void)?)
    func updateSecurity(objToken: String, newSecurityName: String)
}

// 几个 callback 支持不传
extension SpaceInteractionHelperDataManager {
    func updateFileStarValueInAllList(objToken: FileListDefine.ObjToken, isStared: Bool) {
        updateFileStarValueInAllList(objToken: objToken, isStared: isStared, callback: nil)
    }
    func updatePin(objToken: FileListDefine.ObjToken, isPined: Bool) {
        updatePin(objToken: objToken, isPined: isPined, callback: nil)
    }
    func updateHiddenV2(objToken: String, hidden: Bool) {
        updateHiddenV2(objToken: objToken, hidden: hidden, callback: nil)
    }
    func renameFile(objToken: String, newName: String) {
        renameFile(objToken: objToken, newName: newName, callback: nil)
    }
    func moveFile(file: FileListDefine.NodeToken, from: FileListDefine.NodeToken, to: FileListDefine.NodeToken) {
        moveFile(file: file, from: from, to: to, callback: nil)
    }

    func deletePersonFile(nodeToken: FileListDefine.NodeToken) {
        deletePersonFile(nodeToken: nodeToken, callback: nil)
    }

    func deleteFileByToken(token: TokenStruct) {
        deleteFileByToken(token: token, callback: nil)
    }

    func deleteFile(nodeToken: FileListDefine.NodeToken, parent: FileListDefine.NodeToken) {
        deleteFile(nodeToken: nodeToken, parent: parent, callback: nil)
    }

    func deleteShareWithMeFile(nodeToken: FileListDefine.NodeToken) {
        deleteShareWithMeFile(nodeToken: nodeToken, callback: nil)
    }
}

// 目前的唯一实现
extension SKDataManager: SpaceInteractionHelperDataManager {}
