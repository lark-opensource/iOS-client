//
//  WikiTreeMoreProvider + Rename.swift
//  SKWikiV2
//
//  Created by majie.7 on 2022/9/26.
//

import Foundation
import SKFoundation
import SKResource
import SKCommon
import RxCocoa
import RxSwift
import UniverseDesignDialog
import UniverseDesignColor

extension WikiMainTreeMoreProvider {
    
    public func renameHandler(meta: WikiTreeNodeMeta) {
        //drive文件禁止修改后缀名，直接屏蔽掉
        let fileName = SKFilePath.getFileNamePrefix(name: meta.title)
        let fileExtension = SKFilePath.getFileExtension(from: meta.title)
        
        let text = meta.objType == .file ? fileName : meta.title
        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: BundleI18n.SKResource.Doc_Facade_Rename, inputView: true)
        dialog.addTextField(placeholder: BundleI18n.SKResource.Doc_More_RenameSheetPlaceholder, text: text)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: {
            DocsLogger.info("user cancel rename in wiki tree")
        })
        let button = dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Ok, dismissCompletion: { [weak dialog, weak self] in
            guard var name = dialog?.textField.text, !name.isEmpty else { return }
            if let fileExtension = fileExtension, meta.objType == .file {
                name += "." + fileExtension
            }
            self?.confirmRename(meta: meta, newTitle: name)
        })
        dialog.bindInputEventWithConfirmButton(button, initialText: fileName)
        actionInput.accept(.present(provider: { _ in
            return dialog
        }))
    }
    
    private func confirmRename(meta: WikiTreeNodeMeta, newTitle: String) {
        actionInput.accept(.showHUD(.loading))
        WikiMoreAPI.rename(meta: meta, newTitle: newTitle)
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
        moreActionInput.accept(.updateTitle(wikiToken: meta.wikiToken, newTitle: newTitle))
    }
}
