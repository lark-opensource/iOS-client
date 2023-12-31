//
//  AddContactNoResultView.swift
//  LarkContact
//
//  Created by ChalrieSu on 2018/9/14.
//

import Foundation
import UIKit

final class AddContactNoResultView: UIView {
    var bottomButtonClickedBlock: ((AddContactNoResultView) -> Void)?

    private let bottomButton = UIButton()
    private let icon = UIImageView()
    private let topLabel = UILabel()

    init(enableInviteFriends: Bool) {
        super.init(frame: .zero)

        // 图标
        icon.image = Resources.invite_search_empty
        addSubview(icon)

        topLabel.text = BundleI18n.LarkContact.Lark_Legacy_UserNotFound
        topLabel.textColor = UIColor.ud.N500
        topLabel.font = UIFont.systemFont(ofSize: 16)
        addSubview(topLabel)

        icon.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
        })

        topLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(icon.snp.bottom).offset(10)
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        if enableInviteFriends {
            bottomButton.setTitle(BundleI18n.LarkContact.Lark_Legacy_InviteToUserLark(), for: .normal)
            bottomButton.setTitleColor(UIColor.ud.N00, for: .normal)
            bottomButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
            bottomButton.layer.cornerRadius = 4
            bottomButton.backgroundColor = UIColor.ud.colorfulBlue
            addSubview(bottomButton)
            bottomButton.addTarget(self, action: #selector(bottomButtonDidClick), for: .touchUpInside)
            bottomButton.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.equalTo(topLabel.snp.bottom).offset(22)
                make.bottom.equalToSuperview()
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)

                make.height.equalTo(48)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func bottomButtonDidClick() {
        bottomButtonClickedBlock?(self)
    }
}
