//
//  WikiTreeMoreProvider+Move.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/8/8.
// swiftlint:disable file_length

import Foundation
import RxSwift
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignColor
import UniverseDesignDialog
import UniverseDesignToast
import LarkUIKit
import SpaceInterface
import EENavigator
import SKInfra

// MARK: - Move Event
extension WikiMainTreeMoreProvider {

    func didClickMoveTarget(meta: WikiTreeNodeMeta, permission: WikiTreeNodePermission?, isClip: Bool) {
        WikiStatistic.clickWikiTreeMore(click: .moveTo,
                                        isFavorites: isClip,
                                        target: DocsTracker.EventType.wikiFileLocationSelectView.rawValue,
                                        meta: meta)

        let parentToken = parentProvider?(meta.wikiToken)
        let context = WikiInteractionHandler.Context(meta: meta,
                                                     parentToken: parentToken)
        let permission = permission ?? nodePermissionStorage[meta.wikiToken]
        let moveContext = WikiInteractionHandler.MoveContext(subContext: context,
                                                             canMove: permission?.canMove ?? false,
                                                             permissionLocked: permission?.isLocked ?? false,
                                                             hasChild: meta.hasChild) { [weak self] sortID, parentMeta in
            self?.didMoveNode(meta: meta,
                              oldParentToken: parentToken ?? "",
                              targetMeta: parentMeta,
                              sortID: sortID)
            self?.moreActionProxy?.refreshForMoreAction()
        } didMovedToSpace: { [weak self] _ in
            self?.moreActionInput.accept(.remove(meta: meta))
            self?.moreActionProxy?.refreshForMoreAction()
        }

        let entrances = interactionHelper.entrancesForMove(moveContext: moveContext)

        let picker = interactionHelper.makeMovePicker(context: moveContext, triggerLocation: .wikiTree, entrances: entrances) { [weak self] picker, location in
            guard let self else { return }
            self.interactionHelper.confirmMoveTo(location: location, context: moveContext, picker: picker)
        }
        self.actionInput.accept(.present(provider: { _ in
            picker
        }))
    }

    // 移动逻辑
    func didMoveNode(meta: WikiTreeNodeMeta,
                     oldParentToken: String,
                     targetMeta: WikiMeta,
                     sortID: Double) {
        WikiStatistic.clickFileLocationSelect(targetSpaceId: targetMeta.spaceID,
                                              fileId: meta.objToken,
                                              fileType: meta.objType.name,
                                              filePageToken: meta.wikiToken,
                                              viewTitle: .moveTo,
                                              originSpaceId: meta.spaceID,
                                              originWikiToken: meta.wikiToken,
                                              isShortcut: meta.isShortcut,
                                              triggerLocation: .wikiTree,
                                              targetModule: MyLibrarySpaceIdCache.isMyLibrary(targetMeta.spaceID) ? .myLibrary : .wiki,
                                              targetFolderType: nil)
        var newMeta = meta
        newMeta.spaceID = targetMeta.spaceID
        let node = WikiServerNode(meta: newMeta, sortID: sortID, parent: targetMeta.wikiToken)
        moreActionInput.accept(.move(oldParentToken: oldParentToken, movedNode: node))
    }
}

// MARK: - Remove Event
extension WikiMainTreeMoreProvider {

    func didClickRemoveToSpace(meta: WikiTreeNodeMeta, permission: WikiTreeNodePermission?, inClipSection: Bool) {
        WikiStatistic.clickWikiTreeMore(click: .remove,
                                        isFavorites: inClipSection,
                                        target: DocsTracker.EventType.wikiPermissionChangeView.rawValue,
                                        meta: meta)
        let parentToken = parentProvider?(meta.wikiToken)
        let context = WikiInteractionHandler.Context(meta: meta,
                                                     parentToken: parentToken)
        let permission = permission ?? nodePermissionStorage[meta.wikiToken]
        let moveContext = WikiInteractionHandler.MoveContext(subContext: context,
                                                             canMove: permission?.canMove ?? false,
                                                             permissionLocked: permission?.isLocked ?? false,
                                                             hasChild: meta.hasChild) { [weak self] sortID, parentMeta in
            self?.didMoveNode(meta: meta,
                              oldParentToken: parentToken ?? "",
                              targetMeta: parentMeta,
                              sortID: sortID)
        } didMovedToSpace: { [weak self] _ in
            self?.moreActionInput.accept(.remove(meta: meta))
            self?.moreActionProxy?.refreshForMoreAction()
        }

        interactionHelper.verifyMoveToSpace(moveContext: moveContext, location: .ownerSpace, targetModule: .defaultLocation, targetFolderType: .folder, picker: self)
    }
}

extension WikiMainTreeMoreProvider: WikiInteractionUIHandler {
    public func presentForWikiInteraction(controller: UIViewController) {
        actionInput.accept(.present(provider: { _ in controller }))
    }

    public func showToastForWikiInteraction(action: WikiTreeViewAction.HUDAction) {
        actionInput.accept(.showHUD(action))
    }

    public func removeToastForWikiInteraction() {
        actionInput.accept(.hideHUD)
    }

    public func dismissForWikiInteraction(controller: UIViewController?) {
        actionInput.accept(.dismiss(controller: controller))
    }
}
