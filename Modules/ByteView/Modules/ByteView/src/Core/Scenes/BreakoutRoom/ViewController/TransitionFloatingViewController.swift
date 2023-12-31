//
//  TransitionFloatingViewController.swift
//  ByteView
//
//  Created by wulv on 2021/3/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import UniverseDesignIcon

class TransitionFloatingViewController: VMViewController<TransitionViewModel> {

    // MARK: UI
    private lazy var trasitionIcon: UIImageView = {
        let image = BundleResources.ByteView.Meet.iconBreakoutroomsSolid.ud.withTintColor(.ud.N400)
        let imageView = UIImageView.init(image: image)
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 3
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    // MARK: bindViewModel
    override func bindViewModel() {
        viewModel.floatingTitleDriver
            .map { (title: String?) -> NSAttributedString? in
                guard let title = title else { return nil }
                return NSAttributedString(string: title, config: .tinyAssist, alignment: .center)
            }
            .drive(titleLabel.rx.attributedText)
            .disposed(by: rx.disposeBag)
    }

    override func setupViews() {
        view.backgroundColor = UIColor.ud.bgFloat
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview().offset(Layout.ContentMaxHeight / 2)
            maker.left.equalToSuperview().inset(Layout.MarginLeft)
            maker.right.equalToSuperview().inset(Layout.MarginRight)
        }

        view.addSubview(trasitionIcon)
        trasitionIcon.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(titleLabel.snp.top).offset(-Layout.VerticalGap)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.updateMediaStatus(.muteAll)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.updateMediaStatus(.normal)
    }

    private enum Layout {
        static var MarginRight: CGFloat = 4
        static var MarginLeft: CGFloat = 4
        static let ContentMaxHeight: CGFloat = 36
        static let VerticalGap: CGFloat = 8
    }
}
