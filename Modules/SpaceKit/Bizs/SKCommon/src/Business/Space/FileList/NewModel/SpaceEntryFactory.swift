//
//  SpaceEntryFactory.swift
//  SKCommon
//
//  Created by guoqp on 2020/9/9.
//

import Foundation
import SKFoundation
import SpaceInterface
import SKInfra

open class SpaceEntryFactory {
    public static func createEntry(type: DocsType, nodeToken: FileListDefine.NodeToken, objToken: FileListDefine.ObjToken) -> SpaceEntry {
        switch type {
        case .doc:
            return DocEntry(type: type, nodeToken: nodeToken, objToken: objToken)
        case .sheet:
            return SheetEntry(type: type, nodeToken: nodeToken, objToken: objToken)
        case .myFolder, .folder:
            return FolderEntry(type: type, nodeToken: nodeToken, objToken: objToken)
        case .bitable:
            return BitableEntry(type: type, nodeToken: nodeToken, objToken: objToken)
        case .mindnote:
            return MindnoteEntry(type: type, nodeToken: nodeToken, objToken: objToken)
        case .file:
            return DriveEntry(type: type, nodeToken: nodeToken, objToken: objToken)
        case .slides:
            return SlideEntry(type: type, nodeToken: nodeToken, objToken: objToken)
        case .wiki:
            return WikiEntry(type: type, nodeToken: nodeToken, objToken: objToken)
        default:
            return SpaceEntry(type: type, nodeToken: nodeToken, objToken: objToken)
        }
    }

    public static func createEntryBy(docsInfo: DocsInfo) -> SpaceEntry {
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        if let entry = dataCenterAPI?.spaceEntry(objToken: docsInfo.objToken) {
            return entry
        } else {
            DocsLogger.warning("create a unsafe spaceEntry")
            let entry = SpaceEntryFactory.createEntry(type: docsInfo.type, nodeToken: "", objToken: docsInfo.objToken)
            entry.updateName(docsInfo.title)
            entry.updateCreateUid(docsInfo.creatorID)
            entry.updateEditTime(docsInfo.editTime)
            entry.updateCreateTime(docsInfo.createTime)
            entry.updateEditorName(docsInfo.editor)
            entry.updateOwnerID(docsInfo.ownerID)
            entry.updatePinedStatus(docsInfo.pined)
            entry.updateStaredStatus(docsInfo.stared)
            entry.updateShareURL(docsInfo.shareUrl)
            if let ownerType = docsInfo.ownerType {
                entry.updateOwnerType(ownerType)
            }
            entry.updateNodeType(docsInfo.nodeType)
            if let t = entry as? DriveEntry {
                t.updateFileType(docsInfo.fileType)
            }
            return entry
        }
    }

    public static func asyncCreateActualFileEntry(with docsInfo: DocsInfo, completion: @escaping (SpaceEntry) -> Void) {
        let objToken: String
        let objType: DocsType
        if let wikiToken = docsInfo.wikiInfo?.wikiToken {
            objToken = wikiToken
            objType = .wiki
        } else {
            objToken = docsInfo.objToken
            objType = docsInfo.type
        }
        func createEntry() -> SpaceEntry {
            DocsLogger.warning("create a unsafe spaceEntry")
            let entry = SpaceEntryFactory.createEntry(type: objType, nodeToken: "", objToken: objToken)
            entry.updateName(docsInfo.title)
            entry.updateCreateUid(docsInfo.creatorID)
            entry.updateEditTime(docsInfo.editTime)
            entry.updateCreateTime(docsInfo.createTime)
            entry.updateEditorName(docsInfo.editor)
            entry.updateOwnerID(docsInfo.ownerID)
            entry.updatePinedStatus(docsInfo.pined)
            entry.updateStaredStatus(docsInfo.stared)
            entry.updateShareURL(docsInfo.shareUrl)
            entry.updateIconInfo(docsInfo.iconInfo)
            if let t = entry as? DriveEntry {
                t.updateFileType(docsInfo.fileType)
            } else if let wikiEntry = entry as? WikiEntry {
                if let wikiInfo = docsInfo.wikiInfo {
                    wikiEntry.update(wikiInfo: wikiInfo)
                } else {
                    spaceAssertionFailure("createActualFileEntryBy no wikiinfo @peipei")
                }
            }
            return entry
        }
        guard let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) else {
            completion(createEntry())
            return
        }

        dataCenterAPI.spaceEntry(objToken: objToken) { entry in
            let result = entry ?? createEntry()
            if let result = result as? DriveEntry {
                result.updateFileType(docsInfo.fileType)
            }
            completion(result)
        }
    }

    /// 用于识别 wiki token，返回真正的实体 entry 用于更多菜单内操作
    public static func createActualFileEntryBy(docsInfo: DocsInfo) -> SpaceEntry {
        let objToken: String
        let objType: DocsType
        if let wikiInfo = docsInfo.wikiInfo,
           !wikiInfo.wikiNodeState.originIsExternal {
            objToken = wikiInfo.wikiNodeState.shortcutWikiToken ?? wikiInfo.wikiToken
            objType = .wiki
        } else {
            objToken = docsInfo.objToken
            objType = docsInfo.type
        }
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        if let entry = dataCenterAPI?.spaceEntry(objToken: objToken) {
            return entry
        } else {
            DocsLogger.warning("create a unsafe spaceEntry")
            let entry = SpaceEntryFactory.createEntry(type: objType, nodeToken: "", objToken: objToken)
            entry.updateName(docsInfo.title)
            entry.updateCreateUid(docsInfo.creatorID)
            entry.updateEditTime(docsInfo.editTime)
            entry.updateCreateTime(docsInfo.createTime)
            entry.updateEditorName(docsInfo.editor)
            entry.updateOwnerID(docsInfo.ownerID)
            entry.updatePinedStatus(docsInfo.pined)
            entry.updateStaredStatus(docsInfo.stared)
            entry.updateShareURL(docsInfo.shareUrl)
            if let t = entry as? DriveEntry {
                t.updateFileType(docsInfo.fileType)
            } else if let wikiEntry = entry as? WikiEntry {
                if let wikiInfo = docsInfo.wikiInfo {
                    wikiEntry.update(wikiInfo: wikiInfo)
                } else {
                    spaceAssertionFailure("createActualFileEntryBy no wikiinfo @peipei")
                }
            }
            return entry
        }
    }
}
