//
//  MinutesRefreshNoticeView.swift
//  Minutes
//
//  Created by lvdaqian on 2021/4/27.
//

import Foundation
import UniverseDesignColor
import SnapKit
import UniverseDesignColor

class MinutesRefreshNoticeView: UIView {
    let title: String

    var refreshHandler: (() -> Void)?

    init(_ title: String) {
        self.title = title
        super.init(frame: .zero)
        setupSubViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var icon: UIImageView = {
        let image = UIImage.dynamic(light: BundleResources.Minutes.minutes_audio_colorful_light,
                                    dark: BundleResources.Minutes.minutes_audio_colorful_dark)
        let imageView = UIImageView(image: image)
        return imageView
    }()
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.text = title
        return label
    }()
    lazy var dealLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.ud.textCaption
        label.text = BundleI18n.Minutes.MMWeb_G_RecordFinishedProcessing("").trimmingCharacters(in: .whitespaces)
        return label
    }()

    lazy var refreshButton: UIButton = {
        let button = UIButton(type: .custom, padding: 20)
        button.setTitle(BundleI18n.Minutes.MMWeb_G_RefreshPage, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.addTarget(self, action: #selector(onRefresh), for: .touchUpInside)
        return button
    }()

    var titleFirst: Bool {
        return BundleI18n.Minutes.MMWeb_G_RecordFinishedProcessing("+").starts(with: "+")
    }

    func setupSubViews() {
        backgroundColor = UIColor.ud.bgFloat
        layer.borderWidth = 0.5
        layer.cornerRadius = 8
        layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        layer.shadowOffset = CGSize(width: 0, height: 4)

        let shadowColor = UIColor.ud.N900.withAlphaComponent(0.15) & UIColor.clear
        layer.ud.setShadowColor(shadowColor)
        layer.shadowOpacity = 1
        clipsToBounds = false

        addSubview(icon)
        addSubview(titleLabel)
        addSubview(dealLabel)
        addSubview(refreshButton)

        icon.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.left.equalToSuperview().inset(14)
        }

        refreshButton.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview().inset(20)
        }

        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let firstLabel: UILabel
        let secondLabel: UILabel

        if titleFirst {
            firstLabel = titleLabel
            secondLabel = dealLabel
        } else {
            firstLabel = dealLabel
            secondLabel = titleLabel
        }

        firstLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.left.equalTo(icon.snp.right).offset(10)
        }

        secondLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.left.equalTo(titleLabel.snp.right).offset(8)
            maker.right.lessThanOrEqualTo(refreshButton.snp.left).offset(-16)
        }
    }

    @objc
    func onRefresh() {
        refreshHandler?()
    }
}
