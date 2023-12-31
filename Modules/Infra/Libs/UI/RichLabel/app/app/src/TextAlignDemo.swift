//
//  TextAlignDemo.swift
//  LarkUIKitDemo
//
//  Created by qihongye on 2018/12/4.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import CoreText
import RichLabel

class TextAlignDemoViewController: UIViewController {
    lazy var label: LKLabel = {
        let label = LKLabel()
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.backgroundColor = UIColor.clear
        label.autoDetectLinks = true
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false

        label.textCheckingDetecotor = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue
            + NSTextCheckingResult.CheckingType.phoneNumber.rawValue)

        label.linkAttributes = [
                .foregroundColor: UIColor.blue.cgColor
        ]
        label.activeLinkAttributes = [
            LKBackgroundColorAttributeName: UIColor(white: 0, alpha: 0.1)
        ]
        return label
    }()

    @objc
    func redraw() {
        self.label.invalidateIntrinsicContentSize()
        self.label.setNeedsDisplay()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.label)
        self.label.preferredMaxLayoutWidth = self.view.frame.width - 20
        self.label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(20)
            make.left.equalTo(10)
            make.right.equalTo(-10)
        }

        let font = UIFont.systemFont(ofSize: 15)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 2
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineHeightMultiple = 0
        paragraphStyle.maximumLineHeight = 0
        paragraphStyle.minimumLineHeight = font.pointSize + 2
        let attrStr = NSMutableAttributedString(
            string: """
䶮Hi，经过数月的努力力，我们的Lark邮件https://www.baidu.com
""",
            attributes: [
                    .font: font,
                    .paragraphStyle: paragraphStyle
            ]
        )
        var range = NSRange(location: 0, length: 1)
        attrStr.addAttribute(LKPointAttributeName, value: UIColor.green, range: range)
        attrStr.addAttribute(LKPointRadiusAttributeName, value: 2, range: range)
        range.location = 2
        attrStr.addAttribute(LKPointAttributeName, value: UIColor.green, range: range)
        attrStr.addAttribute(LKPointRadiusAttributeName, value: 2, range: range)
        range.location = 5
        attrStr.addAttribute(LKPointAttributeName, value: UIColor.green, range: range)
        attrStr.addAttribute(LKPointRadiusAttributeName, value: 2, range: range)
        attrStr.addAttribute(
                .font,
            value: font.italicBold(),
            range: NSRange(location: 0, length: attrStr.length)
        )
        range.location = 14
        range.length = 6
        attrStr.addAttribute(LKAtAttributeName, value: UIColor.yellow, range: range)

        self.label.attributedText = attrStr

        self.title = "TextAlign Demo"

        self.view.backgroundColor = UIColor.white
    }
}
