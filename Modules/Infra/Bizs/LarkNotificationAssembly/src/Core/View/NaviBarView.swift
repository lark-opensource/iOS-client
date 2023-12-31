//
//  NaviBarView.swift
//  LarkNotificationAssembly
//
//  Created by aslan on 2023/12/14.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import SnapKit

final class NaviBarView: UIView {

    public lazy var closeButton: UIButton = {
        var button = UIButton()
        let closeIcon = UDIcon.closeSmallOutlined.ud.withTintColor(UIColor.ud.iconN1)
        button.setImage(closeIcon, for: .normal)
        return button
    }()

    public lazy var switchTenantButton: UIButton = {
        var button = UIButton()
        button.titleLabel?.textAlignment = .right
        button.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    public lazy var titleLabel: UILabel = {
        var label = UILabel()
        label.textAlignment = .center
        label.textColor = UDColor.textTitle
        label.font = UIFont.systemFont(ofSize: Layout.titleFontSize)
        return label
    }()

    public lazy var subTitleLabel: UILabel = {
        var label = UILabel()
        label.textAlignment = .center
        label.textColor = UDColor.textCaption
        label.font = UIFont.systemFont(ofSize: Layout.subTitleFontSize)
        return label
    }()

    private lazy var titleView: UIStackView = {
        var view = UIStackView()
        view.axis = .vertical
        view.spacing = 0
        view.alignment = .center
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.closeButton)
        self.addSubview(self.switchTenantButton)
        self.addSubview(self.titleView)
        self.titleView.addArrangedSubview(self.titleLabel)
        self.titleView.addArrangedSubview(self.subTitleLabel)

        self.closeButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Layout.padding)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: Layout.buttonSize, height: Layout.buttonSize))
        }

        self.switchTenantButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Layout.padding)
            make.centerY.equalToSuperview()
            make.height.equalTo(Layout.buttonSize)
        }

        self.titleView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(self.closeButton.snp.right).offset(Layout.padding)
            make.right.equalTo(self.switchTenantButton.snp.left).offset(-Layout.padding)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum Layout {
        static let titleFontSize: CGFloat = 17
        static let subTitleFontSize: CGFloat = 12
        static let padding: CGFloat = 14
        static let buttonSize: CGFloat = 24
        static let switchButtonWidth: CGFloat = 64
    }
}
