//
//  MailBaseLoadingView.swift
//  MailSDK
//
//  Created by Ender on 2021/11/29.
//

import UIKit
import UniverseDesignLoading

class MailBaseLoadingView: UIView {
    var text: String = "" {
        didSet {
            label.text = self.text
        }
    }

    let container = UIView()
    var logo : UIView?
    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.ud.bgBody

        // container
        self.addSubview(container)
        container.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        logo = UDLoading.loadingImageView()
        guard let logo = logo else { return }
        // logo
        container.addSubview(logo)
        logo.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 125, height: 125))
            make.top.centerX.equalToSuperview()
        }

        // text
        label.text = BundleI18n.MailSDK.Mail_Toast_Loading
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.numberOfLines = 0
        container.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.width.lessThanOrEqualTo(250)
            make.centerX.equalToSuperview()
            make.top.equalTo(logo.snp.bottom).offset(16)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func play() {
        self.isHidden = false
        self.alpha = 1.0
        logo?.removeFromSuperview()
        

        logo = UDLoading.loadingImageView()
        guard let logo = logo else { return }
        container.addSubview(logo)

        // logo
        logo.snp.remakeConstraints { (make) in
            make.size.equalTo(CGSize(width: 125, height: 125))
            make.top.centerX.equalToSuperview()
        }

        // text
        label.snp.remakeConstraints { (make) in
            make.width.lessThanOrEqualTo(250)
            make.centerX.equalToSuperview()
            make.top.equalTo(logo.snp.bottom).offset(16)
            make.bottom.equalToSuperview()
        }
    }
    func stop() {
        self.isHidden = true
        logo?.removeFromSuperview()
        logo = nil
    }
}
