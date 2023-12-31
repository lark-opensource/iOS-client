//
//  LKLabelDemoViewController.swift
//  LarkUIKitDemo
//
//  Created by qihongye on 2018/2/26.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import RichLabel
import SnapKit
import CoreText

class SomeView: UIView {
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        context.clear(rect)
        if let bgColor = self.backgroundColor {
            context.setFillColor(bgColor.cgColor)
            context.fill(rect)
        }
        context.textMatrix = .identity
        context.translateBy(x: 0, y: rect.height + rect.origin.y)
        context.scaleBy(x: 1.0, y: -1.0)

        context.restoreGState()
    }
}

class LKLabelDemoViewController: UIViewController {
    lazy var someView: SomeView = {
        let view = SomeView()
        view.backgroundColor = UIColor.blue
        return view
    }()

    lazy var label: LKSelectionLabel = {
        let label = LKSelectionLabel()
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.backgroundColor = UIColor.clear
        label.autoDetectLinks = true
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.debug = LKTextRenderDebugOptions([.drawGlyphRect])
        label.lineSpacing = 4

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

    lazy var uiLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.textAlignment = .left
        label.lineBreakMode = .byWordWrapping
        label.isUserInteractionEnabled = true
        label.backgroundColor = UIColor.red
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var forceLayoutLKLabel: LKLabel = {
        let label = LKLabel()
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.textAlignment = .left
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
        self.view.addSubview(self.uiLabel)
        self.view.addSubview(self.someView)
        let gesture = UITapGestureRecognizer(target: self, action: #selector(redraw))
        self.someView.addGestureRecognizer(gesture)
        self.someView.snp.makeConstraints { (make) in
            make.top.equalTo(20)
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.height.equalTo(100)
        }
        self.label.preferredMaxLayoutWidth = self.view.frame.width - 20
        self.label.snp.makeConstraints { (make) in
            make.top.equalTo(self.someView.snp.bottom).offset(10)
            make.left.equalTo(10)
            make.right.equalTo(-10)
        }
        self.uiLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.label.snp.bottom).offset(10)
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.bottom.equalTo(-20)
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
䶮Hi，经过数月的努力力，我们的 Lark 邮件上线了！
本封邮件是第一封 Lark 邮件，也是一封权限邮件。目前Lark 邮件功能还处于内部测试期，由于它非常通用，容易扩散，所以我们做了一些隔离，以免影响用户的正常使用 Lark 。隔离方案详情如下：
1、Lark 允许给一个人或群会话发送邮件，群内成员都会收到这封邮件，类似邮件组的概念，邮件发送成功后会在用户 feed 中出现；
2、本邮件的收件人和抄送人列表是“Lark 邮件测试白名单”，是测试期间 Lark 邮件可发送的用户与群组范围，我们在测试期间可以给上述人员和群组发送邮件；
3、如果给“Lark 邮件测试白名单”之外的用户或群组发送邮件，除了“发送者自己”之外的收件人会被系统自动过滤；
4、本邮件的收件人和抄送人有权限将其他群组或用户添加到“邮件参与者列表”，也就是说大家具备扩散 Lark 邮件的权限，但是最好不要添加非必要的大型群组，如“租房群”，这样可能会对群成员产生不必要的打扰；
功能介绍、bug反馈和意见收集请查看此文档：https://docs.bytedance.net/doc/uhbY8I0Tz2mSubM4XVD1ja
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
            value: font.italic(),
            range: NSRange(location: 10, length: 10)
        )
        attrStr.addAttribute(.font, value: font.bold(), range: NSRange(location: 30, length: 10))
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
            range: NSRange(location: 35, length: 50)
        )
        if #available(iOS 13.0, *) {
            attrStr.append(NSAttributedString(
                string: LKLabelAttachmentPlaceHolderStr,
                attributes: [LKEmojiAttributeName: LKEmoji(icon: UIImage.add, font: font, spacing: 5)]
            ))
            attrStr.append(NSAttributedString(
                string: LKLabelAttachmentPlaceHolderStr,
                attributes: [LKEmojiAttributeName: LKEmoji(icon: UIImage.actions, font: font, spacing: 5)]
            ))
            attrStr.append(NSAttributedString(
                string: LKLabelAttachmentPlaceHolderStr,
                attributes: [LKEmojiAttributeName: LKEmoji(icon: UIImage.checkmark, font: font, spacing: 5)]
            ))
        }

        self.label.attributedText = attrStr

        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.label.inSelectionMode = true
        })

        self.uiLabel.attributedText = attrStr

        self.title = "LKlabel Demo"

        self.view.backgroundColor = UIColor.white
    }
}
