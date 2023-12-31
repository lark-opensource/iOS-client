//
//  MinutesStatisticsTitleView.swift
//  Minutes
//
//  Created by sihuahao on 2021/6/29.
//

import Foundation
import MinutesFoundation
import UniverseDesignIcon

protocol MinutesCloseMoreInfoPanelDelegate: AnyObject {
    func closePanel()
}

class MinutesStatisticsTitleView: UIView {
    weak var delegate: MinutesCloseMoreInfoPanelDelegate?

    private lazy var singleTopLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.text = BundleI18n.Minutes.MMWeb_G_MoreDetails_MenuTitle
        label.numberOfLines = 1
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton()
        let image = UDIcon.getIconByKey(.closeSmallOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24))

        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(onBtnClose), for: .touchUpInside)
        return button
    }()

    private lazy var separatorView: UIView = {
        let view: UIView = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        addSubview(singleTopLabel)
        addSubview(separatorView)
        addSubview(closeButton)

        singleTopLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(14)
            maker.centerX.equalToSuperview()
            maker.height.equalTo(24)
        }

        closeButton.snp.makeConstraints { maker in
            maker.left.equalToSuperview().offset(16)
            maker.centerY.equalTo(singleTopLabel)
            maker.width.height.equalTo(24)
        }

        separatorView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(48)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(0.5)
        }
    }
    @objc
    func onBtnClose() {
        self.delegate?.closePanel()
    }
}
