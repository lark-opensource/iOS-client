//
//  ShareContentScreenOrWhiteboardCell.swift
//  ByteView
//
//  Created by liurundong.henry on 2021/9/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import UniverseDesignIcon
import RxSwift
import RxCocoa

enum ShareTypeInMeet {
    case shareScreen
    case whiteboard
}

class ShareContentScreenOrWhiteboardCell: UITableViewCell {

    private lazy var shareIcon: UIImage = {
        switch shareType {
        case .shareScreen:
            let image: UIImage = UDIcon.getIconByKey(.shareScreenFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 16.0, height: 16.0))
            return image
        case .whiteboard:
            let image: UIImage = UDIcon.getIconByKey(.vcWhiteboardOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 16.0, height: 16.0))
            return image
        }
    }()
    private static let stopShareIcon: UIImage = UDIcon.getIconByKey(.stopRecordFilled, iconColor: UIColor.ud.functionDangerContentDefault, size: CGSize(width: 16.0, height: 16.0))

    var tapShareClosure: (() -> Void)?
    var shareType: ShareTypeInMeet = .shareScreen
    var shouldShowEmptyView: Bool = false

    private let backgroundButton: UIButton = {
        let button = UIButton()
        button.vc.setBackgroundColor(UIColor.ud.bgFloat, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.N900.withAlphaComponent(0.1), for: .highlighted)
        button.layer.cornerRadius = 10.0
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = shareIcon
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(string: "", config: .body)
        label.textColor = UIColor.ud.textTitle
        label.isUserInteractionEnabled = false
        return label
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 12.0
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    private lazy var emptyView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.isHidden = !shouldShowEmptyView
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.ud.bgFloatBase
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = UIColor.ud.bgFloatBase
        self.selectedBackgroundView = selectedBackgroundView
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        contentView.addSubview(backgroundButton)
        contentView.addSubview(stackView)
        contentView.addSubview(emptyView)
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(infoLabel)
        iconImageView.contentMode = .center
        iconImageView.vc.setSquircleMask(cornerRadius: 8, rect: CGRect(x: 0, y: 0, width: 28, height: 28))
        switch shareType {
        case .shareScreen:
            iconImageView.backgroundColor = UIColor.ud.G500
        case .whiteboard:
            iconImageView.backgroundColor = UIColor.ud.primaryPri500
        }
        backgroundButton.snp.makeConstraints { maker in
            maker.top.left.right.equalToSuperview()
            if shouldShowEmptyView {
                maker.height.equalTo(56)
            } else {
                maker.bottom.equalToSuperview()
            }
        }
        stackView.snp.makeConstraints { maker in
            maker.center.equalTo(backgroundButton.snp.center)
        }
        iconImageView.snp.makeConstraints { maker in
            maker.size.equalTo(CGSize(width: 28.0, height: 28.0))
        }
        infoLabel.snp.makeConstraints { maker in
            maker.height.equalTo(24.0)
        }
        backgroundButton.addTarget(self, action: #selector(tapShareScreen), for: .touchUpInside)
        emptyView.snp.makeConstraints { maker in
            maker.left.right.bottom.equalToSuperview()
            maker.height.equalTo(shouldShowEmptyView ? 20 : 0)
        }
    }

    func configAppearance(with imageDriver: Driver<UIImage?>, imageBgDriver: Driver<UIColor>, title: Driver<String>, titleColor: Driver<UIColor>? = nil) {
        imageDriver.drive(iconImageView.rx.image)
            .disposed(by: rx.disposeBag)
        imageBgDriver.drive(iconImageView.rx.backgroundColor)
            .disposed(by: rx.disposeBag)
        title.map { NSAttributedString(string: $0, config: .body) }
            .drive(infoLabel.rx.attributedText)
            .disposed(by: rx.disposeBag)
        if let titleColorDriver = titleColor {
            titleColorDriver.drive(onNext: { [weak self] color in
                self?.infoLabel.textColor = color
            })
            .disposed(by: rx.disposeBag)
        }
    }

    func configEmptyView(shouldShowEmptyView: Bool) {
        self.shouldShowEmptyView = shouldShowEmptyView
        backgroundButton.snp.remakeConstraints { maker in
            maker.top.left.right.equalToSuperview()
            if shouldShowEmptyView {
                maker.height.equalTo(56)
            } else {
                maker.bottom.equalToSuperview()
            }
        }
        emptyView.snp.remakeConstraints { maker in
            maker.left.right.bottom.equalToSuperview()
            if shouldShowEmptyView {
                maker.height.equalTo(20)
            } else {
                maker.height.equalTo(0)
            }
        }
        emptyView.isHidden = !shouldShowEmptyView
    }

    @objc
    func tapShareScreen() {
        tapShareClosure?()
    }

}
