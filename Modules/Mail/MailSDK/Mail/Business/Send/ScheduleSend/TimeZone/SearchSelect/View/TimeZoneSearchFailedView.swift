//
//  TimeZoneSearchFailedView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/17.
//

import UIKit
import SnapKit
import LarkUIKit

/// 搜索失败（服务不可用，譬如网路问题，或者 server 问题）
final class TimeZoneSearchFailedView: UIView {

    private lazy var iconImageView: UIImageView = {
        let theView = UIImageView()
        theView.image = LarkUIKit.Resources.load_fail
        return theView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
         label.text = BundleI18n.MailSDK.Mail_Edit_FindTimeFailed
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    var title: String? {
        didSet { titleLabel.text = title }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(iconImageView)
        addSubview(titleLabel)

        iconImageView.snp.makeConstraints {
            $0.size.equalTo(125)
            $0.top.equalToSuperview().offset(50)
            $0.centerX.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(self.snp.top).offset(185)
            $0.centerX.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
