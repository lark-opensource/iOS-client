//
//  ForwardLingoAlertConfig.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/25.
//

import LarkMessengerInterface
import LarkSDKInterface
import EENavigator

final class ForwardLingoAlertConfig: ForwardAlertConfig {

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ForwardLingoAlertContent != nil {
            return true
        }
        return false
    }

    override func getContentView() -> UIView? {
        guard let textContent = content as? ForwardLingoAlertContent  else {
            return nil
        }
        let wrapperView = UIView()
        wrapperView.backgroundColor = UIColor.ud.bgFloatOverlay
        wrapperView.layer.cornerRadius = 5
        let titleLabel = UILabel()
        let contentLabel = UILabel()
        contentLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        contentLabel.numberOfLines = 4
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        contentLabel.lineBreakMode = .byTruncatingTail
        titleLabel.textColor = UIColor.ud.textTitle
        contentLabel.textColor = UIColor.ud.iconN1
        wrapperView.addSubview(titleLabel)
        wrapperView.addSubview(contentLabel)
        if textContent.title.isEmpty {
            contentLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(10)
            }
            contentLabel.text = textContent.content
        } else {
            titleLabel.snp.makeConstraints { make in
                make.left.right.top.equalToSuperview().inset(10)
            }
            contentLabel.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview().inset(10)
                make.top.equalTo(titleLabel.snp.bottom).offset(4)
            }
            titleLabel.text = textContent.title
            contentLabel.text = textContent.content
        }
        return wrapperView
    }
}
