//
//  CommentFooterView.swift
//  SpaceKit
//
//  Created by xurunkang on 2018/10/25.
//

import UIKit
import RxSwift
import RxCocoa
import SpaceInterface

class CommentFooterView: UIView {

    weak var delegate: CommentFooterViewDelegate?

    weak var dependency: AtInputTextViewDependency?

    lazy var atInputTextView: AtInputTextView = {
        let tv = AtInputTextView(dependency: dependency, font: UIFont.systemFont(ofSize: 16), ignoreRotation: false)
        return tv
    }()

    private let disposeBag = DisposeBag()

    init(_ dependency: AtInputTextViewDependency?) {
        super.init(frame: .zero)

        self.dependency = dependency

        _setupUI()
        _setupBind()
    }

    override private init(frame: CGRect) {
        super.init(frame: frame)

        _setupUI()
        _setupBind()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CommentFooterView {
    private func _setupUI() {
        clipsToBounds = true
        backgroundColor = .clear

        addSubview(atInputTextView)
        atInputTextView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func _setupBind() {
        atInputTextView.isEditing
            .subscribe(onNext: { [weak self] isEditing in
                self?.delegate?.changeEditState(isEditing)
            }).disposed(by: disposeBag)

        atInputTextView.isShowingAtListView
            .subscribe(onNext: { [weak self] isShowing in
                guard let self = self else { return }
                self.delegate?.isShowingAtListView(isShowing: isShowing)
            }).disposed(by: disposeBag)
    }
}
