//
//  AlertTextView.swift
//  Calendar
//
//  Created by zhouyuan on 2018/12/25.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation

final class AlertTextView: UIView {

    private let textView: UITextView = {
        let view = UITextView()
        view.bounces = false
        view.isEditable = false
        view.isScrollEnabled = false
        view.textContainer.lineFragmentPadding = 0
        view.textContainerInset = .zero
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        self.layer.cornerRadius = 6.0
        self.addSubview(textView)
        self.textView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(30)
        }
    }

    func setText(text: String) {
        let attr = NSAttributedString(string: text, attributes: getTextAttributeds())
        self.textView.attributedText = attr
    }

    private func getTextAttributeds() -> [NSAttributedString.Key: Any] {
        let style = NSMutableParagraphStyle()
        // 这个场景textView使用的是16号字体，但是ux同学建议使用22的lineHeight
        let lineHeight: CGFloat = 22
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight

        return [.paragraphStyle: style,
                .foregroundColor: UIColor.ud.textTitle,
                .font: UIFont.cd.regularFont(ofSize: 16)]
    }

    func show() {
        self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        self.alpha = 0
        self.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
            self.transform = CGAffineTransform.identity
        }
    }

    func hide() {
        self.textView.resignFirstResponder()
        UIView.animate(withDuration: 0.25, animations: {
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.alpha = 0
        }) { (_) in
            self.isHidden = true
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
