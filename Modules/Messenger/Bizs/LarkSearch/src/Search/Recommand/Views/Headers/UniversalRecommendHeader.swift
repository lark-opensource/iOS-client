//
//  UniversalRecommendHeader.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/12.
//

import Foundation
import UIKit

protocol UniversalRecommendHeaderProtocol: UITableViewHeaderFooterView {
    func setup(withViewModel viewModel: UniversalRecommendHeaderPresentable)
}

final class UniversalRecommendChipHeader: UITableViewHeaderFooterView, UniversalRecommendHeaderProtocol {
    private let titleLabel = UILabel()
    private let clearButton = UIButton()

    private var clearButtonAction: (() -> Void)?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        // NOTE: UITableViewHeaderFooterView.backgroundColor is not work.
        // use contentView backgroundColor or backgroundView
        contentView.backgroundColor = UIColor.ud.bgBase
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = UIColor.ud.N900

        clearButton.setImage(Resources.search_clear_history.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.imageView?.tintColor = UIColor.ud.N500
        clearButton.addTarget(self, action: #selector(touch(clearButton:)), for: .touchUpInside)

        // layout
        contentView.addSubview(titleLabel)
        contentView.addSubview(clearButton)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(20)
            make.left.equalToSuperview().inset(4)
        }
        clearButton.snp.makeConstraints { (make) in
            make.right.equalTo(-4)
            make.centerY.equalTo(titleLabel)
        }
    }

    func setup(withViewModel viewModel: UniversalRecommendHeaderPresentable) {
        guard let vm = viewModel as? UniversalRecommendChipHeaderPresentable else { return }
        titleLabel.text = vm.title
        clearButtonAction = vm.didClickClearButton
        clearButton.isHidden = vm.shouldHideClickButton
    }

    @objc
    private func touch(clearButton: UIButton) {
        clearButtonAction?()
    }
}

final class UniversalRecommendCardHeader: UniversalRecommendBaseHeader, UniversalRecommendHeaderProtocol {
    static var foldAnimationTime: TimeInterval { return 0.3 }
    private lazy var foldIcon: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(Resources.icon_down_outlined.withRenderingMode(.alwaysOriginal), for: .normal)
        button.imageView?.tintColor = UIColor.ud.iconN3
        button.imageEdgeInsets = UIEdgeInsets(horizontal: 16, vertical: 12)
        button.addTarget(self, action: #selector(touch(foldButton:)), for: .touchUpInside)
        return button
    }()

    private var didClickFoldButton: (() -> Void)?

    private(set) var isFold: Bool = true {
        didSet {
            guard oldValue != isFold else { return }
            setupFoldStatus()
        }
    }

    private func setupFoldStatus() {
        UIView.animate(withDuration: Self.foldAnimationTime) { [weak self] in
            guard let self = self else { return }
            if self.isFold {
                self.foldIcon.transform = .identity
            } else {
                let pi: CGFloat = 3.14159
                let transform = CGAffineTransform(rotationAngle: -pi)
                self.foldIcon.transform = transform
            }
        }
    }

    override func setupView() {
        super.setupView()

        container.addSubview(foldIcon)

        foldIcon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(14 + 16 * 2)
            make.right.equalToSuperview()
        }
    }

    func setup(withViewModel viewModel: UniversalRecommendHeaderPresentable) {
        guard let vm = viewModel as? UniversalRecommendCardHeaderPresentable else { return }
        setTitle(vm.title)
        isFold = vm.isFold
        didClickFoldButton = vm.didClickFoldButton
        foldIcon.isHidden = !vm.shouldShowFoldButton
    }

    // button event

    @objc
    private func touch(foldButton: UIButton) {
        self.isFold = !isFold
        didClickFoldButton?()
    }
}

final class UniversalRecommendListHeader: UniversalRecommendBaseHeader, UniversalRecommendHeaderProtocol {

    override func setupView() {
        super.setupView()

    }

    func setup(withViewModel viewModel: UniversalRecommendHeaderPresentable) {
        setTitle(viewModel.title)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setTitle("")
    }

}
