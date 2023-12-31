//
//  SearchShareDocumentViewController+MaskView.swift
//  ByteView
//
//  Created by weiyuning on 2019/12/25.
//

import UIKit
import RxSwift
import RxCocoa

extension SearchShareDocumentsViewController {
    func bindMaskViewHidden() {
        searchBar.editingDidBegin = { [weak self] isEmpty in
            self?.searchResultMaskView.isHidden = !isEmpty
        }
        searchBar.editingDidEnd = { [weak self] _ in
            self?.searchResultMaskView.isHidden = true
        }
        searchBar.tapCancelButton = { [weak self] in
            self?.searchResultMaskView.isHidden = true
        }
        searchBar.tapClearButton = { [weak self] isEditing in
            self?.searchResultMaskView.isHidden = !isEditing
        }
    }

    func bindMaskViewTap() {
        maskSearchViewTap.rx.event
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.searchBar.resetSearchBar()
                self?.searchBar.cancelButton.isHidden = true
                self?.searchResultMaskView.isHidden = true
            })
            .disposed(by: rx.disposeBag)
    }
}
