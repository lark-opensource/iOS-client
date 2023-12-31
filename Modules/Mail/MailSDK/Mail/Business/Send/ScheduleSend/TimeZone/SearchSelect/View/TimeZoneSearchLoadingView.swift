//
//  TimeZoneSearchLoadingView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/17.
//

import UIKit
import SnapKit

final class TimeZoneSearchLoadingView: UIView {

    lazy var indicatorView: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
         label.text = BundleI18n.MailSDK.Mail_Common_LoadingCommon
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgFloat

        let wrapperView = UIView()
        addSubview(wrapperView)
        wrapperView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(13.5)
        }

        wrapperView.addSubview(titleLabel)
        wrapperView.addSubview(indicatorView)

        titleLabel.snp.makeConstraints {
            $0.right.top.bottom.equalToSuperview()
            $0.height.equalTo(20)
        }

        indicatorView.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.right.equalTo(titleLabel.snp.left).offset(-8)
            $0.centerY.equalTo(titleLabel)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
