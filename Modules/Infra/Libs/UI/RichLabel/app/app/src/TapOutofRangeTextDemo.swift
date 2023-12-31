//
//  TapOutofRangeTextDemo.swift
//  LarkUIKitDemo
//
//  Created by qihongye on 2018/12/7.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation

import UIKit
import SnapKit
import CoreText
import RichLabel

class TapOutofRangeTextDemoViewController: UIViewController {
    lazy var label: LKLabel = {
        let label = LKLabel()
        label.textColor = UIColor.black
        label.numberOfLines = 10
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

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.label)
        self.label.preferredMaxLayoutWidth = self.view.frame.width - 20
        self.label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(20)
            make.left.equalTo(10)
            make.right.equalTo(-10)
        }

        let font = UIFont(name: "Zapfino", size: 15)!
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = 2
        paragraphStyle.lineBreakMode = .byWordWrapping
        let attrStr = NSMutableAttributedString(
            string: """
🌕一1⃣️ Lark 邮件，也是一封权限邮件୧(๑•̀⌄•́๑)૭。目前Lark 邮件功能还处于内部测试期，由于它非常通用，容易扩散，所以我们做了一些隔离，以免影响用户的正常使用 Lark 。隔离方案详情如下：
1、Lark 允许给一个人或群会话发送邮件，https://docs.bytedance.net/doc/uhbY8I0Tz2mSubM4XVD1ja；
2、本邮件的收件人和抄送人列表是“Lark 邮件测试白名单”，是测试期间 Lark 邮件可发送的用户与群组范围，我们在测试Lark jaosdjfohqe23123；
3、如果给“Lark 邮件测试白名单”之外的用户或群组发送邮件，除了“发送者自己”之外的收件人会被系统自动过滤；
4、本邮件的收件人和抄送人有权限将其他群组或用户添加到“邮件参与者列表”，也就是说大家具备扩散 Lark 邮件的权限，但是最好不要添加非必要的大型群组，如“租房群”，这样可能会对群成员产生不必要的打扰；
""",
            attributes: [
                    .font: font,
                    .paragraphStyle: paragraphStyle
            ]
        )
        var range = NSRange(location: 0, length: 2)
        attrStr.addAttribute(LKPointAttributeName, value: UIColor.green, range: range)
        attrStr.addAttribute(LKPointRadiusAttributeName, value: 2, range: range)
        range.location = 3
        range.length = 3
        attrStr.addAttribute(LKPointAttributeName, value: UIColor.green, range: range)
        attrStr.addAttribute(LKPointRadiusAttributeName, value: 2, range: range)
        range.location = 7
        range.length = 1
        attrStr.addAttribute(LKPointAttributeName, value: UIColor.green, range: range)
        attrStr.addAttribute(LKPointRadiusAttributeName, value: 2, range: range)
        attrStr.addAttribute(
                .font,
            value: font.italicBold(),
            range: NSRange(location: 0, length: 10)
        )
        attrStr.addAttribute(
            LKGlyphTransformAttributeName,
            value: NSValue(
                cgAffineTransform: CGAffineTransform(
                    a: 1,
                    b: 0,
                    c: CGFloat(tanf(Float(15 * Double.pi / 180))),
                    d: 1,
                    tx: 0,
                    ty: 0
                )
            ),
            range: NSRange(location: 11, length: 10)
        )
        range.location = 14
        range.length = 4
        attrStr.addAttribute(LKAtAttributeName, value: UIColor.blue.withAlphaComponent(0.5), range: range)
        range.location = 245
        range.length = 21
        attrStr.addAttribute(.foregroundColor, value: UIColor.red, range: range)
        attrStr.addAttribute(.strikethroughColor, value: UIColor.purple, range: range)
        attrStr.addAttribute(.strikethroughStyle, value: NSNumber(integerLiteral: NSUnderlineStyle.single.rawValue), range: range)

        range.location = 100
        range.length = 100
        attrStr.addAttribute(.strikethroughColor, value: UIColor.purple, range: range)
        attrStr.addAttribute(.strikethroughStyle, value: NSNumber(integerLiteral: NSUnderlineStyle.single.rawValue), range: range)

        self.label.debug = LKTextRenderDebugOptions([.drawOutOfRangeTextRect, .drawGlyphRect])
        let outofRangeText = NSMutableAttributedString(string: LKLabelAttachmentPlaceHolderStr, attributes: [
            LKAttachmentAttributeName: LKAsyncAttachment(
                viewProvider: { () -> UIView in
                    let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
                    view.backgroundColor = .systemRed
                    return view
                },
                size: CGSize(width: 100, height: 100),
                verticalAlign: .middle
            )
        ])
        outofRangeText.append(NSAttributedString(string: "点击查看详情>>>"))
        self.label.outOfRangeText = outofRangeText
        self.label.attributedText = attrStr
        self.label.delegate = self

        self.title = "Out of range Demo"

        self.view.backgroundColor = UIColor.white
    }
}

extension TapOutofRangeTextDemoViewController: LKLabelDelegate {
    func tapShowMore(_ label: LKLabel) {
        print("Tap show more.")
    }

    func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        print("Tap link: \(url)")
    }
}
