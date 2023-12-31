//
//  DrawLastLineDemoViewController.swift
//  LarkUIKitDemo
//
//  Created by qihongye on 2018/12/28.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RichLabel

class DrawLastLineDemoViewController: UIViewController {
    lazy var label: LKLabel = {
        let label = LKLabel()
        label.textColor = UIColor.black
        label.numberOfLines = 1
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.backgroundColor = UIColor.yellow
        label.autoDetectLinks = true
        label.isFuzzyPointAt = true
        label.fuzzyEdgeInsets = .init(top: -10, left: -2, bottom: -10, right: -2)
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

    lazy var label2: LKLabel = {
        let label = LKLabel()
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 1
        label.lineBreakMode = .byCharWrapping
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor.black.cgColor
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.label)
        self.label.preferredMaxLayoutWidth = self.view.frame.width - 20
        self.label.snp.makeConstraints { (make) in
            make.top.equalTo(300)
            make.height.equalTo(100)
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
            string: "https://developer.apple.com/documentation/coretext/ctfont-q6r",
            attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle
            ]
        )

        self.label.debug = LKTextRenderDebugOptions([.drawOutOfRangeTextRect, .drawGlyphRect])
        self.label.outOfRangeText = NSAttributedString(string: "点击查看详情>>>")
        self.label.attributedText = attrStr

//        view.addSubview(label2)
        label2.preferredMaxLayoutWidth = view.frame.width - 200
//        label2.snp.makeConstraints { (make) in
//            make.top.equalTo(label.snp.bottom).offset(20)
//            make.left.equalTo(100)
//            make.right.equalTo(-100)
//            make.height.equalTo(16)
//        }
        label2.outOfRangeText = NSAttributedString(string: "\u{2026}")
        label2.attributedText = NSAttributedString(string: "Zhang Li: ∠( ᐛ 」∠)_看戏五个😚ヾડ🌚ડ⸂⸂⸜👊⸝⸃⸃୧😂୨ฅ😸ฅ😉┌✺◟😄◞✺")

        self.title = "Draw Last Line Demo"

        self.view.backgroundColor = UIColor.white
    }
}
