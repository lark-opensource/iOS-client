//
//  MoreLoginOptionLineView.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2020/2/27.
//

import UIKit

extension MoreLoginOptionLineView {
    struct Layout {
        static let topLabelPadding: CGFloat = 8.0
        static let lineHeight: CGFloat = 1
        static let buttonBottom: CGFloat = 20
        static let internalSpace: CGFloat = 4
        static let bottomButtonHeight: CGFloat = 48
        static let buttonBottomSpace: CGFloat = 12
        static let noJoinMettingBottomSapce: CGFloat = 8
        static let verticalItemSpace: CGFloat = 10
        static let buttonToTopLabelPadding: CGFloat = 24
    }
}

class MoreLoginOptionLineView: UIView {

    let actions: BottomAction
    let idpButtons: [UIButton]

    init(_ actions: BottomAction, idpButtons: [UIButton]) {
        self.actions = actions
        self.idpButtons = idpButtons
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var leftLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.lineDividerDefault
        return v
    }()

    lazy var rightLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.lineDividerDefault
        return v
    }()

    lazy var topLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = I18N.Lark_Login_V3_Or
        lbl.font = .systemFont(ofSize: 12, weight: .regular)
        lbl.textColor = UIColor.ud.textPlaceholder
        return lbl
    }()

    /// 企业登录
    lazy var enterpriseLoginButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitleColor(UIColor.ud.textTitle, for: .normal)
        btn.setupBottonActionStyle()
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.setImage(Resource.EnterpriseLogin.enterprise_login_icon, for: .normal)
        btn.imageRect(forContentRect: CGRect(x: 0, y: 0, width: 24, height: 24))
        btn.setImage(Resource.EnterpriseLogin.enterprise_login_icon_highlighted, for: .highlighted)
        return btn
    }()

    lazy var joinTeamButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.setTitleColor(UIColor.ud.textTitle, for: .normal)
        btn.setupBottonActionStyle()
        return btn
    }()

    func setupViews() {
        addSubview(leftLine)
        addSubview(rightLine)
        addSubview(topLabel)

        if actions.contains(.joinTeam) {
            addSubview(joinTeamButton)
            joinTeamButton.snp.makeConstraints { (make) in
                make.top.equalToSuperview()
                make.bottom.equalTo(topLabel.snp.top).offset(-Layout.buttonToTopLabelPadding)
                make.left.right.equalToSuperview()
                make.height.equalTo(Layout.bottomButtonHeight).priority(.required)
            }
        }

        leftLine.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.height.equalTo(Layout.lineHeight)
            make.centerY.equalTo(topLabel)
            make.right.equalTo(topLabel.snp.left).offset(-Layout.topLabelPadding)
        }

        rightLine.snp.makeConstraints { (make) in
            make.left.equalTo(topLabel.snp.right).offset(Layout.topLabelPadding)
            make.height.equalTo(Layout.lineHeight)
            make.centerY.equalTo(topLabel)
            make.right.equalToSuperview()
        }

        topLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            if !actions.contains(.joinTeam) {
                make.top.equalToSuperview()
            }
            if !actions.contains(.enterpriseLogin) && idpButtons.isEmpty {
                make.bottom.equalToSuperview()
            }
        }

        if actions.contains(.enterpriseLogin) {
            addSubview(enterpriseLoginButton)
        }

        let buttonCount: Int = idpButtons.count
        if buttonCount == 0 {
            if actions.contains(.enterpriseLogin) {
                enterpriseLoginButton.snp.makeConstraints { (make) in
                    make.top.equalTo(topLabel.snp.bottom).offset(Layout.verticalItemSpace)
                    make.left.right.equalToSuperview()
                    make.height.equalTo(Layout.bottomButtonHeight)
                    make.bottom.equalToSuperview().offset(-Layout.buttonBottomSpace)
                }
            }
        } else {
            // e.g. Sign in with Apple & Google
            // 一行一个，从下往上排
            var bottomOffset: CGFloat = 8
            let bottomButtonCount = (actions.contains(.enterpriseLogin) ? 1 : 0) + idpButtons.count
            
            for (index, button) in idpButtons.reversed().enumerated() {
                addSubview(button)
                // 60 = 48 button height + 12 padding
                let enterpriseLoginSpacing = actions.contains(.enterpriseLogin) ? 60 : 0
                let topSpacing = CGFloat((bottomButtonCount - index - 1) * 60) + Layout.buttonToTopLabelPadding
                button.snp.makeConstraints { make in
                    make.bottom.equalToSuperview().offset(-bottomOffset)
                    make.top.equalTo(topLabel.snp.bottom).offset(topSpacing)
                    make.left.right.equalToSuperview()
                    make.height.equalTo(Layout.bottomButtonHeight)
                }
                bottomOffset = bottomOffset + Layout.bottomButtonHeight + Layout.buttonBottomSpace
            }
            if actions.contains(.enterpriseLogin) {
                enterpriseLoginButton.snp.makeConstraints { make in
                    make.bottom.equalToSuperview().offset(-bottomOffset)
                    make.left.right.equalToSuperview()
                    make.height.equalTo(Layout.bottomButtonHeight)
                    make.top.equalTo(topLabel.snp.bottom).offset(Layout.buttonToTopLabelPadding)
                }
            }
        }
    }

    func updateLocale() {
        topLabel.text = I18N.Lark_Login_V3_More_Login_Options
        topLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        if actions.contains(.enterpriseLogin) {
            enterpriseLoginButton.setTitle(I18N.Lark_Passport_GoogleUserSignInOption_SSO, for: .normal)
            enterpriseLoginButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        }
        if actions.contains(.joinTeam) {
            joinTeamButton.setTitle(I18N.Lark_Login_V3_Join_Exist_Team, for: .normal)
            joinTeamButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        }
    }

}

extension UIButton {
    func setupBottonActionStyle() {
        setTitleColor(UIColor.ud.textTitle, for: .normal)
        setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.fillPressed), for: .highlighted)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: MoreLoginOptionLineView.Layout.internalSpace, bottom: 0, right: 0)
        imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: MoreLoginOptionLineView.Layout.internalSpace)
        titleLabel?.font = UIFont.systemFont(ofSize: 17)
        clipsToBounds = true
        layer.cornerRadius = 6
        layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        layer.borderWidth = 1
    }
}
