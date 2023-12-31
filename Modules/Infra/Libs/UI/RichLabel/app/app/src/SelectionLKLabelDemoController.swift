//
//  SelectionLKLabel.swift
//  LarkUIKitDemo
//
//  Created by qihongye on 2018/12/17.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RichLabel

class SelectionLKLabelDemoViewController: UIViewController {

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
        label.seletionDebugOptions = LKSelectionLabelDebugOptions([.drawStartEndRect, .drawLineRect, .printTouchEvent])
        label.lineSpacing = 4
        label.selectionDelegate = self

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

    lazy var button: UIButton = {
        let button = UIButton()
        button.setTitle("切换Selection状态", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        return button
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.label)
        self.view.addSubview(self.button)

        self.label.preferredMaxLayoutWidth = self.view.frame.width - 60
        self.label.snp.makeConstraints { (make) in
            if #available(iOS 11.0, *) {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).offset(10)
            } else {
                make.top.equalTo(10)
            }
            make.left.equalTo(30)
            make.right.equalTo(-30)
        }
        self.button.snp.makeConstraints { (make) in
            make.top.equalTo(self.label.snp.bottom).offset(10)
            make.left.right.equalTo(self.label)
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
        attrStr.addAttribute(LKPointInnerRadiusAttributeName, value: 1, range: range)
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
        attrStr.addAttribute(LKAtAttributeName, value: UIColor.blue.withAlphaComponent(0.5), range: NSRange(location: 14, length: 5))
        attrStr.addAttribute(LKAtAttributeName, value: UIColor.blue.withAlphaComponent(0.5), range: NSRange(location: 45, length: 3))

        self.label.attributedText = attrStr
        self.label.inSelectionMode = true

        self.button.addTarget(self, action: #selector(changeInSelectionMode), for: .touchUpInside)

        self.title = "Selection LKlabel Demo"

        self.view.backgroundColor = UIColor.white
    }

    @objc
    private func changeInSelectionMode() {
        self.label.inSelectionMode = !self.label.inSelectionMode
    }
}

extension SelectionLKLabelDemoViewController: LKSelectionLabelDelegate {

    func selectionDragModeUpdate(_ inDragMode: Bool) {
        print("selectionDragModeUpdate \(inDragMode)")
    }

    func selectionRangeDidSelected(_ range: NSRange, didSelectedAttrString: NSAttributedString, didSelectedRenderAttributedString: NSAttributedString) {
        print("selectionRangeDidSelected: ", range, didSelectedAttrString.string, didSelectedRenderAttributedString.string)
    }

    func selectionRangeDidUpdate(_ range: NSRange) {
        guard let attributedText = self.label.attributedText else {
            return
        }
        print("selectionRangeDidUpdate: ", attributedText.attributedSubstring(from: range).string, range)
    }
}
