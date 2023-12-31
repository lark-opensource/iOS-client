//
//  ForwardTextAlertConfig.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/24.
//

import LarkMessengerInterface

final class ForwardTextAlertConfig: ForwardAlertConfig {
    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ForwardTextAlertContent != nil {
            return true
        }
        return false
    }
    override func getContentView() -> UIView? {
        guard let textContent = content as? ForwardTextAlertContent  else {
            return nil
        }
        let wrapperView = UIView()
        wrapperView.backgroundColor = UIColor.ud.bgFloatOverlay
        wrapperView.layer.cornerRadius = 5
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 4
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.ud.iconN1
        wrapperView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        }
        label.text = textContent.text
        return wrapperView
    }
}
