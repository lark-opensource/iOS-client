//
//  TenantAuthView.swift
//  LarkMine
//
//  Created by Hayden Wang on 2021/8/23.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignTheme

final class AuthTagView: UIView {

    enum AuthState {
        case none, auth, unauth
    }

    func setState(hasAuth: Bool, isAuth: Bool) {
        guard hasAuth else {
            state = .none
            return
        }
        state = isAuth ? .auth : .unauth
    }

    var state: AuthState = .none {
        didSet {
            setAuthAppearance()
        }
    }

    private lazy var container: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        return stack
    }()

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.image = UDIcon.verifyFilled.withRenderingMode(.alwaysTemplate)
        return imageView
    }()

    private lazy var authLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        layer.cornerRadius = 4
        layer.masksToBounds = true

        addSubview(container)
        container.addArrangedSubview(iconView)
        container.addArrangedSubview(authLabel)

        container.spacing = 4
        container.snp.makeConstraints { make in
            make.height.equalTo(18)
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(4)
            make.trailing.equalToSuperview().offset(-4)
        }
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(12)
        }
    }

    private func setAuthAppearance() {
        switch state {
        case .none:
            isHidden = true
        case .auth:
            isHidden = false
            iconView.isHidden = false
            authLabel.text = BundleI18n.LarkMine.Lark_FeishuCertif_Verif
            backgroundColor = UIColor.ud.udtokenTagBgTurquoise
            authLabel.textColor = UIColor.ud.udtokenTagTextSTurquoise
            iconView.tintColor = UIColor.ud.udtokenTagTextSTurquoise
        case .unauth:
            isHidden = false
            iconView.isHidden = true
            authLabel.text = BundleI18n.LarkMine.Lark_FeishuCertif_Unverif
            backgroundColor = UIColor.ud.udtokenTagNeutralBgNormal
            authLabel.textColor = UIColor.ud.textCaption
            iconView.tintColor = UIColor.ud.N600
        }
    }
}
