//
//  ZoomHostSearchingView.swift
//  Calendar
//
//  Created by pluto on 2022/11/1.
//

import UIKit
import Foundation
import UniverseDesignIcon
import UniverseDesignColor

final class ZoomHostSearchingView: UIView {

    var selectCallback: ((String) -> Void)?

    private lazy var bgBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(tapToSelectEmail), for: .touchUpInside)
        return button
    }()

    private lazy var emailIcon: UIImageView = {
        let img = UIImageView()
        img.image = UDIcon.getIconByKey(.mailOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 20, height: 20))
        img.backgroundColor = .clear
        return img
    }()

    private lazy var emailBgView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        view.backgroundColor = UIColor.ud.primaryContentDefault
        return view
    }()

    private lazy var emailAddress: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    init() {
        super.init(frame: .zero)
        layoutEmailView()
        backgroundColor = UIColor.ud.bgFloat
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutEmailView() {
        addSubview(bgBtn)
        bgBtn.addSubview(emailBgView)
        emailBgView.addSubview(emailIcon)
        bgBtn.addSubview(emailAddress)

        bgBtn.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(66)
        }

        emailBgView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(40)
            make.centerY.equalToSuperview()
        }

        emailIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }

        emailAddress.snp.makeConstraints { make in
            make.left.equalTo(emailBgView.snp.right).offset(12)
            make.centerY.equalTo(emailIcon)
            make.right.equalToSuperview()
        }
    }

    func updateEmailAddress(addr: String) {
        emailAddress.text = addr
    }

    @objc
    private func tapToSelectEmail() {
        if let addr = emailAddress.text {
            self.selectCallback?(addr)
        }
    }
}
