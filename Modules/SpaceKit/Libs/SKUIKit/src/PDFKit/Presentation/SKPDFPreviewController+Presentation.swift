//
//  SKPDFPreviewController+Presentation.swift
//  SpaceKit
//
//  Created by 邱沛 on 2020/4/3.
//

import Foundation
import RxSwift
import RxCocoa
import SKFoundation

extension SKPDFPreviewController {
    func setupPresentationView() {
        view.addSubview(presentationView)
        presentationView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        presentationView.addSwipe(.left) { [weak self] in
            self?.viewModel.goNextSubject.onNext(())
        }
        presentationView.addSwipe(.right) { [weak self] in
            self?.viewModel.goPreviousSubject.onNext(())
        }
        presentationView.addSwipe(.up) { [weak self] in
            self?.viewModel.goNextSubject.onNext(())
        }
        presentationView.addSwipe(.down) { [weak self] in
            self?.viewModel.goPreviousSubject.onNext(())
        }
        presentationView.closeAction
            .drive(onNext: { [weak self] in
                self?.viewModel.presentationModeChangedSubject.onNext((false, .click))
            })
            .disposed(by: disposeBag)
        updatePresentationCount(1)
    }

    public func updatePresentationCount(_ current: Int) {
        guard let document = self.document else {
            DocsLogger.warning("presentation view count did not changed due to no document")
            return
        }
        presentationView.titleRelay.accept("\(String(current))/\(String(document.pageCount))")
    }
    
    public func updatePresentationCloseTitle(_ title: String) {
        presentationView.closeTitleRelay.accept(title)
    }
}
