//
//  DetailTopModule.swift
//  Todo
//
//  Created by 张威 on 2021/5/10.
//

import RxSwift
import RxCocoa
import LarkUIKit
import UIKit

/// Detail - Top - Module

// nolint: magic number
final class DetailTopModule: DetailBaseModule {
    private lazy var containerView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        return view
    }()
    private lazy var noticeView = DetailTopNoticeView()
    private let disposeBag = DisposeBag()
    private var containerIsHidden: Bool {
        return noticeView.isHidden
    }

    override func setup() {
        setupViews()
        bindViewState()
        bindEvent()
    }

    override func loadView() -> UIView {
        return containerView
    }

    private func bindViewState() {
        noticeView.rx.observe(Bool.self, #keyPath(UIView.isHidden))
        .subscribe(onNext: { [weak self] (value) in
            self?.view.isHidden = value ?? true
        })
        .disposed(by: disposeBag)

    }

    private func setupViews() {
        containerView.addArrangedSubview(noticeView)
        noticeView.isHidden = true
    }

    private func bindEvent() {
        // bind bus event
        context.bus.subscribe { [weak self] action in
            switch action {
            case .showNotice(let config):
                self?.showNotice(with: config)
            default: break
            }
        }
        .disposed(by: disposeBag)
    }

    private func showNotice(with config: Context.Event.NoticeConfig) {
        guard !config.text.isEmpty else { return }
        noticeView.config = config
        view.superview?.setNeedsLayout()
    }

}
