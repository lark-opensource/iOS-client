//
//  CoverSelectLoadFailView.swift
//  SKDoc
//
//  Created by lizechuang on 2021/2/3.
//

import Foundation
import RxSwift
import UniverseDesignEmpty
import UniverseDesignColor
import UIKit

// TODO: UDEmpty 组件接入
class CoverSelectLoadFailView: UIView {

    let retryAction = PublishSubject<()>()
    lazy var imageView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .center
        imgView.image = UDEmptyType.loadingFailure.defaultImage()
        return imgView
    }()

    lazy var contentTextView: ActionableTextView = {
        let textView = ActionableTextView(frame: .zero)
        textView.backgroundColor = .clear
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.textColor = UIColor.ud.N600
        textView.text = BundleI18n.MailSDK.Mail_Cover_UnableLoadRetry(BundleI18n.MailSDK.Mail_Cover_MobileLoadAgain)
        textView.actionableText = BundleI18n.MailSDK.Mail_Cover_MobileLoadAgain
        textView.actionTextColor = .ud.colorfulBlue
        textView.action = { [weak self] in
            self?.retryAction.onNext(())
        }
        textView.updateAttributes()
        textView.textAlignment = .center
        return textView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = Display.pad ? UDColor.bgFloatBase : UDColor.bgContentBase
        addSubview(imageView)
        addSubview(contentTextView)
        imageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(196)
            make.width.height.equalTo(125)
        }
        contentTextView.sizeToFit()
        contentTextView.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.height.greaterThanOrEqualTo(UIFont.systemFont(ofSize: 14).lineHeight)
        }
    }
}
