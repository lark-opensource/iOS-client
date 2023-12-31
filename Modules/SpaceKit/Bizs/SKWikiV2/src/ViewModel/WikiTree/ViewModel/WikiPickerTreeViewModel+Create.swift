//
//  WikiPickerTreeViewModel+Create.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/9/13.
//

import Foundation
import RxSwift
import SKCommon
import SKResource
import SKFoundation
import UniverseDesignDialog
import UniverseDesignColor
import SpaceInterface
import SKWorkspace

extension WikiPickerTreeViewModel {
    func didClickCreateItem(meta: WikiTreeNodeMeta, node: TreeNode, docxEnabled: Bool = LKFeatureGating.createDocXEnable) {
        let parentUID = node.diffId
        actionInput.accept(.showHUD(.customLoading(BundleI18n.SKResource.Doc_Wiki_CreateDialog)))
        // picker tree 上创建节点不允许走离线创建流程
        interactionHandler.confirmCreate(meta: meta, type: docxEnabled ? .docX : .doc, allowOfflineCreate: false)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] node, _ in
                self?.didCreateNode(newNode: node, parentNodeUID: parentUID, parentNodeMeta: meta)
                self?.actionInput.accept(.hideHUD)
            } onError: { [weak self] error in
                DocsLogger.error("create wiki node failed", error: error)
                guard let self = self else { return }
                let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                self.actionInput.accept(.showHUD(.failure(error.addErrorDescription)))
            }
            .disposed(by: disposeBag)
    }

    // 基本参考 WikiMainTreeViewModel+More 中的 didCreateNode 实现，但额外增加重命名逻辑
    private func didCreateNode(newNode: WikiServerNode, parentNodeUID: WikiTreeNodeUID, parentNodeMeta: WikiTreeNodeMeta) {
        dataModel.syncAdd(node: newNode)
            .flatMap { [weak self] state -> Maybe<WikiTreeState> in
                guard let self = self else { return .just(state) }
                // 展开父节点
                return self.dataModel.expand(nodeUID: parentNodeUID).asMaybe()
            }
            .flatMap { [weak self] state -> Maybe<WikiTreeState> in
                guard let self = self else { return .just(state) }
                // 选中新创建的节点
                let newNodeUID = parentNodeUID.extend(childToken: newNode.meta.wikiMeta.wikiToken,
                                                      currentIsShortcut: newNode.meta.isShortcut)
                return self.dataModel.select(wikiToken: newNode.meta.wikiToken, nodeUID: newNodeUID).asMaybe()
            }
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                guard let self = self else { return }
                self.actionInput.accept(.hideHUD)
                self.treeStateRelay.accept(state)
                let newUID = parentNodeUID.extend(childToken: newNode.meta.wikiToken,
                                                  currentIsShortcut: parentNodeMeta.isShortcut)
                // 滚动到新创建的节点
                self.scrollByUIDInput.accept(newUID)
                self.showRenameDialog(meta: newNode.meta)
            } onError: { [weak self] error in
                guard let self = self else { return }
                DocsLogger.error("error found when handle create completed event", error: error)
                spaceAssertionFailure()
                self.actionInput.accept(.hideHUD)
            } onCompleted: { [weak self] in
                DocsLogger.error("not state receive when handle create completed event")
                spaceAssertionFailure()
                self?.actionInput.accept(.hideHUD)
            }
            .disposed(by: disposeBag)
    }

    private func showRenameDialog(meta: WikiTreeNodeMeta) {
        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: BundleI18n.SKResource.Doc_Facade_Rename, inputView: true)
        dialog.addTextField(placeholder: BundleI18n.SKResource.Doc_More_RenameSheetPlaceholder, text: meta.title)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: {
            DocsLogger.info("user cancel rename after create on picker tree")
        })
        let button = dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Ok, dismissCompletion: { [weak dialog, weak self] in
            guard let name = dialog?.textField.text, !name.isEmpty else { return }
            self?.confirmRename(meta: meta, newTitle: name)
        })
        dialog.bindInputEventWithConfirmButton(button)
        actionInput.accept(.present(provider: { _ in
            return dialog
        }))
    }

    private func confirmRename(meta: WikiTreeNodeMeta, newTitle: String) {
        actionInput.accept(.showHUD(.loading))
        let context = WikiInteractionHandler.Context(meta: meta)
        interactionHandler.rename(context: context, newTitle: newTitle)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] in
                guard let self = self else { return }
                self.actionInput.accept(.hideHUD)
                self.didUpdateTitle(meta: meta, newTitle: newTitle)
            } onError: { [weak self] error in
                DocsLogger.error("rename wiki node failed", error: error)
                guard let self = self else { return }
                let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                self.actionInput.accept(.showHUD(.failure(error.renameErrorDescription)))
            }
            .disposed(by: disposeBag)
    }

    private func didUpdateTitle(meta: WikiTreeNodeMeta, newTitle: String) {
        dataModel.syncTitleUpdata(wikiToken: meta.wikiToken, newTitle: newTitle)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                DocsLogger.info("handle title update sync event success")
                self?.treeStateRelay.accept(state)
            } onError: { error in
                DocsLogger.error("handle title update sync event failed", error: error)
            } onCompleted: {
                DocsLogger.info("handle title update sync event complete without update")
            }
            .disposed(by: disposeBag)
    }
}
