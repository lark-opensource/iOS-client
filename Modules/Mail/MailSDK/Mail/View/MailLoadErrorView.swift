//
//  MailLoadErrorView.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2020/5/12.
//

import UIKit

class MailLoadErrorView: UIView {

    private let retryHandler: (() -> Void)

    init(frame: CGRect, retryHandler: @escaping (() -> Void)) {
        self.retryHandler = retryHandler
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        let errorIcon = UIImageView()
        errorIcon.image = Resources.feed_error_icon
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textCaption
        label.text = BundleI18n.MailSDK.Mail_Common_NetworkError
        label.textAlignment = .center
        [errorIcon, label].forEach {
            addSubview($0)
        }
        errorIcon.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-Display.topSafeAreaHeight - Display.realNavBarHeight())
            make.width.equalTo(125)
            make.height.equalTo(125)
        }
        label.snp.makeConstraints { (make) in
            make.top.equalTo(errorIcon).offset(10 + 125)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(20)
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.onClick))
        tapGesture.numberOfTouchesRequired = 1
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGesture)
    }

    @objc
    func onClick() {
        retryHandler()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
