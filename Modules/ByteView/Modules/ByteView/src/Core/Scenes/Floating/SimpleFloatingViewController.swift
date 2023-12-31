//
//  SimpleFloatingViewController.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/7/1.
//

import UIKit
import UniverseDesignIcon
import UniverseDesignColor

/// 仅展示一个通话 icon 和通话时间或通话状态的小窗，包括：
/// 企业办公电话直呼场景下的呼叫中、
/// 企业办公电话直呼 1v1
class SimpleFloatingViewController: VMViewController<SimpleFloatingViewModel> {

    private lazy var content = FloatingHintView.makeCallHintView()
    private var statusLabel: UILabel {
        content.hintLabel
    }

    override func setupViews() {
        view.backgroundColor = .clear

        let containerView = UIView()
        containerView.applyFloatingBGAndBorder()
        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        containerView.addSubview(content)

        content.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func bindViewModel() {
        super.bindViewModel()
        viewModel.delegate = self
        statusTextDidChange(viewModel.statusText)
    }
}

extension SimpleFloatingViewController: SimpleFloatingViewModelDelegate {
    func statusTextDidChange(_ text: String) {
        statusLabel.text = text
    }
}
