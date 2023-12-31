//
//  SpaceMoreProviderFactory.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/11/2.
//

import Foundation
import SKCommon
import SKFoundation
import SKWorkspace

enum SpaceMoreProviderFactory {
    static func createMoreProvider(for entry: SpaceEntry,
                                   sourceView: UIView,
                                   forbiddenItems: [MoreItemType],
                                   needShowItems: [MoreItemType]? = nil,
                                   listType: SpaceMoreAPI.ListType) -> SpaceMoreDataProvider {
        if entry.type == .wiki, let wikiEntry = entry as? WikiEntry {
            DocsLogger.info("creating wiki more provider")
            return WikiMoreDataProvider(entry: wikiEntry, sourceView: sourceView, forbiddenItems: forbiddenItems, listType: listType)
        }
        if entry.isSingleContainerNode {
            return createV2MoreProvider(for: entry, sourceView: sourceView, forbiddenItems: forbiddenItems, needShowItems: needShowItems, listType: listType)
        } else {
            return createV1MoreProvider(for: entry, sourceView: sourceView, forbiddenItems: forbiddenItems, needShowItems: needShowItems, listType: listType)
        }
    }

    private static func createV1MoreProvider(for entry: SpaceEntry,
                                             sourceView: UIView,
                                             forbiddenItems: [MoreItemType],
                                             needShowItems: [MoreItemType]? = nil,
                                             listType: SpaceMoreAPI.ListType) -> SpaceMoreDataProvider {
        if entry.type == .folder, let folderEntry = entry as? FolderEntry {
            DocsLogger.info("creating v1 folder more provider")
            return V1FolderMoreDataProvider(folderEntry: folderEntry, sourceView: sourceView, forbiddenItems: forbiddenItems, listType: listType)
        } else {
            DocsLogger.info("creating v1 file more provider")
            return V1FileMoreDataProvider(entry: entry, sourceView: sourceView, forbiddenItems: forbiddenItems, needShowItems: needShowItems, listType: listType)
        }
    }

    private static func createV2MoreProvider(for entry: SpaceEntry,
                                             sourceView: UIView,
                                             forbiddenItems: [MoreItemType],
                                             needShowItems: [MoreItemType]? = nil,
                                             listType: SpaceMoreAPI.ListType) -> SpaceMoreDataProvider {
        if entry.type == .folder, let folderEntry = entry as? FolderEntry {
            if entry.isShortCut {
                DocsLogger.info("creating v2 folder shortcut more provider")
                return FolderShortcutMoreDataProvider(folderEntry: folderEntry, sourceView: sourceView, forbiddenItems: forbiddenItems, listType: listType)
            } else {
                DocsLogger.info("creating v2 folder more provider")
                return FolderMoreDataProvider(folderEntry: folderEntry, sourceView: sourceView, forbiddenItems: forbiddenItems, listType: listType)
            }
        } else {
            if entry.isShortCut {
                if entry.originInWiki, let wikiToken = entry.bizNodeToken {
                    DocsLogger.info("creating v2 file wiki shortcut more provider")
                    return WikiShortcutMoreDataProvider(entry: entry, wikiToken: wikiToken, sourceView: sourceView, forbiddenItems: forbiddenItems, listType: listType)
                } else {
                    DocsLogger.info("creating v2 file shortcut more provider")
                    return FileShortcutMoreDataProvider(entry: entry, sourceView: sourceView, forbiddenItems: forbiddenItems, listType: listType)
                }
            } else {
                DocsLogger.info("creating v2 file more provider")
                return FileMoreDataProvider(entry: entry, sourceView: sourceView, forbiddenItems: forbiddenItems, needShowItems: needShowItems, listType: listType)
            }
        }
    }
}

protocol SpaceMoreDataProvider: MoreDataProvider {
    var handler: SpaceMoreActionHandler? { get set }
}

protocol SpaceMoreActionHandler: AnyObject {

    func toggleFavorites(for entry: SpaceEntry)
    func toggleQuickAccess(for entry: SpaceEntry)
    func toggleSubscribe(for entry: SpaceEntry, result: @escaping ((Bool) -> Void))
    func toggleManualOffline(for entry: SpaceEntry)
    func toggleHiddenStatus(for entry: SpaceEntry)
    func toggleHiddenStatusV2(for entry: SpaceEntry)

    func copyLink(for entry: SpaceEntry)
    func importAsDocs(for entry: SpaceEntry)
    func copyFile(for entry: SpaceEntry, fileSize: Int64?, originName: String?) // shortcut 需要传本体名字
    func addToFolder(for entry: SpaceEntry)
    func addShortCut(for entry: SpaceEntry, originName: String?) // shortcut 需要传本体名字

    func delete(entry: SpaceEntry)
    func rename(entry: SpaceEntry)

    func openSensitivtyLabelSetting(entry: SpaceEntry, level: SecretLevel?)
    func openWithOtherApp(for entry: SpaceEntry, originName: String?, sourceView: UIView)
    func exportDocument(for entry: SpaceEntry, originName: String?, haveEditPermission: Bool, sourceView: UIView)
    func share(entry: SpaceEntry, sourceView: UIView, shareSource: ShareSource)
    func saveToLocal(for entry: SpaceEntry, originName: String?)

    func moveTo(for entry: SpaceEntry)
    func moveTo(for wikiEntry: WikiEntry, nodePermission: WikiTreeNodePermission)

    func handle(disabledAction: MoreItemType, reason: String, entry: SpaceEntry)
    func handle(disabledAction: MoreItemType, failure: Bool, reason: String, entry: SpaceEntry)
    func retentionHandle(entry: SpaceEntry)
}

extension SpaceMoreActionHandler {
    func copyFile(for entry: SpaceEntry, fileSize: Int64?) {
        copyFile(for: entry, fileSize: fileSize, originName: nil)
    }

    func addShortCut(for entry: SpaceEntry) {
        addShortCut(for: entry, originName: nil)
    }

    func exportDocument(for entry: SpaceEntry, haveEditPermission: Bool, sourceView: UIView) {
        exportDocument(for: entry, originName: nil, haveEditPermission: haveEditPermission, sourceView: sourceView)
    }
}
